extends Test

# Gamut's Tower (GamutsTower): a round hall of stone you walk, a floor for each area difficulty -
# Gentle, Standard, Harsh, bottom up - with a staircase up and one down across a ring of portals. The
# Infernal Meadows and the Astral Nexus open, the rest sealed. Stepping onto an open portal opens its menu: how it's won,
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
	var d: Dungeon = t.dungeon_at(Vector2i(3, 0))
	ok(t.menu.find_child("Enemies", true, false).text == "\n".join(d.enemy_lines()) and not d.enemy_lines().is_empty(), "its enemies: %s" % t.menu.find_child("Enemies", true, false).text)
	ok(t.menu.find_child("Rewards", true, false).text == ", ".join(d.rewards_at(t.difficulty()).map(func(it: Item): return it.name)), "what winning brings on this floor")
	t.close_menu()
	ok(t.menu == null and t.cell == Vector2i(2, 0), "step back: off the portal")
	t.step(Vector2i.RIGHT)
	(t.menu.find_child("Enter", true, false) as Button).pressed.emit()
	ok(t.entered.name == "Infernal Meadows" and Game.difficulty == 1.0 and Game.dungeon == t.entered, "Enter: through, at Standard")
	Game.difficulty = 0.0
	Game.dungeon = null
	t.free()


