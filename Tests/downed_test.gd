extends Test

# Downed, down but not out (Scripts/Downed.gd): on its last life, a unit with a Downed skill taken to
# 0 HP lingers for rank rounds (its side's turns), its HP running below 0 as far as 20% x rank of its
# max - past that it dies at once; healed above 0 it's saved (Battle.rescued()), and it dies as its
# last round ends. Tenacity (Adventurer, Fighter): helpless meanwhile. Grudge (Berserker): it goes on
# acting, but dies of more than rank skill uses, or of a round without a melee attack. Hearts first.

var tenacity: Skill = load("res://Skills/tenacity.tres")
var grudge: Skill = load("res://Skills/grudge.tres")
var first_aid: Skill = load("res://Skills/first_aid.tres")


func give(u: Unit, s: Skill, r := 1) -> void:
	u.learned.append(slot(s, r))


# What Downed has told of since: [unit, how] each.
func told() -> Array:
	var got := []
	b.dbno_changed.connect(func(u: Unit, how: StringName): got.append([u, how]))
	return got


func earned() -> Array:
	var got := []
	b.gained_xp.connect(func(u: Unit, n: int, _levels: int, from: Unit, saved: bool): got.append([u, n, from, saved]))
	return got


func test_limit() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6), v(2): Vector2i(1, 1)})
	give(v(3), tenacity, 2)
	give(v(4), tenacity, 1)
	var got := told()
	var falls := []
	v(3).died.connect(func(u: Unit): falls.append(u))
	v(3).hit(999.0, [], v(1))
	ok(v(3).hp == 0 and v(3).dbno != null and v(3).is_alive() and got == [[v(3), &"down"]], "taken to 0 HP it is Downed, not dead - at 0, whatever the blow (%d, %s)" % [v(3).hp, got])
	ok(b.unit_at(Vector2i(5, 3)) == v(3) and falls.is_empty() and not v(3).reviving and b.fallen.is_empty(), "it holds its tile; nothing of the hearts' going down")
	var most := roundi(0.4 * v(3).max_hp)
	ok(most > 0 and v(3).dbno.limit == most and v(3).dbno.left == 2 and v(3).dbno.rank == 2, "rank II: 40%% of its max HP below 0, for 2 rounds (%d of %d)" % [v(3).dbno.limit, v(3).max_hp])
	v(3).damage(most)
	ok(v(3).hp == -most and v(3).is_alive() and falls.is_empty(), "at its limit below 0 it still lingers (%d)" % v(3).hp)
	v(3).damage(1)
	ok(not v(3).is_alive() and v(3).dbno == null and falls == [v(3)] and got[-1] == [v(3), &"limit"] and b.unit_at(Vector2i(5, 3)) == null, "past it, it dies at once (%s)" % [got])
	v(4).damage(999)
	ok(v(4).dbno != null and v(4).dbno.limit == roundi(0.2 * v(4).max_hp) and v(4).dbno.left == 1, "rank I: 20%, 1 round")
	v(4).damage(v(4).dbno.limit + 1)
	ok(not v(4).is_alive(), "and past that, dead")
	v(2).damage(999)
	ok(not v(2).is_alive() and v(2).dbno == null, "one without a Downed skill just falls")


func test_rounds() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(1, 1), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	give(v(3), tenacity, 2)
	give(v(4), tenacity, 1)
	var got := told()
	v(3).damage(999)
	b.end_turn()
	ok(b.turn == nemes and v(3).is_alive() and v(3).dbno.left == 2, "its foes' turn ending is no round of its own")
	v(4).damage(999)
	ok(v(4).dbno != null and v(4).dbno.fresh, "another goes down in its own side's turn")
	b.end_turn()
	ok(v(3).is_alive() and v(3).dbno.left == 1, "its side's turn ends: a round gone, one left")
	ok(v(4).is_alive() and v(4).dbno.left == 1 and not v(4).dbno.fresh, "the turn it went down in doesn't count")
	b.end_turn()
	b.end_turn()
	ok(not v(3).is_alive() and not v(4).is_alive() and [v(3), &"rounds"] in got and [v(4), &"rounds"] in got, "still down as its last round ends, it dies (%s)" % [got])
	ok(b.phase == Battle.Phase.OVER, "the last of its side gone, the battle is over")


