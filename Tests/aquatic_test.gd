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
	soak(v(1), 99)
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


# The Pike (Scenes/pike.tscn) carries the Aquatic property: water costs it 1, and it reads at its level.
func test_pike() -> void:
	var side: Faction = load("res://Factions/unaligned.tres")
	var u: Unit = b.summon(load("res://Scenes/pike.tscn"), side, Vector2i(5, 3))
	stage(side, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 3)})
	b.move(u, Vector2i(5, 3))
	ok(u.has_tag(&"aquatic") and b._cost(u, Battle.PLAIN, load("res://Terrain/water.tres")) == 1.0, "a pike: water costs it 1")
	ok(b.read(sharp(v(1)), u).level == u.level, "read with recon: its level (%d)" % u.level)


# Seaborn, the Siren's innate trait: +2 str/dex/con only on ground tagged water (Effect.only_on, read by
# Unit.stat() - the generic terrain condition beside unless_on), the aquatic tag, 2 movement, a claimed boon.
func test_seaborn() -> void:
	var siren: Unit = b.get_node("Units/Siren")
	stage(nemes, {siren: Vector2i(5, 3), v(1): Vector2i(9, 7)})
	var seaborn: Skill = load("res://Skills/seaborn.tres")
	ok(&"trait" in seaborn.tags and siren.has_tag(&"aquatic") and siren.movement == 2, "a trait: aquatic, 2 movement")
	siren.ground = [] as Array[StringName]
	var dry := siren.stat(&"strength")
	siren.ground = [&"water"] as Array[StringName]
	ok(siren.stat(&"strength") == dry + 6 and siren.stat(&"dexterity") == siren.dexterity + 2 and siren.stat(&"constitution") == siren.constitution + 2,
			"on water: +2 str, dex and con, and Oceanic's -4 lifts (%d vs %d dry)" % [siren.stat(&"strength"), dry])
	siren.ground = [&"wet"] as Array[StringName]
	ok(siren.stat(&"strength") == dry + 4, "wet but not water: only Oceanic's lift")
	ok(b._cost(siren, Battle.PLAIN, load("res://Terrain/water.tres")) == 1.0, "water costs it 1 to enter")
	stage(nemes, {siren: Vector2i(5, 3), v(1): Vector2i(5, 4)})
	var fooled := b.read(v(1), siren)
	ok(fooled.deceived and fooled.boon == "Something extremely beneficial", "the fooled hear of something extremely beneficial (deceived %s, '%s')" % [fooled.deceived, fooled.boon])
	v(1).afflict(effect("recon", 3), 9)
	ok(b.read(v(1), siren).boon == "", "no boasting to one who sees through it")


# Rake: more damage (betrayal, tags slash) to a target that trusts its attacker. Same seed, so the same rolls:
# the fooled target takes double (to a rounding of glances) what one that sees through the Siren does.
func test_rake_trusting() -> void:
	var siren: Unit = b.get_node("Units/Siren")
	var rake: Skill = load("res://Skills/rake.tres")
	stage(nemes, {siren: Vector2i(5, 3), v(1): Vector2i(5, 4)})
	siren.strength = 40  # it hits
	var raked := func() -> int:
		b.rng.seed = 11
		soak(v(1))
		for i in 3:
			siren.refresh()
			b.cast(siren, rake, v(1))
		return 999 - v(1).hp
	var fooled: int = raked.call()
	v(1).afflict(effect("recon", 3), 9)
	ok(not b.read(v(1), siren).deceived, "it sees through the Siren")
	var wary: int = raked.call()
	ok(wary > 0 and absi(fooled - 2 * wary) <= 3, "fooled: double what it takes once it knows, give or take a rounding (%d vs %d)" % [fooled, wary])
