extends Test

# Saving (Save): the starter, level, outfit, hearts and stash to user://save.json and back; a bad or
# other-versioned file ignored (and set aside); and the test runner's files, never the player's own. The roster
# (Unit.to_dict() / from_dict()) and the Party a battle fields from it; a version 1 save migrated.


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
	Game.equipped = [strike, null, load("res://Skills/everyman.tres")]
	Game.lapses = {leaned = ["meander"]}


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
	Game.equipped = []
	Game.lapses = {}
	ok(Save.load_game(), "read")
	ok(Game.lapses == {leaned = ["meander"]}, "what leans comes back (an older save has none: empty)")
	ok(Game.hero.name == "Wren" and Game.hero.faction == lancin and Game.hero.role.name == "Adventurer", "the hero, by its side and class files")
	ok(Game.level == 4 and Game.xp == 7 and Game.hearts == 2, "level, XP and hearts")
	ok(Game.outfit.size() == 2 and Game.outfit.armor.name == worn.name and Game.outfit.armor.enchant == 1, "the outfit, an item copy's enchant kept")
	ok(Game.outfit.weapon == load("res://Items/dagger.tres"), "an unchanged item is its file's own item")
	ok(Game.stash.size() == 3 and Game.stash[0] == boots and Game.stash[1] == boots, "the stash in order, plain items the file's own")
	ok(Game.stash[2].name == "Broadsword" and Game.stash[2].rank == 3, "a ranked copy keeps its rank")
	ok(Game.stash[0].skills == boots.skills and not Game.stash[0].skills.is_empty(), "an item's lent skills come back with it")
	ok(Game.equipped == [strike, null, load("res://Skills/everyman.tres")], "the equipped set, slot by slot (%s)" % [Game.equipped])
	var u := b.starter(Game.hero)
	b.get_node("Units").add_child(u)
	ok(u.get_equipped().slice(0, 4) == ([strike, null, load("res://Skills/everyman.tres"), null] as Array[Skill]), "the starter comes back with it: Working Knowledge and Field Experience left off")


# A roster member as a battle leaves it: level 5, a skill learned and raised, its bar, an item, XP, a lapse.
func _veteran() -> Unit:
	var u := b.from_role(lancin, load("res://Roles/fighter.tres"), "Brann")
	u.level = 5
	u.skill_points = 4
	u.cell = b.free_near(Vector2i(0, 0))
	b.get_node("Units").add_child(u)
	b.move(u, u.cell)
	var s: Skill
	for x: Skill in u.options()[&"class"]:
		if x.fits_bar() and u.unlock(x):
			s = x
			break
	u.raise(s)
	u.weapon = load("res://Items/broadsword.tres")
	u.xp = 9
	u.leaned.assign([s])
	return u


func test_roster() -> void:
	_game()
	var u := _veteran()
	var s: Skill = u.learned[0].skill
	var bar := u.get_equipped()
	Game.roster.assign([{faction = lancin.resource_path, role = Game.hero.role.resource_path, name = "Wren"}, u.to_dict()])
	Game.party.assign([1, 0])
	ok(Save.save(), "written")
	Game.roster = []
	Game.party = []
	ok(Save.load_game() and Game.roster.size() == 2 and Game.party == ([0, 1] as Array[int]), "the roster and the party (leader first) come back")
	var w := b.from_role(lancin, load(Game.roster[1].role), Game.roster[1].name)
	w.from_dict(Game.roster[1])
	b.get_node("Units").add_child(w)
	ok(w.nick == "Brann" and w.level == 5 and w.xp == 9 and w.weapon == u.weapon, "name, level, XP, the item worn")
	ok(w.own_rank(s) == 2 and w.purchases.size() == 2 and w.skill_points == 1 and u.skill_points == 1, "the skill learned at its rank, what was spent, the points left (%d)" % w.skill_points)
	ok(w.get_equipped() == bar, "the bar, slot by slot")
	ok(w.lapses_out() == u.lapses_out() and not w.lapses_out().is_empty(), "and what leans")
	# the battle fields it beside the leader, in its party; what it gains there goes back into the roster
	b.player = b.starter(Game.hero)
	b.get_node("Units").add_child(b.player)
	b.move(b.player, b.free_near(b.player.cell))
	b._field_party()
	var f: Unit = Game.fielded.get(1)
	ok(f and f in b.units.values() and f.faction == b.player.faction and f.own_rank(s) == 2, "the party member stands on the player's side, as saved")
	ok(f in Command.new(b, b.player).party, "in the leader's party from the start")
	f.gain_xp(1)
	b.player.leaned.assign([s])
	Game.lapses = {}
	Game.keep()
	ok(int(Game.roster[1].xp) == 10 and Game.roster[0].name == "Wren", "kept: the roster reads the fielded units back")
	ok(Game.lapses == {leaned = [s.resource_path.get_file().get_basename()]}, "and the leader's lapses_out() into Game.lapses (%s)" % Game.lapses)
	var again := b.starter(Game.hero)
	ok(again.hearts == b.player.hearts and again.hearts > 0, "the leader from its own entry: its hearts not counted twice (%d, %d)" % [again.hearts, b.player.hearts])
	again.free()
	f.gain_xp(1)
	ok(int(Save.pack().roster[1].xp) == 11, "and so does writing the save")


