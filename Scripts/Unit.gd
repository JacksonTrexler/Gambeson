class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal energy_changed(was: int, now: int)
signal reserve_changed(r: Reserve, was: int, now: int)
signal died(u: Unit)

const OUTLINE := preload("res://Shaders/outline.gdshader")
# Stats with a base value on the unit; effects add to these and to any other named stat.
const CORE: Array[StringName] = [&"strength", &"dexterity", &"constitution", &"intelligence",
		&"wisdom", &"charisma", &"movement", &"reach", &"size"]
const BASE_AP := 10.0
const HOTBAR := 4  # hotbar slots every unit has for now; higher levels will add more
const ENERGY_COLOR := Color("#e8c547")
const HP_COLOR := Color("#3fbf4f")
const SHAPE_EDGE := Color("#8a8f9c")  # outline of a shape whose side can't be told


# A timed effect on this unit: turns left, and the rank of the skill that applied it.
class Applied:
	var turns: int
	var rank: int

	func _init(t: int, r: int) -> void:
		turns = t
		rank = r


@export var cell: Vector2i
@export var faction: Faction
@export var role: Role
@export var race: Race
@export var nick := ""  # the name the player gave it (node names get sanitised)
@export var title := ""  # "of Red"
@export var level := 1
@export var look: Texture2D  # sprite; falls back to the role's, then the scene's
@export var tags: Array[StringName] = []  # what it is, beyond race and role (monster, undead...)
@export var vibe := ""  # the impression it gives off ("Smouldering", "Reeking")
@export var aura := 0  # -2 ominous .. +2 benevolent

@export_group("Persona")  # what it advertises; the Persona skill's rank says how much
@export var as_ally := false  # presents as the observer's ally (rank 2)
@export var shows_vibe: Array[String] = []  # rank 1
@export var shows_tags: Array[StringName] = []  # rank 3: identity
@export var shows_name := ""  # rank 3: the name it goes by while presenting that identity
@export_group("")
@export var innate: Array[Slot] = []  # from the unit's kind (villagers: Strike); the role adds its own
@export var learned: Array[Slot] = []  # per unit
# Skills on the hotbar by slot, null where empty (see Skill.fits_bar()). Left empty, it fills with
# the unit's actives, then its toggled passives.
@export var hotbar: Array[Skill] = []

@export var max_hp := 10:
	set(m):
		max_hp = m
		if hp > m:
			hp = m
		if is_node_ready():
			_show_bars()
@export var max_energy := 10:
	set(m):
		max_energy = m
		if energy > m:
			energy = m
		if is_node_ready():
			_show_bars()
@export var reserves: Dictionary[Reserve, int] = {}  # extra energy types -> max (Icor: mana 12)

@export_group("Stats")
@export var strength := 5
@export var dexterity := 5
@export var constitution := 5
@export var intelligence := 5
@export var wisdom := 5
@export var charisma := 5
@export var movement := 5  # movement points per turn
@export var reach := 0.0  # added to skill ranges; weapons and passives raise it
@export var size := 3  # Medium, when the unit has no race

# Starts at 0 and fills in _ready, so bars get an initial hp_changed(0, max_hp).
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

# The default energy every unit has; reserves (mana...) are extra.
var energy := 0:
	set(v):
		v = clampi(v, 0, max_energy)
		if v == energy:
			return
		var was := energy
		energy = v
		energy_changed.emit(was, v)

var stores: Dictionary[Reserve, int] = {}  # current amount of each reserve
var ap: Array[AP] = []  # refilled at the start of each of this unit's faction turns
var moved := 0.0  # movement spent this turn
var ground: Array[StringName] = []  # tags of the tile it stands on (Battle keeps this current)
var footing: Terrain  # the tile it stands on, whose effects it has while there (Battle keeps this current)
var timed: Dictionary[Effect, Applied] = {}  # effects others put on this unit
var exposed := 0  # concealment levels lost to attacking or being hit (Battle.cast); back as its side's turn starts
var shown: Read  # how the player's side sees it (see appear()); null: as it is
var _role_slots: Array[Slot] = []  # this unit's copies of its role's innate skills

# Every skill entry, the role's first; a skill listed twice keeps its highest rank.
var slots: Array[Slot]:
	get:
		var best := {}
		for s in _role_slots + innate + learned:
			if s and s.skill and (s.skill not in best or s.rank > best[s.skill].rank):
				best[s.skill] = s
		var out: Array[Slot] = []
		out.assign(best.values())
		return out

var actives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		s.assign(slots.filter(func(x: Slot): return not x.skill.passive).map(func(x: Slot): return x.skill))
		return s

