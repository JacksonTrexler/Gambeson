extends Test

# Settings' key rebinds (KeyBinds): the input map's actions in a dropdown, the key on each, and Rebind
# taking the next key pressed; saved and loaded back (the user's keybinds.cfg).


func test_rebind() -> void:
	var acts := KeyBinds.actions()
	ok(&"end_turn" in acts and &"camera_home" in acts and acts.all(func(a: StringName): return not String(a).begins_with("ui_")), "the game's own actions, Home's camera focus among them")
	ok(KeyBinds.key_of(&"camera_home") == "Home" and KeyBinds.key_of(&"skills") == "S", "the keys on them read plainly")
	var had := KeyBinds.key_of(&"end_turn")
	var was: Key = OS.find_keycode_from_string(had)
	var keys := KeyBinds.new()
	tree.root.add_child(keys)
	keys.listen(&"end_turn")
	ok(keys.waiting.visible, "Rebind asks for a key")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E
	ev.pressed = true
	keys._input(ev)
	ok(KeyBinds.key_of(&"end_turn") == "E" and not keys.waiting.visible, "the next key pressed takes it")
	var cfg := ConfigFile.new()
	ok(cfg.load(KeyBinds.SAVE) == OK and cfg.get_value("keys", "end_turn") == KEY_E, "saved")
	KeyBinds.bind(&"end_turn", was)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(KeyBinds.SAVE))
	ok(KeyBinds.key_of(&"end_turn") == had, "put back (%s)" % had)
	keys.free()
