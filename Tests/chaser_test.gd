extends Test

# Chaser (Skills/chaser.tres, Behaviours/chaser.gd): a critical hit (the reaction trigger &"crit") grants an
# interrupt in which only the rightmost rank actives on the hotbar may be used, at no more than Chaser's rank
# (Battle.grant_interrupt()'s `only`, Unit.allowed); once per skill use (Battle.use_of()), and not from a use
# made in an interrupt. The player picks in it (directed), the AI as in any interrupt.

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
	ok(b.cast(v(1), row[2], v(3)) and b.interrupter == null and opened.size() == 1, "the chase used; it crits, but a chase sets off no chase")
	ok(v(1).actives.size() == 3 and v(1).rank(row[2]) == 3, "then all its actives, at their ranks")


func test_reach_and_ai() -> void:
	var row := _kit(2)
	var used := []
	b.used.connect(func(_u: Unit, s: Skill, _at, _d): used.append(s))
	b.cast(v(1), row[2], v(3))  # no one directs it: the AI picks the chase
	ok(Chase.reach(v(1), 2) == [row[1], row[2]], "rank II: the rightmost two")
	ok(used.size() == 2 and used[1] in [row[1], row[2]] and b.interrupter == null, "the AI chased with one in reach (%s)" % [used.map(func(s: Skill): return s.name)])

