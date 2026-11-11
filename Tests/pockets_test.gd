extends Test

# Pockets: parts of the map out of reach, entered and left by their doors (Battle.Pocket). A Wizard's
# Rift opens a door to a domain - an 8x8 diamond of grass with demons at the rift's difficulty - open
# both ways while it's channeled; used again the channel stops and its count starts (3 x its
# difficulty turns), or cast unchanneled it starts at once, and when it runs out the caster's side
# comes back. Emergency Exit hastens a forming escape portal, or warps the Wizard and
# allies near it to a pocket of stone for rank turns.

var rift: Skill = load("res://Skills/rift.tres")
var exit: Skill = load("res://Skills/emergency_exit.tres")
var demons: Faction = load("res://Factions/demons.tres")


func wizard(s: Skill, r := 1) -> Unit:
	v(1).learned.append(slot(s, r))
	v(1).level = 4
	v(1).energy = 99
	v(1).refresh()
	return v(1)


func test_rift() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 6)})
	var w := wizard(rift)
	var c := Vector2i(3, 3)
	ok(b.cast_at(w, rift, c), "Rift I on the tile beside it")
	var p: Battle.Pocket = b.pockets[0]
	ok(p.kind == &"domain" and p.cells.size() == 41 and b.on_map(p.centre) and Command.tiles(p.centre, c) > 500, "a domain: a diamond of grass, far off the field")
	ok(w.channel != null and w.channel.skill == rift and p.turns == -1 and p.marks[1].turns == -1, "channeled: its turns infinite")
	var them := b.members(demons)
	ok(demons in b.order and them.size() == 2 and them.all(func(u: Unit): return u.cell in p.cells and u.level == 4), "demons in it, at its difficulty (0.5: an Undine's three, halved) and the Wizard's level")
	b.move(v(2), c + Vector2i(0, 1))
	b.travel(v(2), c)
	ok(v(2).cell in p.cells, "stepping onto the rift: into the domain")
	b.travel(v(2), p.door)
	ok(not (v(2).cell in p.cells) and Command.tiles(v(2).cell, c) <= 2, "its own door: back beside the rift")
	b.travel(v(2), c)
	ok(v(2).cell in p.cells, "and in again")
	ok(b.cast_at(w, rift, c) and w.channel == null and p.open and p.turns == 2 and p.marks[0].turns == 2, "used again: the channel stops and its count starts, 2 turns (3 x 0.5), still open")
	for i in 4:
		b.end_turn()
	ok(b.pockets.is_empty() and not (v(2).cell in p.cells) and Command.tiles(v(2).cell, c) <= 2 and not b.on_map(p.centre), "it ends: the Wizard's side back in a clump by the rift, the domain gone")
	ok(b.members(demons).is_empty() or not b.members(demons)[0].is_inside_tree() or b.members(demons)[0].is_queued_for_deletion(), "its demons with it")


# The channel rule: a turn the Wizard walks off ends its Rift's channel, and the count starts.
func test_rift_moved() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 6)})
	var w := wizard(rift)
	b.cast_at(w, rift, Vector2i(3, 3))
	var p: Battle.Pocket = b.pockets[0]
	b.end_turn()
	while b.turn != w.faction:  # the demons take turns too
		b.end_turn()
	b.end_turn()
	while b.turn != w.faction:
		b.end_turn()
	ok(w.channel != null and p.turns == -1, "a turn held still: still open for as long as it's kept")
	ok(not b.travel(w, w.cell + Vector2i(0, 1)).is_empty(), "it walks a tile")
	b.end_turn()
	ok(w.channel == null and p.turns == 1, "it walked: the channel ends and its count (2) starts, this turn's end the first off it, as when it stops by a recast (%d)" % p.turns)


func test_rift_unchanneled() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(2): Vector2i(1, 3), v(3): Vector2i(8, 6)})
	var w := wizard(rift)
	ok(b.cast_at(w, rift, Vector2i(3, 3), false) and w.channel == null, "cast unchanneled: nothing to keep up")
	var p: Battle.Pocket = b.pockets[0]
	ok(p.open and p.turns == 2 and p.marks[1].turns == 2, "its count starts at once")
	b.end_turn()
	b.end_turn()
	ok(p.turns == 1, "a turn of its side's gone")
	var metea: Skill = load("res://Skills/metea.tres")
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 6)})
	ok(b.cast_at(w, rift, Vector2i(2, 4)) and b.pockets[1].turns == -1, "a second, channeled")
	w.learned.append(slot(metea, 1))
	w.refresh()
	w.energy = 99
	ok(b.cast_at(w, metea, Vector2i(2, 6)) and w.channel.skill == metea and b.pockets[1].turns == 2, "channeling something else stops it: its count starts")
	b.pockets[0].turns = 1
	w.channel = Unit.Channel.new(rift, Vector2i(2, 4))
	b.pockets[1].turns = -1
	w.damage(999)
	ok(b.pockets.size() >= 1 and b.pockets[-1].turns == 2, "and so does falling")


func test_rift_sight() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 6)})
	var w := wizard(rift, 3)
	b.earthworks[Vector2i(3, 3)] = Battle.Earthwork.new(nemes, 9)
	ok(not b.clear_line(Vector2i(2, 3), Vector2i(4, 3)) and b.clear_line(Vector2i(2, 3), Vector2i(2, 5)), "a wall between: no clear line")
	ok(b.cast_at(w, rift, Vector2i(4, 3)), "Rift III opens over it")
	v(1).learned.clear()
	v(4).learned.append(slot(rift, 2))
	v(4).refresh()
	b.move(v(4), Vector2i(2, 5))
	b.earthworks[Vector2i(2, 6)] = Battle.Earthwork.new(nemes, 9)
	stage(nemes, {v(4): Vector2i(2, 5), v(1): Vector2i(2, 3)})
	v(4).refresh()
	ok(not b.cast_at(v(4), rift, Vector2i(2, 7)), "Rift II can't")


func test_emergency_exit() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3), v(3): Vector2i(8, 6)})
	var w := wizard(exit, 2)
	var from := w.cell
	ok(b.cast(w, exit, w), "Emergency Exit II")
	var p: Battle.Pocket = b.pockets[0]
	ok(p.kind == &"refuge" and b.terrain(p.centre).name == "Stone" and w.cell in p.cells and v(2).cell in p.cells, "it and the ally beside it warp to a pocket of stone")
	ok(not (v(3).cell in p.cells) and p.turns == 2, "foes stay; it lasts 2 turns")
	for i in 4:
		b.end_turn()
	ok(b.pockets.is_empty() and Command.tiles(w.cell, from) <= 2 and Command.tiles(v(2).cell, from) <= 2, "then back in a clump where they left")
