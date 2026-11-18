extends Test

# Facing (docs/plans/facing.md): Unit.facing is set by its steps, by what it aims at and by Shields Up!;
# the cone test Unit.side_of() says front, flank or rear; an attack from the flank or rear carries that tag
# (Battle.hit_tags()), a rear one needs Unit.REAR_EDGE less to hit, Shields Up!'s guard is the front cone, a
# unit that takes a blow in another's place turns to face its attacker, and the AI leans toward the
# tiles that open its target's Defense.

var shields_up: Skill = load("res://Skills/shields_up.tres")
var interject: Skill = load("res://Skills/interject.tres")
var jam: Skill = load("res://Skills/jam.tres")


func test_moves() -> void:
	stage(lancin, {v(1): Vector2i(3, 4), v(3): Vector2i(8, 8)})
	ok(v(1).facing == Vector2.ZERO, "no facing at first")
	b.travel(v(1), Vector2i(4, 4))
	ok(v(1).facing.is_equal_approx(Vector2(1, 0)) and v(1).striding, "a step east: it faces east")
	b.travel(v(1), Vector2i(4, 5))
	ok(v(1).facing.is_equal_approx(Vector2(0, 1)), "a step south")
	b.travel(v(1), Vector2i(2, 5))
	ok(v(1).facing.is_equal_approx(Vector2(-1, 0)), "two west: the last step's way")
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(8, 8)})
	var way := b.travel(v(1), Vector2i(4, 4))
	ok(not way.is_empty() and v(1).facing.is_equal_approx(Vector2(way[-1] - Vector2i(3, 3)).normalized()), "a walk faces start to finish, however it bent (%s)" % [way])


# Whichever came latest wins: a move, then an aim, then a forced move (a push), each turns it.
func test_latest_wins() -> void:
	stage(lancin, {v(1): Vector2i(2, 4), v(3): Vector2i(5, 5)})
	b.travel(v(1), Vector2i(4, 4))
	ok(v(1).facing.is_equal_approx(Vector2(1, 0)), "moved east: east")
	ok(b.cast(v(1), strike, v(3)), "a Strike at the foe")
	ok(v(1).facing.is_equal_approx(Vector2(1, 1).normalized()), "aimed after: that way (%s)" % v(1).facing)
	ok(b.push(v(1), v(3), 1) == 1, "pushed")
	ok(v(1).facing.is_equal_approx(Vector2(-1, -1).normalized()), "forced move after: along the push (%s)" % v(1).facing)
	var kept := v(1).facing
	v(1).turn(Vector2i.ZERO)
	ok(v(1).facing == kept, "a zero vector changes nothing")


func test_attacks() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 4)})
	b.travel(v(1), Vector2i(4, 3))
	v(1).facing = Vector2(-1, 0)
	v(1).striding = true
	ok(b.cast(v(1), strike, v(3)), "a Strike")
	ok(v(1).facing.is_equal_approx(Vector2(1, 1).normalized()) and not v(1).striding, "it turns to face its target, and has stopped striding")
	ok(v(3).facing == Vector2.ZERO, "the one hit doesn't turn")
	v(1).facing = Vector2.ZERO
	b.cast(v(1), strike, v(1))
	ok(v(1).facing == Vector2.ZERO, "a skill on itself turns it nowhere")


func test_cone() -> void:
	stage(lancin, {v(3): Vector2i(5, 5)})
	var u := v(3)
	ok(u.side_of(Vector2i(9, 9)) == &"front", "no facing: front from everywhere")
	u.facing = Vector2(1, 0)
	var want := {Vector2i(6, 5): &"front", Vector2i(6, 6): &"front", Vector2i(6, 4): &"front", Vector2i(9, 7): &"front",
			Vector2i(6, 8): &"flank", Vector2i(5, 6): &"flank", Vector2i(5, 4): &"flank", Vector2i(4, 7): &"flank", Vector2i(4, 3): &"flank",
			Vector2i(4, 6): &"rear", Vector2i(4, 5): &"rear", Vector2i(4, 4): &"rear", Vector2i(1, 5): &"rear", Vector2i(5, 5): &"front"}
	for c: Vector2i in want:
		ok(u.side_of(c) == want[c], "from %s it's %s, read %s" % [c, want[c], u.side_of(c)])
	u.facing = Vector2(0, -1)
	ok(u.side_of(Vector2i(5, 8)) == &"rear" and u.side_of(Vector2i(8, 5)) == &"flank" and u.side_of(Vector2i(5, 2)) == &"front", "turned north: the cone turns")


func test_tags_and_edge() -> void:
	stage(lancin, {v(1): Vector2i(4, 5), v(3): Vector2i(5, 5)})
	v(3).facing = Vector2(1, 0)
	v(3).afflict(effect("defense", 8), 9)  # a hit chance well inside 5-95%
	var front := Battle.hit_tags(v(1), strike, v(3), b)
	ok(&"rear" in front and &"flank" not in front, "from behind: rear (%s)" % [front])
	b.move(v(1), Vector2i(6, 5))
	var from_front := Battle.hit_tags(v(1), strike, v(3), b)
	ok(&"rear" not in from_front and &"flank" not in from_front, "from the front: neither (%s)" % [from_front])
	var p_front := Battle.hit_chance(v(1), strike, v(3), b)
	b.move(v(1), Vector2i(5, 6))
	ok(&"flank" in Battle.hit_tags(v(1), strike, v(3), b) and &"rear" not in Battle.hit_tags(v(1), strike, v(3), b), "from the side: flank")
	ok(is_equal_approx(Battle.hit_chance(v(1), strike, v(3), b), p_front), "a flank has no built-in edge")
	b.move(v(1), Vector2i(4, 5))
	var p_rear := Battle.hit_chance(v(1), strike, v(3), b)
	ok(is_equal_approx(p_rear - p_front, 0.05) and p_front > 0.0 and p_front < 0.95, "from the rear: +1 to hit, 5 points of the d20 (%f, %f)" % [p_front, p_rear])
	ok(v(3).defense([&"rear"] as Array[StringName]) == v(3).defense() - Unit.REAR_EDGE and v(3).defense([&"flank"] as Array[StringName]) == v(3).defense(), "the edge is in Defense, by tag")
	var c := b.cast_of(v(1), strike, v(3), 1, true)
	ok(&"rear" in c.tags, "the cast's tags carry it for behaviours")
	ok(&"rear" not in Battle.hit_tags(v(1), strike, null, b), "a skill with no foe: none")
	ok(&"rear" not in Battle.hit_tags(v(1), strike, v(1), b), "never on itself")


