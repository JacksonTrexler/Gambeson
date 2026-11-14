extends Test

# Pace (Battle UI v2, docs/plans/pace.md): a spent unit hands the focus to the next that can act
# (HUD.hand_over), a held key hurries the turn change and units acting on their own (HUD.speed()),
# and the log is collapsed to its last entry (HUD.show_log()).


func unit(n: String) -> Unit:
	return b.get_node("Units/" + n)


func start(leader: Unit) -> HUD:
	b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	return h


func test_hand_over() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), al: Vector2i(2, 2), v(3): Vector2i(8, 2)})
	v(1).charisma = 8
	var h := await start(v(1))
	ok(h.hand_over, "on by default")
	h.select(al)
	h.click(Vector2i(2, 1))
	ok(al.cell == Vector2i(2, 1) and h.selected == v(1), "cha 8: its one order spent on a walk, the ally hands over (wrapping round to the leader)")
	v(1).charisma = 14
	h.command.new_turn()
	h.select(v(1))
	h.click(Vector2i(1, 1))
	ok(h.selected == v(1), "a walk that leaves it able to act: it keeps the focus")
	h.select(v(2))
	h.click(v(2).cell)
	ok(v(2) in h.command.locked and h.selected == al, "an ally rests: the next in the side's order that hasn't acted")
	h.click(al.cell)
	ok(h.selected == v(1), "the last one rests: round to the leader (it walked, but can still act)")
	h.click(v(1).cell)
	ok(h.selected == v(1), "nobody left who can act: the focus stays")
	h.command.new_turn()
	h.select(v(1))
	h.click(Vector2i(1, 2))
	h.select(al)
	h.click(al.cell)
	ok(h.selected == v(2), "one that hasn't acted comes before one that has (v(2) over the leader)")
	h.command.new_turn()
	h.hand_over = false
	h.select(v(2))
	h.click(v(2).cell)
	ok(h.selected == v(2), "the toggle off: the spent unit stays selected")
	h.free()


func test_hurry() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	ok(InputMap.has_action(&"hurry") and &"hurry" in KeyBinds.actions(), "the hurry key is a bindable action")
	ok(is_equal_approx(h.speed(), 1.0), "not held: speed 1")
	Input.action_press(&"hurry")
	ok(is_equal_approx(h.speed(), HUD.HURRY), "held: HURRY times as fast")
	var t := Time.get_ticks_msec()
	await h._wait(0.6)
	var hurried := (Time.get_ticks_msec() - t) / 1000.0
	ok(hurried < 0.4, "held, a 0.6 s wait is over in a quarter of it (%.2f s)" % hurried)
	h.overlay.walk(v(3), v(3).cell, [v(3).cell + Vector2i(1, 0), v(3).cell + Vector2i(2, 0)] as Array[Vector2i])
	h._hurry()
	var left := h.overlay.walking_left()
	ok(left > 0.0 and left <= 2 * Overlay.STEP_TIME / HUD.HURRY + 0.01, "a walk under way runs HURRY times as fast, and the turn waits that long (%.2f s)" % left)
	Input.action_release(&"hurry")
	h._hurry()
	ok(h.overlay.walking_left() > 2 * Overlay.STEP_TIME / HUD.HURRY + 0.01, "let go: back to speed 1")
	t = Time.get_ticks_msec()
	await h._wait(0.6)
	var plain := (Time.get_ticks_msec() - t) / 1000.0
	ok(plain >= 0.5, "not held: the wait takes its time (%.2f s)" % plain)
	h.free()


func test_log() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	var line: RichTextLabel = h.get_node("%LogLine")
	ok(not h.log_open and not h.log_box.visible and line.visible, "collapsed by default: just the last line")
	h._log("First")
	h._log("Brick hits [b]Elmit[/b]")
	ok(line.get_parsed_text() == "Brick hits Elmit", "the line is the last entry: %s" % line.get_parsed_text())
	ok("First" in h.log_box.get_parsed_text(), "the whole log keeps every line while collapsed")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	line.gui_input.emit(click)
	ok(h.log_open and h.log_box.visible and not line.visible, "a click on the line opens the whole log")
	(h.get_node("%LogTitle") as Control).gui_input.emit(click)
	ok(not h.log_open and line.visible, "a click on the title collapses it again")
	h.free()
