extends Test

# Chaser (Skills/chaser.tres, Behaviours/chaser.gd): a critical hit (the reaction trigger &"crit") grants an
# interrupt in which only the rightmost rank actives on the hotbar may be used, at no more than Chaser's rank
# (Battle.grant_interrupt()'s `only`, Unit.allowed); once per skill use (Battle.use_of()), rank times a use chain
# (its chases join the critting use's Volley.chain), and tagged friction (Battle.loops()): the chain's attack rolls
# past the first rank are at disadvantage, - 1 more each. The player picks in it (directed), the AI as in any.

var chaser: Skill = load("res://Skills/chaser.tres")
const Chase := preload("res://Behaviours/chaser.gd")


# Three cheap attacks on the hotbar, left to right, after its passives; every roll lands and crits (Backstab XVIII, Defense 2).
func _kit(rank: int) -> Array[Skill]:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var row: Array[Skill] = []
	for n in ["Left", "Middle", "Right"]:
		var s: Skill = strike.duplicate()
		s.name = n
		s.ap = 1.0
		s.cost = 0
		row.append(s)
		v(1).learned.append(slot(s, 3))
	row[0].chain = false
	row[1].chain = false
	v(1).learned.append(slot(chaser, rank))
	v(1).learned.append(slot(sk("backstab"), 18))
	v(1).hotbar.assign([chaser, sk("backstab")] + row)  # passives among them don't count
	v(1).strength = 30
	v(1).weapon = null
	soak(v(3), 5000)
	v(1).refresh()
	return row


func test_chase() -> void:
	var row := _kit(1)
	b.directed = func(u: Unit): return u == v(1)
	var opened := []
	b.interrupt_began.connect(func(u: Unit): opened.append(u))
	b.cast(v(1), row[2], v(3))  # a Strike III: three crits in one use
	ok(opened == [v(1)], "a use's crits chase once (%s)" % [opened])
	ok(v(1).actives == [row[2]] and v(1).rank(row[2]) == 1, "Chaser I: the rightmost active alone, at rank I (%s, %d)" % [v(1).actives, v(1).rank(row[2])])
	ok(not b.cast(v(1), row[0], v(3)), "nothing further left")
	ok(b.cast(v(1), row[2], v(3)) and b.interrupter == null and opened.size() == 1, "the chase used; it crits, but Chaser I has chased its chain once")
	ok(v(1).actives.size() == 3 and v(1).rank(row[2]) == 3, "then all its actives, at their ranks")


func test_reach_and_ai() -> void:
	var row := _kit(2)
	var used := []
	b.used.connect(func(_u: Unit, s: Skill, _at, _d): used.append(s))
	b.cast(v(1), row[2], v(3))  # no one directs it: the AI picks the chase
	ok(Chase.reach(v(1), 2) == [row[1], row[2]], "rank II: the rightmost two")
	ok(used.size() == 3 and used[1] in [row[1], row[2]] and used[2] in [row[1], row[2]] and b.interrupter == null, "the AI chased twice in the chain (rank II), each with one in reach (%s)" % [used.map(func(s: Skill): return s.name)])


# The AI picks the best it may, within the reach: the leftmost far outweighs the others but is out of reach at rank II,
# and of the two in reach the middle is the better blow (so it, not the Strike that began it, is the chase's pick).
func test_ai_picks_the_best_in_reach() -> void:
	var row := _kit(2)
	for i in [0, 1]:
		var big: Tier = row[i].tiers[0].duplicate()
		big.power = [300, 60][i]
		row[i].tiers = [big] as Array[Tier]
	v(1).refresh()
	var used := []
	b.used.connect(func(_u: Unit, s: Skill, _at, _d): used.append(s))
	b.cast(v(1), row[2], v(3))
	ok(used.size() == 3 and used.slice(1).all(func(s: Skill): return s == row[1]), "the chases are the best blow in reach, never the leftmost (%s)" % [used.map(func(s: Skill): return s.name)])


