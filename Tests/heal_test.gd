extends Test

# Heals: First Aid (Specialist, tier 1) and Renew (Divinity, tier 1; the Adventurer's Magic root) mend
# an ally (Battle.mend()), clearing wounds (Effect.wound) up to their rank - Renew's rank x rank - as
# regen does each turn at its rank; First Aid heals rank more for each wound it treats. Snare's trap
# leaves a Bleeding wound. Support for a foe the caster takes for an ally lands. Healers pick whom to
# heal by how they tend (AI.want()): benevolent, pragmatic or loyal, each favouring commanders a little.

var first_aid: Skill = load("res://Skills/first_aid.tres")
var renew: Skill = load("res://Skills/renew.tres")
var snare: Skill = load("res://Skills/snare.tres")


func medic(u: Unit, s: Skill, r := 1) -> void:
	u.learned.append(slot(s, r))
	u.refresh()


func wound(n := 1) -> Effect:
	var e := effect("poison", 0.1)
	e.wound = true
	e.name = "Bleeding %d" % n
	return e


func test_first_aid() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(1).dexterity = 14
	v(1).wisdom = 12
	medic(v(1), first_aid)
	v(2).hp = 3
	ok(first_aid.healing(v(1)) == 3 and b.cast(v(1), first_aid, v(2)) and v(2).hp == 6, "(dex mod 2 + wis mod 1) / 2, rounded up while lucky (Favour), + 1: 3 HP")
	ok("Heals (dex mod + wis mod) / 2 + 1 HP, at least 1" in first_aid.describe(1) and "Clears wounds up to rank 1" in first_aid.describe(1),
			"described (%s)" % first_aid.describe(1))
	v(1).dexterity = 4
	v(1).wisdom = 4
	ok(first_aid.healing(v(1)) == 1, "at least 1, however clumsy")
	var cut := wound()
	var deep := wound(2)
	v(2).afflict(cut, 5, 1)
	v(2).afflict(deep, 5, 2)
	v(1).refresh()
	v(2).hp = 1
	ok(b.cast(v(1), first_aid, v(2)) and cut not in v(2).timed and deep in v(2).timed, "rank I clears a rank 1 wound, not a rank 2 one")
	ok(v(2).hp == 3, "and heals 1 more for the wound it treated: 1 + 1 (%d)" % v(2).hp)
	var cuts := [wound(1), wound(2)]
	for i in 2:
		v(2).afflict(cuts[i], 5, i + 1)
	v(1).learned[-1].rank = 2
	v(1).refresh()
	v(2).hp = 1
	ok(b.cast(v(1), first_aid, v(2)) and v(2).hp == 1 + 1 + 2 * 3 and v(2).timed.keys().all(func(e: Effect): return not e.wound),
			"rank II: 2 more for each of the three wounds it treats (%d)" % v(2).hp)
	ok("+2 HP for each wound it clears" in first_aid.describe(2), "described (%s)" % first_aid.describe(2))
	ok(&"specialist" in first_aid.tags and &"physical" in first_aid.tags, "physical, specialist")
	for path in ["res://Roles/adventurer.tres", "res://Roles/rogue.tres", "res://Roles/bard.tres"]:
		ok((load(path) as Role).tier(first_aid) == 1, "%s: First Aid, tier 1" % path.get_file())


func test_renew() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(1).wisdom = 14
	medic(v(1), renew, 2)
	v(2).hp = 2
	v(2).pay(5.0, &"skill")
	var ap := v(2).ap_left()
	var wounds := [wound(1), wound(4), wound(5)]
	for i in 3:
		v(2).afflict(wounds[i], 5, [1, 4, 5][i])
	ok(b.cast(v(1), renew, v(2)) and v(2).hp == 4, "wis mod (2) HP")
	ok(v(2).ap_left() == ap + 2.0, "and rank (2) AP back")
	ok(wounds[0] not in v(2).timed and wounds[1] not in v(2).timed and wounds[2] in v(2).timed, "Renew II clears wounds up to rank 4 (rank x rank)")
	v(1).wisdom = 6
	ok(renew.healing(v(1)) == 1, "at least 1 HP")
	ok((load("res://Roles/paladin.tres") as Role).tier(renew) == 1, "the Paladin's: tier 1")
	var adventurer: Role = load("res://Roles/adventurer.tres")
	ok(adventurer.tier(renew) == 1 and adventurer.roots[0].branches.any(func(x: Branch): return x.skill == renew),
			"and the Adventurer's, in the Magic root (the caster tree): tier 1")
	ok("Gives back 2 AP" in renew.describe(2) and "Clears wounds up to rank 4 (rank x rank)" in renew.describe(2), "described (%s)" % renew.describe(2))