func test_effects_read_the_tag() -> void:
	stage(lancin, {v(1): Vector2i(4, 5), v(3): Vector2i(5, 5)})
	v(3).facing = Vector2(1, 0)
	var plain := Battle.hit_chance(v(1), strike, v(3), b)
	v(3).afflict(effect("defense", 4, [&"rear"] as Array[StringName]), 9)  # a shell on its back
	ok(Battle.hit_chance(v(1), strike, v(3), b) < plain, "an effect tagged rear counts against a rear attack: +4 Defense there, less the edge")
	b.move(v(1), Vector2i(6, 5))
	ok(v(3).defense(Battle.hit_tags(v(1), strike, v(3), b)) == v(3).defense(), "and not against one from the front")
	ok(&"rear" in Glossary.TERMS and &"flank" in Glossary.TERMS and Tags.color(&"rear") != Tags.color(&"flank"), "both are in the Glossary and have colours")


func test_shields_up() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3), v(4): Vector2i(2, 3)})
	v(1).learned.append(slot(shields_up, 2))
	v(1).refresh()
	ok(b.cast_at(v(1), shields_up, Vector2i(6, 3)), "Shields Up! toward the east")
	ok(v(1).guard and v(1).facing.is_equal_approx(Vector2(1, 0)), "it sets the facing")
	ok(v(1).guarding(Vector2i(6, 3)) and v(1).guarding(Vector2i(5, 4)) and not v(1).guarding(Vector2i(4, 4)) and not v(1).guarding(Vector2i(2, 3)),
			"the guard is the front cone: where side_of() says front")
	for x in range(0, 10):
		for y in range(0, 7):
			ok(v(1).guarding(Vector2i(x, y)) == (v(1).side_of(Vector2i(x, y)) == &"front" and Vector2i(x, y) != v(1).cell), "guarding(%d,%d) reads the cone" % [x, y])
	v(1).facing = Vector2(-1, 0)
	ok(v(1).guarding(Vector2i(2, 3)) and not v(1).guarding(Vector2i(6, 3)), "the shield turns with it")
	v(1).guard = false
	ok(not v(1).guarding(Vector2i(2, 3)), "down, it blocks nothing")


func test_interjector_stays() -> void:
	v(2).learned.append(slot(interject, 1))
	v(3).learned.append(slot(jam))
	v(3).dexterity = 40
	v(3).strength = 40
	v(2).afflict(load("res://Tests/interject_test.gd").keen(), 9)
	stage(nemes, {v(1): Vector2i(4, 3), v(2): Vector2i(4, 4), v(3): Vector2i(5, 3)})
	for i in [1, 2, 3]:
		v(i).refresh()
		soak(v(i), 300)
	v(2).facing = Vector2(0, 1)  # looking south, the attacker north-east of it
	ok(b.cast(v(3), jam, v(1)) and v(2).hp < 300, "it takes the hit")
	ok(v(2).facing == Vector2(0, 1), "and doesn't turn (a block is no move or aim of its own)")
	ok(v(1).facing == Vector2.ZERO, "the one it covered for doesn't turn")


func test_line_up() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(1, 3), v(3): Vector2i(6, 1), v(4): Vector2i(7, 7)})
	for i in [1, 2, 3, 4]:
		b._line_up(v(i))
	ok(v(1).facing.is_equal_approx(Vector2(5, 0).normalized()) and v(3).facing.is_equal_approx(Vector2(-1, 0)), "each faces its nearest foe: %s %s" % [v(1).facing, v(3).facing])
	v(1).facing = Vector2(0, 1)
	b._line_up(v(1))
	ok(v(1).facing == Vector2(0, 1), "one that already faces a way keeps it")


func test_ai() -> void:
	stage(nemes, {v(1): Vector2i(5, 7), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	v(3).facing = Vector2(-1, -1).normalized()
	ok(AI._opening(v(3), Vector2i(6, 4)) == Unit.REAR_EDGE and AI._opening(v(3), Vector2i(4, 4)) == 0 and AI._opening(v(3), Vector2i(6, 2)) == 0, "the opening a tile gives: the rear's edge, no more")
	var reads := {v(3): b.read(v(1), v(3))}
	ok(AI._approach(b, v(1), v(3), reads) == Vector2i(6, 4), "of two tiles as far off, it takes the one behind its target (%s)" % AI._approach(b, v(1), v(3), reads))
	v(3).facing = Vector2(1, -1).normalized()
	ok(AI._approach(b, v(1), v(3), reads) == Vector2i(4, 4), "the other way, the other tile")
	v(3).facing = Vector2.ZERO
	ok(AI._approach(b, v(1), v(3), reads) == Vector2i(4, 4), "no facing: the plain pick")
