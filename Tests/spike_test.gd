extends Test

# Spike (Skills/spike.tres, Behaviours/spike.gd): 1d10 + str; the foe adds the AP it left unspent last
# turn to its Defense; a hit deals + rank.

var spike: Skill = load("res://Skills/spike.tres")


func test_unspent() -> void:
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).pay(2.0, &"skill")
	var left := v(3).ap_left()
	b.end_turn()
	ok(is_equal_approx(v(3).unspent, left), "its unspent AP recorded as its turn ends (%s)" % v(3).unspent)
	v(1).learned.append(slot(spike, 3))
	var c := b.cast_of(v(1), spike, v(3), 3, true)
	ok(Battle.guard_of(c) == floori(left), "it adds them to its Defense")
	var p := Battle.hit_chance(v(1), spike, v(3), b)
	v(3).unspent = 0.0
	ok(Battle.hit_chance(v(1), spike, v(3), b) > p, "the HUD's hit chance sees it")


func test_damage() -> void:
	v(1).learned.append(slot(spike, 3))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(3).unspent = 0.0
	v(3).max_hp = 300
	var lo := 999
	for i in 30:
		v(3).hp = 300
		v(1).refresh()
		b.cast(v(1), spike, v(3))
		if v(3).hp < 300:
			lo = mini(lo, 300 - v(3).hp)
	ok(lo >= 1 + v(1).mod(&"strength") + 3, "a hit: + rank (least %d)" % lo)
	ok(not spike.ai and "unspent" in spike.describe(3), spike.describe(3))
