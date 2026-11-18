extends Test

# Heavy Strike (Skills/heavy_strike.tres, Behaviours/heavy_strike.gd): the hits of one skill use (a Strike's,
# or any attacking skill's) rolled as usual, their damage held back and dealt as one blow on a last roll +
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


# Any attacking skill, not only Strike: one use's blow pooled behind a last roll (two rolls, one blow); used
# again, by hand, it is another use and another blow.
func test_any_use() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var plain: Skill = strike.duplicate()
	plain.chain = false
	v(1).strength = 30
	v(1).weapon = null
	v(1).learned.append(slot(heavy_strike, 1))
	v(1).learned.append(slot(plain, 1))
	soak(v(3), 500)
	var dealt := []
	v(3).hp_changed.connect(func(was: int, now: int): dealt.append(was - now))
	var rolls: Array[Check.Roll] = []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): rolls.append(r))
	for i in 2:
		v(1).refresh()
		b.cast(v(1), plain, v(3))
	ok(rolls.size() == 4 and rolls[0].use == rolls[1].use and rolls[2].use == rolls[3].use and rolls[1].use != rolls[2].use,
			"each use: its roll, then the last roll in the same use (%s)" % [rolls.map(func(r: Check.Roll): return r.use)])
	ok(rolls[1].total == rolls[1].d20 + rolls[0].total - rolls[0].d20 + 1 + 1, "the last: + 1 success + rank 1 (%d, %d)" % [rolls[0].total, rolls[1].total])
	ok(dealt.size() == 2, "two uses, two blows (%s)" % [dealt])


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
