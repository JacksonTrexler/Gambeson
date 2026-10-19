class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal ep_changed(was: int, now: int)
signal died(u: Unit)

const OUTLINE := preload("res://Shaders/outline.gdshader")

@export var cell: Vector2i
@export var faction: Faction
@export var learned: Array[Skill] = []
@export var movement := 5

@export var max_hp := 10:
	set(m):
		max_hp = m
		if hp > m:
			hp = m
		if is_node_ready():
			_show_hp()
@export var max_ep := 10:
	set(m):
		max_ep = m
		if ep > m:
			ep = m

# Core stats. Full names: `int` is a builtin type and a `str` member would hide str().
@export_group("Stats")
@export var strength := 5
@export var dexterity := 5
@export var constitution := 5
@export var intelligence := 5
@export var wisdom := 5
@export var charisma := 5

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

var ep := 0:
	set(v):
		v = clampi(v, 0, max_ep)
		if v == ep:
			return
		var was := ep
		ep = v
		ep_changed.emit(was, v)

# Everything the unit can use. Only learned skills so far; class, gear and faction skills merge in here.
var skills: Array[Skill]:
	get:
		var s: Array[Skill] = []
		for k in learned:
			if k and k not in s:
				s.append(k)
		return s

var actives: Array[Skill]:
	get:
		return _of_kind(Skill.Kind.ACTIVE)

var passives: Array[Skill]:
	get:
		return _of_kind(Skill.Kind.PASSIVE)

var timed: Dictionary[Effect, int] = {}  # effects others put on this unit -> turns left

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
		return roundi(_sum(Effect.Kind.LUCK))

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bar: ProgressBar = $HpBar


func _ready() -> void:
	hp_changed.connect(_show_hp)
	_show_faction()
	hp = max_hp
	ep = max_ep


func damage(d: int) -> void:
	hp -= maxi(d, 0)


# A tagged attack: mitigation is rounded down and damage taken up, unless the unit is lucky.
# Returns the damage taken.
func hit(raw: float, tags: Array[StringName]) -> int:
	var m := mitigation(tags)
	if m >= 1.0:
		return 0  # immune: no leftover fraction to round up
	var saved := Luck.settle(raw * m, luck, true)
	var taken := Luck.settle(maxf(raw - saved, 0.0), luck, false)
	damage(taken)
	return taken


# Fraction of a hit with these tags that's blocked (additive, capped at 100%).
func mitigation(tags: Array[StringName]) -> float:
	var t := Tags.expand(tags)
	var m := 0.0
	for e in effects:
		if e.kind == Effect.Kind.MITIGATE and e.tags.any(func(x): return x in t):
			m += _amount(e)
	return minf(m, 1.0)


func initiative_bonus() -> int:
	return roundi(_sum(Effect.Kind.INITIATIVE))


# Re-applying the same effect refreshes its timer rather than stacking.
func afflict(e: Effect) -> void:
	timed[e] = e.turns


# End of this unit's faction turn: timed effects count down.
func tick() -> void:
	for e in timed.keys():
		timed[e] -= 1
		if timed[e] <= 0:
			timed.erase(e)


# Dead units stay dead; use revive().
func heal(h: int) -> void:
	if is_alive():
		hp += maxi(h, 0)


func revive(h: int) -> void:
	if not is_alive():
		hp = maxi(h, 1)


# Pays an action cost; false (and nothing spent) if the unit can't afford it.
func spend(e: int) -> bool:
	if e < 0 or e > ep:
		return false
	ep -= e
	return true


func restore(e: int) -> void:
	ep += maxi(e, 0)


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


func _of_kind(k: Skill.Kind) -> Array[Skill]:
	var s: Array[Skill] = []
	s.assign(skills.filter(func(x: Skill): return x.kind == k))
	return s


func _sum(k: Effect.Kind) -> float:
	var total := 0.0
	for e in effects:
		if e.kind == k:
			total += _amount(e)
	return total


func _amount(e: Effect) -> float:
	if e.per_stat:
		return e.amount * floori(get(e.per_stat) / float(e.per))
	return e.amount
