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


# The one check helper (Battle.check(), odds(), sides(); docs/plans/checks.md): ties, kinds, the better
# of several stats, a range penalty, a cut, and odds that match what it rolls.
func test_check_helper() -> void:
	ok(is_equal_approx(Check.odds(Check.side(0), Check.side(0)), 0.525), "even sides: the actor wins ties, 21/40 (%s)" % Check.odds(Check.side(0), Check.side(0)))
	ok(is_equal_approx(Check.odds(Check.side(0), Check.side(0), false), 0.475), "...and loses them with ties false")
	ok(is_equal_approx(Check.odds(Check.side(-50), Check.side(0)), 0.0) and is_equal_approx(Check.odds(Check.side(50), Check.side(0)), 1.0), "hopeless and certain")
	ok(Check.odds(Check.side(0).edge(1), Check.side(0)) > 0.65 and Check.odds(Check.side(0).edge(-1), Check.side(0)) < 0.4, "advantage and disadvantage weigh in")
	var a := v(1)
	var t := v(3)
	var s := Battle.sides(a, &"strength", t, [&"strength", &"dexterity"], {bonus = 2, penalty = 1, tiles = 3, cut = 0.5})
	ok(s[0].bonus == a.check_mod(&"strength", &"offensive") + 2 - 3, "a's side: its check mod + bonus - penalty x tiles (%d)" % s[0].bonus)
	ok(s[1].bonus == maxi(t.check_mod(&"strength", &"defensive"), t.check_mod(&"dexterity", &"defensive")) and is_equal_approx(s[1].share, 0.5), "b's: the better stat, defensive, cut")
	ok(Battle.sides(a, &"", t, &"", {bonus = 4, their_bonus = 1})[0].bonus == 4, "a stat &\"\": its bonus alone")
	var won := 0
	for n in 2000:
		if b.check(a, &"strength", t, &"strength", {bonus = 3}).won:
			won += 1
	var p := Battle.odds(a, &"strength", t, &"strength", {bonus = 3})
	ok(absf(won / 2000.0 - p) < 0.05, "odds() matches what check() rolls (%.3f vs %.3f)" % [won / 2000.0, p])


# A check against a number rolled earlier (Battle.check() given a total: investigating, a last-stand fall,
# Level Down's bar): that side spends no die, ties and a cut work as on any side, and odds() weighs it.
func test_check_against_a_total() -> void:
	b.rng.seed = 5
	var before := b.rng.state
	var c := b.check(null, &"", null, 15, {bonus = 5})
	ok(c.theirs.total == 15 and c.mine.total == c.mine.d20 + 5 and c.won == (c.mine.total >= 15), "it meets the total with a d20 + its bonus (%d vs %d)" % [c.mine.total, c.theirs.total])
	b.rng.seed = 5
	b.check(null, &"", null, 15, {bonus = 5})
	var one_die := b.rng.state
	b.rng.state = before
	b.rng.randi_range(1, 20)
	ok(one_die == b.rng.state, "only its own die rolls")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5}), 0.55) and is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, ties = false}), 0.5), "d20 + 5 meets 15 on 11 faces of 20, 10 with ties lost")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, edge = 1}), 1.0 - 0.45 * 0.45), "advantage on its die")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, their_bonus = 3}), 0.4), "their_bonus adds to the total (18)")
	ok(is_equal_approx(Battle.odds(null, &"", null, 20, {bonus = 5, cut = 0.5}), 0.8), "a cut halves it (10): d20 + 5 meets it on 16 faces")
	var won := 0
	for n in 2000:
		if b.check(null, &"", null, 15, {bonus = 5}).won:
			won += 1
	ok(absf(won / 2000.0 - 0.55) < 0.05, "odds() matches what it rolls (%.3f)" % (won / 2000.0))


# A declared check (Skill.check) as the helper reads it: + rank when ranked, its edge, a range penalty a
# tile past the first (1 less a rank past I), its own check tags beside the skill's.
func test_declared_check() -> void:
	var s: Skill = load("res://Skills/haluca.tres").duplicate()
	s.check = s.check.duplicate()
	s.check.range_penalty = 2
	s.check.edge = -1
	s.check.tags = [&"taps"] as Array[StringName]
	v(1).learned.append(slot(s, 1))
	v(1).refresh()
	stage(nemes, {v(1): Vector2i(1, 1), v(3): Vector2i(5, 1)})
	var o := Battle.skill_opts(v(1), s, v(3))
	ok(o.penalty == 2 and o.tiles == 3 and o.edge == -1 and o.kind == Check.Kind.SAVE, "rank I: -2 a tile, 3 tiles past the first, disadvantage, a save (%s)" % o)
	ok(&"taps" in o.tags and &"magical" in o.tags and &"taps" not in s.tags, "its check tags join the skill's (which keep their own)")
	ok(Battle.sides(v(1), &"charisma", v(3), &"wisdom", o)[0].bonus == v(1).check_mod(&"charisma", &"offensive", o.tags) + 1 - 6, "+ rank 1, - 2 x 3")
	ok(s.check.penalty(3, 3) == 0 and s.check.penalty(2, 3) == 3, "the penalty falls 1 a rank past I")
