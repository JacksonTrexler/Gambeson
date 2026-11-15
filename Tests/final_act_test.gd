extends Test

# Final Act (Skills/final_act.tres, Behaviours/final_act.gd): a Paladin (Chivalry) reaction. Once a battle,
# reaching 0 HP, it holds on and interrupts the turn to take one free action (Battle.grant_interrupt());
# the turn then resumes. It falls once that's done, as it would have, unless the action got it back up (?12).

var final_act: Skill = load("res://Skills/final_act.tres")
var jam: Skill = load("res://Skills/jam.tres")
var heal: Skill = load("res://Skills/heal.tres")


# v(3) (Nemes, its turn) Strikes v(1) (not Jam: Jam takes its reactions before its damage lands), at 1 HP
# with Final Act and Jam of its own, both sure to hit.
func scene() -> void:
	v(1).learned.append(slot(final_act))
	v(1).learned.append(slot(jam))
	v(1).dexterity = 40
	v(3).strength = 40
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	for i in [1, 3]:
		v(i).refresh()
		soak(v(i), 300)
	v(1).hp = 1


func test_acts_then_falls() -> void:
	scene()
	var fell := []
	v(1).died.connect(func(u: Unit): fell.append(u))
	v(1).downed.connect(func(u: Unit): fell.append(u))
	ok(b.cast(v(3), strike, v(1)), "Jam lands")
	ok(v(1).hp == 0 and v(1).staying and v(1).is_alive() and fell.is_empty(), "at 0 HP it holds on")
	ok(b.interrupter == v(1), "and interrupts the turn")
	ok(b.cast(v(1), jam, v(3)) and v(3).hp < 300, "its free action")
	ok(b.interrupter == null and not v(1).staying and fell == [v(1)], "then it falls, as it would have")
	ok(b.turn == nemes and b.cast(v(3), strike, v(1)) or not v(1).is_alive(), "the turn resumes")


func test_once() -> void:
	scene()
	b.cast(v(3), strike, v(1))
	b.end_interrupt()
	ok(b.times_reacted(v(1), final_act) == 1, "spent")
	var r := b.react(&"fallen", v(1), v(3))
	ok(not r.stay and b.interrupter == null, "once a battle")


func test_gets_back_up() -> void:
	scene()
	v(1).learned.append(slot(heal, 3))
	v(1).wisdom = 30
	b.cast(v(3), strike, v(1))
	ok(b.cast(v(1), heal, v(1)), "it heals itself with its free action")
	ok(v(1).hp > 0 and v(1).is_alive() and not v(1).staying, "back above 0 HP: it doesn't fall (%d)" % v(1).hp)


func test_jammed() -> void:
	scene()
	v(3).learned.append(slot(jam))
	v(3).dexterity = 40
	b.cast(v(3), jam, v(1))
	ok(b.interrupter == null and not v(1).staying, "Jammed (Jam takes its reactions as it lands, before its damage): no Final Act")


func test_describe() -> void:
	ok("once a battle" in final_act.describe(1) and "free action" in final_act.describe(1), final_act.describe(1))
