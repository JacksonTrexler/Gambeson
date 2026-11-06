extends Test

# Tile stacks (Battle.layers, Battle.terrain(), Battle.expose(), Battle._teeter(), Battle._repair_tiles()):
# a tile's ground with layers on top. A unit deals with the top layer; one that lets through (Leaves,
# an overlay starpane) lets the one beneath act too. Leaves obscure and give cover, burn and blow away;
# glass is brittle and unstable; startiles crack into glass that mends near a power source.

const LEAVES := preload("res://Terrain/leaves.tres")
const GLASS := preload("res://Terrain/glass.tres")
const STEW := Vector2i(4, 0)  # the museum's magic stew (sleep and poison at turn end)
const SHRINE := Vector2i(5, 2)  # heals whoever stands there
const TRAP := Vector2i(5, 4)


# Glass whose dex check always passes (dc -99) or always fails (dc 99).
func glass(dc: int) -> Terrain:
	var t: Terrain = GLASS.duplicate()
	t.dc = dc
	return t


func test_compose() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	b.lay_layer(Vector2i(4, 3), LEAVES)
	var t := b.terrain(Vector2i(4, 3))
	ok(t.name == "Leaves" and &"leaves" in t.tags and &"grass" in t.tags and b.reaches_ground(Vector2i(4, 3)), "leaves over grass: both count, the leaves on top")
	ok(is_equal_approx(b.step(v(1), Vector2i(3, 3), Vector2i(4, 3)), 1.1), "entering costs the grass's 1 + the leaves' 0.1")
	b.lay_layer(Vector2i(5, 3), glass(12))
	b.lay_layer(Vector2i(5, 3), LEAVES)
	ok(b.reached(Vector2i(5, 3)).size() == 2 and not b.reaches_ground(Vector2i(5, 3)), "leaves over glass over grass: the leaves let through to the glass, the glass stops there")
	ok(GLASS.effects.is_empty() and b.terrain(Vector2i(5, 3)).name == "Leaves", "the top lends its name")


func test_overlay_or_standalone() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	b.lay_layer(SHRINE, Battle.STARPANE, true)
	ok(not b.terrain(SHRINE).effects.is_empty() and b.terrain(SHRINE).name == "Starpane", "an overlay starpane: the shrine beneath still heals")
	b.layers[SHRINE].clear()
	b._restack(SHRINE)
	b.lay_layer(SHRINE, Battle.STARPANE, false)
	ok(b.terrain(SHRINE).effects.is_empty() and SHRINE in b.panes, "a standalone one: the pane is all there is")


func test_obscured() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	b.lay_layer(Vector2i(4, 3), LEAVES)
	var r := b.read(v(1), Vector2i(4, 3))
	ok(r.obscured and r.name == "Leaves" and r.cost == null and r.net < 0, "under leaves: only the leaves, what's beneath unknown")
	b.move(v(2), Vector2i(4, 3))
	r = b.read(v(1), Vector2i(4, 3))
	ok(not r.obscured and is_equal_approx(r.cost, 1.1), "someone standing in them: see-through, the ground beneath plain")
	ok(b.covered(Vector2i(4, 3)), "and cover: advantage to hide there")


func test_brittle() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	v(1).weapon = load("res://Items/broadsword.tres")
	b.lay_layer(Vector2i(4, 3), glass(12))
	ok(b.attempt(v(1), strike, Vector2i(4, 3)) == &"miss" and b.top_layer(Vector2i(4, 3)) != null, "a slash doesn't break glass")
	v(1).refresh()
	v(1).weapon = null
	ok(b.attempt(v(1), strike, Vector2i(4, 3)) == &"shattered" and b.top_layer(Vector2i(4, 3)) == null, "a bare-handed (blunt) blow does")
	b.lay_layer(TRAP, glass(12))
	b.move(v(2), TRAP)
	var hp := v(2).hp
	ok(b.expose(TRAP, [&"blunt"] as Array[StringName], v(1)) and v(2).hp < hp, "a blunt blow over glass with someone on it: it gives way, onto the spikes beneath")


func test_unstable() -> void:
	stage(lancin, {v(1): Vector2i(2, 3)})
	var c := Vector2i(4, 3)
	b.lay_layer(c, glass(99))
	v(1).refresh()
	b.travel(v(1), Vector2i(3, 3))
	b.end_turn()
	ok(b.top_layer(c) != null, "not on it: nothing")
	stage(lancin, {v(1): Vector2i(3, 3)})
	v(1).refresh()
	b.travel(v(1), c)  # 1 tile: no more than its dex mod (1)
	b.end_turn()
	ok(b.top_layer(c) != null, "one tile onto it, within its dex mod: it holds")
	stage(lancin, {v(1): Vector2i(2, 3)})
	v(1).refresh()
	var kept := []
	b.teetered.connect(func(_u, _t, _dc, k): kept.append(k))
	b.travel(v(1), c)  # 2 tiles
	b.end_turn()
	ok(b.top_layer(c) == null and kept == [false] and v(1).footing.name == "Grass", "2 tiles onto it, then the turn ends: it breaks; failing the check, it drops through")


