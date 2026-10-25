extends Test

# What ground does: beneficial / detrimental by tag (most ground is neutral), effects on whoever
# stands there (the Shrine heals), effects put on whoever steps there (counted from its next turn),
# regen and poison acting as a unit's side starts its turn, sleep, haste, and moist ground.
# Map: shrine (5,2) (3,6); bramble (2,2); hidden trap (5,4); magic stew (4,0).

var shrine: Terrain = load("res://Terrain/shrine.tres")
var trap: Terrain = load("res://Terrain/trap.tres")
var stew: Terrain = load("res://Terrain/stew.tres")
const STEW := Vector2i(4, 0)


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
	v(1).afflict(effect("poison", 0.2), 2)
	b.end_turn()
	b.end_turn()
	ok(v(1).hp == 8, "20% of 10 as its side's turn starts")
	b.end_turn()
	b.end_turn()
	ok(v(1).hp == 8 and v(1).timed.is_empty(), "worn off after its 2 turns")


func test_poison_kills() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(3).hp = 1
	v(3).afflict(effect("poison", 0.1), 3)
	b.end_turn()
	ok(not v(3).is_alive() and b.phase == Battle.Phase.OVER, "poison can finish a side as its turn starts")


func test_stepping_in() -> void:
	var poison := effect("poison", 0.1)
	trap.afflicts = [poison]
	trap.turns = 3
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(8, 2)})
	b.travel(v(1), Vector2i(5, 4))
	ok(poison in v(1).timed and v(1).timed[poison].turns == 4, "stepping on it puts its afflictions on, for 3 turns after this one")
	ok(b.read(v(2), Vector2i(5, 4)).afflicts == [poison], "and once seen, that's known")
	trap.afflicts = []
	trap.turns = 0


func test_stew() -> void:
	ok(b.terrain(STEW) == stew and stew.enter == 4 and stew.worth() == 0, "the magic stew: 3 more to enter than grass, neutral")
	stage(nemes, {v(3): Vector2i(3, 0), v(4): Vector2i(9, 0), v(1): Vector2i(8, 2)})
	v(3).damage(4)
	ok(b.travel(v(3), STEW).size() == 1 and is_equal_approx(v(3).moved, 4.0), "wading in costs 4")
	ok(not v(3).asleep() and v(3).timed.is_empty() and b.cast(v(3), hex, v(1)), "stepping in does nothing yet: it can still act")
	ok(v(3).ground.has(&"moist") and v(3).stat(&"regen") == 0.15, "standing in it: moist, and healing 15%")
	b.end_turn()
	ok(v(3).asleep() and v(3).stat(&"poison") == 0.05 and v(3).stat(&"ap") == 0.1, "ending its turn there: asleep, poisoned, hasted")
	b.end_turn()
	ok(v(3).hp == 6, "its turn starts: heals 1 (15% of 10, rounded down at luck 0), poisoned 1 (5%, rounded up)")
	ok(is_equal_approx(v(3).ap_left(), 11.0 + 1.2 + 1.1), "hasted: +10% general and wis AP, +20% dex AP")
	ok(v(3).asleep() and b.travel(v(3), Vector2i(5, 0)).is_empty(), "it sleeps through this turn")
	b.end_turn()
	b.end_turn()
	ok(v(3).asleep(), "still in the stew as that turn ended: it sleeps on")
	b.move(v(4), Vector2i(4, 1))
	b.end_turn()
	b.end_turn()
	ok(not v(3).asleep() and b.travel(v(3), Vector2i(3, 0)).size() == 1, "an ally ended the turn beside it: awake, and it climbs out")


func test_woken() -> void:
	stage(nemes, {v(3): Vector2i(3, 0), v(4): Vector2i(5, 1), v(1): Vector2i(9, 7)})
	b.travel(v(3), STEW)
	b.end_turn()
	ok(not v(3).asleep() and v(3).stat(&"poison") > 0.0, "an ally beside it as the turn ends: poisoned, but it never drops off")
	b.end_turn()
	ok(b.travel(v(3), Vector2i(3, 0)).size() == 1, "so it acts on its next turn")


func test_passing_through() -> void:
	stage(nemes, {v(3): Vector2i(3, 0), v(1): Vector2i(9, 7)})
	v(3).moved = -4.0  # room to wade through
	ok(b.travel(v(3), Vector2i(5, 0)).back() == Vector2i(5, 0), "through the stew and out")
	b.end_turn()
	ok(v(3).timed.is_empty(), "it only acts on whoever ends a turn in it")


func test_sleeping_ai() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(5, 3)})
	v(3).afflict(effect("sleep", 1), 2)
	ok(AI.act(b, v(3)).is_empty() and v(1).hp == 10, "a sleeping unit does nothing on its own (and doesn't hang)")


func test_moist() -> void:
	var siren: Unit = b.get_node("Units/Siren")
	stage(nemes, {siren: Vector2i(5, 3), v(1): Vector2i(9, 7)})
	ok(siren.stat(&"strength") == 8, "Oceanic: weak on dry ground")
	b.move(siren, STEW)
	ok(siren.stat(&"strength") == 12 and siren.paused_on(siren.ground).size() == 1, "moist in the stew: Oceanic's penalties lift")
