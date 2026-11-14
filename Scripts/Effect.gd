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
# coordinate: linked with the others the same Coordinate linked, it makes out what the best of them do,
# up to its rank in levels better (Battle.read()).
# max_hp: added to max HP (Burning Blade: str mod; Unit.refit()).
# powered: its Energy is Power, which never comes back on its own; what grants Energy grants it Power
# (Powerful; Unit.powered(), Unit.grant_energy()).
# pulse: as its side's turn starts, once every (its side's lives left, at least 1) turns, it heals
# allies within PULSE_REACH tiles (1d4 + 5% of their max HP) x this (Regeneration Pulse; Battle._pulse()).
# damage: that fraction more damage dealt with skills (wauaw; Battle.cast()).
# unmask_gain / uncover_gain: Sweet Nothings back for unmasking a foe it took for friendly or neutral /
# for each level of concealment it takes off a hiding foe (Analysis Dialysis; Battle._dialysis()).
# level: added to its level - a buff, or a curse (Unit.lv()): slots and armor follow; slots a curse
# takes stay on the bar, sealed.
# Skill attributes (Unit.skill_stat()): asked with a skill's tags (and damage, for one that deals any:
# Skill.query()), and only for the skills in `skills` when it lists some.
# range: added to the skill's range (Staff: magical, +rank; Broadsword: damage, +0.5 a rank).
# rank: added to the skill's rank, where it has it (Broadsword: Strike, +rank).
# opening_ap: that fraction more general AP on its first turn of a battle (Dagger: 20% a rank).
# sap: as its side's turn ends, it drains this much Energy (Power) a rank from units of other sides
# within its sap reach, HP once their Energy is gone, while some starpower source isn't full
# (Starsap; Battle._sap()).
# starkind: its max HP is its max Power; off the star lattice it loses (1 - 0.2 x rank) of its max HP
# as its side's turn ends (Starkind; Battle._starkind()).
# sickness: as its side's turn starts, it loses that fraction of its max HP - or is cleansed of it,
# starting the turn at full HP (Resurrection Sickness; Battle._mend()).
# reforming: stacks toward reforming as a Starman (Battle._starkind()).
# chant: waiting a turn out primes its next (this) Sweet Nothing gains to bring one more each, and its
# next Warlock skill to be used a rank higher (Chant; Battle._chant()).
# breathless: its curses (skills tagged curse that land, or deal damage) give their target a stack of
# Asphyxia, each 1% x this of its max HP gone (Breathtaking; Battle._choke()).
# asphyxia: that share of max HP gone a stack (Unit.refit()); stacks start falling after (1 + the
# Breathtaking rank) of its turns.
# brace: armor ranks added to checks (Unit.check_bonus()): its tags are the armor weights it works with
# (none: any), `checks` the stats (mental: int, wis, cha), `kind` offensive or defensive (none: both);
# the armor's rank x this, up to the skill's rank (the Bracing passives).
# move_ap / skill_ap: that much more dex (moving) / wis (skill) AP each turn (Aethendine, Ignauldron,
# Invigorating Bracing).
# Strike (chain skills; Battle._chain()):
# decisive: after a critical, its remaining hits always land; damage by the higher of dex and str mod.
# single: one attack only (Brutal Strike). brutal: its first hit adds its weapon's rank + this.
# steady: its first this hits take no penalty, and a miss among them doesn't end it (Strike Out).
# featured: its first this hits add its cha mod, up to this (Striking Features).
# recording: its first this hits try to curse the target's leftmost skill a rank down (Record Striker).
# restrike: landing 12 hits in one use, it strikes again at once, this - 1 hits more (Strike!).
# elemental: its Strikes carry its element, the first hit + its highest mental mod (Elemental Mastery).
# humble: that much max HP cut (Humble; Unit.refit()).
# shackled: the shackles bound on it (Item.binding) are locked while this lasts - a debuff, so cleansing
# unlocks them (Battle._bind(), Battle.unshackle()).
# affinity: tagged offensive, supportive or defensive - shifts the cost curve of skills serving that
# posture, and so the ranks their points buy, at once (Offender +1, Unsupportive and Indefensible -1;
# Unit.affinity(), Unit.worth()).
# self_known: levels it knows itself at (Self-reflection, Meditate): how far a Meditation lets it shift
# its stats (Battle.respec()).
# abandon: its trees' defensive and supportive prerequisites can be skipped (Reckless Abandon; Unit.missing()).
# hardy: con mod counts (1 + this) times in the max HP each level brings (Hardy; Unit.level_hp()).
# flamecharmed: from rank V, allies' fire heals it for 25% x (this - 4) of what they deal (Flamecharmed;
# Unit.hit()).
# cinders: rank of its rightmost hotbar slots burn: using a skill in one burns it (Cindering;
# Unit.burning_slots()).
# irradiate: an offensive light-damage skill's roll beating Defense deals the overage as more light
# damage, up to this + cha mod (Irradiate; Battle.cast()).
# check: added to its checks of `kind` (offensive, defensive; none: both), in the stats in `checks`
# (none: any) - armor or not (Turtle Tactics: +2 a rank defensive, -1 a rank offensive; Unit.check_bonus()).
# base_ap: that much more general AP each turn, never below 0 (Interdict: less the caster's str mod).
# guard: the share of damage it blocks from sources in the 90 degree cone it faces (Shields Up!;
# Unit.guard, Unit.hit()).
# obstruct: enemies entering a tile next to it pay the larger of half its size penalty and half its con
# mod / 10 more movement, + 25% a point of this (Obstruct; Battle.obstruction()).
# lovely: its love skills used on an adjacent ally also heal it this share of its max HP (Lovely Caster;
# Battle._lovely()).
# impassioned: added to a skill's primary mod used on an adjacent unit (Impassioned Fighter;
# Battle.passion()).
# regen_hp: HP healed as the unit's side starts a turn, on top of regen (Rejuvinate's cha mod).
# strategy / tactics: a leader commands that many more allies a turn / gives each that many more orders,
# on top of what its charisma allows (Strategist, a Strategy Guide / Tactician, a Tactician's Playbook;
# Command.ally_cap(), Command.order_cap()).
# command_mod: added to its cha mod wherever Command reads it - reach, party size, slots, both caps -
# and nowhere else (Grand Design; Command.cha_of()).
# stamina: the holder's exhaustion counts are divided by 1 + this (Stamina: 1 a rank;
# Exhaustion.of())
# jammed: above 0, it has lost its reactions: it can't dodge (Battle.evade()), guard
# (Unit.guarding()) or obstruct (Battle.obstruction()) - Jam; a helpless unit has lost them too (Unit.reacts())
# focus: added to a ranged attack's roll when paying for it spends the last of its holder's Focus
# (Unit.focus_bonus(); Skills/focus.tres, 1 a rank)
# overcharge: marks the Overcharge status: its holder's buffer, Unit.overcharge points, spent
# before any of its own on a cost and decaying to nothing as the status runs out
# (Unit.add_overcharge(), Unit.tick())
# helpless: above 0, it can't act, move or take orders - tapped - unless something lets it act
# anyway (mindless; Unit.helpless(), Unit.stopped()). Stunned
# mindless: helpless, it still takes this many skill uses a turn in a reduced capacity, its mental
# stats counting as 1 (Mindless Fury: its rank; Unit.stopped(), Unit.reduced())
# drone: ordered past its leader's command caps, it still takes orders, in a reduced capacity, its
# mental mods capped at + this (Drone: its rank; Command.tapped(), Unit.overdriven)
# hale: above 0, executes against it go by its full HP, not what it has left
# (Unit.execute_share(); Intervention's Bless)
# defer: on its last life, a death is put off this many of its side's rounds (once a battle), what
# harmed it in the last that many rounds replayed as each ends; then a check against an execute at
# this rank (Borrowed Time; Unit.defer(), Battle._borrowed())
@export_enum("luck", "mitigate", "initiative", "reach", "movement", "move_cost", "size",
		"strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma",
		"recon", "concealment", "trickery", "nullify", "trap_power", "persona",
		"command", "party", "regen", "poison", "sleep", "ap", "dex_ap", "relay", "trap_word",
		"defense", "slots", "meander", "evaluates", "insight", "embellish", "brood", "conspire", "ally_mitigate", "ire",
		"bleed", "grappled", "eyes_forward", "keen_eyes", "scrambled", "damage", "unmask_gain", "uncover_gain", "coordinate", "max_hp", "powered", "pulse",
		"level", "range", "rank", "opening_ap", "sap", "starkind", "sickness", "reforming", "synergy",
		"check", "base_ap", "guard", "obstruct", "lovely", "impassioned", "regen_hp", "mist",
		"chant", "breathless", "asphyxia", "irradiate", "humble", "flamecharmed", "cinders", "brace", "move_ap", "skill_ap",
		"decisive", "single", "brutal", "steady", "featured", "recording", "restrike", "elemental", "hardy", "shackled", "affinity", "abandon", "self_known",
		"discipline", "natural_talent", "strategy", "tactics", "command_mod", "stamina", "jammed", "focus", "overcharge", "helpless", "mindless", "drone", "hale", "defer") var stat := "luck"
