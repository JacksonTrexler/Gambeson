class_name Check
extends RefCounted

# A d20 roll about to happen, resolved by Battle.resolve(). It mirrors the Glossary terms (Attack,
# Save, Contest, Check, Last Stand) so the one definition of "a roll meets its target" - the d20, how
# advantage and a natural 20 work - lives here instead of being hand-rolled at each call site in
# Battle.gd. The first seam of docs/plan-composability.md: offence is always d20 + the roller's mod
# vs a number they can forecast; riders change the result, never the shape.
#
# Build one with the constructors (attack(), check(), side()), optionally .edge()/.sure() it, then
# Battle.resolve(it) -> Roll. A contest is two sides rolled in turn and compared: Battle.beats(a, b)
# -> Contest. Bonuses usually come from Unit.check_mod() (a mod plus bracing).

enum Kind { ATTACK, SAVE, CONTEST, CHECK, LAST_STAND }

var kind := Kind.CHECK
var bonus := 0  # the roller's whole modifier, added to the d20
var advantage := 0  # +1 the better of two d20s, -1 the worse, 0 a single roll
var target := 0  # the number to meet or beat (Defense, a DC, the other side's total)
var crits := false  # a natural 20 always hits and crits, a miss aside (attacks)
var crit_on := 20  # the lowest face that crits, where it crits at all (Discipline: 1 lower a point burned)
var floor_hit := false  # a hit is forced regardless of the roll (decisive Strike after a crit)
var is_fixed := false  # no die: its total is its bonus (a number rolled earlier, the other side of a check against it: Check.fixed())
var share := 1.0  # only this share of the total counts, rounded down (an execute: HP left / max HP / rank)


# The outcome of a resolved Check.
class Roll:
	extends RefCounted
	var d20 := 0  # the face rolled (after advantage)
	var total := 0  # d20 + bonus
	var target := 0
	var crit := false  # a natural 20 on an attack
	var hit := false  # met the target, or crit, or forced

	func margin() -> int:  # how far the total beat the target (negative: fell short)
		return total - target


# The outcome of a Contest: each side's roll, and whether the first side (`mine`, the one acting) won.
class Contest:
	extends RefCounted
	var mine: Roll
	var theirs: Roll
	var won := false


# An Attack: d20 + `bonus` vs `defense`; a natural 20 always hits and crits.
static func attack(bonus: int, defense: int, advantage := false) -> Check:
	var c := Check.new()
	c.kind = Kind.ATTACK
	c.bonus = bonus
	c.target = defense
	c.advantage = 1 if advantage else 0
	c.crits = true
	return c


# A plain Check / Save / Last Stand roll: d20 + `bonus` vs `dc`.
static func check(bonus: int, dc: int, kind := Kind.CHECK) -> Check:
	var c := Check.new()
	c.kind = kind
	c.bonus = bonus
	c.target = dc
	return c


# A check against a difficulty tag at a rank (Difficulty: approachable, unfair...); rank 0: its flat DC.
static func versus(bonus: int, difficulty: StringName, rank := 0, kind := Kind.CHECK) -> Check:
	return check(bonus, Difficulty.dc(difficulty, rank), kind)


# One side of a Contest: d20 + `bonus`, to be compared with the other side's (Battle.beats()).
static func side(bonus: int, kind := Kind.CONTEST) -> Check:
	return check(bonus, 0, kind)


# A side that doesn't roll: the total `n` an earlier roll made, for a check to meet or beat (Battle.check()
# given a number to go against). Resolving it spends no die.
static func fixed(n: int) -> Check:
	var c := side(n)
	c.is_fixed = true
	return c


# The better (+1) or worse (-1) of two d20s.
func edge(n: int) -> Check:
	advantage = n
	return self


# Only a share of its total counts (an execute against a hurt foe's defence: Battle.executed()).
func cut(f: float) -> Check:
	share = f
	return self


# This roll hits no matter what (a decisive Strike's remaining hits after a critical).
# Crits on n faces more than a natural 20 (Discipline: 19 and up for 1), never below a natural 2.
func keen(n: int) -> Check:
	crit_on = maxi(20 - maxi(n, 0), 2)
	return self


func sure(on := true) -> Check:
	floor_hit = on
	return self


# The chance (0-1) side `a` wins a Contest against `b` (Battle.beats()), without rolling: every pair of
# faces, each weighted by its advantage, totalled as resolve() totals them (a cut share included).
static func odds(a: Check, b: Check, a_wins_ties := true) -> float:
	var p := 0.0
	for i in _faces(a):
		var mine := _total(a, i)
		var pa := _face(a, i)
		for j in _faces(b):
			var theirs := _total(b, j)
			if mine > theirs or (a_wins_ties and mine == theirs):
				p += pa * _face(b, j)
	return p


# The faces c may roll: 1 to 20, or the one "face" 0 of a side that doesn't roll.
static func _faces(c: Check) -> Array:
	return [0] if c.is_fixed else range(1, 21)


# The chance of c rolling face d on a d20 with its advantage (+1 the better of two, -1 the worse).
static func _face(c: Check, d: int) -> float:
	if c.is_fixed:
		return 1.0
	var n := c.advantage
	if n > 0:
		return (d * d - (d - 1) * (d - 1)) / 400.0
	if n < 0:
		return ((21 - d) * (21 - d) - (20 - d) * (20 - d)) / 400.0
	return 1.0 / 20.0


# What face d totals to on this check (Battle.resolve()'s sum).
static func _total(c: Check, d: int) -> int:
	return d + c.bonus if is_equal_approx(c.share, 1.0) else floori((d + c.bonus) * c.share)
