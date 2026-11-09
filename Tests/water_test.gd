extends Test

# Water by depth, in unit sizes (Terrain.depth): deeper than a unit's size, it's submerged
# (Battle.submerged()). Floods (Battle.flood()): a layer whose rank is its depth, slowing movement,
# putting out fire, draining as its setter's side ends its turns. Grappling and drowning apart: a
# grapple holds (Skill.grapples), and only the submerged drown (Skill.drowns; Battle._grip()). A Siren
# too far away to lure anyone closes in (AI._out_of_song()).

var drown: Skill = load("res://Skills/drown.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func dry_cell() -> Vector2i:
	for y in range(1, 8):
		for x in range(1, 10):
			var c := Vector2i(x, y)
			if b.on_map(c) and b.depth(c) == 0 and not b.unit_at(c) and b.terrain(c).enter == 1:
				return c
	return Vector2i(-1, -1)


func test_depths() -> void:
	var depths := {}
	for n in ["water", "pond", "flowing_water", "shallows"]:
		var t: Terrain = load("res://Terrain/%s.tres" % n)
		depths[n] = t.depth
		ok(t.douses and &"water" in t.tags, "%s is water, and puts out fire" % t.name)
	ok(depths == {"water": 5, "pond": 5, "flowing_water": 2, "shallows": 1}, "Water and Pond 5 deep, Flowing Water 2, Shallows 1 (%s)" % [depths])
	ok(load("res://Skills/drown.tres").grapples and load("res://Skills/drown.tres").drowns == Vector2i(1, 12) and load("res://Skills/drown.tres").grip == Vector2i.ZERO,
			"Drown: a grapple that drowns, no crushing grip")


func test_flood() -> void:
	stage(lancin, {v(1): Vector2i(1, 1)})
	var c := dry_cell()
	var before := b.terrain(c).drag
	b.flood(c, 4, 2, v(1))
	ok(b.depth(c) == 4 and b.terrain(c).name == "Flood IV" and is_equal_approx(b.terrain(c).drag, before + 2.0), "a Flood IV: 4 deep, +2 movement to cross")
	b.move(v(1), c)
	ok(b.submerged(v(1)), "deeper than a Medium unit (3): submerged")
	b.flood(c, 2, 1, v(1))
	ok(b.depth(c) == 4, "flooded again, shallower: the deeper stays")
	var d := c + Vector2i(1, 0) if b.depth(c + Vector2i(1, 0)) == 0 else c + Vector2i(0, 1)
	b.flood(d, 3, 1, v(1))
	b.move(v(1), d)
	ok(b.depth(d) == 3 and not b.submerged(v(1)), "3 deep: a Medium unit keeps its head up")
	b.flames[c] = Battle.Flame.new(v(1), 3)
	b.flood(c, 1, 1, v(1))
	ok(c not in b.flames, "a Flood puts out fire")
	var ends := 0
	while b.depth(c) > 0 and ends < 8:
		b.end_turn()
		ends += 1
	ok(b.depth(c) == 0 and ends <= 4, "it drains away after its setter's side's 2 turns (%d turns ended)" % ends)


# Held on dry ground, nothing drowns; once the water's over its head, or its holder engulfs it on its own
# tile, it does.
func test_drowning_needs_water() -> void:
	stage(nemes, {siren(): Vector2i(1, 1), v(1): Vector2i(2, 1)})
	var c := dry_cell()
	b.move(v(1), c)
	b.move(siren(), c + Vector2i(-1, 0) if b.on_map(c + Vector2i(-1, 0)) and not b.unit_at(c + Vector2i(-1, 0)) else c + Vector2i(1, 0))
	v(1).max_hp = 99
	v(1).hp = 99
	siren().strength = 20  # every drowning hurts
	var a := v(1).afflict(drown.effects[0], 0, 1)
	a.lasting = true
	a.skill = drown
	a.by = siren()
	ok(b.held_by(v(1)) == a and not b.submerged(v(1)), "grappled on dry ground")
	b._grip(v(1))
	ok(v(1).hp == 99, "held, but not under water: no drowning")
	b.flood(c, 5, 2, siren())
	b._grip(v(1))
	ok(v(1).hp < 99 and b.held_by(v(1)) == a, "flooded over its head: it drowns (%d HP)" % v(1).hp)
	var hp := v(1).hp
	b.flood(c, 0, 0)
	for l in b.layers.get(c, []).duplicate():
		b.layers[c].erase(l)
	b._restack(c)
	siren().cell = c  # engulfing it, as a mist Undine does
	ok(b.submerged(v(1)), "its holder on its own tile: engulfed, submerged")
	b._grip(v(1))
	ok(v(1).hp < hp, "and it drowns there too")


func test_siren_closes_in() -> void:
	stage(nemes, {siren(): Vector2i(9, 7), v(1): Vector2i(1, 1)})
	var from := siren().cell
	ok(AI._luring(b, siren(), {v(1): b.read(siren(), v(1))}) and AI._out_of_song(b, siren(), {v(1): b.read(siren(), v(1))}), "fooled, and too far off to sing to")
	AI.act(b, siren())
	ok(Command.tiles(siren().cell, v(1).cell) < Command.tiles(from, v(1).cell), "it closes in (%s to %s)" % [from, siren().cell])
