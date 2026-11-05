extends Test

# Hogel's Humble and his satisfaction (resting at full HP), and the Cleric's Sol path: Igna, Flamewall,
# Flamecharmed, Inner Fire, the Burning Bag, Flamecharm, Cindering, Level Up, Flamedance, Solar.

var cleric: Role = load("res://Roles/cleric.tres")
var warlock: Role = load("res://Roles/warlock.tres")
var sn: Reserve = load("res://Reserves/sweet_nothings.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


# A unit of the player's side at `at` with skill n at rank r, wis 18 (mod 4), fresh AP.
func caster(n: String, r := 1, at := Vector2i(4, 4)) -> Unit:
	stage(lancin, {v(1): at, v(2): at + Vector2i(1, 0), v(3): at + Vector2i(3, 0), v(4): at + Vector2i(0, 3)})
	v(1).wisdom = 18
	v(1).learned.append(slot(sk(n), r))
	v(1).refresh()
	return v(1)


func test_tiers() -> void:
	var want := {"igna": 1, "flamewall": 2, "flamecharmed": 2, "inner_fire": 3, "burning_bag": 4, "flamecharm": 5, "cindering": 6, "level_up": 7, "flamedance": 8, "solar": 9}
	var got := {}
	for n in want:
		got[n] = cleric.tier(sk(n))
	ok(got == want, "Sol's tiers: %s" % [got])
	ok(warlock.tier(sk("humble")) == 1, "Humble: Hogel, tier 1")


func test_humble() -> void:
	var u := caster("humble")
	u.max_hp = 50
	u.hp = 50
	ok(sk("humble").span(u) < 0.5 and b.cast(u, sk("humble"), u), "rank I: on itself alone")
	ok(u.max_hp == 49 and u.hp == 49, "at full HP: max HP capped 1%% lower (%d)" % u.max_hp)
	var a: Unit.Applied = null
	for e in u.timed:
		if e.stat == "humble":
			a = u.timed[e]
	ok(a != null and a.turns >= 4, "lasts rank x 4 x (1 - 2%%) turns: 4 (%d)" % (a.turns if a else -1))
	u.timed.clear()
	u.refit()
	ok(u.max_hp == 50, "back as it ends")


func test_hogel_rest() -> void:
	var u := b.starter({faction = lancin, role = warlock, name = "Vex"})
	b.get_node("Units").add_child(u)
	stage(lancin, {u: Vector2i(2, 2), v(3): Vector2i(8, 8)})
	u.skill_points = 1
	ok(u.unlock(sk("humble")) and u.devotion().name == "Hogel", "devoted to Hogel")
	u.set_store(sn, 0)
	u.refresh()
	u.hp = u.max_hp
	b.end_turn()
	ok(u.store(sn) == 1, "resting at full HP: a Sweet Nothing")
	b.turn = lancin
	u.hp = u.max_hp - 1
	u.refresh()
	b.end_turn()
	ok(u.store(sn) == 1, "hurt: none")


func test_igna() -> void:
	var u := caster("igna", 2)
	u.intelligence = 14  # mod 2; a Cleric would use wis
	var skill_ap := v(2).ap_for(&"skill")
	ok(b.cast(u, sk("igna"), v(2)) and is_equal_approx(v(2).ap_for(&"skill") - skill_ap, 4.0), "on an ally: int mod + rank skill AP, at once")


func test_flamewall() -> void:
	var u := caster("flamewall", 2)
	var c := Vector2i(6, 4)
	ok(b.cast_at(u, sk("flamewall"), c), "cast on a tile 2 away")
	ok([c, Vector2i(6, 3), Vector2i(6, 5), Vector2i(6, 2), Vector2i(6, 6)].all(func(x: Vector2i): return x in b.flames) and b.flames.size() == 5,
			"it and two tiles to either side, across the line: %s" % [b.flames.keys()])
	v(2).max_hp = 200
	v(2).hp = 200
	b.move(v(2), Vector2i(5, 3))
	v(2).refresh()
	b.travel(v(2), Vector2i(7, 3))
	ok(v(2).hp < 200, "walking into it burns")


func test_inner_fire() -> void:
	var u := caster("inner_fire", 2)
	ok(b.cast(u, sk("inner_fire"), u), "on itself")
	ok(is_equal_approx(u.stat(&"ap"), 0.2) and is_equal_approx(u.stat(&"damage"), 0.2) and is_equal_approx(u.stat(&"poison"), 0.1), "rank II: +20% AP, +20% damage, 10% of max HP a turn")


func test_burning_bag() -> void:
	var u := caster("burning_bag", 2)
	v(3).trinket = load("res://Items/burning_bag.tres")
	var bar := u.bar_size()
	ok(b.cast(u, sk("burning_bag"), u), "retrieved")
	ok(u.trinket.name == "Burning Bag" and u.trinket.rank == 2 and v(3).trinket == null, "taken from wherever it was, at rank II")
	ok(u.bar_size() == bar + 2 and u.burning_slots().size() == 2, "two burning slots")
	u.max_hp = 100
	u.hp = 100
	b._mend(u)
	ok(u.hp < 100, "it burns as its turn starts")


func test_flamecharmed() -> void:
	var u := caster("flamecharmed", 5)
	ok(u.mitigation([&"fire"] as Array[StringName]) >= 1.0, "rank V: all fire blocked")
	u.max_hp = 100
	u.hp = 50
	u.hit(20.0, [&"fire"] as Array[StringName], v(2))
	ok(u.hp == 55, "an ally's fire heals it for 25%% of it (%d)" % u.hp)


func test_flamecharm() -> void:
	var u := caster("flamecharm", 2)
	ok(b.cast(u, sk("flamecharm"), u), "used")
	ok(is_equal_approx(u.mitigation([&"fire"] as Array[StringName]), 0.4) and is_equal_approx(v(2).mitigation([&"fire"] as Array[StringName]), 0.4), "allies within 2: 40% fire")
	ok(is_zero_approx(v(4).mitigation([&"fire"] as Array[StringName])), "not 3 tiles away")
	var w := caster("flamecharm", 5)
	b.cast(w, sk("flamecharm"), w)
	ok(w.mitigation([&"fire"] as Array[StringName]) < 1.0, "rank V: split among those it picks")


func test_cindering() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(5, 4)})
	v(1).wisdom = 40
	v(1).learned.append(slot(sk("cindering"), 2))
	v(1).refresh()
	for i in 10:
		v(1).refresh()
		b.cast(v(1), sk("cindering"), v(3))
		if not v(3).burning_slots().is_empty():
			break
	ok(v(3).burning_slots().size() == 2, "its two rightmost slots burn")
	v(3).max_hp = 200
	v(3).hp = 200
	v(3).hotbar.fill(null)
	v(3).hotbar[v(3).bar_size() - 1] = strike
	b.turn = nemes
	v(3).refresh()
	b._burn(v(3), strike)
	ok(v(3).hp < 200, "a skill used from one burns it")


func test_flamedance() -> void:
	var u := caster("flamedance", 2)
	ok(b.cast(u, sk("flamedance"), u), "as its turn opens")
	ok(v(2).mitigation([&"environmental"] as Array[StringName]) >= 1.0 and is_equal_approx(v(2).stat(&"damage", [&"fire"] as Array[StringName]), 0.2), "allies: no environmental fire, +20% fire")
	var w := caster("flamedance", 1)
	b.travel(w, Vector2i(4, 5))
	ok(not b.cast(w, sk("flamedance"), w), "not once it has moved")


func test_solar() -> void:
	var u := caster("solar", 1)
	for x in [v(2), v(3), v(4)]:
		x.max_hp = 300
		x.hp = 300
	u.max_hp = 300
	u.hp = 300
	ok(b.cast_at(u, sk("solar"), Vector2i(8, 4)), "toward a tile")
	ok(u.hp < 300 and v(2).hp < 300 and v(3).hp < 300, "itself and those in the cone (wis mod 4 tiles)")
	ok(v(4).hp == 300, "not off to the side")
