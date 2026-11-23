extends Test

# Thesis of Theseus (Skills/thesis_of_theseus.tres, Behaviours/theseus.gd): a tile cast designs and summons a Monster
# of the path chosen (Battle.cast_at()'s chose, Behaviour.choices()) at a level of its rank, its traits free, by the
# summon rules (kept AP, the soft cap); with none chosen (the AI) the path its side holds fewest of.

var theseus: Skill = load("res://Skills/thesis_of_theseus.tres")


func monsters(by: Unit) -> Array:
	return b.members(lancin).filter(func(u: Unit): return u.raised_by == by)


func test_theseus() -> void:
	var caster := v(1)
	caster.learned.append(slot(theseus, 3)); caster.sync_bar()
	roomy(caster)
	caster.intelligence = 14  # soft cap 3 + 2
	stage(lancin, {caster: Vector2i(4, 3), v(3): Vector2i(20, 3)})
	var paths := Unit.monster_paths()
	ok(", ".join(b.choices_of(caster, theseus)) == "Starmen, Sirens, Skeletons", "its choices: the paths (%s)" % [b.choices_of(caster, theseus)])
	for p in ["Starmen", "Sirens"]:
		caster.ap[0].amount = 99.0; caster.max_energy = 99; caster.energy = 99
		ok(b.cast_at(caster, theseus, Vector2i(6, 3), true, p), "cast, %s chosen" % p)
		var m: Unit = monsters(caster)[-1]
		ok(m.role.name == "Monster" and m.level == 3 and m.faction == lancin and m.picked.size() == 1 and "Path/%s" % p in m.picked
				and (paths[p] as Array).all(func(s: Skill): return m.rank(s) >= 1) and m.skill_points == 0, "%s: a level 3 (rank) Monster on its side, its traits held, its 2 points spent (take_path)" % p)
		ok(m.ap_left() <= 3 + 2 + 0.001, "it keeps no more than rank + int mod AP (%s)" % m.ap_left())
	caster.ap[0].amount = 99.0; caster.max_energy = 99; caster.energy = 99
	ok(b.cast_at(caster, theseus, Vector2i(6, 4)), "cast with no path chosen")
	ok("Path/Skeletons" in monsters(caster)[-1].picked, "it takes the path its side lacks: Skeletons (%s)" % [monsters(caster)[-1].picked])
	ok(monsters(caster).all(func(u: Unit): return not u.disturbed()), "3 in hand, under the cap of 5")
	caster.intelligence = 8  # cap 3 - 1
	caster.ap[0].amount = 99.0; caster.max_energy = 99; caster.energy = 99
	ok(b.cast_at(caster, theseus, Vector2i(6, 2), true, "Sirens"), "a fourth")
	ok(monsters(caster).filter(func(u: Unit): return not u.disturbed()).size() == 2, "past the soft cap (2): the rest Disturbed")
	# the AI raises one, with a foe in sight
	var ai := v(2)
	ai.learned.append(slot(theseus, 1)); ai.sync_bar()
	roomy(ai)
	ai.intelligence = 12
	ai.ap[0].amount = 99.0; ai.max_energy = 99; ai.energy = 99
	b.move(ai, Vector2i(4, 8))
	b.move(v(3), Vector2i(10, 8))
	var log: Array[String] = []
	ok(AI._summon(b, ai, AI._reads(b, ai), log) and monsters(ai).size() == 1 and monsters(ai)[0].level == 1, "the AI raises a level 1 Monster (%s)" % [log])
	ok(theseus.behaviours[0].describe(2).contains("level {r:2}"), "it says the level: %s" % theseus.behaviours[0].describe(2))
