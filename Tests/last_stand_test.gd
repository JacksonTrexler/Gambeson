extends Test

# Last stands (Battle.last_stand(): d20 + average stat mod, cut by an execute), Level Down (rank rolls
# against the higher of average stat mod + level and the foe's last stand; a brittle level curse) and
# Death (an execute: failing its last stand, the foe takes 1 true damage and dies), on Elmon's path.

var level_down: Skill = load("res://Skills/level_down.tres")
var death: Skill = load("res://Skills/death.tres")
var warlock: Role = load("res://Roles/warlock.tres")
var sn: Reserve = load("res://Reserves/sweet_nothings.tres")
var sweet: Skill = load("res://Skills/sweet_nothings.tres")


func caster(s: Skill, r := 1) -> void:
	v(3).charisma = 40  # mod 15: every roll beats a villager
	roomy(v(3))
	v(3).learned.append(slot(sweet))
	v(3).learned.append(slot(s, r))
	v(3).set_store(sn, v(3).pools()[sn])
	v(3).refresh()


func test_tree() -> void:
	ok(warlock.tier(level_down) == 5 and warlock.tier(death) == 6, "Level Down tier 5, Death the capstone (tier 6), on Elmon's path")
	ok(level_down.needs == sn and death.needs == sn, "both need a Sweet Nothing")
	ok(&"execute" in death.tags and &"dark" in death.tags, "Death: execute, dark")


func test_last_stand() -> void:
	v(1).hp = v(1).max_hp
	var full: Array[int] = []
	var half: Array[int] = []
	b.rng.seed = 5
	for i in 20:
		full.append(b.last_stand(v(1)))
	b.rng.seed = 5
	v(1).hp = v(1).max_hp / 2
	for i in 20:
		half.append(b.last_stand(v(1), 2))
	ok(full.all(func(x: int): return x >= 1 + v(1).average_mod() and x <= 20 + v(1).average_mod()), "d20 + average stat mod")
	var cut := true
	for i in 20:
		cut = cut and half[i] == floori(full[i] * (float(v(1).hp) / v(1).max_hp) / 2)
	ok(cut, "against an execute at rank II, at half HP: x (1/2) / 2")


func test_level_down() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	caster(level_down, 3)
	v(1).level = 8
	var lv := v(1).lv()
	ok(b.cast(v(3), level_down, v(1)) and v(1).lv() == lv - 3, "three rolls, all beating it: three levels off (%d -> %d)" % [lv, v(1).lv()])
	var a: Unit.Applied = v(1).timed[level_down.effects[0]]
	ok(a.rank == 3 and a.turns == 3 + 0, "for rank - misses (3) turns")
	ok(v(3).store(sn) == v(3).pools()[sn] - 1, "a Sweet Nothing paid")
	ok(b.cleanse(v(1), 1) == 1 and v(1).lv() == lv - 1, "brittle: cleansing a rank takes two levels' worth off")
	v(1).timed.clear()
	v(3).charisma = 14  # mod 2, against level 40: no roll gets there
	v(1).level = 40
	lv = v(1).lv()
	v(3).refresh()
	v(3).set_store(sn, v(3).pools()[sn])
	ok(b.cast(v(3), level_down, v(1)) and v(1).lv() == lv, "every roll short: nothing")


# A roll must beat the bar, not meet it: a tie takes no level (the bar is a total rolled before, spent).
func test_level_down_ties_lose() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	caster(level_down, 3)
	v(3).charisma = 20  # mod 5 against a bar near level + 0: the dice decide
	v(1).level = 8
	v(3).refresh()
	var rolls := []
	var took := [0]
	var spy := func(_c: Unit, _t: Unit, total: int, against: int): rolls.append([total, against])
	var seen := func(_c: Unit, _t: Unit, n: int): took[0] += n
	b.contested.connect(spy)
	b.leveled.connect(seen)
	for i in 40:
		v(1).timed.clear()
		b._level_down(v(3), level_down, v(1), 3)
	b.contested.disconnect(spy)
	b.leveled.disconnect(seen)
	var ties := rolls.filter(func(r): return r[0] == r[1]).size()
	var beats := rolls.filter(func(r): return r[0] > r[1]).size()
	ok(ties > 0 and took[0] == beats, "%d rolls, %d ties took nothing: %d levels for %d beats" % [rolls.size(), ties, took[0], beats])


# The forecast of Level Down (hit_chance(): Battle.level_odds()) is the chance at least one of its rolls beats
# the bar: one last stand rolled for them all, then each roll's odds against it. It matches what casts take.
func test_level_down_odds() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	caster(level_down, 3)
	v(3).charisma = 20  # mod 5 against a bar near level + 0: the dice decide
	v(1).level = 8
	v(3).refresh()
	var p := Battle.hit_chance(v(3), level_down, v(1), b)
	var each := Battle.odds(v(3), level_down.stat(), null, Battle.level_floor(v(1)) + 10, Battle.level_opts(v(3), level_down, [0, 0, 0, 0, 0.0]))
	ok(p > 0.2 and p < 0.98 and each > 0.0 and each < 1.0, "neither sure nor hopeless (%.3f)" % p)
	var took := 0
	var n := 600
	for i in n:
		v(1).timed.clear()
		took += 1 if b._level_down(v(3), level_down, v(1), 3) > 0 else 0
	ok(absf(took / float(n) - p) < 0.07, "a cast takes a level as often as forecast (%.3f vs %.3f)" % [took / float(n), p])
	var shared := 1.0 - pow(1.0 - Battle.odds(v(3), level_down.stat(), null, Battle.level_floor(v(1)) + 10, Battle.level_opts(v(3), level_down, [0, 0, 0, 0, 0.0])), 3)
	ok(absf(p - shared) > 0.01, "the one bar they share is not three bars of its mean (%.3f vs %.3f)" % [p, shared])


func test_death() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1), v(2): Vector2i(6, 1)})
	caster(death)
	v(1).hp = 3
	var hp := v(1).hp
	ok(b.cast(v(3), death, v(1)) and not v(1).is_alive() and v(1).slain_from == hp, "its last stand fails: it dies, keeping its HP for revival (%d)" % v(1).slain_from)
	v(2).hearts = 1
	v(3).refresh()
	v(2).hp = 1  # all but dead: the execute leaves its last stand next to nothing
	ok(b.cast(v(3), death, v(2)) and not v(2).is_alive() and v(2).reviving, "a heart left: it goes down, as with any death")
	ok(death.describe(2).contains("x (its HP left / 2)"), death.describe(2))
