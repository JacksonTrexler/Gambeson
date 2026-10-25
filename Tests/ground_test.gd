extends Test

# What ground does: beneficial / detrimental by tag (most ground is neutral), effects on whoever
# stands there (the Shrine heals), effects put on whoever steps there, and regen and poison acting
# as a unit's side starts its turn.
# Map: shrine (5,2) (3,6); bramble (2,2); hidden trap (5,4).

var shrine: Terrain = load("res://Terrain/shrine.tres")
var trap: Terrain = load("res://Terrain/trap.tres")


func test_worth() -> void:
	ok(shrine.worth() == 1 and trap.worth() == -1, "beneficial and detrimental by tag")
	ok(b.terrain(Vector2i(2, 2)).worth() == 0 and b.terrain(Vector2i(0, 0)).worth() == 0, "bramble and grass are neutral")


func test_shrine_heals() -> void:
	stage(lancin, {v(1): Vector2i(5, 2), v(3): Vector2i(8, 2)})
	ok(v(1).stat(&"regen") == 0.1, "standing on the shrine: Heal 10%")
	v(1).damage(5)
	b.end_turn()
	ok(v(1).hp == 5, "not on the other side's turn")
	b.end_turn()
	ok(v(1).hp == 6, "as its side's turn starts: 10% of 10")
	b.move(v(1), Vector2i(5, 3))
	ok(v(1).stat(&"regen") == 0.0, "off the shrine, no more")
	b.end_turn()
	b.end_turn()
	ok(v(1).hp == 6, "and no more healing")


func test_poison() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(1).afflict(effect("poison", 2), 2)
	b.end_turn()
	b.end_turn()
	ok(v(1).hp == 8, "2 as its side's turn starts")
	b.end_turn()
	b.end_turn()
	ok(v(1).hp == 8 and v(1).timed.is_empty(), "worn off after its 2 turns")


func test_poison_kills() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(3).hp = 1
	v(3).afflict(effect("poison", 1), 3)
	b.end_turn()
	ok(not v(3).is_alive() and b.phase == Battle.Phase.OVER, "poison can finish a side as its turn starts")


func test_stepping_in() -> void:
	var poison := effect("poison", 1)
	trap.afflicts = [poison]
	trap.turns = 3
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(8, 2)})
	b.travel(v(1), Vector2i(5, 4))
	ok(poison in v(1).timed and v(1).timed[poison].turns == 3, "stepping on it puts its afflictions on")
	ok(b.read(v(2), Vector2i(5, 4)).afflicts == [poison], "and once seen, that's known")
	trap.afflicts = []
	trap.turns = 0