func test_regen_clears() -> void:
	var regen := effect("regen", 0.1)
	var cut := wound()
	var deep := wound(3)
	v(2).afflict(regen, 5, 2)
	v(2).afflict(cut, 5, 2)
	v(2).afflict(deep, 5, 3)
	b._mend(v(2))
	ok(cut not in v(2).timed and deep in v(2).timed, "regen at rank 2 heals away a rank 2 wound, not a rank 3 one")



# Snare's trap leaves a Bleeding wound: 1d4 + the setter's dex mod a turn, for its rank + dex mod turns.
func test_snare_bleeds() -> void:
	stage(nemes, {v(3): Vector2i(3, 2), v(1): Vector2i(1, 2), v(2): Vector2i(2, 3), v(4): Vector2i(8, 5)})
	v(3).dexterity = 14
	v(3).learned.append(slot(snare, 2))
	v(3).refresh()
	ok(b.cast_at(v(3), snare, Vector2i(2, 2)), "a snare, laid")
	b.end_turn()
	v(1).max_hp = 99
	v(1).hp = 99
	b.travel(v(1), Vector2i(2, 2))
	var bleed: Effect = snare.lays.wounds[0]
	ok(bleed in v(1).timed and v(1).timed[bleed].rank == 2 and v(1).timed[bleed].turns == 2 + 2 + 1,
			"sprung: Bleeding, at the snare's rank, for rank (2) + dex mod (2) turns (+ this one)")
	ok(bleed.wound and bleed.label() == "Bleeding" and bleed.value() == "1d4 + dex mod HP as each of its turns ends; a wound, healed away" and v(1).timed[bleed].by == v(3),
			"a wound, its setter's (%s)" % bleed.describe())
	var hp := v(1).hp
	b.end_turn()
	ok(v(1).hp == hp, "not as the turn it was put on ends")
	b.end_turn()
	ok(v(1).hp == hp, "nor on the other side's turn")
	b.end_turn()
	ok(v(1).hp <= hp - 1 - 2 and v(1).hp >= hp - 4 - 2, "as its side's next turn ends, it bleeds 1d4 + the setter's dex mod (2): %d" % (hp - v(1).hp))
	b.end_turn()
	medic(v(2), first_aid, 2)
	ok(b.cast(v(2), first_aid, v(1)) and bleed not in v(1).timed, "First Aid II binds it")


func test_fooled_support() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(2, 2)})
	medic(v(1), first_aid)
	v(3).hp = 2
	ok(not b.cast(v(1), first_aid, v(3)), "a foe it knows for one: no")
	v(3).afflict(effect("persona", 2), 9)
	v(3).afflict(effect("trickery", 5), 9)
	v(3).stance = "Friendly"
	ok(b.read(v(1), v(3)).attitude(v(1)) == &"ally" and b.cast(v(1), first_aid, v(3)) and v(3).hp > 2, "Friendly, and fooled: it patches up its enemy")


func test_tends() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), b.get_node("Units/Alabaster"): Vector2i(1, 3)})
	var al: Unit = b.get_node("Units/Alabaster")
	medic(v(1), first_aid)
	v(1).wisdom = 10
	v(2).charisma = 10  # easy enough to read: cha 8 would dim v(1)'s read of them
	al.charisma = 10
	v(2).hp = v(2).max_hp - 1
	al.hp = 1
	var wants := func(t: Unit) -> float: return AI.want(b, v(1), first_aid, t, b.read(v(1), t))
	ok(wants.call(al) > wants.call(v(2)) and wants.call(v(1)) == 0.0, "benevolent: the one most in need; the unhurt not at all")
	AI.act(b, v(1))
	ok(al.hp > 1, "and heals it")
	al.hp = 1
	v(1).refresh()
	v(1).tends = &"pragmatic"
	v(2).level = 6
	v(2).hp = v(2).max_hp - 3
	ok(wants.call(v(2)) == wants.call(v(2)) and b.read(v(1), v(2)).level == null and wants.call(al) > wants.call(v(2)),
			"pragmatic: levels it can't read count for nothing")
	v(2).afflict(effect("persona", 2), 9)
	ok(wants.call(v(2)) > wants.call(al), "advertised (Persona II), the higher level draws its heals")
	v(2).hp = v(2).max_hp - 1
	v(1).dexterity = 16
	v(1).wisdom = 10
	ok(first_aid.healing(v(1)) == 3 and wants.call(v(2)) == 0.0, "but not where most of the heal would go to waste (1 HP short, heals 3)")
	v(1).tends = &""
	v(1).role = load("res://Roles/adventurer.tres")
	v(2).hp = v(2).max_hp - 2
	al.hp = al.max_hp - 2
	v(1).follows = al  # Command.join()
	v(2).follows = al
	ok(wants.call(v(2)) > 1.0, "loyal (the Adventurer's way): its party first")
	ok(wants.call(al) > wants.call(v(2)), "its leader, a commander, a little more")