# Passive entries that are on.
var on_passives: Array[Slot]:
	get:
		var s: Array[Slot] = []
		s.assign(slots.filter(func(x: Slot): return x.skill.passive and x.on))
		return s

var passives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		s.assign(on_passives.map(func(x: Slot): return x.skill))
		return s

var luck: int:
	get:
		return roundi(stat(&"luck"))

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hp_bar: ProgressBar = $HpBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var reserve_bar: ProgressBar = $ReserveBar


func _ready() -> void:
	# Skill entries hold per-unit state (rank, toggles), but scenes and roles share them: copy.
	_role_slots.assign((role.innate if role else []).map(func(s: Slot): return s.duplicate()))
	innate.assign(innate.map(func(s: Slot): return s.duplicate()))
	learned.assign(learned.map(func(s: Slot): return s.duplicate()))
	if role and not race:
		race = role.race
	if role and not look:
		look = role.look
	_fill_bar()
	_show_look()
	_layout_bars()
	_show_faction()
	hp_changed.connect(_show_bars.unbind(2))
	energy_changed.connect(_show_bars.unbind(2))
	reserve_changed.connect(_show_bars.unbind(3))
	hp = max_hp
	energy = max_energy
	for r in reserves:
		set_store(r, reserves[r])
	_show_bars()


func rank(s: Skill) -> int:
	for x in slots:
		if x.skill == s:
			return x.rank
	return 0


func is_on(s: Skill) -> bool:
	for x in slots:
		if x.skill == s:
			return x.on
	return false


# Switches a passive that has a toggle on or off. False if the unit has no such skill.
func toggle(s: Skill) -> bool:
	for x in slots:
		if x.skill == s and s.passive and s.toggle:
			x.on = not x.on
			return true
	return false


func bar_size() -> int:
	return HOTBAR


# Puts one of the unit's skills in hotbar slot i. A skill already on the bar swaps places with
# whatever is in i.
func bar_place(s: Skill, i: int) -> bool:
	if i < 0 or i >= hotbar.size() or not s or not s.fits_bar() or rank(s) == 0:
		return false
	var old := hotbar.find(s)
	if old >= 0:
		hotbar[old] = hotbar[i]
	hotbar[i] = s
	return true


func bar_clear(i: int) -> void:
	if i >= 0 and i < hotbar.size():
		hotbar[i] = null


func _fill_bar() -> void:
	var fresh := hotbar.is_empty()
	hotbar.resize(bar_size())
	if not fresh:
		return
	var picks := slots.filter(func(x: Slot): return not x.skill.passive)
	picks.append_array(slots.filter(func(x: Slot): return x.skill.passive and x.skill.fits_bar()))
	for i in mini(picks.size(), hotbar.size()):
		hotbar[i] = picks[i].skill


# Passives (on) that stop working on ground with these tags (Oceanic on water).
func paused_on(ground_tags: Array[StringName]) -> Array[Skill]:
	var out: Array[Skill] = []
	for s in passives:
		if s.effects.any(func(e: Effect): return e.unless_on.any(func(t): return t in ground_tags)):
			out.append(s)
	return out


# Base value (core stats only) plus every effect on that stat whose tags match the query;
# "mul" effects then multiply the total (Stoneskin halves dexterity).
func stat(s: StringName, tags: Array[StringName] = []) -> float:
	var t := Tags.expand(tags)
	var sum: float = 0.0
	if s == &"size" and race:
		sum = race.size
	elif s in CORE:
		sum = get(s)
	var factor := 1.0
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat != s or not (e.tags.is_empty() or e.tags.any(func(x): return x in t)):
			continue
		if e.above_hp > 0 and hp <= e.above_hp * max_hp:
			continue
		if pair[1] < e.min_rank or e.unless_on.any(func(x): return x in ground):
			continue
		var amount: float = e.amount * (floori(stat(e.per_stat) / e.per) if e.per_stat else 1) * (pair[1] if e.per_rank else 1)
		if e.op == "mul":
			factor *= amount
		else:
			sum += amount
	return sum * factor


# d20-style modifier: 10-11 -> 0, 12-13 -> +1, 8-9 -> -1. With a skill's tags, stand-in
# passives may swap the stat (see scaling()).
func mod(s: StringName, tags: Array[StringName] = []) -> int:
	return floori((scaling(s, tags) - 10) / 2.0)


