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
	v(1).learned.append(slot(jam, 1)); v(1).sync_bar()
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
	duel(jam, 1)
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


# Forced unshape (docs/plans/unshape.md): Battle.unshape() and the Effect stat unshape end a beast's form
# and a mist, neutralized as &"unshaped"; turning back by choice (Beastshape) is not neutralized. A Poach
# whose blow unshapes its target is told (felled) like any neutralizing blow.
func test_unshaped() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var got := []
	b.neutralized.connect(func(u: Unit, _by: Unit, how: StringName): got.append([u, how]))
	ok(not b.unshape(v(3), v(1)) and got.is_empty(), "in no shape: nothing ended, nothing told")
	v(3).shape(&"rabbit", &"", 1, 3)
	ok(b.unshape(v(3), v(1)) and v(3).form == &"" and got == [[v(3), &"unshaped"]], "a form ended by force: told once (%s)" % [got])
	got.clear()
	var mist := b.summon(load("res://Scenes/undine.tscn"), nemes, Vector2i(6, 4))
	mist.refresh()
	mist.toggle(load("res://Skills/vaporize.tres"))
	ok(mist.stat(&"mist") > 0.0, "a mist")
	ok(b.unshape(mist, v(1)) and mist.stat(&"mist") == 0.0 and got == [[mist, &"unshaped"]], "a mist ended by force too")
	got.clear()
	v(3).shape(&"rabbit", &"", 1, 3)
	var e := effect("unshape", 1.0)
	b.drive(v(3), e, v(3).afflict(e, 2))
	ok(v(3).form == &"" and e not in v(3).timed and got.size() == 1, "the effect stat does it and stays on nothing")
	got.clear()
	v(1).learned.append(slot(load("res://Skills/beastshape.tres"), 1)); v(1).sync_bar()
	v(1).refresh()
	v(1).shape(&"rabbit", &"", 1, 3)
	b.cast(v(1), load("res://Skills/beastshape.tres"), v(1))
	ok(v(1).form == &"" and got.is_empty(), "turning back by choice is not neutralized")


func test_unshaped_poach() -> void:
	var poach: Skill = (load("res://Skills/poach.tres") as Skill).duplicate()
	poach.effects = poach.effects.duplicate()
	poach.effects.append(effect("unshape", 1.0))
	v(1).learned.append(slot(poach, 1)); v(1).sync_bar()
	v(1).dexterity = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	soak(v(3), 300)
	v(3).shape(&"rabbit", &"", 1, 3)
	v(1).max_energy = 40
	v(1).energy = 5
	var before := v(1).energy
	ok(b.cast(v(1), poach, v(3)), "used")
	ok(v(3).form == &"" and v(1).energy > before - v(1).price(poach) + floori(v(1).price(poach) * 0.5), "its blow unshaped the foe: Poach regains (%d)" % v(1).energy)
