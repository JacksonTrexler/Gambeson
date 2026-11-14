extends Test

# Telepathy (Skills/telepathy.tres, Behaviours/telepathy.gd): for one ally a turn within rank tiles, the
# leader commands by its rank in place of its charisma mod (Command.cha_for()): reach, orders, slots.
# The first ally it carries an order to is bound to it until the leader's side's next turn.

var telepathy: Skill = load("res://Skills/telepathy.tres")


func test_telepathy() -> void:
	var al: Unit = b.get_node("Units/Alabaster")
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(5, 3), al: Vector2i(3, 6)})
	var c := Command.new(b, v(1))
	v(1).charisma = 8  # -1
	ok(c.slots(v(2)) == 0 and not c.in_range(v(2)), "without it: cha -1, move orders only, reach 1 - v(2) 2 tiles off is out of reach")
	v(1).learned.append(slot(telepathy, 3))
	ok(c.cha_for(v(2)) == 3 and c.slots(v(2)) == 3 and c.order_cap(v(2)) == 3 and c.in_range(v(2)), "Telepathy III: v(2) within 3 tiles is ordered as by cha +3 - slots 1-3, 3 orders, in reach")
	ok(c.cha_for(al) == 3, "so is Alabaster, 3 tiles off, until one is picked")
	ok(c.cha() == -1 and c.slots() == 0 and c.ally_cap() == 1, "the leader's own charisma, and the allies a turn, are unchanged")
	c.order(v(2))
	ok(c.linked == v(2) and c.cha_for(v(2)) == 3 and c.cha_for(al) == -1, "ordering v(2) binds it: Alabaster is back to cha -1")
	ok(c.basis(0, v(2)) == "charisma -1, +3 for this ally", c.basis(0, v(2)))
	c.new_turn()
	ok(c.linked == null and c.cha_for(al) == 3, "a new turn frees it")
	v(2).cell = Vector2i(7, 3)
	ok(c.cha_for(v(2)) == -1, "4 tiles off is past rank III")
	c.order(v(2))
	ok(c.linked == null, "an order it didn't carry doesn't bind it")
	ok(telepathy.describe(3).contains("within 3 tiles"), telepathy.describe(3))
