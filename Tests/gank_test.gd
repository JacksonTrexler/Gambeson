extends Test

# Gank (Skills/gank.tres, Behaviours/gank.gd): 1d10 + str, only on a foe an ally is within rank tiles
# of, at disadvantage unless it ambushes (Battle.ambushes()).

var gank: Skill = load("res://Skills/gank.tres")


func ganker(r := 1) -> void:
	v(1).learned.append(slot(gank, r))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(1, 1)})
	v(1).refresh()
	v(3).max_hp = 300
	v(3).hp = 300


func test_backed() -> void:
	ganker()
	ok(not b.cast(v(1), gank, v(3)), "no ally near the foe: it can't")
	b.move(v(2), Vector2i(6, 3))
	ok(b.cast(v(1), gank, v(3)), "an ally beside it: it can")
	b.move(v(2), Vector2i(7, 3))
	ok(not b.cast(v(1), gank, v(3)), "2 tiles off at rank I: too far")
	v(1).learned.clear()
	v(1).learned.append(slot(gank, 2))
	v(1).refresh()
	ok(b.cast(v(1), gank, v(3)), "...in reach at rank II")


func test_ambush() -> void:
	ganker()
	b.move(v(2), Vector2i(6, 3))
	ok(not b.ambushes(v(1), v(3)), "in plain view: no ambush")
	ok(Battle.edge_of(gank, b.cast_of(v(1), gank, v(3), 1, true)) == -1, "disadvantage, in plain view")
	var p := Battle.hit_chance(v(1), gank, v(3), b)
	v(1).afflict(effect("concealment", 4), 3)
	ok(b.ambushes(v(1), v(3)), "concealed from it: an ambush")
	var c := b.cast_of(v(1), gank, v(3), 1, true)
	ok(&"ambush" in c.tags and Battle.edge_of(gank, c) == 0, "its hit is tagged ambush, and no disadvantage")
	ok(Battle.hit_chance(v(1), gank, v(3), b) >= p, "the HUD's hit chance sees it too")


func test_who() -> void:
	ok(load("res://Trees/slayer.tres").branches.any(func(x: Branch): return x.skill == gank), "on the Slayer tree")
	ok(not gank.ai and gank.stub == "" and gank.name == "Gank", "the user's, built")
	ok(&"martial" in gank.tags and &"physical" in gank.tags and gank.weapon_tag, "martial, physical, its weapon's blow")
	ok("ambush" in gank.describe(1).to_lower(), gank.describe(1))


func test_ai() -> void:
	ganker()
	v(1).learned.clear()
	v(1).learned.append(slot(gank, 1))
	v(1).refresh()
	var log: Array[String] = []
	var reads := {v(3): b.read(v(1), v(3))}
	ok(not AI._strike(b, v(1), reads, log) or log.all(func(x: String): return "Gank" not in x), "the AI doesn't pick Gank where it can't be used (%s)" % [log])
	b.move(v(2), Vector2i(6, 3))
	log.clear()
	ok(AI._strike(b, v(1), reads, log), "with an ally beside the foe it strikes (%s)" % [log])
