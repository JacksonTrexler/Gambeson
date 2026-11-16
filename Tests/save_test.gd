extends Test

# Saving (Save): the starter, level, outfit, hearts and stash to user://save.json and back; a bad or
# other-versioned file ignored (and set aside); and the test runner's files, never the player's own.


func _game() -> void:
	var gambeson: Item = load("res://Items/gambeson.tres")
	var boots: Item = load("res://Items/hobnail_boots.tres")
	var worn := gambeson.duplicate()  # what Pray makes of it: a copy with no file of its own
	worn.enchant = 1
	var ranked: Item = load("res://Items/broadsword.tres").duplicate()
	ranked.rank = 3
	Game.hero = {faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Wren"}
	Game.outfit = {armor = worn, weapon = load("res://Items/dagger.tres")}
	Game.stash = [boots, boots, ranked]
	Game.level = 4
	Game.xp = 7
	Game.hearts = 2


func test_round_trip() -> void:
	_game()
	ok(Save.save() and FileAccess.file_exists(Save.PATH), "written")
	var worn: Item = Game.outfit.armor
	var boots: Item = Game.stash[0]
	Game.hero = {}
	Game.outfit = {}
	Game.stash = []
	Game.level = 1
	Game.xp = 0
	Game.hearts = 0
	ok(Save.load_game(), "read")
	ok(Game.hero.name == "Wren" and Game.hero.faction == lancin and Game.hero.role.name == "Adventurer", "the hero, by its side and class files")
	ok(Game.level == 4 and Game.xp == 7 and Game.hearts == 2, "level, XP and hearts")
	ok(Game.outfit.size() == 2 and Game.outfit.armor.name == worn.name and Game.outfit.armor.enchant == 1, "the outfit, an item copy's enchant kept")
	ok(Game.outfit.weapon == load("res://Items/dagger.tres"), "an unchanged item is its file's own item")
	ok(Game.stash.size() == 3 and Game.stash[0] == boots and Game.stash[1] == boots, "the stash in order, plain items the file's own")
	ok(Game.stash[2].name == "Broadsword" and Game.stash[2].rank == 3, "a ranked copy keeps its rank")
	ok(Game.stash[0].skills == boots.skills and not Game.stash[0].skills.is_empty(), "an item's lent skills come back with it")
	ok(Save.pack().has("equipped"), "the equipped-set hook is in the file")


func test_never_blank() -> void:
	Game.stash = [load("res://Items/dagger.tres")]
	ok(not Save.save() and not FileAccess.file_exists(Save.PATH), "no hero picked (a scene played from the editor): nothing is written over a save")
	_game()
	Save.save()
	Game.stash.append(Item.new())  # no file, no name to find one by
	var out := Save.pack()
	ok(out.stash.size() == 3, "an item with nothing to come back from is left out")


func test_bad_file() -> void:
	ok(not Save.load_game(), "no file: nothing to read")
	for text in ["{not json", "[1, 2]", "{\"version\": 99, \"level\": 9}", "{\"level\": 9}", "{\"version\": \"1\"}"]:
		var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		Game.level = 1
		ok(not Save.load_game() and Game.level == 1, "ignored: %s" % text)
		ok(not FileAccess.file_exists(Save.PATH) and FileAccess.file_exists(Save.PATH + ".bad"), "and set aside, not overwritten: %s" % text)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.PATH + ".bad"))
	# a good file naming things that are gone: those are dropped, the rest comes back
	Save.unpack({version = 1, level = 3, hero = {faction = "res://Factions/gone.tres", role = "res://Roles/adventurer.tres", name = "x"},
			stash = [{item = "res://Items/gone.tres", rank = 1, enchant = 0}, {item = "res://Items/dagger.tres", rank = 1, enchant = 0}, 7], outfit = {trinket = {item = "res://Items/dagger.tres"}}})
	ok(Game.level == 3 and Game.hero.is_empty() and Game.stash.size() == 1 and Game.outfit.is_empty(), "missing files and items out of place are left out")


func test_test_paths() -> void:
	ok("save_test_%d" % OS.get_process_id() in Save.PATH and Save.PATH != "user://save.json", "the save is this process's own file")
	ok("keybinds_test_%d" % OS.get_process_id() in KeyBinds.SAVE and Prefs.SAVE != "user://settings.cfg", "and so are the key binds and settings")


func _entry() -> Control:
	var e: Control = load("res://Scenes/entry.tscn").instantiate()
	e.next_scene = ""
	tree.root.add_child(e)
	return e


func test_entry() -> void:
	var e := _entry()
	ok(not e.get_node("%Continue").visible and not FileAccess.file_exists(Save.PATH), "a first run offers no Continue")
	e._play()
	ok(FileAccess.file_exists(Save.PATH) and Game.hero.name == "Shrike" and not Game.hero.has("prep"), "Play saves the new starter")
	e.free()
	Game.level = 5
	Save.save()
	Game.hero = {}
	Game.starter = {}
	Game.level = 1
	Save.loaded = false
	e = _entry()
	var cont: Button = e.get_node("%Continue")
	ok(cont.visible and "Shrike" in cont.text and "level 5" in cont.text, "the next run offers it: %s" % cont.text)
	cont.pressed.emit()
	ok(Game.starter.name == "Shrike" and Game.starter.prep and Game.level == 5 and Game.starter.role == Game.hero.role, "Continue starts that starter as it was, at its level")
	e.free()


func test_new_game() -> void:
	_game()
	Save.save()
	Game.dungeon = Dungeon.new()
	var e := _entry()
	var wipe: Button = e.get_node("%Delete")
	ok(wipe.visible, "a save to delete: the button shows")
	wipe.pressed.emit()
	ok(FileAccess.file_exists(Save.PATH) and not Game.hero.is_empty(), "the first press only asks")
	wipe.pressed.emit()
	ok(not FileAccess.file_exists(Save.PATH) and Game.hero.is_empty() and Game.stash.is_empty() and Game.outfit.is_empty(), "the second clears the file and Game")
	ok(Game.level == 1 and Game.xp == 0 and Game.hearts == 0 and Game.dungeon == null, "level, xp, hearts, dungeon back to the start")
	ok(not wipe.visible and not e.get_node("%Continue").visible, "nothing left to continue or delete")
	e.free()


func test_tower_quit_saves() -> void:
	_game()
	var t := GamutsTower.new()
	t._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	t.free()
	Game.xp = 0
	ok(Save.load_game() and Game.xp == 7 and Game.level == 4, "closing the window in the tower writes the save")
