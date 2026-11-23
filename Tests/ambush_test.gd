extends Test

# The ambush (Battle.ambushes(), the ambush hit tag): the first attack roll out of concealment since its
# side's turn began (Unit.ambush_rolls, counted by Battle.roll_attack(), a miss too); later rolls aren't,
# but for Ambush Fusillade's rank more (Effect stat fusillade). Ambush (Skills/ambush.tres): a blow with a
# contingency test=ambush (Requirement): advantage as one. Sally: + 20% damage a rank on one. The AI's
# forecast prices it (AI.score() reads hit_tags() and the contingency).

var ambush: Skill = load("res://Skills/ambush.tres")
var sally: Skill = load("res://Skills/sally.tres")
var fusillade: Skill = load("res://Skills/ambush_fusillade.tres")


func setup(skills: Array) -> void:
	for pair in skills:
		v(1).learned.append(slot(pair[0], pair[1]))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).dexterity = 14
	v(1).refresh()
	soak(v(3), 900)
	v(1).afflict(effect("concealment", 9), 9)  # deep: still concealed after its blows erode it


func edge(s: Skill) -> int:
	return Battle.edge_of(s, b.cast_of(v(1), s, v(3), 1, true)) + int(b.requirement(v(1), s, v(3), 1)[2])


func test_first_roll_only() -> void:
	setup([[ambush, 1], [sally, 3]])
	ok(b.ambushes(v(1), v(3)) and &"ambush" in Battle.hit_tags(v(1), ambush, v(3), b), "concealed, no roll yet: an ambush")
	ok(edge(ambush) == 1, "Ambush: advantage as one")
	ok(is_equal_approx(v(1).stat(&"damage", Battle.hit_tags(v(1), ambush, v(3), b)), 0.6) and v(1).stat(&"damage") == 0.0,
			"Sally III: + 60% damage on an ambush, none otherwise")
	var p := AI.score(v(1), ambush, b.read(v(1), v(3)), b, v(3))
	b.cast(v(1), ambush, v(3))
	ok(v(1).ambush_rolls == 1 and b.read(v(3), v(1)).concealed, "one roll spent it, still concealed")
	ok(not b.ambushes(v(1), v(3)) and edge(ambush) == 0 and v(1).stat(&"damage", Battle.hit_tags(v(1), ambush, v(3), b)) == 0.0,
			"the next blow is no ambush: no advantage, no Sally")
	ok(AI.score(v(1), ambush, b.read(v(1), v(3)), b, v(3)) < p, "the AI prices the ambush, then its loss")
	b.end_turn()
	b.end_turn()
	ok(v(1).ambush_rolls == 0 and b.ambushes(v(1), v(3)), "its side's turn again, still hidden: a fresh one")


func test_fusillade() -> void:
	setup([[strike, 3], [fusillade, 1]])
	v(3).afflict(effect("defense", -40), 9)  # its blows land: the chain runs all 3
	b.cast(v(1), strike, v(3))
	ok(v(1).ambush_rolls == 2, "Fusillade I: the first roll and one more ambush, the third doesn't (%d)" % v(1).ambush_rolls)
	ok(not b.ambushes(v(1), v(3)), "spent")
	v(1).learned.clear()
	v(1).learned.append(slot(fusillade, 3))
	v(1).refresh()
	ok(b.ambushes(v(1), v(3)), "Fusillade III: two rolls in, the next still ambushes, seen or not")


func test_who() -> void:
	var slayer: SkillRoot = load("res://Trees/slayer.tres")
	ok(slayer.branches.any(func(x: Branch): return x.skill == sally) and slayer.branches.any(func(x: Branch): return x.skill == fusillade), "on the Slayer tree")
	ok(sally in (load("res://Roles/rogue.tres") as Role).options, "the Rogue's to take")
	ok([ambush, sally, fusillade].all(func(s: Skill): return not s.ai and s.stub == ""), "the user's, built")