@export_enum("add", "mul") var op := "add"  # mul: multiplies the stat after everything is added
@export var amount := 1.0
@export var tags: Array[StringName] = []  # only counts for queries carrying one of these (or a child of one); empty: always
@export var skills: Array[Skill] = []
@export var checks: Array[StringName] = []  # brace: the stats of the checks it adds to (mental: int, wis, cha)
@export var kind := &""  # brace: offensive or defensive checks only; empty: both
@export var armored := false  # only while its holder wears armor to some effect (Unit.armored(): Invigorating Bracing's AP)  # a skill attribute (range, rank): only for these skills; empty: any the tags allow
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
@export var by_mod := &""  # put on a unit: its amount x the mod (at least 0) in this of whoever put it on, fixed as it's put on (Interdict: str mod AP off; Rejuvinate: + cha mod HP; Battle.cast())
@export var ease := 1  # how easy it is to remove: cleansing or dispelling takes this many of its ranks for each spent (Level Down 2, Level Up 4; Battle._strip())
@export var arc := false  # put on a unit: its amount is a step, climbing a step a turn to the middle of its turns, then back down (wauaw: 10%, 20%, 30%, 20%, 10%)


const TITLES := {"mitigate": "Damage taken", "move_cost": "Move cost", "trap_power": "Trap power",
		"regen": "Heal", "poison": "Poison", "ap": "AP", "dex_ap": "Dex AP", "trap_word": "Trap word",
		"slots": "Skill slots", "evaluates": "Self-evaluation", "ally_mitigate": "Friendly fire taken",
		"eyes_forward": "Eyes forward", "keen_eyes": "Keen eyes", "scrambled": "Scrambled", "damage": "Damage dealt",
		"unmask_gain": "Unmasking", "uncover_gain": "Uncovering", "max_hp": "Max HP", "powered": "Power", "pulse": "Regeneration Pulse",
		"range": "Skill range", "rank": "Skill rank", "opening_ap": "Opening AP", "brace": "Bracing",
		"move_ap": "Dex AP", "skill_ap": "Skill AP", "sap": "Starsap",
		"sickness": "Resurrection Sickness", "hardy": "Hardy", "shackled": "Shackled", "affinity": "Affinity", "abandon": "Reckless", "self_known": "Self-knowledge",
		"discipline": "Discipline", "natural_talent": "Natural Talent",
		"check": "Checks", "base_ap": "AP", "guard": "Shields Up", "obstruct": "Obstruct", "lovely": "Lovely Caster",
		"impassioned": "Impassioned", "regen_hp": "Heal", "mist": "Mist",
		"strategy": "Allies commanded a turn", "tactics": "Orders per ally a turn", "command_mod": "Cha mod when commanding",
		"mindless": "Mindless Fury actions", "drone": "Drone", "hale": "Hale ??", "defer": "Borrowed Time"}
