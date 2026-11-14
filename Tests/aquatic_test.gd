extends Test

# The aquatic tag (Glossary.TERMS): water is plain going to whoever carries it - a step into any water
# (depth > 0) costs 1 movement, nothing dragging (Battle._cost()) - and it can't be drowned
# (Battle._grip()). The Aquatic property gives it (an Undine, a Pike); so does a pike's shape while a
# Druid holds it (Battle.FORMS' traits count as tags: Unit.has_tag()).

var drown: Skill = load("res://Skills/drown.tres")


func test_aquatic() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	var water: Terrain = load("res://Terrain/water.tres")
	var shallows: Terrain = load("res://Terrain/shallows.tres")
	var plain: Terrain = Battle.PLAIN
	ok(b._cost(v(1), plain, water) == 3.0 and b._cost(v(1), plain, shallows) == 2.0, "water costs most units 3, shallows 2")
	v(1).tags.append(&"aquatic")
	ok(v(1).has_tag(&"aquatic") and b._cost(v(1), plain, water) == 1.0 and b._cost(v(1), plain, shallows) == 1.0, "aquatic: 1 into either")
	var flood: Terrain = b._flood_terrain(4)
	ok(flood.depth == 4 and b._cost(v(1), plain, flood) == 1.0 and b._cost(v(3), plain, flood) > 1.0, "a Flood drags at others, not at it")
	ok(b._cost(v(1), water, plain) == b._cost(v(3), water, plain), "climbing out costs it what it costs anyone")


func test_no_drowning() -> void:
	var siren: Unit = b.get_node("Units/Siren")
	stage(nemes, {siren: Vector2i(1, 1), v(1): Vector2i(2, 1)})
	var c := Vector2i(2, 1)
	v(1).max_hp = 99
	v(1).hp = 99
	v(1).tags.append(&"aquatic")
	siren.strength = 20
	var a := v(1).afflict(drown.effects[0], 0, 1)
	a.lasting = true
	a.skill = drown
	a.by = siren
	b.flood(c, 5, 2, siren)
	ok(b.submerged(v(1)) and b.held_by(v(1)) == a, "held under water")
	b._grip(v(1))
	ok(v(1).hp == 99, "it breathes water: no drowning (%d HP)" % v(1).hp)