func test_teeter_reprieve() -> void:
	stage(lancin, {v(1): STEW + Vector2i(-2, 0)})
	b.lay_layer(STEW, glass(-99))
	v(1).refresh()
	b.travel(v(1), STEW)
	b.end_turn()
	ok(b.top_layer(STEW) == null and v(1).steadied == STEW and not v(1).asleep(), "glass over the stew breaks; catching itself, it's spared the stew's sleep")
	stage(lancin, {v(2): STEW + Vector2i(-2, 0)})
	b.lay_layer(STEW, glass(99))
	v(2).refresh()
	b.travel(v(2), STEW)
	b.end_turn()
	ok(v(2).steadied == null and v(2).asleep(), "failing, it drops in and ends its turn there: asleep")


func test_rested_holds() -> void:
	stage(lancin, {v(1): Vector2i(4, 3)})
	b.lay_layer(Vector2i(4, 3), glass(99))
	v(1).refresh()
	b.end_turn()
	ok(b.top_layer(Vector2i(4, 3)) != null, "resting on glass: it holds")


func test_burn_and_blow() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	b.lay_layer(Vector2i(4, 3), LEAVES)
	ok(b.expose(Vector2i(4, 3), [&"fire"] as Array[StringName], v(1)) and b.top_layer(Vector2i(4, 3)) == null and Vector2i(4, 3) in b.flames,
			"fire on leaves: they burn away, and the tile's alight")
	b.lay_layer(Vector2i(6, 3), LEAVES)
	ok(b.expose(Vector2i(6, 3), [&"wind"] as Array[StringName]) and b.top_layer(Vector2i(6, 3)) == null and Vector2i(6, 3) not in b.flames,
			"wind blows them away")
	b.lay_layer(Vector2i(6, 3), LEAVES)
	ok(not b.expose(Vector2i(6, 3), [&"blunt"] as Array[StringName]), "a blunt blow does nothing to leaves")


func test_startile() -> void:
	stage(lancin, {v(1): Vector2i(8, 6)})
	b.lay_layer(Vector2i(1, 1), Battle.STARTILE)
	b.charge[Vector2i(1, 1)] = Battle.STAR_CAPACITY  # full: reaches 5 tiles to mend
	b.lay_layer(Vector2i(2, 1), Battle.STARPANE)
	var c := Vector2i(3, 3)
	b.lay_layer(c, Battle.STARTILE)
	ok(c in b.starpower and b.top_layer(c).terrain.source, "a startile: a source on the lattice")
	b.expose(c, [&"blunt"] as Array[StringName], v(1))
	var l: Battle.Layer = b.top_layer(c)
	ok(l.terrain.name == "Cracked Startile" and l.terrain.unstable and c not in b.starpower, "broken, it's a cracked startile: glass, no longer a source")
	b._repair_tiles()
	ok(l.repair_goal == 2 and l.source == Vector2i(1, 1) and b.charge[Vector2i(1, 1)] == Battle.STAR_CAPACITY - 1,
			"the nearest lattice tile is 2 away, within reach: mending begins, drawing 5% of a source's capacity from it")
	b._repair_tiles()
	ok(l.repairing == 1 and l.terrain.name == "Cracked Startile", "Repairing 1/2")
	var done := []
	b.mended.connect(func(at, _t): done.append(at))
	b._repair_tiles()
	ok(l.terrain.name == "Startile" and c in b.starpower and done == [c], "2/2: it upgrades into a startile, a source again")


func test_repair_out_of_reach() -> void:
	stage(lancin, {v(1): Vector2i(8, 6)})
	b.lay_layer(Vector2i(1, 1), Battle.STARTILE)
	b.charge[Vector2i(1, 1)] = 4  # 20% full: reaches 1 tile
	var c := Vector2i(4, 4)
	b.lay_layer(c, Battle.STARTILE)
	b.expose(c, [&"blunt"] as Array[StringName], v(1))
	b._repair_tiles()
	ok(b.top_layer(c).repair_goal == 0 and b.charge[Vector2i(1, 1)] == 4, "too far from a source this empty: no mending, nothing drawn")
