extends Test

# Heavy Strike (Skills/heavy_strike.tres, Behaviours/heavy_strike.gd): the hits of one skill use made with a
# Strike skill (the strike tag; any other skill's land as they would) rolled as usual, their damage held back and dealt as one blow on a last roll +
# successes + rank, through the generic `striking` hook on a use's Volley (Battle.use_of()). Pins the pooling,
# the use's scope (a skill used again is another blow), the last roll's bonus and its outcomes.

var heavy_strike: Skill = load("res://Skills/heavy_strike.tres")


# A real Strike III from v(1) (str mod 10) at v(3) (Defense 2: every hit lands) with Heavy Strike I:
# three rolls, then the last; one blow of 11 + 10 + 9 (each hit in a row 1 less) + 3 successes + rank 1.
func test_one_blow() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 30
	v(1).weapon = null
	v(1).learned.append(slot(heavy_strike, 1))
	v(1).learned.append(slot(strike, 3))
	soak(v(3), 500)
	var dealt := []
	v(3).hp_changed.connect(func(was: int, now: int): dealt.append(was - now))
	var rolls: Array[Check.Roll] = []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): rolls.append(r))
	v(1).refresh()
	b.cast(v(1), strike, v(3))
	ok(rolls.size() == 4 and rolls.all(func(r: Check.Roll): return r.hit), "three hits rolled, then the last roll (%d)" % rolls.size())
	ok(rolls[3].total == rolls[3].d20 + 10 + 3 + 1, "the last: + successes (3) + rank (1) (%d on %d)" % [rolls[3].total, rolls[3].d20])
	ok(dealt.size() == 1, "one blow, not three (%s)" % [dealt])
	if rolls.slice(0, 4).all(func(r: Check.Roll): return not r.crit):
		ok(dealt[0] == 11 + 10 + 9 + 3 + 1, "the pool + successes + rank (%s)" % [dealt])
	ok("must hit or it all misses" in heavy_strike.describe(2), heavy_strike.describe(2))


# Any Strike skill, not only the chain one (Silent Strike, Waterstrike: the strike tag): one use's blow pooled
# behind a last roll (two rolls, one blow); used again, by hand, it is another use and another blow. Another
# attacking skill (no strike tag) isn't pooled: its one roll, its blow as it lands.
func test_strike_skills_only() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var lone: Skill = strike.duplicate()
	lone.chain = false
	var plain: Skill = lone.duplicate()
	plain.tags = [&"physical", &"str", &"martial"] as Array[StringName]
	v(1).strength = 30
	v(1).weapon = null
	v(1).learned.append(slot(heavy_strike, 1))
	v(1).learned.append(slot(lone, 1))
	v(1).learned.append(slot(plain, 1))
	soak(v(3), 500)
	var dealt := []
	v(3).hp_changed.connect(func(was: int, now: int): dealt.append(was - now))
	var rolls: Array[Check.Roll] = []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): rolls.append(r))
	for i in 2:
		v(1).refresh()
		b.cast(v(1), lone, v(3))
	ok(rolls.size() == 4 and rolls[0].use == rolls[1].use and rolls[2].use == rolls[3].use and rolls[1].use != rolls[2].use,
			"each use: its roll, then the last roll in the same use (%s)" % [rolls.map(func(r: Check.Roll): return r.use)])
	ok(rolls[1].total == rolls[1].d20 + rolls[0].total - rolls[0].d20 + 1 + 1, "the last: + 1 success + rank 1 (%d, %d)" % [rolls[0].total, rolls[1].total])
	ok(dealt.size() == 2, "two uses, two blows (%s)" % [dealt])
	v(1).refresh()
	b.cast(v(1), plain, v(3))
	ok(rolls.size() == 5 and dealt.size() == 3 and dealt[2] > 0, "not a Strike skill: one roll, its blow landing as it hits (%d rolls, %s)" % [rolls.size(), dealt])