func test_saved() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), v(3): Vector2i(2, 2), v(4): Vector2i(5, 5)})
	give(v(2), tenacity, 1)
	give(v(1), first_aid, 1)
	var got := told()
	var xp := earned()
	v(2).hit(999.0, [], v(3))
	ok(v(2).dbno != null and xp.is_empty() and not v(2).paid_fall, "going down pays nobody: it hasn't fallen yet")
	v(2).damage(1)
	ok(b.cast(v(1), first_aid, v(2)) and v(2).hp > 0 and v(2).dbno == null and v(2).is_alive() and got[-1] == [v(2), &"saved"], "healed above 0, it is saved (%d, %s)" % [v(2).hp, got])
	ok(xp == [[v(1), 9, v(2), true]] and v(2).paid_rise, "its saviour takes two shares of its worth: %s" % [xp])
	xp.clear()
	v(2).hit(999.0, [], v(3))
	ok(v(2).dbno != null and v(2).healed_by == null, "down again")
	v(2).heal(2)
	ok(v(2).hp == 2 and v(2).dbno == null and xp.is_empty(), "saved again: that pays out only once")
	v(2).hit(999.0, [], v(3))
	v(2).damage(999)
	ok(not v(2).is_alive() and xp == [[v(3), 9, v(2), false]] and v(2).paid_fall, "dying of it pays for its fall, to whoever struck it last: %s" % [xp])
	v(2).heal(5)
	ok(not v(2).is_alive(), "the dead stay dead")


func test_heal_short() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), v(3): Vector2i(2, 2)})
	give(v(2), tenacity, 3)
	v(2).damage(999)
	v(2).damage(4)
	v(2).heal(4)
	ok(v(2).hp == 0 and v(2).dbno != null, "healed only to 0, it's still down")
	v(2).damage(3)
	v(2).afflict(Battle.SICKNESS, 3)
	b.end_turn()
	b.end_turn()
	ok(v(2).hp == -3 and v(2).dbno != null, "Resurrection Sickness doesn't lift it to 1 HP (%d)" % v(2).hp)


func test_tenacity_helpless() -> void:
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	give(v(3), tenacity, 3)
	var c := Command.new(b, v(4))
	var could := c.can_order(v(3))
	ok(not v(3).helpless() and b.cast(v(3), strike, v(1)), "standing, it acts")
	v(3).refresh()
	v(3).damage(999)
	ok(v(3).helpless() and v(3).is_alive(), "Downed by Tenacity: helpless")
	ok(not b.cast(v(3), strike, v(1)) and b.travel(v(3), Vector2i(6, 3)).is_empty() and v(3).cell == Vector2i(5, 3), "it can't act or move")
	ok(could and not c.can_order(v(3)), "it takes no orders (it could: %s)" % could)
	ok(AI.act(b, v(3)).is_empty(), "left to itself, it does nothing")
	b.end_turn()
	v(1).refresh()
	var was := v(3).hp
	ok(b.cast(v(1), strike, v(3)) and v(3).hp <= was, "its foes can still strike it")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(b.phase == Battle.Phase.TURNS and v(3) in b.members(nemes), "its side isn't beaten while it lingers")


func test_grudge_actions() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(1, 1), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	give(v(3), grudge, 2)
	v(1).armor = bulwark()
	var got := told()
	v(3).hit(999.0, [], v(1))
	ok(v(3).dbno != null and not v(3).helpless() and v(3).dbno.spare() == 2, "Grudge II: down, but it goes on acting - 2 skill uses to spare")
	b.end_turn()
	ok(not b.travel(v(3), Vector2i(6, 3)).is_empty() and not b.travel(v(3), Vector2i(5, 3)).is_empty() and v(3).dbno != null and v(3).dbno.acted == 0, "walking is no action (%d)" % v(3).hp)
	v(3).refresh()
	ok(b.cast(v(3), strike, v(1)) and v(3).dbno.acted == 1 and v(3).dbno.meleed, "a Strike: one action, and its melee attack this round - hit or miss")
	v(3).refresh()
	ok(b.cast(v(3), strike, v(1)) and v(3).is_alive() and v(3).dbno.spare() == 0, "a second: as many as its rank")
	v(3).refresh()
	ok(b.cast(v(3), strike, v(1)) and not v(3).is_alive() and got[-1] == [v(3), &"actions"], "one more is done, and it dies at once (%s)" % [got])


