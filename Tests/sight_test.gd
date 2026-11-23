extends Test

# Sight in every battle (Battle.sight, on unless a scene turns it off): a unit perceives others within
# its wisdom total in tiles, and makes out how they look within half that - the range shared across its
# side (Battle.in_range()). Each side remembers where it last made out its foes (Battle.sightings) -
# to begin with, where the others drew up in the open - and a unit with none in sight goes looking
# there (AI._hunt()). The museum's other tests turn it off (Test.calm()). Past its side's sight a foe
# can't be picked or struck, and the tiles there are the fog of war (Battle.sight_cells(), Overlay.fog_of_war()).


func test_on_everywhere() -> void:
	for path in ["res://Scenes/museum.tscn", "res://Scenes/meadows.tscn", "res://Scenes/astral_envoy.tscn"]:
		var scene: Node = load(path).instantiate()
		var battle: Battle = scene.get_node("Battle") if scene.has_node("Battle") else scene.find_children("Battle", "Node2D", true, false)[0]
		ok(battle.sight, "%s: sight limited" % path)
		scene.free()


func test_shared() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(7, 2)})
	b.sight = true  # stage() calms, turning it off
	v(1).wisdom = 4
	v(3).wisdom = 4
	ok(b.in_range(v(1), v(3)) == 0 and b.read(v(1), v(3)).cell == null, "beyond its wisdom total (4): not perceived")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(5, 2), v(3): Vector2i(7, 2)})
	b.sight = true  # stage() calms, turning it off
	v(2).wisdom = 4
	ok(b.in_range(v(1), v(3)) == 2 and b.read(v(1), v(3)).net > -2, "an ally within half its own range of it: its whole side makes it out")
	v(2).wisdom = 3
	var r := b.read(v(1), v(3))
	ok(b.in_range(v(1), v(3)) == 1 and r.cell == v(3).cell and r.name == "", "within its range but past half: where it is, not how it looks")
	ok(b.in_range(v(3), v(1)) == 0, "the other side has its own: 6 tiles off at wisdom 4, nothing")
	b.sight = false
	ok(b.in_range(v(3), v(1)) == 2, "sight off: no limit")


func test_start() -> void:
	ok(b.last_seen(lancin).has(v(3)) and b.last_seen(lancin)[v(3)] == Vector2i(8, 2) and b.last_seen(nemes).has(v(1)),
			"each side knows where the others drew up in the open")


func test_hunt() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	b.sight = true  # stage() calms, turning it off
	v(3).wisdom = 3
	b.sightings.clear()
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "nothing in sight and nowhere to look: it stays put")
	b.sighted(nemes, v(1), Vector2i(1, 2))
	AI.act(b, v(3))
	ok(v(3).cell.x < 8, "it heads for where its side last made it out: %s" % v(3).cell)
	stage(nemes, {v(1): Vector2i(1, 6), v(3): Vector2i(5, 2)})
	b.sight = true  # stage() calms, turning it off
	b.sighted(nemes, v(1), Vector2i(4, 2))
	AI.act(b, v(3))
	ok(not b.last_seen(nemes).has(v(1)), "there, and no one to be found: its side forgets it")
	stage(nemes, {v(1): Vector2i(5, 4), v(3): Vector2i(5, 2)})
	b.sight = true  # stage() calms, turning it off
	AI.act(b, v(3))
	ok(b.last_seen(nemes).get(v(1)) == Vector2i(5, 4), "made out again, if only where it is: remembered there")


func test_fog() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): Vector2i(3, 2)})
	b.sight = true  # stage() calms, turning it off
	b.sightings.clear()
	v(1).wisdom = 4
	v(2).wisdom = 2
	v(3).wisdom = 1
	var hp := v(1).hp
	AI.act(b, v(3))
	ok(v(1).hp == hp and b.in_range(v(3), v(1)) == 0, "a foe 2 tiles off, past its wisdom total (1): not struck")
	var seen := b.sight_cells(lancin)
	ok(seen.has(Vector2i(5, 2)) and not seen.has(Vector2i(6, 2)) and not seen.has(Vector2i(5, 3)) and seen.has(Vector2i(1, 7)) and not seen.has(Vector2i(1, 8)),
			"the side's sight: each member's full wisdom total, joined")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): Vector2i(8, 2)})
	b.sight = true  # stage() calms, turning it off
	var h := await hud(v(1))
	h._refresh()
	ok(not h.pickable(v(1), v(3)) and not h.view(v(3)).located(), "past its side's sight: not shown, not pickable")
	ok(h.overlay.fog_at(Vector2i(1, 2)) == 0.0 and absf(h.overlay.fog_at(Vector2i(8, 2)) - Overlay.FOG_UNSEEN) < 0.01, "fog over what it has never seen")
	b.move(v(1), Vector2i(6, 2))
	h._refresh()
	ok(h.overlay.fog_at(Vector2i(8, 2)) == 0.0 and absf(h.overlay.fog_at(Vector2i(1, 2)) - Overlay.FOG_EXPLORED) < 0.01, "in sight now clear; seen once, dimmed")
	h.free()
