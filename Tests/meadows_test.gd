extends Test

# Infernal Meadows (Scenes/meadows.tscn, Meadows.gd): a plane generated around the party; the
# commanders and soldiers of both sides on the player's; demons that stay in the fight with nobody
# standing (Battle.lasting), spawning in formations (Formation) beyond the party's perception
# (Battle.sight: wisdom total; appearances within half; fog halves it), up to the party's count x the
# area's difficulty; the escape portal forming where the 30th fell and opening after 3 x difficulty
# turns; stepping onto it wins (Battle.escape()). Gamut's Tower picks the difficulty (Game.difficulty).
# The battle camera keeps to the player's unit, Home to the selected one (BattleCamera).

var demons: Faction = load("res://Factions/demons.tres")


# A fresh Meadows with a Fighter starter, its own seed so the plane is the same each run.
func meadows(difficulty := 0.0) -> Node:
	Game.starter = {faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"}
	Game.difficulty = difficulty
	var m: Node = load("res://Scenes/meadows.tscn").instantiate()
	m.get_node("Battle/Meadows").seed = 7
	tree.root.add_child(m)
	await tree.process_frame
	return m


func test_plane() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var md: Meadows = mb.get_node("Meadows")
	ok(mb.on_map(Vector2i.ZERO) and mb.on_map(Vector2i(12, 12)) and not mb.on_map(Vector2i(60, 60)), "generated around the party, not beyond")
	ok(md._tally.get_rect().end.x <= 240.0 - 8.0, "the tally ends left of the HUD's turn clock (top middle, a two-digit number is ~12 wide)")
	ok(mb.terrain(Vector2i.ZERO).name == "Grass" and mb.depth(Vector2i(1, 0)) == 0, "the landing kept dry")
	var kinds := {}
	for x in range(-150, 150, 3):
		for y in range(-150, 150, 3):
			kinds[md.ground_at(Vector2i(x, y))] = true
	ok(kinds.has(&"pond") and kinds.has(&"shallows") and kinds.has(&"stream") and kinds.has(&"brush") and kinds.has(&"grass"), "grass, brush, ponds, shallows and streams: %s" % [kinds.keys()])
	md.ensure_around(Vector2i(60, 60))
	ok(mb.on_map(Vector2i(60, 60)), "more of it as the party goes")
	ok(mb.members(lancin).size() == 7 and demons in mb.order, "the starter, both commanders and four soldiers on its side; the demons in the order with nobody yet")
	m.free()


# The plane streams: a chunk is the same whichever order it's reached in (its seed's noise alone), and
# what loops over "the tiles near here" walks only the box around it (Battle.cells_near()), so the work
# stays the area's as the plane grows - no whole-map get_used_cells() loop in Battle or the AI.
func test_streaming() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var md: Meadows = mb.get_node("Meadows")
	md.ensure_around(Vector2i(60, 60))
	var first := {}
	for c in mb.cells_near(Vector2i(60, 60), 16):
		first[c] = mb.map.get_cell_atlas_coords(c)
	m.free()
	m = await meadows()
	mb = m.get_node("Battle")
	md = mb.get_node("Meadows")
	md.ensure_around(Vector2i(-60, 30))
	md.ensure_around(Vector2i(60, 60))
	ok(first.size() > 600 and first.keys().all(func(c: Vector2i): return mb.map.get_cell_atlas_coords(c) == first[c]), "the same seed, reached another way: the same ground")
	var near := mb.cells_near(Vector2i(60, 60), 3)
	ok(near.size() == mb.map.get_used_cells().filter(func(c: Vector2i): return Vector2(c).distance_to(Vector2(60, 60)) <= 3.5).size(), "cells_near: every tile within reach, from its box")
	var was := mb.on_map(Vector2i(90, 90))
	mb.move(mb.player, Vector2i(83, 83))
	mb.driven.emit(mb.player, null, [] as Array[StringName], 3, false)
	ok(not was and mb.on_map(Vector2i(90, 90)), "pushed to its edge: the plane grows around it")
	for f in ["res://Scripts/Battle.gd", "res://Scripts/AI.gd", "res://Scripts/HUD.gd", "res://Scripts/Overlay.gd"]:
		var code := FileAccess.get_file_as_string(f).split("\n")
		ok(not Array(code).any(func(l: String): return "get_used_cells()" in l and not l.strip_edges().begins_with("#")), "%s loops over no whole map" % f.get_file())
	m.free()


func test_sight() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var me := mb.player
	me.wisdom = 12
	var s: Unit = mb.summon(load("res://Scenes/siren.tscn"), demons, me.cell + Vector2i(14, 0))
	ok(mb.read(me, s).net <= -4 and mb.read(me, s).cell == null, "beyond its wisdom total (12): not perceived at all")
	mb.move(s, me.cell + Vector2i(9, 0))
	var r := mb.read(me, s)
	ok(r.cell == s.cell and r.vibe == "" and r.name == "", "within it but past half: where it is, not how it looks")
	mb.move(s, me.cell + Vector2i(4, 0))
	ok(mb.read(me, s).net > -2, "within half: as close as anything")
	mb.conditions.append(&"fog")
	mb.move(s, me.cell + Vector2i(7, 0))
	ok(mb.perception_range(me) == 6.0 and mb.read(me, s).net <= -4, "fog halves it")
	m.free()


func test_spawning() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var md: Meadows = mb.get_node("Meadows")
	ok(md.cap() == 7, "the cap: the party's 7 x difficulty 1")
	var by_water: Formation = load("res://Formations/siren_by_water.tres")
	var got := md.spawn(by_water)
	ok(got.size() == 1 and got[0].faction == demons, "a Siren by the water spawns")
	ok(md.party().all(func(u: Unit): return Vector2(u.cell).distance_to(Vector2(got[0].cell)) > mb.perception_range(u)), "beyond the whole party's perception")
	ok(md._beside(got[0].cell, &"water"), "beside water")
	var group := md.spawn(load("res://Formations/undine_and_sirens.tres"))
	ok(group.size() == 3 and group[0].tags.has(&"undine"), "an Undine and its two Sirens")
	ok(load("res://Formations/undine_and_sirens.tres").count(1.5) == 5 and load("res://Formations/sirens_by_water.tres").count(0.5) == 1, "harder areas bring more, easier fewer")
	ok(mb.last_seen(demons).size() == 7 and mb.last_seen(demons).keys().all(func(u: Unit): return u.faction == lancin), "they arrive knowing where the living are")
	var siren: PackedScene = load("res://Scenes/siren.tscn")
	var asked := mb.player.cell + Vector2i(3, 0)
	var plain := mb.summon(siren, demons, asked)
	ok(plain.cell == asked and mb.read(mb.player, plain).located(), "summon(): where it's asked, in plain view")
	var hid := mb.summon(siren, demons, asked, lancin)
	ok(md.party().all(func(o: Unit): return not mb.read(o, hid).located()), "summoned unseen by a side: none of it makes it out (Battle.read())")
	ok(hid.cell.distance_to(asked) < 30.0, "the nearest such tile, not just anywhere: %s" % [hid.cell])
	mb.conditions.append(&"fog")
	var nearer := mb.summon(siren, demons, asked, lancin)
	ok(nearer.cell.distance_to(asked) < hid.cell.distance_to(asked), "fog halves sight: it comes nearer")
	m.free()


func test_cap_counts_the_living() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var md: Meadows = mb.get_node("Meadows")
	for i in 3:
		md.spawn(load("res://Formations/undine_and_sirens.tres"))
	ok(md.alive_demons() == 9 and md.cap() == 7, "9 demons against the party's 7")
	for u in md.party().filter(func(x: Unit): return x != mb.player).slice(0, 4):
		u.hearts = 0
		u.damage(999)
	ok(md.party().size() == 3 and md.cap() == 3, "4 of the party fall: the cap counts the living, 3")
	md._on_turn(lancin, demons)
	ok(md.alive_demons() == 9, "the demons over it stay; none join until they're under it")
	m.free()


func test_portal() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var md: Meadows = mb.get_node("Meadows")
	md.spawns = false
	var last: Unit
	for i in md.kills_needed:
		last = mb.summon(load("res://Scenes/siren.tscn"), demons, mb.player.cell + Vector2i(5, 0))
		last.died.connect(md._on_kill)
		var at := last.cell
		last.damage(999)
		if i == md.kills_needed - 1:
			ok(md.portal == at, "the portal forms where the 30th fell")
	ok(md.kills == 30 and md.portal_turns == 3 and not md.opened and mb.phase != Battle.Phase.OVER, "it opens in 3 x difficulty turns; the fight goes on with no demons standing")
	var exit: Skill = load("res://Skills/emergency_exit.tres")
	mb.player.learned.append(slot(exit, 2))
	load("res://Behaviours/emergency_exit.gd").open(mb, mb.player, exit, 2, 2)
	ok(md.portal_turns == 1 and mb.pockets.is_empty(), "Emergency Exit II: the forming portal 2 turns sooner, no pocket")
	md._on_turn(demons, mb.player.faction)
	ok(md.opened, "open a turn later")
	mb.move(mb.player, md.portal + Vector2i(1, 0))
	mb.traveled.emit(mb.player, mb.player.cell, [mb.player.cell, md.portal] as Array[Vector2i])
	ok(mb.phase == Battle.Phase.OVER and mb.won(mb.player.faction), "stepping onto it: the party wins at once")
	m.free()


func test_tower_difficulty() -> void:
	var m: Node = await meadows(1.5)
	var mb: Battle = m.get_node("Battle")
	ok(mb.difficulty == 1.5 and Game.difficulty == 0.0 and mb.get_node("Meadows").cap() == 11, "Gamut's Tower's pick: harsh (1.5), the cap 7 x 1.5 rounded up")
	ok(Difficulty.area(1.5) == &"difficult" and Difficulty.area(0.5) == &"approachable", "area difficulty on the check ladder")
	m.free()
	Game.dungeon = load("res://Dungeons/infernal_meadows.tres")
	m = await meadows(1.0)
	mb = m.get_node("Battle")
	ok(mb.rewards.map(func(it: Item): return it.name) == ["Health Potion", "Mana Potion", "Heart"] and Game.dungeon == null, "entered from the tower: its rewards at that floor")
	m.free()


func test_camera() -> void:
	var m: Node = await meadows()
	var mb: Battle = m.get_node("Battle")
	var cam: BattleCamera = m.get_node("Camera")
	var fake := {selected = null}
	ok(cam.target() == mb.player, "on the player's unit")
	var other: Unit = mb.members(lancin).filter(func(u: Unit): return u != mb.player)[0]
	cam.focus = other
	ok(cam.target() == other, "Home's pick: kept to")
	cam.home()
	ok(cam.focus == null and cam.target() == mb.player, "Home again: back to the player's unit")
	cam.hud = Eyes.new(mb)
	mb.move(other, mb.player.cell + Vector2i(8, 0))
	mb.traveled.emit(other, other.cell, [other.cell] as Array[Vector2i])
	ok(cam.target() == other, "follows the active unit once it's far off centre")
	var lurker: Unit = mb.summon(load("res://Scenes/siren.tscn"), demons, mb.player.cell + Vector2i(30, 0))
	mb.traveled.emit(lurker, lurker.cell, [lurker.cell] as Array[Vector2i])
	ok(cam.target() == other, "not to a demon acting out of sight")
	var at := cam.global_position
	cam.pan(Vector2(40, 0))
	ok(cam.target() == null and cam.global_position == at + Vector2(40, 0), "panned: it holds there")
	ok(InputMap.has_action(&"camera_left") and &"camera_down" in KeyBinds.actions() and KeyBinds.key_of(&"camera_up") == "Up", "the arrow keys, rebindable")
	var view := Vector2(480, 270)
	var side: Array[Rect2] = [Rect2(0, 0, 77, 270)]
	ok(BattleCamera.edge_dir(Vector2(240, 1), view, side) == Vector2(0, -1) and BattleCamera.edge_dir(Vector2(300, 269), view, side) == Vector2(0, 1), "the mouse at the top or bottom edge pans that way")
	ok(BattleCamera.edge_dir(Vector2(479, 100), view, side).x == 1.0 and BattleCamera.edge_dir(Vector2(240, 135), view, side) == Vector2.ZERO, "the right edge pans; the middle doesn't")
	ok(BattleCamera.edge_dir(Vector2(1, 100), view, side) == Vector2.ZERO and BattleCamera.edge_dir(Vector2(1, 1), view, side) == Vector2.ZERO, "over a HUD panel at the edge: no pan")
	mb.turn_changed.emit(lancin, demons)
	ok(not cam.panned and cam.target() == mb.player, "a new turn: back to the player's unit")
	cam.hud.free()
	m.free()


# Stands in for the HUD: the player's unit's eyes.
class Eyes:
	extends Node
	var selected: Unit = null
	var b: Battle
	func _init(battle: Battle) -> void:
		b = battle
	func view(u: Unit) -> Read:
		return b.read(b.player, u)
