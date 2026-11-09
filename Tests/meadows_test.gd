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
	mb.emergency_exit(mb.player, exit)
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
	m.free()
