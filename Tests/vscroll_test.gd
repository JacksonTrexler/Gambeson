extends Test

# VScroll (Scripts/VScroll.gd) and the menus that sit in it (the entry page, the Party screen, the skills screen):
# one rule, "ask for the content's height, no more than the screen's less the reserve", and each menu
# that can be taller than the screen scrolls rather than running off it. A menu with room doesn't.


const SCREEN := 270.0  # the shortest screen there is (the design height; the window only widens past it)


# The test window as the game's shortest, 480 x SCREEN, where the menus are tightest; `_restore()` puts it back.
var _was: Array = []


func _short() -> void:
	var w := tree.root
	_was = [w.size, w.content_scale_size, w.content_scale_mode, w.content_scale_aspect]
	w.size = Vector2i(960, int(SCREEN) * 2)
	w.content_scale_size = Vector2i(480, int(SCREEN))
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _restore() -> void:
	var w := tree.root
	w.size = _was[0]
	w.content_scale_size = _was[1]
	w.content_scale_mode = _was[2]
	w.content_scale_aspect = _was[3]


func _screen() -> float:
	return tree.root.get_visible_rect().size.y


func test_rule() -> void:
	_short()
	ok(is_equal_approx(_screen(), SCREEN), "(the test screen is %d tall: %s)" % [SCREEN, _screen()])
	var holder := VBoxContainer.new()
	tree.root.add_child(holder)
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(20, 5000)
	var short := Control.new()
	short.custom_minimum_size = Vector2(20, 40)
	var after := Label.new()
	holder.add_child(tall)
	holder.add_child(after)
	var s := VScroll.wrap(tall, 30.0)
	ok(tall.get_parent() == s and holder.get_child(0) == s and holder.get_child(1) == after, "wrap puts the content in a VScroll where it stood")
	await tree.process_frame
	ok(is_equal_approx(s.custom_minimum_size.y, _screen() - 30.0), "tall content asks for the screen less the reserve, no more")
	ok(s.get_v_scroll_bar().max_value > s.get_v_scroll_bar().page, "and scrolls the rest")
	s.reserve = 100.0
	ok(is_equal_approx(s.custom_minimum_size.y, _screen() - 100.0), "a new reserve refits at once")
	tall.custom_minimum_size.y = 60.0
	await tree.process_frame
	ok(is_equal_approx(s.custom_minimum_size.y, 60.0), "content with room is asked for whole (no bar), following it as it changes")
	ok(not s.get_v_scroll_bar().visible or s.get_v_scroll_bar().max_value <= s.get_v_scroll_bar().page, "no scrolling there")
	short.free()
	holder.free()
	_restore()


func test_menus() -> void:
	_short()
	var e: Control = load("res://Scenes/entry.tscn").instantiate()
	e.next_scene = ""
	tree.root.add_child(e)
	await tree.process_frame
	await tree.process_frame
	var page: VScroll = e.get_node("Scroll")
	var form: Control = e.get_node("%Play").get_parent()
	ok(form.get_combined_minimum_size().y > _screen(), "the start screen's form is taller than the screen (the reason for all this)")
	ok(page.get_v_scroll_bar().max_value >= form.get_combined_minimum_size().y - 1.0, "so the page scrolls over all of it")
	page.scroll_vertical = 9999
	await tree.process_frame
	ok(form.get_global_rect().end.y <= page.get_global_rect().end.y + 1.0 and e.get_node("%Play").get_global_rect().position.y >= 0.0, "at the bottom the last button is on screen, and Play too")
	e._play()  # a leader and a recruit of each other class
	Game.roster.append_array(Game.roster.slice(1, 9))  # and a roster grown past what fits
	var p: PartyPanel = e.open_party()
	await tree.process_frame
	await tree.process_frame
	var box: Control = p.boxes[0].get_parent().get_parent().get_parent()  # the panel: grid, its scroll, the column, then the panel
	ok(box.get_global_rect().size.y <= _screen() and box.get_global_rect().position.y >= -0.5, "the Party screen stays on the screen with a roster past what fits")
	e.free()
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await hud(v(1))
	h.skills.get_node("Scroll/Column").custom_minimum_size.y = 400.0  # a tall tree, the Adventurer's wheel and its footer
	h.toggle_skills()
	await tree.process_frame
	await tree.process_frame
	ok(h.skills.get_global_rect().size.y <= _screen() and h.skills.get_global_rect().position.y >= -0.5, "and so does the skills screen with a tall tree (its title and Close in view)")
	h.free()
	_restore()