static var _MOD := RegEx.create_from_string("\\b(str|dex|con|int|wis|cha) mod\\b")
static var _NUM := RegEx.create_from_string("[+-]?\\d+(\\.\\d+)?%?")
const ENDLESS := 999.0  # a command bonus this big has no limit (Quartz Ring)
const HARMFUL := ["move_cost", "poison", "sleep", "ire", "bleed", "grappled", "scrambled", "sickness", "asphyxia", "humble", "cinders", "shackled", "jammed", "helpless"]  # more of these is worse for whoever has them


# "Luck: -3", "Damage taken: -40% (physical), above 85% HP", "Heal: 10% each turn", at a skill rank.
func describe(rank := 1) -> String:
	return Glossary.plain(markup(rank))


# describe() in Glossary markup.
func markup(rank := 1) -> String:
	return "%s: %s" % [title(), marked(rank)]


# value() in Glossary markup: the mods it names are its holder's own (offense), a number growing with
# rank is gold, and conditions with a term go by it (Held, Asleep).
func marked(rank := 1) -> String:
	var v := value(rank)
	if stat == "grappled":
		v = Glossary.term(&"held", "held")
	elif stat == "sleep":
		v = Glossary.term(&"asleep", "can't act")
	elif stat == "jammed":
		v = Glossary.term(&"jammed", "no reactions")
	elif stat == "helpless":
		v = Glossary.term(&"helpless", "helpless")
	elif stat == "hale":
		v = "%s go by its full HP" % Glossary.term(&"execute", "executes")
	elif stat == "defer":
		var n := roundi(amount * (rank if per_rank else 1))
		v = "on its last life, death put off %d round%s (once a battle) - what harmed it in the last %d replayed in order as each ends - then a %s against an %s at rank %d" % [
				n, "" if n == 1 else "s", n, Glossary.term(&"check", "check"), Glossary.term(&"execute", "execute"), n]
	v = _MOD.sub(v, "{o:$1 mod}", true)
	if per_rank:
		v = _NUM.sub(v, "{r:$0}")
	return v


