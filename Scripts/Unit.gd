class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal energy_changed(was: int, now: int)
signal reserve_changed(r: Reserve, was: int, now: int)
signal died(u: Unit)

# Stats with a base value on the unit; effects add to these and to any other named stat.
const CORE: Array[StringName] = [&"strength", &"dexterity", &"constitution", &"intelligence",
		&"wisdom", &"charisma", &"movement", &"reach", &"size"]
const BASE_AP := 10.0
const SLOTS := 4  # skill slots at level 1; one more every 4 levels (slot_count()), plus any skills grant
const ENERGY_COLOR := Color("#e8c547")
const HP_COLOR := Color("#3fbf4f")
const SHAPE_EDGE := Color("#8a8f9c")  # glow of a shape whose side can't be told
const SHAPE := Color(0.03, 0.03, 0.03)  # what a shape is painted
const GLOW := 0.55  # how strongly a unit glows in its side's colour
const TRIM_DARKEN := 0.45  # bar trim: the side's primary, this much darker
const BAR_WIDTH := 24.0


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
# Skills on the hotbar by slot, null where empty (see Skill.fits_bar() and slot_kinds()). Left empty,
# it fills with the unit's actives, then its toggled passives.
@export var hotbar: Array[Skill] = []
@export var lore: Array[Skill] = []  # accrued knowledge: skills it has come to know of and can unlock
@export var skill_points := 0  # one per level gained, spent unlocking skills (unlock())

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

@export_group("Equipment")
@export var armor: Item  # sets its Defense (none: dex mod + con mod; see armor_defense())
@export var weapon: Item  # can let its strength attacks use another stat (wielded())

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
var rest := 0.0  # energy recovered towards the next whole point (recover())
var _role_slots: Array[Slot] = []  # this unit's copies of its role's innate skills
var _ap_start: Array[float] = []  # each AP pool as its turn started, to tell how hard it worked (activity())
var _kinds: Array[StringName] = []  # the slot kinds the hotbar was last arranged for (_arrange())

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
@onready var glow: Sprite2D = $Glow
@onready var trim: Panel = $BarTrim
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


# Its sure skill slots: 4 + level / 4, rounded down.
func slot_count() -> int:
	return SLOTS + floori(level / 4.0)


# Slots its passives grant (Basic Magic Skill Slot +1), in the order it learned them: each one's type
# (magical, martial, specialist: it only holds skills carrying that tag), or &"" for an untyped one.
func granted_slots() -> Array[StringName]:
	var out: Array[StringName] = []
	for x in on_passives:
		for e in x.skill.effects:
			if e.stat == "slots":
				for i in roundi(e.amount * (x.rank if e.per_rank else 1)):
					out.append(e.tags[0] if not e.tags.is_empty() else &"")
	return out


# Every hotbar slot's kind, in order: its sure slots (&""), then the slots its skills grant (their
# type), then the clover slot (&"clover") while level / 4 has something to round.
func slot_kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	for i in slot_count():
		out.append(&"")
	out.append_array(granted_slots())
	if level % 4:
		out.append(&"clover")
	return out


func slot_kind(i: int) -> StringName:
	var kinds := slot_kinds()
	return kinds[i] if i >= 0 and i < kinds.size() else &""


# The clover slot: the one more a lucky unit gets from rounding level / 4 up instead - the last slot,
# while level isn't a multiple of 4 (-1 when it is: there's nothing to round). It only works while the
# unit is lucky; a level that makes the rounding exact turns it into a plain slot.
func clover() -> int:
	return slot_count() + granted_slots().size() if level % 4 else -1


# Hotbar slots, the clover slot included (whether it works now or not).
func bar_size() -> int:
	return slot_kinds().size()


# Whether hotbar slot i works now: every slot does but the clover slot, which needs the unit lucky.
func slot_works(i: int) -> bool:
	return i >= 0 and i < bar_size() and (i != clover() or luck > 0)


# Whether s can go in hotbar slot i: a typed slot only holds skills carrying its type.
func fits(s: Skill, i: int) -> bool:
	var k := slot_kind(i)
	return k == &"" or k == &"clover" or k in s.tags


# x rounded down, or up while the unit is lucky (level / 2 for a Gambeson, level / 4 for slots).
func rounded(x: float) -> int:
	return Luck.settle(x, luck, true, false)


# Puts one of the unit's skills in hotbar slot i (one that works and that it fits). A skill already on
# the bar swaps places with whatever is in i - which comes off the bar if it doesn't fit there.
func bar_place(s: Skill, i: int) -> bool:
	if i < 0 or i >= hotbar.size() or not slot_works(i) or not s or not s.fits_bar() or rank(s) == 0 or not fits(s, i):
		return false
	var old := hotbar.find(s)
	if old >= 0:
		hotbar[old] = hotbar[i] if hotbar[i] and fits(hotbar[i], old) else null
	hotbar[i] = s
	return true