# The forecast counts a chase's friction (Battle.friction_ahead()): in an interrupt granted to carry a looping chain on,
# the chase's first roll is at its disadvantage and - N, as the cast will make it, though Unit.friction is 0 until its use
# opens; the AI prices the rolls of a Strike's use from there (_use_ratio(): each later roll at more), a plain use at 1.
func test_forecast_counts_friction() -> void:
	var row := _kit(1)
	v(1).learned = v(1).learned.filter(func(x: Slot): return x.skill != sk("backstab") and x.skill != chaser)  # its crit range would make every roll a hit; its chases are priced by test_forecast_counts_crit_loops
	v(1).refresh()
	v(3).afflict(effect("defense", 16), 99)  # a roll that can miss
	b.directed = func(u: Unit): return u == v(1)
	var read := b.read(v(1), v(3))
	var d := Battle.damage_range(v(1), row[2], v(3), b)
	var free := Battle.hit_chance(v(1), row[1], v(3), b)
	ok(AI._use_ratio(b, v(1), row[2], v(3), read, d) == 1.0 and b.friction_ahead(v(1)) == 0, "no friction: the plain reckoning")
	b.grant_interrupt(v(1), 1, {row[1]: 1, row[2]: 3}, {Battle.FRICTION: [1, 2]})  # (Strike at III: three rolls) looping: 1 roll free, 2 rolled since
	ok(b.interrupter == v(1) and v(1).friction == 0 and b.friction_ahead(v(1)) == 2 and b.friction_ahead(v(1), 2) == 4, "the chase's next roll is at friction 2, the ones after worse")
	var chased := Battle.hit_chance(v(1), row[1], v(3), b)
	ok(chased < free, "the odds of the chase's first roll count it (%.2f, against %.2f)" % [chased, free])
	var ratio := AI._use_ratio(b, v(1), row[2], v(3), read, d)
	ok(ratio < 0.95, "a Strike's later rolls, at more friction, are priced (x %.2f)" % ratio)
	b.end_interrupt()
	v(1).friction = 2  # as the use will have set it
	ok(is_equal_approx(Battle.hit_chance(v(1), row[1], v(3), b), chased), "the same odds as the roll it is")
	v(1).friction = 0
	b.directed = Callable()


# The AI's forecast counts the uses a crit sets off (Behaviour.Forecast.loops: AI._use_ratio()), each as likely as the crits before
# it and at its chain's friction: Chaser's chases (rank of them, so a higher rank adds more) and, from the skill's own flag, a
# Jugular's recasts. A use that can't crit (no crit range, a natural 20 only) adds little; no Chaser, nothing.
func test_forecast_counts_crit_loops() -> void:
	var row := _kit(1)
	v(3).afflict(effect("defense", 16), 99)  # a roll that can miss
	var ratio := func(s: Skill) -> float:
		return AI._use_ratio(b, v(1), s, v(3), b.read(v(1), v(3)), Battle.damage_range(v(1), s, v(3), b))
	var with_one: float = ratio.call(row[2])
	v(1).learned.append(slot(chaser, 3))
	v(1).refresh()
	var with_three: float = ratio.call(row[2])
	v(1).learned = v(1).learned.filter(func(x: Slot): return x.skill != chaser)
	v(1).refresh()
	var none: float = ratio.call(row[2])
	ok(with_one > none + 0.05 and with_three > with_one + 0.02, "Chaser counts its chase, and a chase more for each rank: x%.2f (none), x%.2f (I), x%.2f (III)" % [none, with_one, with_three])
	var j: Skill = load("res://Skills/jugular.tres").duplicate()
	j.disadvantage = false  # (a crit range to see it)
	var k: Skill = j.duplicate()
	k.recast_on_crit = false
	for s in [j, k]:
		v(1).learned.append(slot(s, 1))
	v(1).refresh()
	var recasts: float = ratio.call(j)
	var once: float = ratio.call(k)
	var read := b.read(v(1), v(3))
	ok(recasts > once + 0.05 and AI.score(v(1), j, read, b, v(3)) > AI.score(v(1), k, read, b, v(3)), "a skill that recasts on a crit counts its recasts: x%.2f against x%.2f" % [recasts, once])
	var sure: Skill = k.duplicate()
	sure.sure_crit = false
	v(1).learned.append(slot(sure, 1))
	v(1).refresh()
	var sure_score := AI.score(v(1), k, read, b, v(3))
	var plain_score := AI.score(v(1), sure, read, b, v(3))
	ok(sure_score > plain_score * 1.6 and sure_score < plain_score * 2.05, "a use whose hits all crit is priced at double the damage of its hits (not its glances): %.2f against %.2f" % [sure_score, plain_score])
	v(1).learned = v(1).learned.filter(func(x: Slot): return x.skill != sk("backstab"))
	v(1).refresh()
	ok(ratio.call(j) < recasts - 0.05, "with only a natural 20 to crit on, it counts far fewer (x%.2f)" % ratio.call(j))


