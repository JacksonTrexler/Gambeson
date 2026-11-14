class_name Prefs

# The player's Settings values, kept between runs in user://settings.cfg (one section, "settings"), the
# way KeyBinds keeps its binds in user://keybinds.cfg. Read with get_pref(key, default) as a screen
# opens; put() saves at once. Tests point SAVE somewhere else.

static var SAVE := "user://settings.cfg"


static func get_pref(key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return default
	return cfg.get_value("settings", key, default)


static func put(key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	cfg.set_value("settings", key, value)
	cfg.save(SAVE)
