extends Test

# Clairvoyance (Wizard and Mage, Luun): channeled on the caster, it pings the foes its side can't see
# within its wisdom score + rank in tiles - walls or not - as black shapes at their tiles, location
# only, each a stack of the caster's suspicion of the tile. Each of its turn ends while it holds, the
# pings move to where the foes are, then its rank for the channel rises (Battle.clairvoy()).

var clairvoyance: Skill = load("res://Skills/clairvoyance.tres")


func learn(r := 1) -> void:
	v(1).learned.append(slot(clairvoyance, r))
	v(1).refresh()


# v(1) at (1, 2), wisdom 3; foes hidden deep (concealment 9) at the given cells.
func setup(at3: Vector2i, at4: Vector2i) -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): at3, v(4): at4})
	v(1).wisdom = 3
	for t in [v(3), v(4)]:
		t.afflict(effect("concealment", 9), 99)
	learn()


func test_range() -> void:
	setup(Vector2i(5, 2), Vector2i(7, 2))  # 4 and 6 tiles off
	ok(not b.read(v(1), v(3)).located(), "hidden: not located before")
	ok(b.cast(v(1), clairvoyance, v(1)), "cast on itself")
	ok(v(1).channel != null and v(1).channel.skill == clairvoyance, "it channels")
	ok(b.clairvoyance_reach(v(1)) == roundi(v(1).stat(&"wisdom")) + 1, "reach: wisdom + rank (%d)" % b.clairvoyance_reach(v(1)))
	var pings := b.pinged(lancin)
	ok(pings.get(v(3)) == Vector2i(5, 2), "a foe within wisdom + rank: pinged")
	ok(not pings.has(v(4)), "one beyond it: not")
	ok(not b.pinged(nemes).has(v(1)), "the other side knows nothing of it")
	ok(not b.cast(v(1), clairvoyance, v(3)), "only on itself")


func test_location_only() -> void:
	setup(Vector2i(5, 2), Vector2i(8, 6))
	b.cast(v(1), clairvoyance, v(1))
	var r := b.read(v(1), v(3))
	ok(r.cell == Vector2i(5, 2) and r.silhouette(), "located, as a black shape")
	ok(r.faction == null and r.name == "" and r.hp == null and r.tags.is_empty() and r.level == null, "no side, name, HP, traits")
	ok(b.read(v(2), v(3)).cell == Vector2i(5, 2), "its ally knows where it is too")
	ok(v(1).suspects(Vector2i(5, 2)) == 1 and v(2).suspects(Vector2i(5, 2)) == 0, "a stack of the caster's suspicion of its tile")
	ok("black shapes" in clairvoyance.describe(1) and "wisdom + 1 tiles" in clairvoyance.describe(1), clairvoyance.describe(1))


func test_seen_not_pinged() -> void:
	setup(Vector2i(5, 2), Vector2i(4, 4))
	v(4).timed.clear()  # in plain view
	ok(b.read(v(1), v(4)).located(), "in sight")
	b.cast(v(1), clairvoyance, v(1))
	ok(not b.pinged(lancin).has(v(4)) and v(1).suspects(Vector2i(4, 4)) == 0, "a foe already in sight: not pinged")
	ok(b.pinged(lancin).has(v(3)), "the hidden one is")


func test_turns() -> void:
	setup(Vector2i(5, 2), Vector2i(7, 2))  # 4 and 6 off: reach 4 at rank I
	b.cast(v(1), clairvoyance, v(1))
	b.end_turn()  # pings at rank I, then rank II: reach 5
	ok(v(1).channel.rank == 2 and b.clairvoyance_reach(v(1)) == roundi(v(1).stat(&"wisdom")) + 2, "its turn end: a rank more")
	ok(b.turn == nemes and not b.pinged(lancin).has(v(4)), "the update came before the rank: the one 6 off still unpinged")
	b.move(v(3), Vector2i(4, 3))
	ok(not b.read(v(1), v(3)).located(), "moved off its ping: no longer located where it is")
	ok(b.pinged(lancin).get(v(3)) == Vector2i(5, 2), "the ping stays where it was until the caster's turn ends")
	b.move(v(4), Vector2i(6, 2))  # 5 off
	b.end_turn()  # nemes' turn ends: nothing moves
	ok(b.pinged(lancin).get(v(3)) == Vector2i(5, 2) and v(1).channel.rank == 2, "only the caster's turn ends update it")
	b.end_turn()  # lancin's: the pings move, then rank III
	var pings := b.pinged(lancin)
	ok(pings.get(v(3)) == Vector2i(4, 3) and b.read(v(1), v(3)).cell == Vector2i(4, 3), "the ping moved to where it is now")
	ok(pings.get(v(4)) == Vector2i(6, 2), "one that came into reach: added")
	ok(v(1).channel.rank == 3, "rank III")
	ok(v(1).suspects(Vector2i(4, 3)) >= 1, "suspicion of its new tile")
	b.move(v(4), Vector2i(9, 7))
	b.end_turn()
	b.end_turn()
	ok(not b.pinged(lancin).has(v(4)), "one that left its reach: dropped")


func test_channel_ends() -> void:
	setup(Vector2i(5, 2), Vector2i(8, 6))
	b.cast(v(1), clairvoyance, v(1))
	b.end_channel(v(1))
	ok(v(1).channel == null and b.pinged(lancin).is_empty(), "the channel ended: the pings go")
	ok(not b.read(v(1), v(3)).located() and v(1).suspects(Vector2i(5, 2)) == 1, "no longer located; the suspicion stays")
	ok(b.cast(v(1), clairvoyance, v(1)) and b.pinged(lancin).has(v(3)), "cast again")
	var ap := v(1).ap_left()
	ok(b.cast(v(1), clairvoyance, v(1)) and v(1).channel == null and b.pinged(lancin).is_empty(), "cast while channeling: it stops")
	ok(is_equal_approx(v(1).ap_left(), ap), "stopping is free")


func test_hud() -> void:
	setup(Vector2i(5, 2), Vector2i(8, 6))
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	h._refresh()
	ok(not v(3).visible, "hidden: not drawn")
	b.cast(v(1), clairvoyance, v(1))
	h._refresh()
	ok(v(3).visible and v(3).sprite.modulate == Unit.SHAPE and h.dubious.has(Vector2i(5, 2)), "pinged: a black shape, its tile marked")
	b.move(v(3), Vector2i(4, 3))
	h._refresh()
	ok(v(3).visible and v(3).position == b.map.map_to_local(Vector2i(5, 2)), "moved since: drawn where it was sensed")
	ok(h.unit_seen(Vector2i(4, 3)) == null, "nothing shown where it really is")
	b.end_channel(v(1))
	h._refresh()
	ok(not v(3).visible and v(3).position == b.map.map_to_local(Vector2i(4, 3)), "the channel ended: gone, back in place")
	h.free()
