extends Test

# Overcharge (Effects/overcharge.tres, its Effect stat overcharge marking it; Unit.overcharge,
# add_overcharge(), covers(), pay_for(), tick()): an extra buffer spent before the unit's own Energy or
# reserve on a cost, counted toward what it can afford only when nothing could pay without it, decaying to
# nothing over the turns it was given for - (what's left / turns left), rounded up, each turn that counts.

var transfer: Skill = load("res://Skills/energy_transfer.tres")
var focus: Skill = load("res://Skills/focus.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var missile: Skill = load("res://Skills/energy_missile.tres")


func test_overcharge() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).add_overcharge(10, 3)
	ok(v(1).overcharge == 10 and v(1).stat(&"overcharge") > 0.0, "10 points, the status on")
	var seen := []
	for i in 3:
		v(1).tick()
		seen.append(v(1).overcharge)
	ok(seen == [6, 3, 0], "it decays to nothing over 3 turns: %s" % [seen])
	ok(Unit.OVERCHARGE not in v(1).timed and v(1).stat(&"overcharge") <= 0.0, "and the status ends")


func test_spare_turn() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).add_overcharge(4, 2, 1)
	v(1).tick()
	ok(v(1).overcharge == 4, "the turn it came on doesn't count")
	v(1).tick()
	v(1).tick()
	ok(v(1).overcharge == 0 and Unit.OVERCHARGE not in v(1).timed, "then 2 turns, and gone")


func test_stacks() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).add_overcharge(3, 1)
	v(1).add_overcharge(2, 4)
	ok(v(1).overcharge == 5 and v(1).timed[Unit.OVERCHARGE].turns == 4, "more adds up, the timer starts again")


func test_spent_first() -> void:
	v(1).learned.append(slot(transfer))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).refresh()
	v(1).energy = 5
	v(1).add_overcharge(2, 3)
	ok(v(1).funding(transfer) == &"energy", "Energy pays, as without it")
	ok(v(1).pay_for(transfer) and v(1).overcharge == 1 and v(1).energy == 5, "its cost (1) comes off Overcharge first")
	v(1).energy = 0
	v(1).refresh()
	ok(v(1).can_afford(transfer) and v(1).funding(transfer) == &"energy", "no Energy: Overcharge alone affords it")
	ok(v(1).pay_for(transfer) and v(1).overcharge == 0 and v(1).energy == 0, "spent from Overcharge")
	ok(Unit.OVERCHARGE not in v(1).timed, "spent to nothing: the status ends")
	ok(not v(1).can_afford(transfer), "and then it can't")


func test_not_focus() -> void:
	v(1).learned.append(slot(focus, 3))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(1).set_store(focus_pool, 1)
	v(1).add_overcharge(3, 3)
	ok(v(1).funding(missile) == focus_pool, "a ranged attack: Focus first, as ever")
	ok(v(1).pay_for(missile) and v(1).store(focus_pool) == 0 and v(1).overcharge == 3, "Focus pays its own, to its last point: Overcharge kept")


func test_card() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	ok(not h._info(v(1)).rows.any(func(r): return r[0] == "OC"), "no Overcharge: no row")
	v(1).add_overcharge(4, 2)
	var rows: Array = h._info(v(1)).rows
	var at := rows.map(func(r): return r[0]).find("OC")
	ok(at > 0 and rows[at][1] == "+4" and rows[at - 1][0] == "EN", "the card's OC row, +4, right under Energy: %s" % [rows.map(func(r): return r[0])])
	h.free()