func bar_clear(i: int) -> void:
	if i >= 0 and i < hotbar.size():
		hotbar[i] = null


func level_up() -> void:
	level += 1
	skill_points += 1
	_arrange()


# The first empty hotbar slot that works (and that s fits, given one), or -1.
func free_slot(s: Skill = null) -> int:
	for i in hotbar.size():
		if not hotbar[i] and slot_works(i) and (s == null or fits(s, i)):
			return i
	return -1


# The skills on offer to it, by where they come from: its class (its options, or its whole skill
# tree), its species, and what it's come to know.
func sources() -> Dictionary:
	return {
		&"class": role.offered() if role else ([] as Array[Skill]),
		&"species": race.options if race else ([] as Array[Skill]),
		&"knowledge": lore,
	}


# sources(), less the skills it already has and those it can't learn yet: what a skill point could
# unlock.
func options() -> Dictionary:
	var out := {}
	var all := sources()
	for k in all:
		var fresh: Array[Skill] = []
		fresh.assign(all[k].filter(func(x: Skill): return x and rank(x) == 0 and missing(x) == ""))
		out[k] = fresh
	return out


# What stands between it and learning s, apart from skill points: "" if nothing. A stub waits on an
# open question; on a class tree, the skills a branch comes after, and the count of its root's
# skills a capstone needs.
func missing(s: Skill) -> String:
	if s.stub:
		return s.waits()
	var root := role.root_of(s) if role else null
	if not root:
		return ""
	var b := root.branch(s)
	var first := b.after.filter(func(x: Skill): return rank(x) == 0)
	if not first.is_empty():
		return "Learn %s first" % " and ".join(first.map(func(x: Skill): return x.name))
	if b.needs > 0:
		var have := root.skills().filter(func(x: Skill): return x != s and rank(x) > 0).size()
		if have < b.needs:
			return "Needs %d %s skills (%d so far)" % [b.needs, root.name, have]
	return ""


# Spends a skill point on one of options(), learning it at rank I: onto the hotbar's first free slot
# that fits it, if it goes there; slots it grants join the bar. False if it can't.
func unlock(s: Skill) -> bool:
	if skill_points <= 0 or not options().values().any(func(list: Array): return s in list):
		return false
	var x := Slot.new()
	x.skill = s
	learned.append(x)
	skill_points -= 1
	_arrange()
	var free := free_slot(s)
	if s.fits_bar() and free >= 0:
		hotbar[free] = s
	return true


# Skill points to raise s from its rank r to r + 1: 1 + r^2 (II costs 2, III 5, IV 10). Unlocking
# (r = 0) is the same rule: 1.
func raise_cost(s: Skill) -> int:
	var r := rank(s)
	return 1 + r * r


# Whether s can go up a rank at all: it has it, and it's below the skill's cap.
func can_raise(s: Skill) -> bool:
	var r := rank(s)
	return r > 0 and not s.stub and (s.max_rank == 0 or r < s.max_rank)


# Spends raise_cost() to take s up a rank. False (nothing spent) if it can't, or lacks the points.
func raise(s: Skill) -> bool:
	if not can_raise(s) or skill_points < raise_cost(s):
		return false
	skill_points -= raise_cost(s)
	for x in slots:
		if x.skill == s:
			x.rank += 1
	_arrange()  # a slot-granting skill may grant more per rank
	return true


func _fill_bar() -> void:
	var fresh := hotbar.is_empty()
	hotbar.resize(bar_size())
	_kinds = slot_kinds()
	if not fresh:
		return
	var picks := slots.filter(func(x: Slot): return not x.skill.passive)
	picks.append_array(slots.filter(func(x: Slot): return x.skill.passive and x.skill.fits_bar()))
	for x in picks:
		var i := free_slot(x.skill)
		if i >= 0:
			hotbar[i] = x.skill


# Re-sorts the hotbar after its slots change (a level, a slot-granting skill): each skill keeps a slot
# of the kind it was in - sure slots in order, typed ones by type, and the clover slot's skill in the
# clover slot, or in a sure one when the clover slot turns plain. A skill left with no slot comes off
# the bar.
func _arrange() -> void:
	var now := slot_kinds()
	if now == _kinds and hotbar.size() == now.size():
		return
	var queues := {}
	for i in hotbar.size():
		queues.get_or_add(_kinds[i] if i < _kinds.size() else &"", []).append(hotbar[i])
	var out: Array[Skill] = []
	for k in now:
		var from: Array = queues.get(k, [])
		if from.is_empty() and k == &"" and &"clover" not in now:
			from = queues.get(&"clover", [])
		out.append(from.pop_front() if not from.is_empty() else null)
	hotbar = out
	_kinds = now


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
		if e.per_mod:
			amount *= mod(e.per_mod)
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
# Perspective: int for wis/cha on magical skills). Below rank 5 the replaced stat must be at least
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


