extends Test

# The generic hooks the Slayer skills stand on (docs/plans/slayer.md): neutralized, the targeting
# memory (Battle.aimed()), ambush, Unit.refund(), tow on any grip.

var jam: Skill = load("res://Skills/jam.tres")
var drown: Skill = load("res://Skills/drown.tres")


func test_neutralized() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var got := []
	b.neutralized.connect(func(u: Unit, by: Unit, how: StringName): got.append(how))
	v(3).last_hit_by = v(1)
	v(3).hp = 0
	ok(not got.is_empty() and got[0] in [&"downed", &"down", &"killed"], "taken out: told once (%s)" % [got])


func test_aimed() -> void:
	v(1).learned.append(slot(jam, 1))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	v(1).refresh()
	ok(b.aimed(v(1), v(3)) == 0, "nothing yet")
	b.cast(v(1), jam, v(3))
	b.cast(v(1), jam, v(3))
	ok(b.aimed(v(1), v(3)) == 2 and b.aimed(v(1), v(4)) == 0 and b.aimed(v(3), v(1)) == 0, "counted by caster and target, hit or miss")


func test_ambush_tag() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(Glossary.TERMS.has(&"ambush"), "a Glossary term")
	v(1).afflict(effect("concealment", 4), 3)
	ok(&"ambush" in Battle.hit_tags(v(1), jam, v(3), b), "an ambushing hit carries the tag")
	ok(&"ambush" not in Battle.hit_tags(v(1), jam), "not without a foe to ask")
	v(1).afflict(effect("damage", 1.0, [&"ambush"] as Array[StringName]), 3)
	ok(v(1).stat(&"damage", Battle.hit_tags(v(1), jam, v(3), b)) >= 1.0, "so an effect tagged ambush counts on it")


func test_refund() -> void:
	v(1).learned.append(slot(jam, 1))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(1).energy = 5
	v(1).endurance = 2
	var ap := v(1).ap_left()
	v(1).pay_for(jam)
	ok(v(1).refund(jam, 1.0) == 1 and v(1).energy == 5 and is_equal_approx(v(1).ap_left(), ap), "all of it back")
	ok(v(1).endurance == 2, "a refund isn't a recovery: no RE spent")


func test_tow_any_grip() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	var a := v(3).afflict(drown.effects[0], 3)
	a.lasting = true
	a.skill = drown
	a.by = v(1)
	v(3).afflict(effect("tow", 1.0), 3)
	b.travel(v(1), Vector2i(4, 4))
	ok(v(3).cell == Vector2i(5, 4), "any grip with tow tows (%s)" % v(3).cell)
