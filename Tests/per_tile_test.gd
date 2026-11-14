extends Test

# The per_tile Effect stat (Battle._toll(), called by travel()): HP lost for each tile walked while it lasts,
# unless Meander passes it by: still(), and the effect's rank (its level) no higher than the Meander rank
# (Unit.wards(), the same test as ground's passes_by()).

var meander: Skill = load("res://Skills/meander.tres")
var footsore: Effect = load("res://Effects/footsore.tres")


func start(effect_rank: int, meander_rank := 0) -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(9, 7)})
	if meander_rank > 0:
		v(1).learned.append(slot(meander, meander_rank))
	v(1).movement = 9
	v(1).refresh()
	v(1).afflict(footsore, 5, effect_rank)


func test_each_tile_walked_hurts() -> void:
	start(1)
	var hp := v(1).hp
	var tolls := []
	b.toll_paid.connect(func(u: Unit, n: int): tolls.append(n))
	var walked := b.travel(v(1), Vector2i(4, 4))
	ok(walked.size() == 3 and hp - v(1).hp == tolls.reduce(func(s, x): return s + x, 0) and tolls.size() == 3, "3 tiles: three tolls (%s)" % [tolls])
	ok(hp - v(1).hp >= 3 - 2 and hp - v(1).hp <= 3 + 2, "about 1 HP a tile (%d)" % (hp - v(1).hp))


func test_standing_still_costs_nothing() -> void:
	start(1)
	var hp := v(1).hp
	b.end_turn()
	ok(v(1).hp == hp, "not walking: nothing")


func test_rank_multiplies() -> void:
	start(3)
	var e := footsore
	ok(e.stat == "per_tile" and e.per_rank, "Footsore is a per_tile effect that grows with rank")
	var hp := v(1).hp
	b.travel(v(1), Vector2i(3, 4))
	ok(hp - v(1).hp >= 4 and hp - v(1).hp <= 8, "rank 3: about 3 a tile, 2 tiles (%d)" % (hp - v(1).hp))


func test_a_teleport_isnt_walking() -> void:
	start(1)
	var hp := v(1).hp
	b.place(v(1), Vector2i(6, 4))
	ok(v(1).hp == hp, "placed: no tiles walked, no toll")


func test_meander_wards_the_first_tiles() -> void:
	start(1, 2)
	var hp := v(1).hp
	b.travel(v(1), Vector2i(3, 4))
	ok(v(1).hp == hp, "Meander II beside a level 1 toll: the first 2 tiles are passed by")
	b.travel(v(1), Vector2i(4, 4))
	ok(hp - v(1).hp >= 1 and hp - v(1).hp <= 2, "...the third, past what Meander II passes by in a turn, hurts (%d)" % (hp - v(1).hp))


func test_meander_needs_the_rank() -> void:
	start(2, 1)
	var hp := v(1).hp
	b.travel(v(1), Vector2i(2, 4))
	ok(v(1).hp < hp, "a level 2 toll isn't passed by Meander I, even on its first tile")
	start(2, 2)
	hp = v(1).hp
	b.travel(v(1), Vector2i(3, 4))
	ok(v(1).hp == hp, "...Meander II wards it off (its rank is at least the effect's)")


func test_ground_and_tolls_share_the_test() -> void:
	start(2, 2)
	var t := Terrain.new()
	t.level = 2
	ok(v(1).passes_by(t, 1) and v(1).wards(2, 1) and not v(1).wards(3, 1) and not v(1).wards(2, 3), "passes_by() is wards() of the ground's level; past Meander's tiles it wards nothing")
