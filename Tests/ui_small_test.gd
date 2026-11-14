extends Test

# Small UI things: Settings kept between runs (Prefs), floating numbers hurried with the walks, the Guide
# naming the Hurry key as bound, high contrast's heavier faction trim, a mark on a modified skill's slot.


func start(leader: Unit) -> HUD:
	b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	return h


func test_prefs() -> void:
	ok(Prefs.SAVE != "user://settings.cfg", "the suite keeps its own settings file")
	var h := await start(v(1))
	var picker: OptionButton = h.get_node("%HighContrast").get_parent().get_node("AllyGlow")
	ok(h.ally_glow == HUD.ALLY_GLOW and not h.high_contrast, "nothing saved: the defaults")
	picker.select(2)
	picker.item_selected.emit(2)
	h.get_node("%HighContrast").toggled.emit(true)
	ok(Prefs.get_pref("ally_glow", "") == "Sky" and Prefs.get_pref("high_contrast", false), "a change is saved")
	h.free()
	h = await start(v(1))
	picker = h.get_node("%HighContrast").get_parent().get_node("AllyGlow")
	ok(h.ally_glow == HUD.ALLY_GLOWS["Sky"] and picker.selected == 2 and h.high_contrast and h.get_node("%HighContrast").button_pressed,
			"and back on the next run")
	h.free()


func test_floats_hurry() -> void:
	var h := await start(v(1))
	var ref := Node2D.new()  # a rise at plain speed, to compare with
	tree.root.add_child(ref)
	ref.create_tween().tween_property(ref, "position:y", -10.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	h.overlay.float_text(v(1), "-3", Color.RED)
	var label: Label = h.overlay.top.get_child(h.overlay.top.get_child_count() - 1)
	var y0 := label.position.y
	Input.action_press(&"hurry")  # the HUD hurries what's under way every frame while it's held
	ok(h.overlay._floats.size() >= 1, "the floater is tracked")
	for i in 6:
		await tree.process_frame
	var rose := y0 - label.position.y
	ok(rose > 0.0 and rose > 1.8 * -ref.position.y, "hurried, it rises faster than a plain one (%.2f vs %.2f)" % [rose, -ref.position.y])
	Input.action_release(&"hurry")
	ref.free()
	h.free()


func test_guide_key() -> void:
	ok("Hold F " in Guide.text(&"play"), "the Hurry key as bound (F)")
	KeyBinds.bind(&"hurry", KEY_G)
	ok("Hold G " in Guide.text(&"play") and not "Hold F " in Guide.text(&"play"), "rebound, the Guide follows")
	KeyBinds.bind(&"hurry", KEY_F)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(KeyBinds.SAVE))


func test_heavy_trim() -> void:
	var u := v(1)
	var box := u.trim.get_theme_stylebox("panel") as StyleBoxFlat
	ok(box.border_width_left == 1, "plain trim is one pixel")
	u.set_glow(-1, true)
	ok(box.border_width_left == 2 and u.trim.size.x == Unit.BAR_WIDTH + 4.0, "high contrast: two, standing out the further")
	u.set_glow(-1, false)
	ok(box.border_width_left == 1 and u.trim.size.x == Unit.BAR_WIDTH + 2.0, "and back")


func test_modded_mark() -> void:
	var slot_ui := SkillSlot.new()
	tree.root.add_child(slot_ui)
	slot_ui.set_state(0, load("res://Skills/strike.tres"), 1, false, false, true, true, false, 2, "")
	ok(not slot_ui.modded, "no modifier: no mark")
	slot_ui.set_state(0, load("res://Skills/strike.tres"), 1, false, false, true, true, false, 2, "F")
	ok(slot_ui.modded, "a worn emblem's modifier marks the slot")
	slot_ui.free()
