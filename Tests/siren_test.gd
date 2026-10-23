extends Test

# The Siren's hunt: Sing's lure, Rake's crit on the trusting, Drown (grab, drag, drown), grapples,
# swimming, and Detective. She waits on a wet rock at (8,6); water at (7,6) (9,6) (6,7) (7,7) (9,7).

var sing: Skill = load("res://Skills/sing.tres")
var rake: Skill = load("res://Skills/rake.tres")
var drown: Skill = load("res://Skills/drown.tres")
var detective: Skill = load("res://Skills/detective.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func test_lure_fooled() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
	v(1).wisdom = -20  # fails every check
	ok(b.read(v(1), siren()).deceived, "it's fooled")
	ok(b.cast(siren(), sing, v(1)), "she sings to it")
	ok(v(1).cell == Vector2i(7, 5), "it walks right up beside her")
	ok(siren().moved == 2.0 and siren().energy == 8, "she pays with all her movement (and the song's energy)")
	ok(v(1).moved == 0.0 and not v(1).acted and not v(1).provoked and v(1).suspicion.is_empty(), "it spends nothing, and thinks nothing of it")


func test_lure_resisted() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
	v(1).wisdom = 40
	b.cast(siren(), sing, v(1))
	ok(v(1).cell == Vector2i(5, 5) and not b.read(v(1), siren()).deceived, "it passes: it doesn't come, and it sees her for what she is")


func test_lure_ally() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(3): Vector2i(5, 4), v(1): Vector2i(0, 0)})
	v(3).wisdom = 40
	ok(b.cast(siren(), sing, v(3)) and v(3).cell == Vector2i(7, 5), "allies come when called, no check")


func test_lure_limits() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
	v(1).wisdom = -20
	v(1).movement = 1
	b.cast(siren(), sing, v(1))
	ok(v(1).cell == Vector2i(6, 5), "it only walks as far as its own movement")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
	siren().moved = 2
	var energy := siren().energy
	ok(not b.cast(siren(), sing, v(1)) and siren().energy == energy and v(1).cell == Vector2i(5, 5), "no movement left to pay with: no song at all")


func test_rake_crits_the_trusting() -> void:
	v(1).learned = []  # no Favour: luck 0, no mitigation
	v(1).max_hp = 100
	var trusting := {}
	var wary := {}
	for seed in 40:
		b.rng.seed = seed
		stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5)})
		v(1).heal(100)
		v(1).suspicion.clear()
		v(1).timed.clear()
		b.cast(siren(), rake, v(1))
		trusting[100 - v(1).hp] = true
		v(1).heal(100)
		v(1).suspicion.clear()
		v(1).afflict(effect("recon", 3), 9)
		siren().refresh()
		b.cast(siren(), rake, v(1))
		wary[100 - v(1).hp] = true
	ok(trusting.keys().all(func(d): return d in [4, 6, 8, 10]) and trusting.size() >= 3, "trusting: 2 x (1d4 + 1) %s" % [trusting.keys()])
	ok(wary.keys().all(func(d): return d >= 2 and d <= 5) and wary.size() >= 3, "seeing her for what she is: 1d4 + 1 %s" % [wary.keys()])


func test_drown() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5)})
	siren().strength = 40  # never misses the grab
	v(1).max_hp = 100
	v(1).heal(100)
	ok(b.cast(siren(), drown, v(1)), "she grabs it")
	ok(v(1).grappler == siren() and v(1).cell == Vector2i(7, 6), "grappled, and dragged into the water")
	ok(siren().cell == Vector2i(7, 7) and siren().moved == 2.0, "she follows it in (1 to drag, 1 to dive)")
	ok(siren().stat(&"strength") == 42, "submerged: +2 strength")
	ok(v(1).hp >= 100 - 28 and v(1).hp <= 100 - 17, "drowning: 1d12 + str mod 16 (%d)" % (100 - v(1).hp))
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5)})
	v(1).heal(100)
	v(1).tags.append(&"aquatic")
	b.cast(siren(), drown, v(1))
	ok(v(1).hp >= 100 - 20 and v(1).hp <= 100 - 17, "it breathes underwater: 1d4 + 16 (%d)" % (100 - v(1).hp))