# What an attack with these tags must roll to hit it: what its armor sets, plus defense effects -
# untagged ones always, tagged ones against attacks carrying that tag or a child of it (physical
# Defense counts against a pierce).
func defense(tags: Array[StringName] = []) -> int:
	return armor_defense() + roundi(stat(&"defense", tags))


# The Defense it has on top against attacks carrying a particular tag: tag -> how much more (Hydera:
# magical +1). Tags it has none extra for are left out.
func tagged_defense() -> Dictionary:
	var out := {}
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat == "defense":
			for t in e.tags:
				var extra := defense([t]) - defense()
				if extra:
					out[t] = extra
	return out


# Defense from armor alone. Unarmored: dex mod + con mod. Armored: the higher of the armor's floor
# and level x its per_level (rounded down, or up while lucky), plus dex mod if the armor allows it.
func armor_defense() -> int:
	if not armor:
		return mod(&"dexterity") + mod(&"constitution")
	var floor_or_level := maxi(armor.defense, rounded(level * armor.per_level))
	return floor_or_level + (mod(&"dexterity") if armor.plus_dex else 0)


# What it adds to s's attack roll: its mod in the skill's stat (Skill.stat()), or in a stat its
# weapon lets it use instead.
func attack_mod(s: Skill) -> int:
	return mod(wielded(s.stat(), s.tags), s.tags)


# The stat it really uses where one is asked for: for strength, a weapon may allow others, and it
# uses the best (a rapier: dexterity).
func wielded(s: StringName, tags: Array[StringName] = []) -> StringName:
	if s != &"strength" or not weapon:
		return s
	var best := s
	for x in weapon.attack_stats:
		if mod(x, tags) > mod(best, tags):
			best = x
	return best


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


# What s costs it, at its rank (starter spells: cost x rank), before any savings (cost_from()).
func price(s: Skill) -> int:
	return s.price(rank(s))


# What s costs it paid from fund: price(), times the best cost_with factor of any reserve that
# payment counts as, where its passives open that reserve up to s's tier (Mana I: the starter spells
# at half cost). Rounded up.
func cost_from(s: Skill, fund: Variant) -> int:
	var factor := 1.0
	for r in s.cost_with:
		if pays_as(s, fund, r) and opened(r) >= tier(s):
			factor = minf(factor, s.cost_with[r])
	return ceili(price(s) * factor - 0.0001)


# The highest tier its passives open r's savings for (Mana II: tier 2); 0 if none do.
func opened(r: Reserve) -> int:
	var best := 0
	for x in on_passives:
		if x.skill.opens == r:
			best = maxi(best, x.rank)
	return best


# s's tier for it: from its class's tree, else 1 (species and lore skills).
func tier(s: Skill) -> int:
	return maxi(role.tier(s) if role else 0, 1)


# What pays for a skill: a reserve that makes it cheaper (Hex: mana, for AP; the starter spells:
# mana, for cost), then one dedicated to its tags (mana for magical skills, so Energy is kept for
# generic skills), then Energy, then any other reserve. Returns the Reserve, &"energy", or null if
# nothing can.
func funding(s: Skill) -> Variant:
	var allowed := reserves.keys().filter(func(r: Reserve): return r.only.is_empty() or r.only.any(func(t): return t in s.tags))
	for r: Reserve in allowed:
		if (s.ap_with.has(r) or cost_from(s, r) < price(s)) and store(r) >= cost_from(s, r):
			return r
	for r: Reserve in allowed:
		if not r.only.is_empty() and store(r) >= cost_from(s, r):
			return r
	if energy >= cost_from(s, &"energy"):
		return &"energy"
	for r: Reserve in allowed:
		if store(r) >= cost_from(s, r):
			return r
	return null


# Tags its Energy counts as, from its passives (Working Knowledge: magical).
func energy_tags() -> Array[StringName]:
	var out: Array[StringName] = []
	for p in passives:
		for t in p.energy_as:
			if t not in out:
				out.append(t)
	return out


