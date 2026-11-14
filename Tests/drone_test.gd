extends Test

# Drone (Skills/drone.tres; the drone stat), tier 4 of the general Caster tree: the permit against the
# command-limit tap. A Drone takes orders past its leader's caps (orders per ally, allies a turn), in a
# reduced capacity for the turn (Unit.overdriven, Unit.reduced()): its mental mods capped at + its rank.
# Its tap from running out of AP still holds. The HUD draws a reduced unit at half colour.

var drone: Skill = load("res://Skills/drone.tres")


func al() -> Unit:
	return b.get_node("Units/Alabaster")


func drones() -> Command:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), al(): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	v(1).charisma = 10  # one ally a turn, one order each
	v(2).learned.append(slot(drone, 2))
	v(2).wisdom = 18
	for u in [v(1), v(2), al()]:
		u.refresh()
	return Command.new(b, v(1))


func test_drone() -> void:
	var c := drones()
	ok(c.can_order(al()), "a plain ally takes an order")
	c.order(al())
	ok(c.tapped(al()) and not c.can_order(al()), "the caps used: tapped till the turn ends")
	ok(c.can_order(v(2)) and not v(2).reduced(), "the Drone still takes one, the ally cap aside")
	ok(v(2).mod(&"wisdom") == 4, "its own mind meanwhile (wis mod +4)")
	c.order(v(2))
	ok(v(2).overdriven and v(2).reduced() and c.can_order(v(2)), "past the caps: reduced capacity, still taking orders")
	ok(v(2).mod(&"wisdom") == 2, "its mental mods capped at + its rank (II)")
	for p in v(2).ap:
		p.amount = 0.0
	ok(c.tapped(v(2)), "out of AP it's tapped all the same")
	v(2).refresh()
	ok(not v(2).overdriven and v(2).mod(&"wisdom") == 4, "a new turn: itself again")
	ok(drone.describe(2).contains("Drone"), "described: %s" % drone.describe(2))


func test_colour() -> void:
	drones()
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	h.command.order(al())
	h.command.order(v(2))
	h._refresh()
	ok(h.command_state(v(2)) == &"reduced" and h.command_sat(v(2)) == HUD.SAT_REDUCED, "reduced capacity: half colour (%.2f)" % h.command_sat(v(2)))
	ok(h.command_state(al()) == &"spent" and h.command_sat(al()) == 0.0, "tapped: grey")
	h.free()
