extends Test

# What helpless costs (Unit.helpless(), stopped()) besides its own actions: a leader gives no orders, and
# a unit has lost its reactions (Unit.reacts(): dodge, guard, obstruct, as Jam takes them). It still sees:
# watching isn't acting (Battle._watch()). A permit (the mindless stat: Mindless Fury) lets it act, and
# keeps its reactions, until it's spent.

var stunned: Effect = load("res://Effects/stunned.tres")


func test_leader() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), v(3): Vector2i(8, 3)})
	var c := Command.new(b, v(1))
	ok(c.can_order(v(2)) and c.can_join(v(2)), "a leader on its feet orders and gathers")
	v(1).afflict(stunned, 3, 3)
	ok(v(1).stopped() and not c.can_order(v(2)) and not c.could_order(v(2)) and not c.can_join(v(2)), "a stunned leader gives no orders and gathers no one")
	ok(not c.can_order(v(1)), "nor does it order itself: it's tapped")
	b.mend(v(1), 0, 3)
	ok(c.can_order(v(2)), "healed, it orders again")
	v(1).damage(999)  # no Tenacity: it dies, and the dead give none
	ok(not c.can_order(v(2)), "(and the fallen leader still gives none)")


func test_leader_permit() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), v(3): Vector2i(8, 3)})
	var c := Command.new(b, v(1))
	v(1).afflict(stunned, 3, 3)
	v(1).afflict(effect("mindless", 1.0), 3)
	ok(v(1).helpless() and not v(1).stopped() and c.can_order(v(2)), "Mindless Fury lets a helpless leader keep leading, in a reduced capacity")
	v(1).fury_acts = 1
	ok(v(1).stopped() and not c.can_order(v(2)), "its uses spent, it gives none")


func test_reactions() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(5, 3)})
	v(3).guard = Vector2(-1, 0)
	v(3).afflict(effect("guard", 0.5), 9)
	v(3).afflict(effect("obstruct", 3.0), 9)
	ok(v(3).reacts() and v(3).guarding(Vector2i(4, 3)) and b.obstruction(v(1), Vector2i(5, 4)) > 0.0, "on its feet it guards and obstructs")
	ok(b.evade(v(3), 1) < 1.0, "and dodges an easy blow (DC 1)")
	v(3).afflict(stunned, 3, 3)
	ok(not v(3).reacts() and not v(3).guarding(Vector2i(4, 3)), "stunned, it doesn't guard")
	ok(is_equal_approx(b.evade(v(3), 1), 1.0), "or dodge: all of it lands, even against DC 1")
	ok(is_zero_approx(b.obstruction(v(1), Vector2i(5, 4))), "or obstruct")
	b.mend(v(3), 0, 3)
	ok(v(3).reacts() and v(3).guarding(Vector2i(4, 3)) and v(3).guard != Vector2.ZERO, "healed, the shield it had up is up again")
	v(3).afflict(effect("mindless", 1.0), 3)
	v(3).afflict(stunned, 3, 3)
	ok(v(3).reacts(), "under a permit it still reacts")
	v(3).fury_acts = 1
	ok(not v(3).reacts(), "spent, it doesn't")


func test_asleep_and_downed() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(5, 3)})
	v(3).afflict(effect("sleep", 1.0), 3)
	ok(v(3).helpless() and not v(3).reacts(), "asleep: no reactions")
	v(3).wake()
	v(3).afflict(effect("jammed", 1.0), 3)
	ok(not v(3).reacts(), "Jammed still takes them")


func test_still_sees() -> void:
	stage(nemes, {v(1): Vector2i(3, 3), v(3): Vector2i(8, 3)})
	v(3).wisdom = 1  # mod -5: it looks only every sixth turn... the count is what shows it looked
	v(3).afflict(stunned, 3, 3)
	var before := v(3).unwatched
	b.end_turn()
	ok(v(3).stopped() and v(3).unwatched == before + 1, "a stunned unit's turn ending still has it look around (%d -> %d)" % [before, v(3).unwatched])