# Whether paying for s with fund counts as paying with reserve r, for r's bonuses: r itself, or Energy
# its passives let count as r for skills like s (Working Knowledge: Energy counts as Mana for Hex).
func pays_as(s: Skill, fund: Variant, r: Reserve) -> bool:
	if fund is Reserve:
		return fund == r
	if fund != &"energy":
		return false
	return energy_tags().any(func(t): return t in s.tags and t in r.only)


# AP to use s paid from fund: its AP, times the best factor of any reserve that payment counts as.
func ap_cost(s: Skill, fund: Variant) -> float:
	var factor := 1.0
	for r in s.ap_with:
		if pays_as(s, fund, r):
			factor = minf(factor, s.ap_with[r])
	return s.ap * factor


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
		set_store(fund, store(fund) - cost_from(s, fund))
	else:
		energy -= cost_from(s, fund)
	return true


# Start of this unit's faction turn: fresh AP and movement, and it can slip back into hiding.
func refresh() -> void:
	ap = _pools()
	_ap_start.assign(ap.map(func(p: AP): return p.amount))
	moved = 0.0
	exposed = 0


# How hard it worked this turn: &"rest" (it didn't move or spend AP), &"light" (it only spent its
# dex move or wis skill AP, leaving the general pool whole) or &"busy".
func activity() -> StringName:
	var general := 0.0
	var spent := 0.0
	for i in mini(ap.size(), _ap_start.size()):
		var used := _ap_start[i] - ap[i].amount
		spent += used
		if ap[i].only == &"":
			general += used
	if spent < 0.0001 and is_zero_approx(moved):
		return &"rest"
	return &"light" if general < 0.0001 else &"busy"


# Energy back as its side's turn ends, by activity(). Resting: (con mod + wis mod) / 2 a turn,
# rounded down (up while lucky), at least 1; below 0, a point every (1 - that) turns rested
# instead (-2: one every 3). Light activity: half as fast. Busy: none. Returns what it got back.
func recover() -> int:
	var k := rounded((mod(&"constitution") + mod(&"wisdom")) / 2.0)
	var rate := float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)
	match activity():
		&"rest":
			rest += rate
		&"light":
			rest += rate / 2.0
		_:
			return 0
	if energy >= max_energy:
		rest = 0.0
		return 0
	var whole := floori(rest + 0.0001)
	rest -= whole
	var was := energy
	energy += whole
	return energy - was


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


# Bars sit just above the sprite's head as one block: HP on top and, peeking out 2px under it, each
# lesser pool - the main reserve (if any), then Energy (fading back when there's a reserve). Their
# side trims the block (_show_side()).
func _layout_bars() -> void:
	var main := main_reserve()
	energy_bar.add_theme_stylebox_override("fill", _flat(ENERGY_COLOR))
	energy_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	energy_bar.modulate.a = 0.45 if main else 1.0
	if main:
		reserve_bar.add_theme_stylebox_override("fill", _flat(main.color))
		reserve_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	hp_bar.add_theme_stylebox_override("fill", _flat(HP_COLOR))
	hp_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_border_width_all(1)
	trim.add_theme_stylebox_override("panel", box)


# Stacks the visible bars from the bottom up, with the trim one pixel out around them.
func _stack() -> void:
	var bottom := -sprite.sprite_frames.get_frame_texture(&"default", 0).get_height() / 2.0 - 2.0
	var y := bottom
	for pair in [[energy_bar, 2.0], [reserve_bar, 2.0], [hp_bar, 4.0]]:
		var bar: ProgressBar = pair[0]
		if bar.visible:
			bar.size = Vector2(BAR_WIDTH, pair[1])
			bar.position = Vector2(-BAR_WIDTH / 2.0, y - pair[1])
			y -= pair[1]
	trim.visible = y < bottom
	trim.position = Vector2(-BAR_WIDTH / 2.0 - 1.0, y - 1.0)
	trim.size = Vector2(BAR_WIDTH + 2.0, bottom - y + 2.0)


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
	_stack()


func _show_faction() -> void:
	_show_side(faction, false)


# Stand-in art: a faint glow of the side's primary behind the sprite; the bars get its primary,
# darkened, as trim and its secondary behind HP. A shape is painted black over a neutral glow.
func _show_side(f: Faction, shape: bool) -> void:
	sprite.modulate = SHAPE if shape else Color.WHITE
	glow.visible = shape or f != null
	if glow.visible:
		glow.modulate = Color(SHAPE_EDGE if shape else f.primary, GLOW)
	if f:
		hp_bar.add_theme_stylebox_override("background", _flat(f.secondary))
		(trim.get_theme_stylebox("panel") as StyleBoxFlat).border_color = f.primary.darkened(TRIM_DARKEN)


func _flat(c: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	return box
