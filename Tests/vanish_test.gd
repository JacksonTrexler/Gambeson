extends Test

# Suspicion's turns, not its stacks: a unit's first suspicion of a unit or tile (Battle.discovered: "?"
# in the log), its seeing through one (unmasked: "!"), and a unit slipping from sight before its eyes
# (vanished: "!?", Battle._vanish()) - after which it goes on taking it for the side it seemed
# (Unit.assumed, Perception), unless a lie fools it. On the card all suspicion is one purple eye
# (HUD.suspicion_icons()), naming what it suspects as it knows it.


func hud() -> HUD:
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	return h


func test_discovered_once() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).charisma = 1  # keeps it to itself (Battle.spread())
	var found := []
	b.discovered.connect(func(by: Unit, of: Variant): found.append([by, of]))
	b.suspect(v(1), v(3))
	b.suspect(v(1), v(3))
	b.suspect(v(1), Vector2i(5, 5))
	ok(found == [[v(1), v(3)], [v(1), Vector2i(5, 5)]], "the first stack of each finds something odd, the next doesn't (%s)" % [found])


func test_revealed() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(2).afflict(effect("persona", 1), 9)
	v(1).wisdom = 10
	var seen := []
	b.unmasked.connect(func(by: Unit, of: Variant, was: Read): seen.append([by, of, was.deceived]))
	ok(b.read(v(1), v(2)).deceived, "an ally's front fools it")
	b.suspect(v(1), v(2))
	ok(seen == [[v(1), v(2), true]], "seen through: revealed, with what it took it for (%s)" % [seen])
	b.suspect(v(1), v(2))
	ok(seen.size() == 1, "once")


func test_vanished_keeps_side() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	ok(b.read(v(1), v(3)).faction == nemes, "it makes out a Nemes")
	var gone := []
	b.vanished.connect(func(by: Unit, of: Unit, was: Read): gone.append([by, of, was.faction]))
	var before := b._sightings(v(3))
	v(3).afflict(effect("concealment", 2), 9)
	b._vanish(v(3), before)
	var r := b.read(v(1), v(3))
	ok([v(1), v(3), nemes] in gone, "it slipped from sight before v(1)'s eyes (%s)" % [gone])
	ok(r.net < 0 and r.faction == nemes and r.assumed, "v(1) still takes it for a Nemes (net %d)" % r.net)
	ok(b.read(v(2), v(3)).faction == null, "one that didn't see it go can't tell")


func test_far_off_isnt_vanishing() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	b.sight = true
	v(1).wisdom = 4  # sees 4 tiles, makes out how things look within 2
	var gone := []
	b.vanished.connect(func(by: Unit, of: Unit, _was: Read): gone.append(by))
	var before := b._sightings(v(3))
	ok(v(1) in before, "it makes it out")
	b.move(v(3), Vector2i(5, 3))
	v(3).afflict(effect("concealment", 2), 9)
	b._vanish(v(3), before)
	ok(gone.is_empty() and v(3) not in v(1).assumed, "too far off to watch it go: no assumption")


func test_travel_into_cover() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	var gone := []
	b.vanished.connect(func(by: Unit, of: Unit, _was: Read): gone.append([by, of]))
	b.paint(Vector2i(5, 3), load("res://Terrain/tall_grass.tres"))
	b.turn = nemes
	b.travel(v(3), Vector2i(5, 3))
	var r := b.read(v(1), v(3))
	ok(v(3).cell == Vector2i(5, 3), "it walked into the tall grass")
	ok(r.faction == null or r.assumed, "lost from v(1)'s sight, or still assumed (net %d)" % r.net)
	ok(r.net >= 0 or [v(1), v(3)] in gone, "lost from sight: it vanished before v(1)'s eyes")


func test_eye() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(4, 2)})
	b.player = v(1)
	v(1).charisma = 1
	var h := hud()
	await tree.process_frame
	b.suspect(v(1), v(3), 2)
	b.suspect(v(1), Vector2i(6, 6))
	var icons: Array = h._info(v(1)).effects.filter(func(x: Array): return x[0] is Texture2D)
	ok(icons.size() == 1, "one eye, whatever it suspects")
	ok(icons[0][1] == HUD.SUSPICION and icons[0][3] == "2", "purple, counting the two")
	ok(h.known_name(v(1), v(3)) + ": sees through 2 ranks" in icons[0][2] and "at 6, 6: sees through 1 rank" in icons[0][2],
			"naming each as it knows it (%s)" % icons[0][2])
	b.vanished.emit(v(1), v(3), b.read(v(1), v(3)))
	b.discovered.emit(v(1), Vector2i(6, 6))
	var text: String = h.log_box.get_parsed_text()
	ok(" !? " in text and " vanishes" in text and "%s ? " % v(1).name in text and "at 6, 6" in text, "the log: !? and ? (%s)" % text)
	h.free()