func test_drown_awareness() -> void:
	siren().strength = 30  # mod 10: d20 + 10 is 11-30
	v(1).strength = 60  # mod 25: DC 35 if it knows what she is
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5)})
	b.cast(siren(), drown, v(1))
	ok(v(1).grappler == siren(), "fooled, it doesn't brace: DC 10")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5)})
	v(1).grappler = null
	v(1).afflict(effect("recon", 3), 9)
	b.cast(siren(), drown, v(1))
	ok(v(1).grappler == null and v(1).cell == Vector2i(7, 5), "aware, its strength counts: DC 35, no grab")


func test_grapple() -> void:
	stage(lancin, {v(1): Vector2i(7, 5), siren(): Vector2i(8, 6)})
	v(1).grappler = siren()
	v(1).strength = -20
	ok(b.travel(v(1), Vector2i(3, 5)).is_empty() and v(1).moved == 1.0 and v(1).grappler == siren(), "fails to break free: stuck, and it cost a movement (her str mod 1, min 1)")
	v(1).strength = 40
	ok(not b.travel(v(1), Vector2i(3, 5)).is_empty() and v(1).grappler == null, "breaks free and moves off")
	stage(lancin, {v(1): Vector2i(7, 5), siren(): Vector2i(8, 6)})
	v(1).grappler = siren()
	b.move(siren(), Vector2i(9, 7))
	v(1).strength = -20
	ok(not b.travel(v(1), Vector2i(3, 5)).is_empty() and v(1).grappler == null, "she let go (not beside it): no check")


func test_swimming() -> void:
	ok(b.step(siren(), Vector2i(8, 6), Vector2i(7, 6)) == 1.0 and b.step(v(1), Vector2i(8, 6), Vector2i(7, 6)) == 3.0, "water costs her 1 (Oceanic), others 3")
	b.move(siren(), Vector2i(7, 6))
	ok(siren().stat(&"strength") == 14 and siren().stat(&"intelligence") == 12, "submerged: +2 physical")


func test_detective() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(3): Vector2i(2, 1)})
	ok(Investigation.lead(b, v(1)) == null, "nothing concealed nearby: nothing to look into")
	v(1).learned.append(slot(detective, 2))
	ok(Investigation.lead(b, v(1)) != null, "a Detective observes the unconcealed too")
	v(1).wisdom = 40
	Investigation.run(b, v(1), v(3))
	var r := b.read(v(1), v(3))
	ok(v(1).marks.get(v(3), 0) == 2 and r.net >= 2 and r.level == 1, "passing grants rank 2 recon on that unit: its level shows")
	Investigation.run(b, v(1), Vector2i(5, 2))
	ok(b.read(v(1), Vector2i(5, 2)).worth == 1, "and on tiles: the shrine reads as good ground")


func test_unmade_hunt() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5), v(2): Vector2i(0, 0)})
	siren().strength = 40
	v(1).wisdom = -20
	v(1).max_hp = 100
	v(1).heal(100)
	AI.act(b, siren())
	ok(v(1).cell == Vector2i(7, 5) and v(1).hp == 100, "turn one: she lures it over")
	b.end_turn()
	b.end_turn()
	AI.act(b, siren())
	ok(v(1).grappler == siren() and &"water" in b.terrain(v(1).cell).tags and v(1).hp < 100, "turn two: it's beside her and water's near - drowned")


func test_lure_details() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
	ok(not b.cast(siren(), sing, siren()), "she can't sing to herself")
	v(1).wisdom = 14  # mod +2: fails DC 14 often, would pass an arrival check (DC 11) often
	var lured := 0
	for seed in 30:
		b.rng.seed = seed
		stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 5)})
		siren().energy = 10
		v(1).suspicion.clear()
		b.cast(siren(), sing, v(1))
		if v(1).cell == Vector2i(7, 5):
			lured += 1
			ok(v(1).suspicion.is_empty(), "the lured think nothing of it (no arrival check)")
	ok(lured > 5, "some were lured (%d/30)" % lured)


func test_drown_in_water() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 6)})
	siren().strength = 40
	v(1).max_hp = 100
	v(1).heal(100)
	b.cast(siren(), drown, v(1))
	ok(v(1).cell == Vector2i(7, 6) and v(1).hp < 100, "already in the water: held under where it is")


func test_drag_keeps_hold() -> void:
	stage(nemes, {siren(): Vector2i(5, 5), v(1): Vector2i(6, 5)})
	siren().strength = 40
	v(1).max_hp = 100
	v(1).heal(100)
	b.cast(siren(), drown, v(1))
	ok(&"water" in v(1).ground and Battle.steps(siren().cell, v(1).cell) <= 1 and v(1).grappler == siren(), "dragged into water, and she keeps hold (still beside it)")