func test_migrate() -> void:
	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({version = 1, level = 3, xp = 4, equipped = ["strike"], lapses = {leaned = ["meander"]},
			hero = {faction = lancin.resource_path, role = "res://Roles/adventurer.tres", name = "Old"}}))
	f.close()
	ok(Save.load_game() and Game.level == 3 and Game.lapses == {leaned = ["meander"]}, "a version 1 save loads")
	ok(Game.roster.size() == 1 and Game.roster[0].name == "Old" and int(Game.roster[0].level) == 3 and Game.roster[0].bar == ["strike"], "its hero is the roster's one entry")
	ok(Game.party == ([0] as Array[int]) and Save.pack().version == 2, "the party is the leader alone, and it saves as version 2")


# A skill renamed since a save was written (Skill.RENAMED): its old id still finds the file, on the bar and in the roster.
func test_renamed_skill() -> void:
	var harmony: Skill = load("res://Skills/harmony.tres")
	ok(Skill.by_id("symphony_bard") == harmony and Skill.by_id("harmony") == harmony and Skill.by_id("no_such_skill") == null and Skill.by_id("") == null, "a renamed id and its new one find the same skill; none is null")
	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({version = 1, level = 1, xp = 0, equipped = ["symphony_bard", "strike"],
			hero = {faction = lancin.resource_path, role = "res://Roles/adventurer.tres", name = "Old"}}))
	f.close()
	ok(Save.load_game() and Game.equipped == [harmony, load("res://Skills/strike.tres")], "a save from before the rename keeps it on the bar (%s)" % [Game.equipped])


func test_party_size() -> void:
	Game.hero = {faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Wren"}
	# [level, base charisma, size]: the charisma mod if positive (at least +0) plus level / 4 (at least 1); 1 is solo (?216)
	for row in [[1, 10, 1], [1, 16, 4], [3, 8, 1], [4, 12, 2], [8, 10, 2], [12, 10, 3], [12, 6, 3], [7, 11, 1], [20, 18, 9]]:
		ok(Game.party_size(row[0], row[1]) == row[2], "level %d, charisma %d: %d (%d)" % [row[0], row[1], row[2], Game.party_size(row[0], row[1])])
	Game.roster.assign(range(6).map(func(i): return {name = str(i)}))
	Game.party.assign([4, 9, 2, 1, 4])
	Game.level = 1
	ok(Game.party_now() == ([0, 4, 2, 1] as Array[int]), "the party: the leader first, real entries once each, cut to its size (Adventurer, level 1, charisma 16: 4)")
	Game.hero = {faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brann"}
	ok(Game.leader_party_size() == 1 and Game.party_now() == ([0] as Array[int]), "a leader with charisma 9 at level 1 goes solo: the party is the leader alone, though others are picked")
	var e := _entry()
	ok(e.party.text == "Party: solo", "Entry says so: %s" % e.party.text)
	e.free()


# Every item the player owns, by name: the stash and what each roster entry wears (the leader's entry counted once).
func _owned() -> Array:
	var out := Game.stash.map(func(it: Item): return it.name)
	for d in Game.roster:
		for slot in d.get("outfit", {}):
			out.append(Save.item_in(d.outfit[slot]).name)
	out.sort()
	return out


# The Party panel's Outfit buttons: the stash screen on any roster member, saved through its entry (Game.roster), the leader's
# also its own fields; what's worn leaves and returns to the stash with nothing lost or duplicated.
func test_member_outfit() -> void:
	var e := _entry()
	e._play()  # an Adventurer leader and one recruit of each other class
	var sword: Item = load("res://Items/rapier.tres")
	var heart: Item = load("res://Items/heart.tres")
	Game.stash.append_array([sword, heart])
	var owned := _owned()
	var p: PartyPanel = e.open_party()
	(p.find_child("Outfit1", true, false) as Button).pressed.emit()
	var m := p.unit
	ok(p.sheet.visible and p.member == 1 and m.nick == Game.roster[1].name and m.is_inside_tree(), "Outfit opens the stash screen on that member, made from its roster entry")
	var was := m.weapon
	var other := str(Game.roster[2].get("outfit"))
	p._on_equipped(m, sword)
	ok(m.weapon == sword and sword not in Game.stash and (was == null or was in Game.stash), "it puts on a stash item; what it wore goes back")
	ok(Game.roster[1].outfit.weapon.item == sword.resource_path and _owned() == owned, "kept in its roster entry, nothing lost or doubled (%s)" % [_owned()])
	ok(str(Game.roster[2].get("outfit")) == other and Game.outfit.get("weapon") != sword, "no one else's entry, nor the leader's, moves")
	p.outfit(1)
	ok(p.unit != m and p.unit.weapon == sword, "opened again, it is wearing it: the round trip through Game.roster")
	p._on_unequipped(p.unit, "weapon")
	ok(not Game.roster[1].outfit.has("weapon") and sword in Game.stash and _owned() == owned, "taking it off returns it to the stash")
	p._on_used_up(p.unit, heart)
	ok(Game.roster[1].hearts == 1 and heart not in Game.stash and Game.hearts == 0, "a Heart is a member's own extra life, not the leader's")
	p.outfit(0)
	p._on_equipped(p.unit, sword)
	ok(Game.outfit.weapon == sword and Game.roster[0].outfit.weapon.item == sword.resource_path and sword not in Game.stash, "the leader's goes through Game.outfit and its entry both")
	owned = _owned()
	Save.save()
	var kept := Game.roster.duplicate(true)
	Game.reset()
	ok(Save.load_game() and Game.roster[0].outfit.weapon.item == sword.resource_path and Game.roster[1].hearts == 1 and _owned() == owned, "and it all survives the save")
	e.free()
	ok(kept.size() == Game.roster.size(), "(roster size kept)")


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
