class_name Exhaustion
extends RefCounted

# How worn a unit is from using its skills, and what that adds to their costs (Unit.exhaustion): the
# one place every cost reads it from (Unit.price(), Unit.ap_cost(), Unit.strike_ap(), Unit.strike_cost()).
# It counts its uses of each skill, and weighs them against the skill about to be used as pressure (of()):
# 1 is where it bites. A use weighs 1 / SAME against the skill itself, 1 / IN_KIND against the other skills
# of its broad kind (kinds(): martial, specialist, magical, from the trees it sits on), 1 / ANY against
# every other skill - so the 2nd cast of one skill, the 3rd skill of a kind in a row, or the 4th different
# skill in a turn is the first to bite. Below 1 a use is nearly free (MILD a unit of pressure), from 1 on
# it costs STEP of its AP and cost more a unit (rate()). Burnout (Scripts/Burnout.gd) is the same with a
# harsher penalty (every int skill: penalty()), and harsher still on costs paid from a reserve that burns (Mana).
# Stamina divides the pressure by 1 + its rank (the Effect stat stamina; ease).
# A use is one payment (Unit.pay_for()): a Strike of three hits is one, a skill landing on several
# (Sing) is one, a free recast (Jugular) none - and a channeled skill is one from its start to its
# strike, the strike paid at the rate the channel began at (strike_rate()).
# As each of its side's turns ends a unit gets over RECOVERY uses of every skill, and over more for
# a turn it rested through (resting()). relieve() is the one way uses come off: that, and Wear, the
# use as Battle settles it once its cast is over, are what passives' hooks (Behaviour.wearing()) work on.

const SAME := 1  # uses of a skill before it bites: its 2nd cast does
const IN_KIND := 2  # uses of skills of one broad kind before the next of them bites: the 3rd caster skill in a row
const ANY := 3  # uses of any skills before the next bites: the 4th different skill in a turn
const MILD := 0.1  # of a skill's AP and cost more a unit of pressure, below the bite (rounded away on a cost: raise())
const STEP := 0.5  # of a skill's AP and cost more a unit of pressure, from the bite on
const RECOVERY := 1.0  # uses of each skill it gets over as each of its side's turns ends

static var on := true  # off: nothing wears anyone out (staged tests: Test.calm())

var uses: Dictionary[Skill, float] = {}  # its uses of each skill it hasn't got over yet
var ease := func() -> float: return 1.0  # what the pressure is divided by: 1 + its holder's Stamina rank (Unit sets it: the Effect stat stamina)
var penalty := func(_s: Skill) -> float: return 1.0  # what its wear on a skill is multiplied by: Burnout's (Unit sets it: Burnout.penalty())
var begun: Dictionary[Skill, float] = {}  # what each skill's last use multiplied its costs by (a channel's strike pays the same)


# One use as it was paid for, held open by Battle until the cast it was paid in is over: what it added
# to the count (gain), what of that it keeps (uses: a passive's wearing() hook may lower it, to 0 to cancel
# it), and who was taken out of the fight meanwhile (felled: Unit -> how, as Battle.neutralized has it).
class Wear:
	var skill: Skill
	var caster: Unit
	var target: Unit  # who it was aimed at
	var gain := 0.0
	var uses := 0.0
	var felled := {}

	func killed() -> bool:
		return felled.values().has(&"killed")


# The broad kinds a skill is of, from the trees it sits on (Skill.kinds(): Strike general, a Cleric's
# Solar magical); on none, its category tags. One with no kind shares IN_KIND's weight with no other;
# ANY's it shares with all.
static func kinds(s: Skill) -> Array[StringName]:
	var out: Array[StringName] = []
	for t in s.kinds():
		if t in Skill.CATEGORIES:
			out.append(t)
	return out


# Whether two skills share a broad kind.
static func alike(a: Skill, b: Skill) -> bool:
	var mine := kinds(a)
	return kinds(b).any(func(t: StringName): return t in mine)


# The uses more a turn of rest takes off, by its con mod: the mod itself, or below 1 a fraction of
# a use, 1 / (1 - mod) - one more every (1 - mod) turns rested (0: 1, -1: 1/2, -3: 1/4).
static func resting(con: int) -> float:
	return float(con) if con >= 1 else 1.0 / (1 - con)


# What a cost of `cost` comes to at `rate`: rounded up as ever, and what exhaustion adds to it rounded
# to the nearest point - a mild wear (under half a point) adds nothing.
static func raise(cost: float, rate: float) -> int:
	return ceili(cost - 0.0001) + roundi(cost * (rate - 1.0))


# One use of s, as it's paid for: what it added to the count (0 with exhaustion off).
func used(s: Skill) -> float:
	if not on:
		return 0.0
	begun[s] = rate(s)
	uses[s] = uses.get(s, 0.0) + 1.0
	return 1.0


# Takes n uses off the count of s, or of every skill: it gets over them (recover(), Deathlust).
func relieve(n: float, s: Skill = null) -> void:
	if n <= 0.0:
		return
	for k in uses.keys():
		if s == null or k == s:
			uses[k] -= n
			if uses[k] < 0.0001:
				uses.erase(k)


# Takes a share (0 to 1) of every skill's count off it (Deathlust), through relieve().
func relieve_share(share: float) -> void:
	for k in uses.keys():
		relieve(uses[k] * clampf(share, 0.0, 1.0), k)


# The pressure on s now, 1 where it bites: its own uses / SAME, the other skills of its kind's / IN_KIND,
# every other skill's / ANY - divided by ease (Stamina).
func of(s: Skill) -> float:
	if not on:
		return 0.0
	var n := 0.0
	for o in uses:
		if o == s:
			n += uses[o] / SAME
		elif alike(s, o):
			n += uses[o] / IN_KIND
		else:
			n += uses[o] / ANY
	return n / maxf(ease.call(), 1.0) if n > 0.0 else 0.0


# Whether s's pressure has reached the bite.
func bites(s: Skill) -> bool:
	return of(s) >= 1.0 - 0.0001


# What that multiplies s's AP and cost by: 1 fresh, MILD more a unit of pressure below the bite and STEP
# from it on, times its penalty (Burnout) and `harsher` (a reserve that burns, on a cost: Burnout.on_cost()).
func rate(s: Skill, harsher := 1.0) -> float:
	var p := of(s)
	return 1.0 + (STEP if p >= 1.0 - 0.0001 else MILD) * p * penalty.call(s) * harsher


# The same for the strike of a channel of s already begun: what its channel was paid at, the two
# being one use.
func strike_rate(s: Skill) -> float:
	return begun.get(s, 1.0) if on else 1.0


# As its side's turn ends: RECOVERY off every count, and resting() more if it rested the turn through.
func recover(rested: bool, con: int) -> void:
	relieve(RECOVERY + (resting(con) if rested else 0.0))


# Why s costs more now, for a tooltip or a cost line: "exhausted x2" (the pressure on it: 1 bites), "burnout
# x2" for a Burnout skill, or "" fresh.
func note(s: Skill) -> String:
	var p := of(s)
	if p <= 0.0001:
		return ""
	return "%s x%s" % ["burnout" if Burnout.of(s) else "exhausted", Skill.num(p)]
