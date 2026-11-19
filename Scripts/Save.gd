class_name Save

# The player's progress between battles, kept in user://save.json: what Game holds that outlives a battle
# (the hero, its level and XP, outfit, hearts, and the stash). Settings keep to Prefs and KeyBinds, apart.
# Game.dungeon and Game.difficulty are about the portal just taken, not progress, so they are not saved.
#
# JSON, with a version. A file that isn't JSON, isn't a dictionary or is another version is moved aside to
# <PATH>.bad (so a newer game's save is never overwritten) with a line in the log, and the game starts empty.
# Items go by their file (res://Items/<id>.tres) with the rank and enchant they have now: the same .tres gets
# a copy only if either differs (Unit.enchant() copies an item). Item-lent skills come back with their items.
# Tests point PATH at a file of their own (Tests/run.gd), as Prefs.SAVE.

const VERSION := 1
const ITEMS := "res://Items/"

# A script run with -s (a screenshot driver, or the test runner, which sets its own path too) is not the game: it keeps to a file of its own. (No main loop yet while a -s script loads.)
static var PATH := "user://save_driver.json" if not Engine.get_main_loop() or Engine.get_main_loop().get_script() else "user://save.json"
static var loaded := false  # load_once() has run: going back to the entry screen doesn't reload over what's in memory
static var _ids := {}  # item name -> its file, for an item copy that no longer knows its own (id())


# Game's progress, as a dictionary ready for JSON.
static func pack() -> Dictionary:
	var out := {version = VERSION, hearts = Game.hearts, level = Game.level, xp = Game.xp}
	if Game.hero:
		out.hero = {faction = Game.hero.faction.resource_path, role = Game.hero.role.resource_path, name = Game.hero.name}
	var worn := {}
	for slot in Game.outfit:
		var d := item_out(Game.outfit[slot])
		if d:
			worn[slot] = d
	out.outfit = worn
	var stash := []
	for it in Game.stash:
		var d := item_out(it)
		if d:
			stash.append(d)
	out.stash = stash
	out.equipped = _equipped_out()
	if not Game.lapses.is_empty():
		out.lapses = Game.lapses
	return out


# The starter's equipped set (Game.equipped, Unit.get_equipped()): each slot's skill id (Skills/<id>.tres),
# "" where it's empty. A file from before it has no "equipped" key: the class's default bar.
static func _equipped_out() -> Array:
	return Game.equipped.map(func(s): return s.resource_path.get_file().get_basename() if s is Skill and s.resource_path.begins_with("res://Skills/") else "")


# Back into Game.equipped, slot by slot: an id with no file is an empty slot (Unit.set_equipped() skips
# what the unit doesn't have).
static func _equipped_in(ids: Array) -> void:
	Game.equipped = ids.map(func(id): return load("res://Skills/%s.tres" % id) if id is String and id != "" and ResourceLoader.exists("res://Skills/%s.tres" % id) else null)


# d (from pack(), or a file) into Game. What it can't make sense of is left out, with a line in the log.
static func unpack(d: Dictionary) -> void:
	Game.hearts = maxi(int(d.get("hearts", 0)), 0)
	Game.level = maxi(int(d.get("level", 1)), 1)  # Battle.starter() clamps it to Unit.MAX_LEVEL
	Game.xp = maxi(int(d.get("xp", 0)), 0)
	Game.hero = {}
	var h = d.get("hero")
	if h is Dictionary:
		var f = load(h.get("faction", "")) if _is_path(h.get("faction")) else null
		var r = load(h.get("role", "")) if _is_path(h.get("role")) else null
		if f is Faction and r is Role:
			Game.hero = {faction = f, role = r, name = str(h.get("name", "Shrike"))}
		else:
			push_warning("Save: the saved hero's side or class is gone; it is left out")
	Game.outfit = {}
	var worn = d.get("outfit")
	if worn is Dictionary:
		for slot in worn:
			var it := item_in(worn[slot])
			if it and (it.slot == slot or (it.slot == "armor" and slot.begins_with(Unit.PLATE))):
				Game.outfit[slot] = it
	Game.stash = []
	var stash = d.get("stash")
	if stash is Array:
		for e in stash:
			var it := item_in(e)
			if it:
				Game.stash.append(it)
	var eq = d.get("equipped")
	_equipped_in(eq if eq is Array else [])
	var lp = d.get("lapses")
	Game.lapses = lp if lp is Dictionary else {}  # a file from before it: nothing leans


static func _is_path(p: Variant) -> bool:
	return p is String and p.begins_with("res://")


# it as {item, rank, enchant}, or {} for one with no file to come back from.
static func item_out(it: Item) -> Dictionary:
	var path := id(it)
	if not path:
		push_warning("Save: %s has no file to be saved by; it is left out" % it.name)
		return {}
	return {item = path, rank = it.rank, enchant = it.enchant}


# The item d names, with its saved rank and enchant, or null.
static func item_in(d: Variant) -> Item:
	if not d is Dictionary or not _is_path(d.get("item")) or not ResourceLoader.exists(d.item):
		push_warning("Save: an item (%s) is gone; it is left out" % str(d))
		return null
	var it = load(d.item)
	if not it is Item:
		push_warning("Save: %s is not an item; it is left out" % d.item)
		return null
	var rank := maxi(int(d.get("rank", it.rank)), 1)
	var enchant := maxi(int(d.get("enchant", it.enchant)), 0)
	if rank != it.rank or enchant != it.enchant:
		it = it.duplicate()
		it.rank = rank
		it.enchant = enchant
	return it


# The file an item is from: its own, or (a copy has none) the one file of that name in Items/.
static func id(it: Item) -> String:
	if it.resource_path:
		return it.resource_path
	if _ids.is_empty():
		for f in DirAccess.get_files_at(ITEMS):
			f = f.trim_suffix(".remap")
			if f.ends_with(".tres"):
				var base = load(ITEMS + f)
				if base is Item and not _ids.has(base.name):
					_ids[base.name] = ITEMS + f
	return _ids.get(it.name, "")


# Writes the save, through a temp file so a crash mid-write leaves the last one. Nothing is saved before a
# hero has been picked (a scene played straight from the editor must not blank the player's save).
static func save() -> bool:
	if not Game.hero:
		return false
	var tmp := PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if not f:
		push_warning("Save: can't write %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(pack(), "\t"))
	f.close()
	var dir := ProjectSettings.globalize_path(tmp)
	return DirAccess.rename_absolute(dir, ProjectSettings.globalize_path(PATH)) == OK


# Reads the save into Game. True if there was one to read; a bad or other-versioned file is moved aside
# (PATH + ".bad") and counts as none.
static func load_game() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var text := FileAccess.get_file_as_string(PATH)
	var d = JSON.parse_string(text)
	var v = d.get("version") if d is Dictionary else null
	if not (v is float or v is int) or int(v) != VERSION:
		push_warning("Save: %s is not a version %d save; ignored, kept as .bad" % [PATH, VERSION])
		DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(PATH + ".bad"))
		return false
	unpack(d)
	return true


# As the game starts: the save, once.
static func load_once() -> void:
	if not loaded:
		loaded = true
		load_game()


# New game: the save file (and a set-aside .bad) gone and everything Game holds back to its start.
static func erase() -> void:
	for p in [PATH, PATH + ".bad", PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	Game.reset()