func test_grudge_melee() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(1, 1), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	give(v(3), grudge, 3)
	give(v(4), grudge, 3)
	v(1).armor = bulwark()
	var got := told()
	v(3).damage(999)
	v(4).damage(999)
	b.end_turn()
	ok(b.cast(v(3), strike, v(1)), "one strikes the foe beside it")
	var far := b.cast(v(4), hex, v(2))
	ok(not far or not v(4).dbno.meleed, "the other only hexes a foe far off: no melee attack")
	b.end_turn()
	ok(v(3).is_alive() and v(3).dbno.left == 2 and not v(3).dbno.meleed, "a round with a melee attack: it goes on, owing one next round")
	ok(not v(4).is_alive() and [v(4), &"melee"] in got, "a round without one: it dies as the round ends (%s)" % [got])
	b.end_turn()
	ok(b.cast(v(3), strike, v(1)), "its second round's blow")
	b.end_turn()
	b.end_turn()
	ok(b.cast(v(3), strike, v(1)) and v(3).is_alive(), "its third: the last its rank allows")
	b.end_turn()
	ok(not v(3).is_alive() and got[-1] == [v(3), &"rounds"], "its rank in rounds over, it dies (%s)" % [got])


func test_hearts_first() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	v(3).hearts = 1
	give(v(3), tenacity, 1)
	var got := told()
	var downs := []
	b.downed.connect(func(u: Unit): downs.append(u))
	v(3).hp = 0
	ok(downs == [v(3)] and v(3).reviving and v(3).dbno == null and got.is_empty() and not v(3).is_alive(), "a heart left: it goes down the hearts' way, beyond harm")
	b.end_turn()
	ok(v(3).is_alive() and v(3).hp == v(3).max_hp and v(3).lives_left() == 0, "and gets up as the turn ends")
	v(3).hp = 0
	ok(downs.size() == 1 and v(3).dbno != null and v(3).is_alive() and not v(3).reviving and got == [[v(3), &"down"]], "on its last life: Downed")


func test_executes() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	give(v(3), tenacity, 2)
	var got := told()
	ok(not Downed.finish(v(3)) and v(3).is_alive() and v(3).hp == v(3).max_hp, "an execute on one standing: nothing of Downed's")
	v(3).hp = 0
	ok(v(3).dbno != null, "taken to 0, it goes down as usual")
	ok(Downed.finish(v(3)) and not v(3).is_alive() and got[-1] == [v(3), &"slain"], "an execute on one already Downed: it dies")


func test_skills() -> void:
	var fighter := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brick"})
	var shrike := b.starter({faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Shrike"})
	var brute := b.starter({faction = lancin, role = load("res://Roles/berserker.tres"), name = "Brute"})
	for u: Unit in [fighter, shrike, brute]:
		b.get_node("Units").add_child(u)
		u.skill_points = 5
	ok(tenacity in fighter.options()[&"class"] and tenacity in shrike.options()[&"class"], "Tenacity: on offer to a Fighter and an Adventurer")
	ok(fighter.unlock(tenacity) and shrike.unlock(tenacity) and Downed.slot_of(fighter) != null, "they learn it")
	ok(brute.missing(grudge) == "" and brute.tier(grudge) == 1 and brute.unlock(grudge) and Downed.slot_of(brute).skill == grudge, "Grudge: a Berserker's, low on Fury (%s)" % brute.missing(grudge))
	ok(fighter.missing(grudge) != "" and tenacity.passive and grudge.passive and not tenacity.ai and not grudge.ai, "nobody else's (%s)" % fighter.missing(grudge))
	var t := tenacity.describe(2)
	ok("Downed instead of dying, for 2 rounds: helpless" in t and "as far as 40% of its max HP" in t and "Healed above 0 HP it is saved" in t, "Tenacity II described: %s" % t)
	var g := grudge.describe(3)
	ok("for 3 rounds: it goes on acting" in g and "more than 3 skills" in g and "without a melee attack" in g, "Grudge III described: %s" % g)
	ok(Glossary.name_of(&"downed") == "Downed", "a glossary term")