# The user's case: a non-Strike attack (Left, a Jam: three rolls, no strike tag) crits; Chaser II follows up
# with Strike (Right) twice in the chain. Heavy Strike pools only the Strike's rolls: Left's hits land one by
# one, each chase's land as one blow after its rolls. Friction: from the crit, each roll past the first two is
# at disadvantage (the second die shown) with Unit.friction 1, 2, ... before it; the chain over, none.
func test_chain_friction_and_heavy_strike() -> void:
	var row := _kit(2)
	row[0].chain = true
	row[0].tags = [&"physical", &"str", &"martial"] as Array[StringName]
	var heavy: Skill = load("res://Skills/heavy_strike.tres")
	v(1).learned.append(slot(heavy, 1))
	v(1).hotbar.push_front(heavy)
	v(1).refresh()
	b.rng.seed = 11
	var picks := [row[2], row[2]]
	b.directed = func(u: Unit): return u == v(1)  # held open: the picks below are cast by hand
	var line := []  # [&"roll", use, friction before it, two dice, crit] / [&"hp", n]
	var before := [0]
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): line.append([&"roll", r.use, before[0], r.other != 0, r.crit and r.hit]); before[0] = v(1).friction)
	v(3).hp_changed.connect(func(was: int, now: int): line.append([&"hp", was - now]))
	var opened := []
	b.interrupt_began.connect(func(u: Unit): opened.append(u))
	b.cast(v(1), row[0], v(3))
	while b.interrupter == v(1) and not picks.is_empty():
		b.cast(v(1), picks.pop_front(), v(3))
	ok(opened.size() == 2 and b.interrupter == null, "Chaser II: two chases in the chain, no third (%d)" % opened.size())
	var rolls := line.filter(func(x: Array): return x[0] == &"roll")
	var uses := []
	for x in rolls:
		if x[1] not in uses:
			uses.append(x[1])
	ok(uses.size() == 3, "three uses: the Jam, two chases (%s)" % [uses])
	var first := rolls.find(rolls.filter(func(x: Array): return x[4])[0])
	var friction_ok := true
	for i in rolls.size():
		var k := i - first  # rolls since the chain began to loop
		var want := maxi(k - 2, 0)
		if rolls[i][2] != want or rolls[i][3] != (want > 0):
			friction_ok = false
	ok(friction_ok and rolls.size() > first + 3, "past two rolls from the crit: disadvantage, friction 1, 2, ... (%s)" % [rolls.map(func(x: Array): return [x[1], x[2], x[3]])])
	# Left's hits land one by one; in a chase, no damage until its rolls are done
	var pooled_ok := true
	var hp_in := {}
	var use := 0
	var rolled_after := false
	for x in line:
		if x[0] == &"roll":
			if use != 0 and x[1] == use and hp_in.get(use, 0) > 0 and use != uses[0]:
				rolled_after = true
			use = x[1]
		else:
			hp_in[use] = hp_in.get(use, 0) + 1
	var jam_rolls := rolls.filter(func(x: Array): return x[1] == uses[0]).size()
	ok(hp_in.get(uses[0], 0) == jam_rolls and not rolled_after and hp_in.get(uses[1], 0) <= 1 and hp_in.get(uses[2], 0) <= 1,
			"the Jam's %d hits land one by one; each Strike chase one pooled blow, after its rolls (%s)" % [jam_rolls, hp_in])
	ok(v(1).friction == 0, "the chain over: no friction left")
	b.directed = Callable()

