extends Test

# The turn clock (HUD.turn_clock): the player gets wisdom + half its intelligence in seconds to act,
# shown top middle; it pauses while Settings is open and ends the turn when it runs out. And units
# acting on their own move together (HUD.together): no pause between them.


func hud(pace := 0.45) -> HUD:
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = pace
	tree.root.add_child(h)
	return h


func test_seconds() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	b.player = v(1)
	v(1).wisdom = 12
	v(1).intelligence = 11
	var h := hud(0.0)
	await tree.process_frame
	ok(is_equal_approx(h.turn_seconds(), 17.0), "wis 12 + int 11 / 2 (5): 17 s (%s)" % h.turn_seconds())
	h._tick_clock(1.0)
	ok(not h.clock_label.visible, "unwatched (pace 0): no clock")
	h.free()


func test_runs_out() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	b.player = v(1)
	var h := hud()
	await tree.process_frame
	h._end_intro()
	ok(h.clock_on and h.clock > 10.0, "the player's turn arms its clock")
	h.clock_on = false
	h.clock = 0.0
	h._tick_clock(1.0)
	ok(h.my_turn(), "a turn the clock wasn't set for (the turn changes deferred): it doesn't end on 0")
	h.clock = 3.0
	h.clock_on = true
	ok(h.my_turn(), "the player's turn")
	h.settings.show()
	h._tick_clock(5.0)
	ok(is_equal_approx(h.clock, 3.0) and h.clock_label.visible, "Settings open: it holds")
	h.settings.hide()
	h._tick_clock(1.0)
	ok(h.clock_label.text == "2", "ticking: %s" % h.clock_label.text)
	h._tick_clock(2.5)
	ok(not h.my_turn(), "out of time: the turn ends")
	h.free()


func test_together() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var h := hud()
	await tree.process_frame
	ok(h.together, "on by default")
	h.overlay.walk(v(3), v(3).cell, [v(3).cell + Vector2i(1, 0), v(3).cell + Vector2i(2, 0)] as Array[Vector2i])
	ok(h.overlay.walking_left() > 0.0 and h.overlay.walking_left() <= 2 * Overlay.STEP_TIME + 0.01, "a walk under way: the turn waits it out")
	h.free()
