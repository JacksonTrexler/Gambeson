class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal energy_changed(was: int, now: int)
signal died(u: Unit)

const OUTLINE := preload("res://Shaders/outline.gdshader")
# Stats with a base value on the unit; effects add to these and to any other named stat.
const CORE: Array[StringName] = [&"strength", &"dexterity", &"constitution", &"intelligence",
		&"wisdom", &"charisma", &"movement", &"reach", &"size"]
const BASE_AP := 10.0

@export var cell: Vector2i
@export var faction: Faction
@export var innate: Array[Skill] = []  # from the unit's kind/class scene (villagers: Strike)
@export var learned: Array[Skill] = []  # per unit

@export var max_hp := 10:
	set(m):
		max_hp = m
		if hp > m:
			hp = m
		if is_node_ready():
			_show_hp()
@export var max_energy := 10:
	set(m):
		max_energy = m
		if energy > m:
			energy = m

@export_group("Stats")
@export var strength := 5
@export var dexterity := 5
@export var constitution := 5
@export var intelligence := 5
@export var wisdom := 5
@export var charisma := 5
@export var movement := 5  # movement points per turn
@export var reach := 0.0  # added to skill ranges; weapons and passives raise it
@export var size := 3  # Medium (Human)

# Starts at 0 and fills in _ready, so HP bars get an initial hp_changed(0, max_hp).
var hp := 0:
	set(v):
		v = clampi(v, 0, max_hp)
		if v == hp:
			return
		var was := hp
		hp = v
		hp_changed.emit(was, v)
		if v == 0:  # local v, not hp: a listener may have changed hp re-entrantly
			died.emit(self)

# The default resource skills are paid in; classes may add others (mana, stamina...).
var energy := 0:
	set(v):
		v = clampi(v, 0, max_energy)
		if v == energy:
			return
		var was := energy
		energy = v
		energy_changed.emit(was, v)

var ap: Array[AP] = []  # refilled at the start of each of this unit's faction turns
var moved := 0.0  # movement spent this turn
var timed: Dictionary[Effect, int] = {}  # effects others put on this unit -> turns left

var skills: Array[Skill]:
	get:
		var s: Array[Skill] = []
		for k in innate + learned:
			if k and k not in s:
				s.append(k)
		return s

var actives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		s.assign(skills.filter(func(k: Skill): return not k.passive))
		return s

var passives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		s.assign(skills.filter(func(k: Skill): return k.passive))
		return s

# Passives' effects plus timed ones (e.g. Hex).
var effects: Array[Effect]:
	get:
		var e: Array[Effect] = []
		for s in passives:
			e.append_array(s.effects)
		e.append_array(timed.keys())
		return e

var luck: int:
	get:
		return roundi(stat(&"luck"))

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bar: ProgressBar = $HpBar


func _ready() -> void:
	hp_changed.connect(_show_hp)
	_show_faction()
	hp = max_hp
	energy = max_energy


# Base value (core stats only) plus every effect on that stat whose tags match the query.
func stat(s: StringName, tags: Array[StringName] = []) -> float:
	var t := Tags.expand(tags)
	var sum: float = get(s) if s in CORE else 0.0
	for e in effects:
		if e.stat == s and (e.tags.is_empty() or e.tags.any(func(x): return x in t)):
			sum += e.amount * (floori(stat(e.per_stat) / e.per) if e.per_stat else 1)
	return sum


# d20-style modifier: 10-11 -> 0, 12-13 -> +1, 8-9 -> -1.
func mod(s: StringName) -> int:
	return floori((stat(s) - 10) / 2.0)


func damage(d: int) -> void:
	hp -= maxi(d, 0)


# A tagged attack. Mitigation applies, then net luck (mine minus the attacker's) rounds what's
# left: up (against me) unless I'm luckier. Returns the damage taken.
func hit(raw: float, tags: Array[StringName], by: Unit = null) -> int:
	var net := luck - (by.luck if by else 0)
	var taken := Luck.settle(raw * (1.0 - mitigation(tags)), net, false)
	damage(taken)
	return taken


# Fraction of a hit with these tags that's blocked (additive, capped at 100%).
func mitigation(tags: Array[StringName]) -> float:
	return minf(stat(&"mitigate", tags), 1.0)


# Dead units stay dead.
func heal(h: int) -> void:
	if is_alive():
		hp += maxi(h, 0)


func can_afford(s: Skill) -> bool:
	return ap_for(&"skill") >= s.ap - 0.0001 and get(s.resource) >= s.cost


# Pays a skill's resource cost; false (and nothing spent) if the unit can't afford it.
func spend(n: int, res := &"energy") -> bool:
	if n < 0 or n > get(res):
		return false
	set(res, get(res) - n)
	return true


# Start of this unit's faction turn: fresh AP and movement.
func refresh() -> void:
	var dex := mod(&"dexterity")
	var wis := mod(&"wisdom")
	# general, then dex (moving only), then wis (skills only); negative mods cut the general pool
	ap = [AP.new(BASE_AP + mini(dex, 0) + mini(wis, 0)), AP.new(maxi(dex, 0), &"move"), AP.new(maxi(wis, 0), &"skill")]
	moved = 0.0


# AP available for a use (&"move" or &"skill").
func ap_for(use: StringName) -> float:
	var sum := 0.0
	for p in ap:
		if p.only == use or p.only == &"":
			sum += p.amount
	return sum


# Pays AP for a use, draining pools reserved for it before general ones.
func pay(n: float, use: StringName) -> bool:
	if n > ap_for(use) + 0.0001:
		return false
	for p in ap.filter(func(x: AP): return x.only == use) + ap.filter(func(x: AP): return x.only == &""):
		var take := minf(p.amount, n)
		p.amount -= take
		n -= take
	return true


# Re-applying the same effect refreshes its timer rather than stacking.
func afflict(e: Effect) -> void:
	timed[e] = e.turns


# End of this unit's faction turn: timed effects count down.
func tick() -> void:
	for e in timed.keys():
		timed[e] -= 1
		if timed[e] <= 0:
			timed.erase(e)


func is_alive() -> bool:
	return hp > 0


func _show_hp(_was := 0, _now := 0) -> void:
	bar.max_value = max_hp
	bar.value = hp


# Stand-in art: faction primary outlines the sprite and trims the HP bar; secondary backs the bar.
func _show_faction() -> void:
	if not faction:
		return
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE
	mat.set_shader_parameter("color", faction.primary)
	sprite.material = mat
	bar.add_theme_stylebox_override("background", _trimmed(faction.secondary))
	bar.add_theme_stylebox_override("fill", _trimmed(Color("#3fbf4f")))


func _trimmed(c: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	box.border_color = faction.primary
	box.set_border_width_all(1)
	return box
