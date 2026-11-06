extends Test

# The Check resolver (Check, Battle.resolve): the one definition of a d20 roll - attack vs Defense, a
# natural 20, advantage, and a forced-sure hit (docs/plan-composability.md, seam 1).

func test_roll_invariants() -> void:
	for n in 300:
		var r := b.resolve(Check.attack(5, 12))
		ok(r.total == r.d20 + 5 and r.target == 12 and r.margin() == r.total - 12, "total is d20 + bonus; margin is total - target")
		ok(r.crit == (r.d20 == 20), "a natural 20 is a crit")
		ok(r.hit == (r.crit or r.total >= 12), "a hit meets Defense, or crits")
		ok(r.d20 >= 1 and r.d20 <= 20, "the face is a d20")


func test_crit_and_sure() -> void:
	ok(not b.resolve(Check.check(-50, 10)).hit, "a plain check far below its DC misses (no crit to save it)")
	ok(b.resolve(Check.attack(-50, 10).sure()).hit, "a sure() attack hits however the die falls")
	var crits := 0
	var hopeless_hits := 0
	for n in 400:
		var r := b.resolve(Check.attack(-50, 10))  # only a natural 20 can land this
		if r.hit:
			hopeless_hits += 1
			ok(r.crit, "the only way a hopeless attack lands is a crit")
		if r.d20 == 20:
			crits += 1
	ok(hopeless_hits == crits and crits > 0, "a natural 20 always hits, even far below Defense (%d crits)" % crits)


func test_advantage() -> void:
	var single := 0
	var better := 0
	for n in 400:
		single += b.resolve(Check.check(0, 0)).d20
		better += b.resolve(Check.check(0, 0).edge(1)).d20
	ok(better > single, "the better of two d20s averages higher (%.1f vs %.1f)" % [better / 400.0, single / 400.0])