# The stat value a skill with these tags scales on, after stand-in passives (Arcanist
# Perspective: int for wis/cha on magic skills). Below rank 5 the replaced stat must be at least
# (100% - 20% x rank) of the stand-in used, so the stand-in caps at replaced / (1 - 0.2 x rank).
# From rank 5 there's no cap, and each rank past 5 adds 20% of the replaced stat.
func scaling(s: StringName, tags: Array[StringName]) -> float:
	var base := stat(s)
	var best := base
	for x in on_passives:
		var p := x.skill
		if not (p.stand_in and s in p.replaces and p.tags.any(func(t): return t in tags)):
			continue
		var other := stat(p.stand_in)
		if x.rank < 5:
			best = maxf(best, minf(other, base / (1.0 - 0.2 * x.rank)))
		else:
			best = maxf(best, other + 0.2 * (x.rank - 5) * base)
	return best


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


func store(r: Reserve) -> int:
	return stores.get(r, 0)


func set_store(r: Reserve, v: int) -> void:
	v = clampi(v, 0, reserves.get(r, 0))
	var was := store(r)
	if v == was:
		return
	stores[r] = v
	reserve_changed.emit(r, was, v)


# What pays for a skill: a reserve that makes it cheaper (Hex: mana), then one dedicated to its tags
# (mana for magic, so Energy is kept for generic skills), then Energy, then any other reserve.
# Returns the Reserve, &"energy", or null if nothing can.
func funding(s: Skill) -> Variant:
	var allowed := reserves.keys().filter(func(r: Reserve): return r.only.is_empty() or r.only.any(func(t): return t in s.tags))
	for r: Reserve in allowed:
		if s.ap_with.has(r) and store(r) >= s.cost:
			return r
	for r: Reserve in allowed:
		if not r.only.is_empty() and store(r) >= s.cost:
			return r
	if energy >= s.cost:
		return &"energy"
	for r: Reserve in allowed:
		if store(r) >= s.cost:
			return r
	return null


func ap_cost(s: Skill, fund: Variant) -> float:
	if fund is Reserve:
		return s.ap * s.ap_with.get(fund, 1.0)
	return s.ap


func can_afford(s: Skill) -> bool:
	return can_afford_after(s, 0.0)


# Whether it could still pay for s after walking `steps` movement first (which takes move-only AP,
# then general AP the skill might have needed).
func can_afford_after(s: Skill, steps: float) -> bool:
	var fund: Variant = funding(s)
	if fund == null:
		return false
	var general := 0.0
	var move_only := 0.0
	for p in ap:
		if p.only == &"":
			general += p.amount
		elif p.only == &"move":
			move_only += p.amount
	var left := ap_for(&"skill") - maxf(steps - move_only, 0.0)
	return general >= maxf(steps - move_only, 0.0) - 0.0001 and left >= ap_cost(s, fund) - 0.0001


# Pays a skill's AP and cost from its funding. False (and nothing spent) if it can't.
func pay_for(s: Skill) -> bool:
	var fund: Variant = funding(s)
	if fund == null or not pay(ap_cost(s, fund), &"skill"):
		return false
	if fund is Reserve:
		set_store(fund, store(fund) - s.cost)
	else:
		energy -= s.cost
	return true


# Start of this unit's faction turn: fresh AP and movement, and it can slip back into hiding.
func refresh() -> void:
	ap = _pools()
	moved = 0.0
	exposed = 0


# What refresh() hands out: every pool together.
func full_ap() -> float:
	return _pools().reduce(func(sum: float, p: AP): return sum + p.amount, 0.0)


# General, then dex (moving only), then wis (skills only); negative mods cut the general pool.
# Haste: ap adds that fraction to the general and wis pools, dex_ap to the dex pool.
func _pools() -> Array[AP]:
	var dex := mod(&"dexterity")
	var wis := mod(&"wisdom")
	var more := 1.0 + stat(&"ap")
	var out: Array[AP] = [AP.new((BASE_AP + mini(dex, 0) + mini(wis, 0)) * more),
			AP.new(maxi(dex, 0) * (1.0 + stat(&"dex_ap")), &"move"), AP.new(maxi(wis, 0) * more, &"skill")]
	return out


func ap_left() -> float:
	return ap.reduce(func(sum: float, p: AP): return sum + p.amount, 0.0)


# Movement it can still make this turn: what's left of its movement, as far as its AP allows.
func move_left() -> float:
	return minf(stat(&"movement") - moved, ap_for(&"move"))


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


# Puts an effect on this unit for some of its faction's turns. Re-applying refreshes the timer
# (keeping the higher rank) rather than stacking.
func afflict(e: Effect, turns: int, at_rank := 1) -> void:
	var r := maxi(at_rank, timed[e].rank) if e in timed else at_rank
	timed[e] = Applied.new(turns, r)


