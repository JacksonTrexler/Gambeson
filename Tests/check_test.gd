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


func test_beats() -> void:
	var ties := 0
	for n in 400:
		var vs := b.beats(Check.side(3), Check.side(3))
		ok(vs.mine.total == vs.mine.d20 + 3 and vs.theirs.total == vs.theirs.d20 + 3, "each side rolls d20 + its bonus")
		ok(vs.won == (vs.mine.total >= vs.theirs.total), "the one acting wins ties")
		var held := b.beats(Check.side(3), Check.side(3), false)
		ok(held.won == (held.mine.total > held.theirs.total), "unless it must beat the other outright (breaking free)")
		if vs.mine.total == vs.theirs.total:
			ties += 1
	ok(ties > 0, "ties happen, and go to the one acting (%d)" % ties)
	ok(not b.beats(Check.side(-40), Check.side(40)).won and b.beats(Check.side(40), Check.side(-40)).won, "a lopsided contest goes the way of the bonus")


func test_no_inline_d20() -> void:
	var src := FileAccess.get_file_as_string("res://Scripts/Battle.gd")
	ok(src.count("randi_range(1, 20)") == 3, "every d20 in Battle goes through resolve() (its own three rolls: one die, the edge's two)")


func test_cut() -> void:
	for n in 100:
		var r := b.resolve(Check.check(10, 0).cut(0.5))
		ok(r.total == floori((r.d20 + 10) * 0.5), "only half its total counts, rounded down")


# An execute (a skill tagged execute) cuts a foe's defensive check by how hurt it is: HP left / max HP
# / rank, as Death does a last stand (Battle.executed()).
func test_execute() -> void:
	v(3).max_hp = 100
	v(3).hp = 25
	var death: Skill = load("res://Skills/death.tres")
	ok(is_equal_approx(Battle.executed(v(3), death, 1), 0.25) and is_equal_approx(Battle.executed(v(3), death, 2), 0.125), "a quarter left: x0.25 at rank I, x0.125 at II")
	ok(Battle.executed(v(3), strike, 1) == 1.0, "nothing to cut against what isn't an execute")
	var grip: Skill = load("res://Skills/interdict.tres").duplicate()
	grip.tags.append(&"execute")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(grip))
	v(3).strength = 40  # str mod 15: unhurt, it would nearly always win
	v(3).hp = 1
	var theirs := []
	b.contested.connect(func(_c, _t, _mine, against): theirs.append(against))
	for n in 20:
		v(1).refresh()
		v(1).energy = v(1).max_energy
		b.cast(v(1), grip, v(3))
	ok(theirs.size() == 20 and theirs.all(func(t): return t == 0), "1 HP of 100: its saves count for nothing (%s)" % [theirs])
