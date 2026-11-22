extends Test

# Coordinate (Paladin, Idealism): the caster links up with teammates within its cha mod in tiles (at
# least 1) and its leader wherever it is; each makes out what the best of them does, up to the
# link's rank in levels better than it would alone (Battle.read(), Battle.linked()).

var coordinate: Skill = load("res://Skills/coordinate.tres")


func link(r: int) -> void:
	if not v(1).learned.any(func(x: Slot): return x.skill == coordinate):
		v(1).learned.append(slot(coordinate, r))
	v(1).learned.filter(func(x: Slot): return x.skill == coordinate)[0].rank = r
	v(1).refresh()
	ok(b.cast(v(1), coordinate, v(1)), "linked at rank %d" % r)


func test_pooled() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(2, 1), v(3): Vector2i(6, 1)})
	v(3).afflict(effect("concealment", 2), 9)
	v(2).afflict(effect("recon", 3), 9)
	ok(b.read(v(1), v(3)).net == -2 and b.read(v(2), v(3)).net == 1, "alone: -2 and 1")
	link(1)
	ok(v(2).linked() != null and v(2).linked().by == v(1) and b.linked(v(1)) == [v(2)], "the ally beside it is linked")
	ok(b.read(v(1), v(3)).net == -1, "rank I: a level better, from what its ally makes out")
	var alone := b._read(v(1), Vector2i(5, 4)).net
	ok(b._read(v(2), Vector2i(5, 4)).net > alone and b.read(v(1), Vector2i(5, 4)).net == alone + 1, "tiles too: the trap's")
	link(3)
	ok(b.read(v(1), v(3)).net == 1, "rank III: as well as its ally")
	ok(b.read(v(2), v(3)).net == 1, "the ally sees no worse than it did")


func test_reach() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(5, 6), v(3): Vector2i(6, 1)})
	v(3).afflict(effect("concealment", 2), 9)
	v(2).afflict(effect("recon", 3), 9)
	link(3)
	ok(v(2).linked() == null and b.read(v(1), v(3)).net == -2, "an ally further than its cha mod (at least 1): not linked")
	v(1).follows = v(2)
	v(1).timed.clear()
	link(3)
	ok(v(2).linked() != null and b.read(v(1), v(3)).net == 1, "its leader: linked wherever it is")
	ok("linked: makes out what the best of the others linked do, up to 3 levels better" in coordinate.describe(3), coordinate.describe(3))
