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

