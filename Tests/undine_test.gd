extends Test

# The Undine (Scenes/undine.tscn): an elemental, here a demon variant - Malevolent and Abyssal, Murky,
# Aquatic. Waterstrike; Waltz of Vapors (fog around it, kept up by using it as each turn opens:
# Battle.waltz()); Vaporize (a mist: resistant, weak to wind, only Coalescing); Coalescing (into a foe's
# tile, sharing it, grappling and drowning it there: Battle.engulf()); Well Up (Battle.well_up()). Its
# AI: AI._undine().


func undine(at := Vector2i(6, 4)) -> Unit:
	var u := b.summon(load("res://Scenes/undine.tscn"), nemes, at)
	u.refresh()
	return u


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func test_undine() -> void:
	stage(nemes, {v(1): Vector2i(1, 1)})
	var u := undine()
	ok(["elemental", "demon", "aquatic", "malevolent", "abyssal"].all(func(t: String): return StringName(t) in u.tags) and u.vibe == "Murky",
			"an elemental demon: Malevolent, Abyssal, Aquatic, and Murky")
	ok(["Waterstrike", "Waltz of Vapors", "Vaporize", "Coalescing", "Well Up"].all(func(n: String): return u.slots.any(func(x: Slot): return x.skill.name == n)), "its five skills")
	ok(u.stat(&"mist") == 0.0, "not a mist until it Vaporizes")


func test_well_up() -> void:
	stage(nemes, {v(1): Vector2i(1, 1)})
	var u := undine(Vector2i(5, 4))
	var c := u.cell + Vector2i(2, 0)
	ok(b.cast_at(u, sk("well_up"), c), "Well Up III, 2 tiles off")
	ok(b.depth(c) >= 3 and b.depth(c + Vector2i(1, 0)) >= 2 and b.depth(c + Vector2i(1, 1)) >= 2, "the tile 3 deep, those beside it 2")
	ok(not b.cast_at(u, sk("well_up"), u.cell + Vector2i(5, 0)), "out of its range (rank)")


func test_waltz() -> void:
	stage(nemes, {v(1): Vector2i(1, 1)})
	var u := undine(Vector2i(5, 4))
	ok(b.cast(u, sk("waltz_of_vapors"), u), "as its turn opens: a waltz")
	var fog: Array = b.zones.filter(func(z: Battle.Zone): return z.kind == &"fog")
	ok(fog.size() == 1 and fog[0].levels.has(u.cell + Vector2i(3, 0)) and not fog[0].levels.has(u.cell + Vector2i(4, 0)) and fog[0].levels[u.cell] == 1,
			"fog out to rank I + the better of dex and cha mods (2): 3 tiles, concealing at 1")
	u.walked(1, 1.0)
	ok(not b.cast(u, sk("waltz_of_vapors"), u), "only as its turn opens")


func test_vaporize() -> void:
	stage(nemes, {v(1): Vector2i(1, 1)})
	var u := undine(Vector2i(5, 4))
	u.toggle(sk("vaporize"))
	ok(u.stat(&"mist") > 0.0 and is_equal_approx(u.mitigation([&"physical"]), 0.75) and is_equal_approx(u.mitigation([&"magical"]), 0.5)
			and is_equal_approx(u.mitigation([&"wind", &"magical"]), -0.5), "a mist: 75% off physical, 50% off magic, wind hits 50% harder")
	b.move(v(1), u.cell + Vector2i(1, 0))
	ok(not b.cast(u, sk("waterstrike"), v(1)), "it can't attack")


# Coalescing into a foe: it shares its tile, holds it, and drowns it there; once the foe's gone from the
# tile, the tile is the Undine's.
func test_coalescing() -> void:
	stage(nemes, {v(1): Vector2i(4, 4)})
	var u := undine(Vector2i(5, 4))
	u.strength = 40  # sure to win
	v(1).max_hp = 99
	v(1).hp = 99
	ok(not b.cast(u, sk("coalescing"), v(1)), "not a mist yet: no Coalescing")
	u.toggle(sk("vaporize"))
	var c := v(1).cell
	ok(b.cast(u, sk("coalescing"), v(1)) and u.cell == c and b.unit_at(c) == v(1) and b.inside[u] == v(1), "coalesced: inside its tile, the tile still the foe's")
	ok(b.held_by(v(1)) != null and b.submerged(v(1)) and u in b.members(nemes), "held, engulfed (submerged), and still taking its turns")
	b._grip(v(1))
	ok(v(1).hp < 99, "it drowns in the Undine (%d HP)" % v(1).hp)
	b.move(v(1), c + Vector2i(0, 2))
	ok(b.unit_at(c) == u and not b.inside.has(u), "the foe gone from the tile: it's the Undine's now")


func test_ai() -> void:
	stage(nemes, {v(1): Vector2i(1, 1)})
	var u := undine(Vector2i(4, 2))
	var log := AI.act(b, u)
	ok(b.zones.any(func(z: Battle.Zone): return z.kind == &"fog"), "it keeps its fog up (%s)" % ", ".join(log))
	u.hp = 5
	u.refresh()
	b.zones.clear()
	log = AI.act(b, u)
	ok(u.stat(&"mist") > 0.0 and ", ".join(log).contains("vaporizes"), "bloodied, it turns to mist (%s)" % ", ".join(log))