# The hook alone, on a Volley built by hand: each hit's damage held, then the last roll decides - a miss
# loses it all (the Strike misses), a hit deals the pool + successes + rank, a critical double, a glance half.
func test_last_roll() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var hs: Behaviour = heavy_strike.behaviours[0]
	var last := []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): last.append(r))
	var seen := {}
	for i in 200:
		var vo := Behaviour.Volley.new()
		vo.skill = strike
		vo.tags = Battle.hit_tags(v(1), strike)
		vo.target = v(3)
		vo.defense = 20
		for n in [7, 5]:
			vo.dealt = n
			hs.striking(b, v(1), 2, vo)
			ok(vo.dealt == 0, "a hit's damage held back")
		vo.stage = &"end"
		vo.landed = 2
		vo.dealt = 0
		hs.striking(b, v(1), 2, vo)
		var r: Check.Roll = last[-1]
		ok(r.total == r.d20 + 2 + 2, "the last roll: + 2 successes + rank 2")
		var want := 0 if not r.hit else (2 * 16 if r.crit else (8 if r.glance else 16))
		ok(vo.dealt == want and vo.missed != r.hit, "12 held + 2 + 2: %d as rolled (%d, %s)" % [want, vo.dealt, r.d20])
		seen[&"crit" if r.crit else (&"glance" if r.glance else (&"hit" if r.hit else &"miss"))] = true
	ok(seen.size() == 3 and not seen.has(&"glance"), "hits, misses and criticals all seen; no glance at +4 vs 20: 16 hits (%s)" % [seen.keys()])


# The AI's forecast counts the pool (Behaviour.forecasting(), AI._use_ratio()): a Strike skill's use deals one blow, as
# often as its last roll lands, and the forecast agrees with the casts - the pooled use averages what forecast() says
# (a lone Strike: its roll, then the last at + 1 success + rank), where an unpooled one lands at its hit chance. Another
# attack is not pooled: its worth is as it was.
func test_forecast_pool() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var lone: Skill = strike.duplicate()
	lone.chain = false
	var plain: Skill = lone.duplicate()
	plain.tags = [&"physical", &"str", &"martial"] as Array[StringName]
	v(1).strength = 30
	v(1).weapon = null
	roomy(v(1))
	v(1).learned.append(slot(lone, 1))
	v(1).learned.append(slot(plain, 1))
	soak(v(3), 99999)
	v(3).afflict(effect("defense", 18), 99)  # a roll that can miss
	v(1).refresh()
	var read := b.read(v(1), v(3))
	var avg: float = Battle.damage_range(v(1), lone, v(3), b).avg
	ok(AI._use_ratio(b, v(1), lone, v(3), read, {avg = avg}) == 1.0, "without Heavy Strike the reckoning is the plain one")
	v(1).learned.append(slot(heavy_strike, 1))
	v(1).refresh()
	var ratio := AI._use_ratio(b, v(1), lone, v(3), read, {avg = avg})
	var p := Battle.hit_chance(v(1), lone, v(3), b)
	var o := Battle.attack_odds(v(1), lone, v(3), b, -1, 1, 2)  # the last roll: + 1 success + rank
	var last := o[0] + o[1] - 0.5 * o[2]  # as often as it lands, a critical double, a glance half
	ok(is_equal_approx(ratio, last * (avg + 2.0) / avg) and ratio < 1.0, "a Strike's use is one blow behind its last roll: x %.2f (last roll %.2f)" % [ratio, last])
	ok(AI._use_ratio(b, v(1), plain, v(3), read, {avg = avg}) == 1.0, "an attack that is not a Strike is not pooled")
	var got := 0.0
	b.rng.seed = 7
	var n := 500
	for i in n:
		v(3).hp = v(3).max_hp
		v(1).refresh()
		b.cast(v(1), lone, v(3))
		got += v(3).max_hp - v(3).hp
	var want := p * last * (avg + 2.0)
	ok(absf(got / n - want) < 0.15 * want, "it deals what the forecast says on average (%.1f; forecast %.1f)" % [got / n, want])
