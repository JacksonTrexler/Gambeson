extends Test

# HScroll (Scripts/HScroll.gd): the scroll rule for every input, and a wide row on the entry screen.


func _wheel(i: MouseButton, shift := false, factor := 1.0) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = i
	e.pressed = true
	e.shift_pressed = shift
	e.factor = factor
	return e


func test_rule() -> void:
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(0.5, 2.0)
	var swipe := InputEventPanGesture.new()
	swipe.delta = Vector2(-4.0, 1.0)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(9, 3)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	var hover := InputEventMouseMotion.new()
	hover.relative = Vector2(9, 3)
	var cases := [
		[_wheel(MOUSE_BUTTON_WHEEL_DOWN), HScroll.STEP, "wheel down goes right"],
		[_wheel(MOUSE_BUTTON_WHEEL_UP, true), -HScroll.STEP, "shift-wheel the same, up goes left"],
		[_wheel(MOUSE_BUTTON_WHEEL_RIGHT), HScroll.STEP, "a sideways wheel too"],
		[_wheel(MOUSE_BUTTON_WHEEL_DOWN, false, 2.5), HScroll.STEP * 2.5, "a fast wheel notch counts its factor"],
		[_wheel(MOUSE_BUTTON_LEFT), 0.0, "a click isn't a scroll"],
		[pan, 2.0 * 80.0 / HScroll.PAN, "a pan goes by its larger axis (vertical here)"],
		[swipe, -4.0 * 80.0 / HScroll.PAN, "or sideways"],
		[drag, -9.0, "a held-button drag carries the row with it"],
		[hover, 0.0, "a hover doesn't"],
	]
	for c: Array in cases:
		ok(is_equal_approx(HScroll.amount(c[0], 80.0), c[1]), c[2])


func test_strip() -> void:
	var h := HScroll.new()
	var row := HBoxContainer.new()
	for i in 30:
		var bt := Button.new()
		bt.text = "Class %d" % i
		row.add_child(bt)
	h.add_child(row)
	tree.root.add_child(h)
	await tree.process_frame
	await tree.process_frame
	var w := h.strip.size.x
	ok(row.get_parent() == h.strip and h.strip.size.x <= h.max_width, "its children go in the strip, and the row asks for no more than max_width")
	ok(h.left.visible and h.left.disabled and not h.right.disabled, "a long row shows both arrows, the left dimmed at the start")
	h.right.pressed.emit()
	ok(h.strip.scroll_horizontal > w / 2.0 and not h.left.disabled, "the arrow pages right")
	var at := h.strip.get_global_transform_with_canvas() * Vector2(5, 5)  # where input events are, in the viewport
	var e := _wheel(MOUSE_BUTTON_WHEEL_UP)
	e.position = at
	var was := h.strip.scroll_horizontal
	h._input(e)
	ok(h.strip.scroll_horizontal == was - roundi(HScroll.STEP), "the wheel over it scrolls it")
	e.position = at + Vector2(0, 500)
	h._input(e)
	ok(h.strip.scroll_horizontal == was - roundi(HScroll.STEP), "and off it does nothing")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	h._input(press)
	var move := InputEventMouseMotion.new()
	move.position = at
	move.relative = Vector2(-2, 0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	var so_far := h.strip.scroll_horizontal
	h._input(move)
	ok(h.strip.scroll_horizontal == so_far, "a nudge under the slop is still a click")
	move.relative = Vector2(-30, 0)
	h._input(move)
	ok(h.strip.scroll_horizontal == so_far + 30, "dragging past it pulls the row along")
	h.scroll_by(99999.0)
	ok(h.right.disabled and not h.left.disabled, "it stops at the end, the right arrow dimmed")
	h.free()
	var e2: Control = load("res://Scenes/entry.tscn").instantiate()
	e2.next_scene = ""
	tree.root.add_child(e2)
	await tree.process_frame
	var role: Choice = e2.get_node("%Role")
	role.pick(e2.roles[-1])
	await tree.process_frame
	await tree.process_frame
	var scroll: HScroll = role.get_node("Scroll")
	ok(scroll.right.disabled and scroll.strip.scroll_horizontal > 0, "picking the last class scrolls it into view on the entry screen")
	e2.free()
