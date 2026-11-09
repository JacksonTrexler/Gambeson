extends Test

# Gamut's Tower (GamutsTower): a round hall of stone you walk, a floor for each area difficulty -
# Gentle, Standard, Harsh, bottom up - with a staircase up and one down across a ring of portals. The
# Infernal Meadows open, the rest sealed. Stepping onto an open portal opens its menu: how it's won,
# its enemies, and what winning it brings at that floor (Dungeon).


func tower() -> GamutsTower:
	GamutsTower.level = 0
	Game.starter = {faction = lancin, role = load("res://Roles/wizard.tres"), name = "Ash"}
	var t: GamutsTower = load("res://Scenes/gamuts_tower.tscn").instantiate()
	t.travels = false
	tree.root.add_child(t)
	t.pace = 0.0
	return t


func test_hall() -> void:
	var t := tower()
	ok(t.cell == Vector2i.ZERO and t.walker.texture == load("res://Units/RedMage.png"), "the starter in the middle of the hall, as itself")
	ok(t.difficulty() == 0.5 and t.map.get_cell_source_id(Vector2i(5, 0)) == 0 and t.map.get_cell_alternative_tile(Vector2i(0, 6)) == 1, "the ground floor, Gentle: stone, walled round")
	ok(t.PORTALS.size() == 6 and t.dungeon_at(Vector2i(3, 0)).name == "Infernal Meadows" and t.dungeon_at(Vector2i(-3, 0)) == null, "a ring of six portals between the stairs: the Meadows open, the rest sealed")
	ok(t.step(Vector2i.LEFT) and t.cell == Vector2i(-1, 0) and not t.step(Vector2i(-9, 0)), "a tile at a time, on the floor only")
	t.place(Vector2i(-2, 0))
	t.step(Vector2i.LEFT)
	ok(t.menu == null and t._note.text.begins_with("A sealed portal"), "a sealed portal: nothing answers")
	t.free()


func test_stairs() -> void:
	var t := tower()
	ok(t.walk_to(t.UP) and t.level == 1 and t.difficulty() == 1.0 and t.cell == t.DOWN + Vector2i(0, -1), "up the stairs: Standard, out of the stairs down")
	t.place(t.UP + Vector2i(0, 1))
	t.step(Vector2i.UP)
	ok(t.level == 2 and t.difficulty() == 1.5, "and up again: Harsh")
	t.place(t.UP + Vector2i(0, 1))
	t.step(Vector2i.UP)
	ok(t.level == 2 and t._note.text.ends_with("the way is shut."), "nothing above the top floor yet")
	t.place(t.DOWN + Vector2i(0, -1))
	t.step(Vector2i.DOWN)
	ok(t.level == 1 and t.cell == t.UP + Vector2i(0, 1), "down: out of the stairs up")
	t.free()


func test_portal_menu() -> void:
	var t := tower()
	GamutsTower.level = 1
	t._show_floor()
	t.place(Vector2i(2, 0))
	t.step(Vector2i.RIGHT)
	ok(t.menu != null and t.menu.find_child("Title", true, false).text == "Infernal Meadows · Standard (1)", "stepping onto it: its menu, at the floor's difficulty")
	ok(t.menu.find_child("Enemies", true, false).text.begins_with("Siren · Briny, hungry · 16 HP: ") and "Undine · Murky · 18 HP" in t.menu.find_child("Enemies", true, false).text,
			"its enemies: %s" % t.menu.find_child("Enemies", true, false).text)
	ok(t.menu.find_child("Rewards", true, false).text == "Health Potion, Mana Potion, Heart", "what winning brings on this floor")
	t.close_menu()
	ok(t.menu == null and t.cell == Vector2i(2, 0), "step back: off the portal")
	t.step(Vector2i.RIGHT)
	(t.menu.find_child("Enter", true, false) as Button).pressed.emit()
	ok(t.entered.name == "Infernal Meadows" and Game.difficulty == 1.0 and Game.dungeon == t.entered, "Enter: through, at Standard")
	Game.difficulty = 0.0
	Game.dungeon = null
	t.free()
