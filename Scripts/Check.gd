class_name Check
extends RefCounted

# A d20 roll about to happen, resolved by Battle.resolve(). It mirrors the Glossary terms (Attack,
# Save, Contest, Check, Last Stand) so the one definition of "a roll meets its target" - the d20, how
# advantage and a natural 20 work - lives here instead of being hand-rolled at each call site in
# Battle.gd. The first seam of docs/plan-composability.md: offence is always d20 + the roller's mod
# vs a number they can forecast; riders change the result, never the shape.
#
# Build one with the constructors (attack(), check(), versus()), optionally .edge()/.sure() it, then
# Battle.resolve(it) -> Roll. A contest is two resolves compared (Battle.beats()).

enum Kind { ATTACK, SAVE, CONTEST, CHECK, LAST_STAND }

var kind := Kind.CHECK
var bonus := 0  # the roller's whole modifier, added to the d20
var advantage := 0  # +1 the better of two d20s, -1 the worse, 0 a single roll
var target := 0  # the number to meet or beat (Defense, a DC, the other side's total)
var crits := false  # a natural 20 always hits and crits, a miss aside (attacks)
var floor_hit := false  # a hit is forced regardless of the roll (decisive Strike after a crit)


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


# The better (+1) or worse (-1) of two d20s.
func edge(n: int) -> Check:
	advantage = n
	return self


# This roll hits no matter what (a decisive Strike's remaining hits after a critical).
func sure(on := true) -> Check:
	floor_hit = on
	return self
