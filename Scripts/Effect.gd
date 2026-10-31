class_name Effect
extends Resource

# Changes a unit stat. Any stat Unit.stat() knows works; the dropdown just guards typos
# (and stores names, not numbers, so reordering it can't corrupt saved skills).
# Perception stats take a kind as their tag: concealment/nullify [dark], trickery [sound], recon [trap].
# command / party: added to how far the leader's orders reach and how big its party can be.
# regen / poison: that fraction of max HP healed / lost as the unit's side starts a turn.
# bleed: HP lost as the unit's side ends a turn: `dice` + the mod in `dice_mod` of whoever put it
# on, at least 1 (Snare's Bleeding: 1d4 + the setter's dex mod).
# grappled: held - it must break free to move, and takes its holder's grip each turn it ends held
# (Drown; Battle._break_free(), Battle._grip()).
# sleep: above 0, the unit can't act (Battle wakes it when an ally ends the turn beside it).
# ap / dex_ap: that fraction more AP each turn - the general and wis pools / the dex pool (Haste).
# relay: per point of strength mod, that share off the size penalty for moving through units - its
# own moves, and allies' through it - which can turn it into a boost (Battle.pass_cost()).
# trap_word: word of the traps it lays carries (1 + this) times as far, and allies it doesn't reach
# still get a vibe of them (Hazard Expert; Battle.lay()).
# defense: added to the Defense its armor sets; tagged, only against attacks carrying the tag or a
# child of it (physical: slash, pierce, blunt) - see Unit.defense().
# slots: hotbar slots a passive grants, typed by its first tag (magical, martial, specialist: they
# only hold skills carrying it) or untyped with none - see Unit.granted_slots().
# meander: tiles a turn it can walk while still standing still, passing by ground no stronger than
# that (Meander; Unit.still()).
# evaluates: tiles off it sees the rolls of allies using active skills, its own too (Self-evaluation;
# Battle.evaluators()).
# insight: a bonus to reading others; any makes its holder insightful (Unit.insightful()).
# embellish: stats, highest first, that seem 20% higher to those it fools (Embellish;
# Perception.embellish()).
# brood: its stats seem 25% lower a point to those it fools; from 5, allies within (brood - 4) tiles
# seem 10% x (brood - 4) lower (Brood; Perception._seem()).
# conspire: allies within (conspire + cha mod) tiles let its persona fool them, and each gives it
# (conspire - 1) trickery (Conspire; Perception.conspires_with()).
# ally_mitigate: the share of damage from allies blocked, on top of mitigate (Conspire).
# eyes_forward: ending its turn on a move, it looks this + wis mod tiles ahead, this to either side
# (Eyes Forward; Battle._look_ahead()).
# keen_eyes: its checks on things not beside it lose only distance / (this + 1) (Special Eyes;
# Battle.distance_penalty()).
# scrambled: it sees everyone's tags scrambled; investigating an ally may set that one straight (Haluca;
# Perception.unit(), Battle.inspect()).
# ire: that many ranks of its concealment and trickery defeated, against everyone (Ramut's Ire,
# a rank a stalled turn; Perception).
@export_enum("luck", "mitigate", "initiative", "reach", "movement", "move_cost", "size",
		"strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma",
		"recon", "concealment", "trickery", "nullify", "trap_power", "persona",
		"command", "party", "regen", "poison", "sleep", "ap", "dex_ap", "relay", "trap_word",
		"defense", "slots", "meander", "evaluates", "insight", "embellish", "brood", "conspire", "ally_mitigate", "ire",
		"bleed", "grappled", "eyes_forward", "keen_eyes", "scrambled") var stat := "luck"
@export_enum("add", "mul") var op := "add"  # mul: multiplies the stat after everything is added
@export var amount := 1.0
@export var tags: Array[StringName] = []  # only counts for queries carrying one of these (or a child of one); empty: always
@export var per_stat := &""  # optional scaling: amount x floor(stat / per), e.g. charisma / 10
@export var per := 10
@export var per_mod := &""  # optional scaling: amount x the holder's mod in this stat (Mage Armor: intelligence)
@export var per_rank := false  # amount x the skill's rank (Hex III: luck -3)
@export var min_rank := 0  # only from this rank of the skill up (Wary V: traps hit enemies harder)
@export var above_hp := 0.0  # only while hp is above this fraction of max (Stoneskin: 0.85)
@export var unless_on: Array[StringName] = []  # off while the unit stands on ground with these tags (Oceanic: water, wet)
@export var name := ""  # a condition it's part of ("Haste": ap and dex_ap), shown as one; empty: its stat
@export var turns := 0  # put on a unit: lasts this many of its turns (0: as the skill or ground says)
@export var wound := false  # tagged wound: a heal of at least its rank clears it (Battle.mend())
@export var dice := Vector2i.ZERO  # bleed: rolled each turn...
@export var dice_mod := &""  # ...plus the mod in this of whoever put it on (Snare: dexterity)


