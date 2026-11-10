extends Test

# A unit's bio (Scripts/Bio.gd): its behaviour drives its AI, its appearance and adjectives are how it
# looks to whoever can't make out its class (and what the AI guesses from), its properties are always
# on it, and its clout with a side lends its persona and its lies weight there.

var rotting: Property = load("res://Properties/rotting.tres")
var renew: Skill = load("res://Skills/renew.tres")


func bio(behaviour := &"", appearance := "", adjectives: Array[String] = []) -> Bio:
	var x := Bio.new()
	x.behaviour = behaviour
	x.appearance = appearance
	x.adjectives = adjectives
	return x


func test_properties() -> void:
	var u: Unit = load("res://Scenes/villager.tscn").instantiate()
	u.bio = bio()
	u.bio.properties = [rotting]
	b.get_node("Units").add_child(u)
	stage(lancin, {v(1): Vector2i(1, 2)})
	b.move(u, Vector2i(3, 2))
	ok(&"rotting" in u.tags, "a property's tags are the unit's: it counts as rotting")
	ok(is_equal_approx(u.mitigation([&"fire"]), -0.5) and is_equal_approx(u.mitigation([&"dark"]), 0.25),
			"Rotting: fire takes half again (%s), darkness a quarter less (%s)" % [u.mitigation([&"fire"]), u.mitigation([&"dark"])])
	u.max_hp = 100
	u.hp = 100
	ok(u.hit(10, [&"fire"] as Array[StringName]) >= 15, "a fire hit of 10 lands 15")
	v(1).afflict(effect("recon", 3), 9)
	ok(b.read(v(1), u).properties == [rotting], "whoever makes out its identity reads what it's made of")


func test_looks() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(4, 2)})
	v(3).bio = bio(&"", "Soldier", ["Injured"] as Array[String])
	var r := b.read(v(1), v(3))
	ok(r.role == null and r.looks == "Injured Soldier", "its class lost on it, it goes by how it looks: %s" % r.looks)
	ok(AI._level(v(1), r) == v(1).lv() + 0, "a Soldier, but Injured: guessed at its own level (%s)" % AI._level(v(1), r))
	v(3).bio.adjectives = ["Horrific"] as Array[String]
	r = b.read(v(1), v(3))
	ok(AI._level(v(1), r) == v(1).lv() + 2 and AI._hate(r) == AI.HATE * -1,
			"Horrific: guessed stronger, and hated like an ominous aura (%s, %s)" % [AI._level(v(1), r), AI._hate(r)])
	v(3).bio = bio(&"", "Knight")
	ok(Perception.kind_noun(v(3)) == "Knight", "its appearance is its kind's noun, where its class's would be")
	ok(Bio.hurt("Injured Knight") and not Bio.hurt("Beautiful Knight"), "Injured looks hurt")


func test_temper() -> void:
	ok(v(1).temper() == &"", "no bio: no temper")
	v(1).behaviour = &"craven"
	ok(v(1).temper() == &"timid", "a craven unit is timid")
	v(1).bio = bio(&"brave")
	ok(v(1).temper() == &"brave" and AI._leaning(v(1)) == 1, "brave: goes for the strongest")
	v(1).bio = bio(&"aggressive")
	ok(AI._leaning(v(1)) == -1, "aggressive: the weakest")
	v(1).strategy = [&"strongest"] as Array[StringName]
	ok(AI._leaning(v(1)) == 1, "a strategy outranks its temper")


func test_stoic_holds() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(3).bio = bio(&"stoic")
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "stoic: no foe in reach, it holds")
	v(3).bio = null
	v(3).refresh()
	AI.act(b, v(3))
	ok(v(3).cell != Vector2i(8, 2), "without a temper it closes in")


func test_timid_waits() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(3).bio = bio(&"timid")
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "timid: no stronger ally near, it waits")
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2), v(4): Vector2i(8, 3)})
	v(4).bio = bio(&"", "Knight")
	v(3).refresh()
	AI.act(b, v(3))
	ok(v(3).cell != Vector2i(8, 2), "an ally that looks like a Knight beside it: emboldened (it can't read the level, so it guesses)")


func test_helpful_tends() -> void:
	v(3).learned.append(slot(renew, 1))
	v(3).refresh()
	stage(nemes, {v(1): Vector2i(1, 6), v(3): Vector2i(8, 2), v(4): Vector2i(8, 7)})
	v(4).hp = 2
	v(3).bio = bio(&"helpful")
	var log := AI.act(b, v(3))
	ok(log.size() > 0 and log[0].begins_with("Villager3 goes to Villager4") and v(4).hp > 2, "helpful: it goes to the wounded and heals them (%s)" % ", ".join(log))


func test_aggressive_heals_last() -> void:
	v(1).learned.append(slot(renew, 1))
	v(1).strength = 40
	v(1).refresh()
	stage(lancin, {v(1): Vector2i(4, 4), v(2): Vector2i(4, 5), v(3): Vector2i(5, 4)})
	v(2).hp = 2
	v(3).max_hp = 300
	v(3).hp = 300
	v(1).bio = bio(&"aggressive")
	var log := AI.act(b, v(1))
	var hit := log.find_custom(func(x: String): return x.contains("uses Strike"))
	var healed := log.find_custom(func(x: String): return x.contains("heals"))
	ok(hit != -1 and (healed == -1 or healed > hit), "aggressive: it strikes first, heals with what's left (%s)" % ", ".join(log))


func test_clout() -> void:
	var bl: Unit = b.summon(load("res://Scenes/blinthe.tscn"), load("res://Factions/unaligned.tres"), Vector2i(5, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	b.move(bl, Vector2i(5, 3))
	var with_lancin := Perception.trickery(bl, Read.new(), v(1), b)
	var with_nemes := Perception.trickery(bl, Read.new(), v(3), b)
	ok(is_equal_approx(with_lancin - with_nemes, 1.0), "clout 3 with Lancin, 2 with Nemes: its lies go a rank further with Lancin (%s, %s)" % [with_lancin, with_nemes])
	bl.bio = bl.bio.duplicate(true)  # the scene's bio is shared: don't touch it
	bl.bio.clout.clear()
	ok(is_equal_approx(Perception.trickery(bl, Read.new(), v(1), b), with_lancin - 3.0), "no clout: 3 less")