# The Astral Nexus (AstralNexus.gd) on the second portal: 2 to 3 full generators (ranked by difficulty) wired into one circuit
# of startiles and starpanes (all in bounds, every lattice cell joined side-on to a generator), the same
# for a seed; stone floor and void round it; difficulty-scaled hostile starmen (more, and rarely a neutral princess, in a rare nest), every one on lattice the party's
# landing reaches; the void costs a step 99; and its reward, the Power Star.
func test_nexus() -> void:
	var t := tower()
	var d: Dungeon = t.dungeon_at(t.PORTALS[1])
	ok(d != null and d.name == "Astral Nexus" and d.rewards_at(0.5)[0].name == "Power Star", "the second portal: the Astral Nexus, rewarding a Power Star")
	t.place(t.PORTALS[1] - Vector2i(1, 1))
	t.step(Vector2i.DOWN)
	t.step(Vector2i.RIGHT)
	ok(t.menu != null and t.menu.find_child("Title", true, false).text.begins_with("Astral Nexus"), "stepping onto it opens its menu")
	t.free()
	Game.starter = {faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"}
	var n: Node = load("res://Scenes/astral_nexus.tscn").instantiate()
	n.get_node("Battle/Nexus").seed = 3
	n.get_node("Battle/Nexus").rare = 0.0
	n.get_node("Camera").free()  # it would look for a HUD, and find one left by another test
	tree.root.add_child(n)
	await tree.process_frame
	var nb: Battle = n.get_node("Battle")
	var nx: AstralNexus = nb.get_node("Nexus")
	ok(nx.starmen.size() >= 3 and nx.starmen.size() <= 5 and nx.princess == null and nx.starmen.all(func(u: Unit): return not Faction.friends(u.faction, lancin)), "3 to 5 hostile starmen at difficulty 1 (%d)" % nx.starmen.size())
	ok(nx.generators.size() >= 2 and nx.generators.size() <= 3 and nx.generators.all(func(c: Vector2i): return nb.charge[c] == Battle.STAR_CAPACITY * nx.gen_rank / 5 and nb.top_layer(c).terrain.name == "Starpower Generator"), "2 to 3 full generators (%d)" % nx.generators.size())
	ok(nx.width == 33 and nx.height == 21 and nx.gen_rank == 4 and nx.pane_rank == 2 and nx.bridges.size() % 2 == 0 and nx.bridges.all(func(c: Vector2i): return nb.top_layer(c).terrain.name == "Startile"), "difficulty 1: a 33 x 21 map, rank 4 generators, rank 2 starpanes, bridges of startiles only (%d tiles)" % nx.bridges.size())
	var lattice: Array[Vector2i] = nx.generators + nx.startiles + nx.panes
	ok(lattice.all(func(c: Vector2i): return c.x >= 0 and c.y >= 0 and c.x < nx.width and c.y < nx.height and nb.on_lattice(c)), "the circuit in bounds, all lattice")
	ok(lattice.all(func(c: Vector2i): return nb.star_source(c) != null and not nb.circuit_ends(c).is_empty() or c in nx.generators), "one live circuit: every tile joined to a generator")
	ok(nx.dust.size() > 5 and (nx.startiles + nx.dust).all(func(c: Vector2i): return nb.signal_at(c) >= 0 and nb.top_layer(c).terrain.name in ["Startile", "Stardust"]), "star flooring (%d startiles, %d Stardust) only where signal reaches" % [nx.startiles.size(), nx.dust.size()])
	ok(nx.generators.all(func(g: Vector2i): return nb.signal_at(g) == nx.gen_rank and nb.top_layer(g + Vector2i(1, 1)).terrain.name == "Startile"), "rank 4 generators, full: 4 tiles of signal, on a platform")
	ok(nx.floor_cells.size() > 20 and nx.voids.size() > nx.width * nx.height / 2 and nx.floor_cells.all(func(c: Vector2i): return not nb.on_lattice(c)), "stone floor and void off it")
	var reach := {nx.start: true}
	var queue: Array[Vector2i] = [nx.start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if at + dir not in reach and nb.on_map(at + dir) and nb.terrain(at + dir).name != "Astral Void":
				reach[at + dir] = true
				queue.append(at + dir)
	ok(nx.starmen.all(func(u: Unit): return u.cell in reach) and nx.generators.all(func(c: Vector2i): return c in reach), "the party's landing reaches every starman and generator over the lattice")
	ok(nb.step(nb.player, nx.start, nx.voids[0]) >= 99.0 and nb.star_source(nx.generators[0]) != null, "a step into the void costs 99; the lattice reaches its source")
	var again := AstralNexus.new()
	again.seed = 3
	again.map = TileMapLayer.new()
	again.battle = Battle.new()
	again.rng.seed = 3
	again._lay()
	var rich := AstralNexus.new()  # the scaling: difficulty 1.5 against 0.5
	rich.map = TileMapLayer.new()
	rich.battle = Battle.new()
	rich.battle.difficulty = 1.5
	rich.rng.seed = 3
	rich._lay()
	var poor := AstralNexus.new()
	poor.map = TileMapLayer.new()
	poor.battle = Battle.new()
	poor.battle.difficulty = 0.5
	poor.rng.seed = 3
	poor._lay()
	ok(rich.width > poor.width and rich.gen_rank == 5 and poor.gen_rank == 3 and rich.pane_rank == 3 and poor.pane_rank == 1, "difficulty scales the map (%d vs %d) and the ranks" % [rich.width, poor.width])
	for x in [rich, poor]:
		x.map.free()
		x.battle.free()
		x.free()
	ok(again.generators == nx.generators and again.panes == nx.panes, "the same seed, the same circuit")
	again.map.free()
	again.battle.free()
	again.free()
	n.free()
	var rare: Node = load("res://Scenes/astral_nexus.tscn").instantiate()  # a rare nest: the neutral princess and a larger horde
	rare.get_node("Battle/Nexus").seed = 3
	rare.get_node("Battle/Nexus").rare = 1.0
	rare.get_node("Camera").free()
	tree.root.add_child(rare)
	await tree.process_frame
	var rx: AstralNexus = rare.get_node("Battle/Nexus")
	ok(rx.princess != null and rx.princess.faction.neutral, "a rare nest: a neutral Astral Princess")
	ok(rx.starmen.size() >= 5 and not Faction.friends(rx.princess.faction, rx.starmen[0].faction), "...among a larger horde (%d), not their friend" % rx.starmen.size())
	rare.free()


# The Power Star: a powered wearer's overflowing Power fills it at rank x 15%, to their max Power, and
# using it gives the lot back as Power; nobody else's overflow counts.
func test_power_star() -> void:
	stage(lancin, {v(1): Vector2i(2, 3)})
	var star: Item = load("res://Items/power_star.tres")
	v(1).max_energy = 20
	v(1).energy = 10
	v(1).equip(star)
	v(1).grant_energy(40)  # 10 fit, 30 overflow: a plain unit's is lost
	ok(v(1).trinket.held == 0, "nobody but a powered wearer fills it")
	v(1).afflict(effect("powered", 1.0), 99)
	v(1).energy = 10
	v(1).grant_energy(10 + 100)  # 100 over
	ok(v(1).trinket.held >= 14 and v(1).trinket.held <= 16 and star.held == 0, "15%% of the overflow at rank 1 (%d of 100), the shared item untouched" % v(1).trinket.held)
	v(1).grant_energy(1000)
	ok(v(1).trinket.held == 20, "up to its max Power (%d)" % v(1).trinket.held)
	v(1).energy = 0
	ok(b.use_item(v(1), v(1).trinket) and v(1).energy == 20 and v(1).trinket.held == 0, "used: all of it back as Power, then spent")
	ok(not b.use_item(v(1), v(1).trinket), "spent, there's nothing to use")
	v(1).trinket = star.duplicate()
	v(1).trinket.rank = 2
	v(1).energy = 20
	v(1).grant_energy(20)
	ok(v(1).trinket.held >= 5 and v(1).trinket.held <= 7, "rank 2: 30%% of the overflow (%d of 20)" % v(1).trinket.held)