const TITLES := {"mitigate": "Damage taken", "move_cost": "Move cost", "trap_power": "Trap power",
		"regen": "Heal", "poison": "Poison", "ap": "AP", "dex_ap": "Dex AP", "trap_word": "Trap word",
		"slots": "Skill slots", "evaluates": "Self-evaluation", "ally_mitigate": "Friendly fire taken",
		"eyes_forward": "Eyes forward", "keen_eyes": "Keen eyes", "scrambled": "Scrambled"}
const HARMFUL := ["move_cost", "poison", "sleep", "ire", "bleed", "grappled", "scrambled"]  # more of these is worse for whoever has them


# "Luck: -3", "Damage taken: -40% (physical), above 85% HP", "Heal: 10% each turn", at a skill rank.
func describe(rank := 1) -> String:
	return "%s: %s" % [title(), value(rank)]


func title() -> String:
	return TITLES.get(stat, stat.capitalize())


# What it's shown under: the condition it's part of, or its stat.
func label() -> String:
	return name if name else title()


# "Poison: 5% each turn", "Haste: AP +10%, Dex AP +20%" - a condition's effects as one line.
static func summarize(group: Array[Effect]) -> String:
	var parts := group.map(func(e: Effect): return e.value() if e.title() == e.label() else "%s %s" % [e.title(), e.value()])
	return "%s: %s" % [group[0].label(), ", ".join(parts)]


# Effects by label() in order of first appearance, each group a condition.
static func conditions(effects: Array[Effect]) -> Array[Array]:
	var out: Array[Array] = []
	var at := {}
	for e in effects:
		if e.label() not in at:
			at[e.label()] = out.size()
			out.append([] as Array[Effect])
		out[at[e.label()]].append(e)
	return out


# +1 if it helps whoever has it, -1 if it hurts them.
func helps() -> int:
	var up := amount > 1.0 if op == "mul" else amount > 0.0
	return (1 if up else -1) * (-1 if stat in HARMFUL else 1)


func value(rank := 1) -> String:
	var x := amount * (rank if per_rank else 1)
	var text: String
	if op == "mul":
		text = "x" + Skill.num(x)
	elif stat == "mitigate":
		text = _signed(-x * 100.0) + "%"
	elif stat in ["regen", "poison"]:
		text = "%s%% each turn" % Skill.num(x * 100.0)
	elif stat == "sleep":
		text = "can't act till an ally ends the turn beside it"
	elif stat == "bleed":
		text = "%dd%d%s HP as each of its turns ends" % [dice.x, dice.y, " + %s mod" % String(dice_mod).left(3) if dice_mod else ""] if dice != Vector2i.ZERO else "%s HP as each of its turns ends" % Skill.num(x)
	elif stat == "grappled":
		text = "held: must break free to move, and takes its holder's grip each turn it ends held"
	elif stat == "ire":
		text = "%s rank%s of its concealment and trickery defeated, against everyone" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat in ["ap", "dex_ap"]:
		text = _signed(x * 100.0) + "%"
	elif stat == "eyes_forward":
		return "ending its turn on a move, inspects every tile %s + wis mod tiles ahead and %s to either side" % [Skill.num(x), Skill.num(x)]
	elif stat == "scrambled":
		return "sees everyone's tags scrambled, until it investigates an ally"
	elif stat == "keen_eyes":
		return "its checks on things not beside it lose only tiles away / %s" % Skill.num(x + 1.0)
	elif stat == "trap_word":
		text = "word of traps it sets carries x%s as far; allies out of earshot get a vibe of them" % Skill.num(1.0 + x)
	elif stat == "relay":
		text = "%s%% per strength mod off moving through units, for itself and allies through it (can become a boost)" % Skill.num(x * 100.0)
	elif stat == "evaluates":
		return "sees the rolls of allies using active skills within %s tile%s, its own too" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat == "slots":
		return "%s %s" % [_signed(x), Skill.CATEGORIES.get(tags[0], String(tags[0])) if not tags.is_empty() else "untyped"]
	else:
		text = _signed(x)
	if per_stat:
		text += " per %d %s" % [per, per_stat]
	if per_mod:
		text += " per %s mod" % String(per_mod).left(3)
	if not tags.is_empty():
		text += " (%s)" % ", ".join(tags)
	if above_hp > 0.0:
		text += ", above %d%% HP" % roundi(above_hp * 100.0)
	if min_rank > 0:
		text += ", from rank %s" % Skill.roman(min_rank)
	if not unless_on.is_empty():
		text += ", except on %s" % " or ".join(unless_on)
	if wound:
		text += "; a wound, healed away"
	return text


static func _signed(x: float) -> String:
	return ("+" if x > 0 else "") + Skill.num(x)
