extends Test

# Resuscitate (Skills/resuscitate.tres, Behaviours/resuscitate.gd), Specialist tier 4: on a Downed ally
# beside it only; it comes back up at once with rank x 5% of its max HP, through the heal every recovery
# passes (Unit.heal(), being_healed), and is saved (Battle.rescued()).

var resuscitate: Skill = load("res://Skills/resuscitate.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")


func test_resuscitate() -> void:
	v(1).learned.append(slot(resuscitate, 2))
	v(2).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	v(2).max_hp = 100
	v(2).hp = 100
	ok(not b.cast(v(1), resuscitate, v(2)), "not on a standing ally")
	v(2).damage(100)
	v(2).damage(30)
	ok(v(2).dbno != null and v(2).hp == -30, "Downed, 30 below 0 (%d)" % v(2).hp)
	var heard := []
	v(2).being_healed.connect(func(u: Unit, got: Dictionary): heard.append(got.hp))
	ok(b.cast(v(1), resuscitate, v(2)), "used on it")
	ok(v(2).hp == 10 and v(2).dbno == null and v(2).paid_rise, "back up with 10%% of its max HP at rank II, saved (%d)" % v(2).hp)
	ok(heard == [40], "through the one heal every recovery passes (%s)" % [heard])
	var tree: SkillTab = load("res://Trees/general_specialist.tres")
	ok(tree.offers(resuscitate) and tree.roots[0].branch(resuscitate).tier == 4, "Specialist, tier 4")
	ok(Glossary.plain(resuscitate.markup(2)).contains("10%"), "described: %s" % Glossary.plain(resuscitate.markup(2)))


func test_reach() -> void:
	v(1).learned.append(slot(resuscitate, 1))
	v(2).learned.append(slot(tenacity, 3))
	v(3).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(7, 3), v(3): Vector2i(4, 4)})
	v(1).refresh()
	v(2).damage(999)
	v(3).damage(999)
	ok(not b.cast(v(1), resuscitate, v(2)), "not on one out of reach")
	ok(v(3).dbno != null and not b.cast(v(1), resuscitate, v(3)), "nor on a Downed foe")
