class_name Exhaustion
extends RefCounted

# How worn a unit is from using its skills, and what that adds to their costs (Unit.exhaustion): the
# one place every cost reads it from (Unit.price(), Unit.ap_cost(), Unit.strike_ap(), Unit.strike_cost()).
# It counts its uses of each skill. Every use counted against a skill makes its next one cost STEP of
# its AP and of its cost more; a use counts whole against the skill used, and KIND as much against
# the other skills of its broad kind (kinds(): martial, specialist, magical).
# A use is one payment (Unit.pay_for()): a Strike of three hits is one, a skill landing on several
# (Sing) is one, a free recast (Jugular) none - and a channeled skill is one from its start to its
# strike, the strike paid at the rate the channel began at (strike_rate()).
# As each of its side's turns ends a unit gets over RECOVERY uses of every skill, and over more for
# a turn it rested through (resting()).

const STEP := 0.5  # of a skill's AP and of its cost, more for each use counted against it
const KIND := 0.5  # what a use counts against the other skills of its broad kind
const RECOVERY := 1.0  # uses of each skill it gets over as each of its side's turns ends

static var on := true  # off: nothing wears anyone out (staged tests: Test.calm())

var uses: Dictionary[Skill, float] = {}  # its uses of each skill it hasn't got over yet
var begun: Dictionary[Skill, float] = {}  # what each skill's last use multiplied its costs by (a channel's strike pays the same)


# The broad kinds a skill is of: its category tags (Skill.CATEGORIES). One with none wears on no
# other skill, and no other wears on it.
static func kinds(s: Skill) -> Array[StringName]:
	var out: Array[StringName] = []
	for t in s.tags:
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


# One use of s, as it's paid for.
func used(s: Skill) -> void:
	if not on:
		return
	begun[s] = rate(s)
	uses[s] = uses.get(s, 0.0) + 1.0


# The uses that count against s now: its own, and KIND of those of the other skills of its kind.
func of(s: Skill) -> float:
	if not on:
		return 0.0
	var n := 0.0
	for o in uses:
		if o == s:
			n += uses[o]
		elif alike(s, o):
			n += KIND * uses[o]
	return n


# What that multiplies s's AP and cost by: 1 fresh, STEP more a use.
func rate(s: Skill) -> float:
	return 1.0 + STEP * of(s)


# The same for the strike of a channel of s already begun: what its channel was paid at, the two
# being one use.
func strike_rate(s: Skill) -> float:
	return begun.get(s, 1.0) if on else 1.0


# As its side's turn ends: RECOVERY off every count, and resting() more if it rested the turn through.
func recover(rested: bool, con: int) -> void:
	var n := RECOVERY + (resting(con) if rested else 0.0)
	for s in uses.keys():
		uses[s] -= n
		if uses[s] < 0.0001:
			uses.erase(s)


# Why s costs more now, for a tooltip or a cost line: "exhausted x2" (the uses counted against it),
# or "" fresh.
func note(s: Skill) -> String:
	return "exhausted x%s" % Skill.num(of(s)) if of(s) > 0.0001 else ""