# End of this unit's faction turn: timed effects count down.
func tick() -> void:
	for e in timed.keys():
		timed[e].turns -= 1
		if timed[e].turns <= 0:
			timed.erase(e)


func is_alive() -> bool:
	return hp > 0


func asleep() -> bool:
	return stat(&"sleep") > 0.0


func wake() -> void:
	for e in timed.keys():
		if e.stat == "sleep":
			timed.erase(e)


# [effect, rank] for every passive (that's on), timed effect, and effect of the ground it stands
# on. A timed effect the unit's own passives already give doesn't count twice (Stonegift on a
# Stoneskin golem).
func _effects() -> Array:
	var out := []
	var own := {}
	for x in on_passives:
		for e in x.skill.effects:
			out.append([e, x.rank])
			own[e] = true
	for e in timed:
		if e not in own:
			out.append([e, timed[e].rank])
	if footing:
		for e in footing.effects:
			out.append([e, 1])
	return out


# The reserve with the largest pool: the one shown above Energy (Wizards: mana).
func main_reserve() -> Reserve:
	var main: Reserve = null
	for r in reserves:
		if main == null or reserves[r] > reserves[main]:
			main = r
	return main


func _show_look() -> void:
	if look:
		var frames := SpriteFrames.new()
		frames.add_frame(&"default", look)
		sprite.sprite_frames = frames
		sprite.play(&"default")


# Bars stack up from just above the sprite's head: a slim yellow Energy bar, the main reserve
# (if any; Energy then fades back as the secondary pool), HP on top.
func _layout_bars() -> void:
	var main := main_reserve()
	energy_bar.add_theme_stylebox_override("fill", _flat(ENERGY_COLOR))
	energy_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	energy_bar.modulate.a = 0.45 if main else 1.0
	reserve_bar.visible = main != null
	if main:
		reserve_bar.add_theme_stylebox_override("fill", _flat(main.color))
		reserve_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	hp_bar.add_theme_stylebox_override("fill", _flat(HP_COLOR))
	var y := -sprite.sprite_frames.get_frame_texture(&"default", 0).get_height() / 2.0 - 1.0
	for pair in [[energy_bar, 2.0], [reserve_bar, 2.0], [hp_bar, 4.0]]:
		var bar: ProgressBar = pair[0]
		if not bar.visible:
			continue
		bar.size = Vector2(24, pair[1])
		bar.position = Vector2(-12, y - pair[1])
		y -= pair[1] + 1.0


# How the player's side sees it (the HUD calls this; until then it's drawn as it is). Not located:
# not drawn at all. Located with its side unknown: a black shape with no side colours and no bars.
# Otherwise it wears the side it shows as - its own, or one a persona claims - with bars for
# whatever of HP, energy and reserves can be made out. null: as it is.
func appear(r: Read) -> void:
	shown = r
	visible = r == null or r.located()
	_show_side(faction if r == null else r.faction, r != null and r.faction == null)
	_show_bars()


func _show_bars() -> void:
	var r := shown
	var main := main_reserve()
	hp_bar.visible = r == null or r.hp != null
	energy_bar.visible = r == null or r.energy != null
	reserve_bar.visible = main != null and energy_bar.visible
	hp_bar.max_value = r.max_hp if r and r.hp != null else max_hp
	hp_bar.value = r.hp if r and r.hp != null else hp
	energy_bar.max_value = maxi(max_energy, 1)
	energy_bar.value = r.energy if r and r.energy != null else energy
	if main:
		reserve_bar.max_value = reserves[main]
		reserve_bar.value = r.stores.get(main, 0) if r else store(main)


func _show_faction() -> void:
	_show_side(faction, false)


# Stand-in art: the side's primary outlines the sprite and trims the HP bar; secondary backs it.
# A shape is painted black inside a neutral outline.
func _show_side(f: Faction, shape: bool) -> void:
	var mat := sprite.material as ShaderMaterial
	if not mat:
		if not f and not shape:
			return
		mat = ShaderMaterial.new()
		mat.shader = OUTLINE
		sprite.material = mat
	mat.set_shader_parameter("color", SHAPE_EDGE if shape else (f.primary if f else Color.TRANSPARENT))
	mat.set_shader_parameter("shadow", shape)
	if f:
		hp_bar.add_theme_stylebox_override("background", _trimmed(f.secondary, f.primary))
		hp_bar.add_theme_stylebox_override("fill", _trimmed(HP_COLOR, f.primary))


func _trimmed(c: Color, trim: Color) -> StyleBoxFlat:
	var box := _flat(c)
	box.border_color = trim
	box.set_border_width_all(1)
	return box


func _flat(c: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	return box