func title() -> String:
	return TITLES.get(stat, stat.capitalize())


# What it's shown under: the condition it's part of, or its stat.
func label() -> String:
	return name if name else title()


# "Poison: 5% each turn", "Haste: AP +10%, Dex AP +20%" - a condition's effects as one line (in
# Glossary markup, marked_up).
static func summarize(group: Array[Effect], marked_up := false) -> String:
	var parts := group.map(func(e: Effect):
		var v := e.marked() if marked_up else e.value()
		return v if e.title() == e.label() else "%s %s" % [e.title(), v])
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
	elif stat == "jammed":
		text = "no reactions: it can't dodge, guard or obstruct"
	elif stat == "helpless":
		text = "helpless: it can't act, move or take orders"
	elif stat == "bleed":
		text = "%dd%d%s HP as each of its turns ends" % [dice.x, dice.y, " + %s mod" % String(dice_mod).left(3) if dice_mod else ""] if dice != Vector2i.ZERO else "%s HP as each of its turns ends" % Skill.num(x)
	elif stat == "grappled":
		text = "held: must break free to move; its holder's grip, and drowning while submerged, hurt it each turn it ends held"
	elif stat == "ire":
		text = "%s rank%s of its concealment and trickery defeated, against everyone" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat in ["ap", "dex_ap", "damage"]:
		text = _signed(x * 100.0) + "%"
	elif stat == "check":
		text = "%s to %s%schecks" % [_signed(x), (String(kind) + " ") if kind else "", (" or ".join(checks.map(func(c): return String(c).left(3))) + " ") if not checks.is_empty() else ""]
	elif stat == "base_ap":
		text = "%s each turn" % _signed(x)
	elif stat == "guard":
		return "blocks %d%% of damage from sources in the 90 degree cone it faces" % roundi(x * 100.0)
	elif stat == "obstruct":
		return "foes entering a tile next to it pay the larger of half its size penalty and half its con mod / 10 more movement, +%d%%" % roundi(25.0 * x)
	elif stat == "lovely":
		return "its {x:love} skills used on an adjacent ally also heal it %d%% of its max HP" % roundi(x * 100.0)
	elif stat == "impassioned":
		return "+%s to a skill's primary mod used on an adjacent unit" % Skill.num(x)
	elif stat == "regen_hp":
		text = "%s HP each turn" % Skill.num(x)
	elif stat == "mist":
		return "a mist: it can't attack, only Coalesce into another unit's tile"
	elif stat in ["unmask_gain", "uncover_gain"]:
		return "%s Sweet Nothing%s for %s" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s",
				"unmasking a foe it took for friendly or neutral" if stat == "unmask_gain" else "each level of concealment it takes off a hiding foe"]
	elif stat == "eyes_forward":
		return "ending its turn on a move, inspects every tile %s + wis mod tiles ahead and %s to either side" % [Skill.num(x), Skill.num(x)]
	elif stat == "scrambled":
		return "sees everyone's tags scrambled, until it investigates an ally"
	elif stat == "command" and x >= ENDLESS:
		return "no limit"
	elif stat == "brace":
		var on := " or ".join(checks.map(func(c): return "mental" if c == &"mental" else String(c).left(3)))
		return "%s equipped %sarmor rank%s to %s%s checks, up to rank" % ["half the" if amount < 1.0 else "+", "%s " % " or ".join(tags) if not tags.is_empty() else "",
				"" if amount < 1.0 else "s", (String(kind) + " ") if kind else "", on]
	elif stat in ["decisive", "single", "brutal", "steady", "featured", "recording", "restrike", "elemental"]:
		return {"decisive": "after a critical, the rest of Strike's hits land; damage by the higher of dex and str mod",
				"single": "Strike is a single attack",
				"brutal": "Strike's first hit adds its weapon's rank + %s" % Skill.num(x),
				"steady": "Strike's first %s hits take no penalty, and a miss among them doesn't end it" % Skill.num(x),
				"featured": "Strike's first %s hits add cha mod, up to %s" % [Skill.num(x), Skill.num(x)],
				"recording": "Strike's first %s hits try to curse the target's leftmost skill a rank down (its wis against your highest mental mod)" % Skill.num(x),
				"restrike": "landing 12 Strike hits in one use strikes again at once%s, up to three times; 36 in a row is a Perfect: %d HP healed" % [", with %s more" % Skill.num(x - 1.0) if x > 1.0 else "", Battle.PERFECT_HEAL],
				"elemental": "Strike carries your element; its first hit adds your highest mental mod"}[stat]
	elif stat == "humble":
		return "%s max HP cut" % Skill.num(x)
	elif stat == "abandon":
		return "may skip defensive and supportive skills on its trees"
	elif stat == "discipline":
		return "an attack burns all the AP you have left into points: AP ^ (%s / %s), so 4 AP is %s points. Each point +%d to hit, +%d%% damage a point of its stat mod, and crits a face lower; with Focus, half the points come back to it" % [Skill.num(x), Skill.num(x + 1.0), Skill.num(snappedf(Battle.discipline_curve(4.0, x), 0.1)), Battle.DISCIPLINE_HIT, roundi(Battle.DISCIPLINE_DAMAGE * 100.0)]
	elif stat == "natural_talent":
		return "Nature magic up to tier %s is easier to learn: Affinity +1" % Skill.num(x)
	elif stat == "shackled":
		return "its shackles are locked"
	elif stat == "hardy":
		return "con mod counts %s times over in the max HP each level brings" % Skill.num(1.0 + x)
	elif stat == "flamecharmed":
		return "allies' fire heals it for %d%% of what they deal" % maxi(roundi(25.0 * (x - 4.0)), 0) if x > 4.0 else "allies' fire heals it, from rank V"
	elif stat == "cinders":
		return "its %s rightmost skill slot%s burn: using a skill in one burns it" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat == "chant":
		return "waiting a turn out: its next %s Sweet Nothing gain%s bring one more, and its next Warlock skill is used a rank higher" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat == "breathless":
		return "its curses that land give a stack of Asphyxia: %s%% of max HP gone a stack, falling a stack a turn after %s turns" % [Skill.num(x), Skill.num(1.0 + x)]
	elif stat == "asphyxia":
		return "%s%% of max HP gone" % Skill.num(x * 100.0)
	elif stat == "irradiate":
		return "an offensive light attack beating Defense deals the overage as light damage too, up to %s + cha mod" % Skill.num(x)
	elif stat == "sap":
		return "drains %s Energy (or Power) a turn from other sides' units beside it, HP once theirs is gone, while starpower isn't full" % Skill.num(x)
	elif stat == "starkind":
		return "its max HP is its max Power; off the star lattice it loses %d%% of its max HP each turn" % roundi(maxf(1.0 - 0.2 * x, 0.0) * 100.0)
	elif stat == "sickness":
		return "loses %d%% of max HP as each of its turns starts; gone if one starts at full HP" % roundi(x * 100.0)
	elif stat == "reforming":
		return "%s stack%s toward reforming" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat == "powered":
		return "its Energy is Power: it never comes back on its own, and what grants Energy grants Power"
	elif stat == "overcharge":
		return "an extra buffer of Energy, spent first"
	elif stat == "pulse":
		return "every (its side's lives left) turns, heals allies within %d tiles (1d4 + 5%% of their max HP) x %s" % [Battle.PULSE_REACH, Skill.num(x)]
	elif stat == "coordinate":
		return "linked: makes out what the best of the others linked do, up to %s level%s better" % [Skill.num(x), "" if is_equal_approx(x, 1.0) else "s"]
	elif stat == "stamina":
		return "its exhaustion counts / %s" % Skill.num(x + 1.0)
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
	if by_mod:
		text += " x the caster's %s mod" % String(by_mod).left(3)
	if not tags.is_empty() or not skills.is_empty():
		text += " (%s)" % ", ".join(skills.map(func(x: Skill): return x.name) + tags.map(func(t): return String(t)))
	if above_hp > 0.0:
		text += ", above %d%% HP" % roundi(above_hp * 100.0)
	if min_rank > 0:
		text += ", from rank %s" % Skill.roman(min_rank)
	if not unless_on.is_empty():
		text += ", except on %s" % " or ".join(unless_on)
	if wound:
		text += "; a wound, healed away"
	if ease > 1:
		text += "; easily removed (x%d)" % ease
	if arc:
		text += " a step, climbing a step a turn to the middle of its turns, then back down"
	return text


static func _signed(x: float) -> String:
	return ("+" if x > 0 else "") + Skill.num(x)
