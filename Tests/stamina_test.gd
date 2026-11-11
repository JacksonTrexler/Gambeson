extends Test

# Stamina (Skills/stamina.tres, Reserves/stamina.tres, the Effect stat stamina): a passive giving the
# Stamina reserve, (con mod + 2) x rank, yellow tinted green; its holder's exhaustion counts / (rank + 1).
# Stamina pays, before Energy, for martial, specialist, general and physical skills, by tag or by tree
# (Skill.tagged()) - not for purely magical ones. Who offers it: the Rogue's Blade, the Ranger's Scout,
# Fury (the Berserker's, a Paladin's Prowess) and Slayer (a Paladin's agile Prowess; a Fighter's too).

var stamina: Skill = load("res://Skills/stamina.tres")
var pool: Reserve = load("res://Reserves/stamina.tres")
var crushing: Skill = load("res://Skills/crushing_blow.tres")
var waterstrike: Skill = load("res://Skills/waterstrike.tres")
var solar: Skill = load("res://Skills/solar.tres")


# What pays for s: a reserve's name, "energy", or "" (nothing can).
func fund(u: Unit, s: Skill) -> String:
	var f: Variant = u.funding(s)
	return f.name if f is Reserve else String(f) if f != null else ""


# u learns Stamina at rank r, its reserve full.
func fit(u: Unit, r := 1) -> Unit:
	u.learned.append(slot(stamina, r))
	u.set_store(pool, u.pools().get(pool, 0))
	return u


func test_reserve() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	fit(v(1), 2)
	ok(pool.name == "Stamina" and pool.color.r > 0.7 and pool.color.g > pool.color.r and pool.color.b < 0.4, "yellow tinted green")
	ok(v(1).pools()[pool] == (v(1).mod(&"constitution") + 2) * 2 and v(1).store(pool) == v(1).pools()[pool], "(con mod + 2) x rank, full")
	ok(stamina.passive and not stamina.ai and stamina.effects[0].describe(2) == "Stamina: its exhaustion counts / 3", stamina.effects[0].describe(2))


func test_pays() -> void:
	for s in [crushing, waterstrike, solar]:
		v(1).learned.append(slot(s))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	fit(v(1))
	ok(fund(v(1), crushing) == "Stamina" and fund(v(1), strike) == "Stamina", "martial and general skills: Stamina, before Energy")
	ok(fund(v(1), waterstrike) == "Stamina", "a physical magical skill (Waterstrike): Stamina too")
	ok(fund(v(1), solar) == "energy" and fund(v(1), hex) == "energy", "purely magical ones, by tree (Solar) or tag (Hex): not Stamina: %s, %s" % [fund(v(1), solar), fund(v(1), hex)])
	var was := v(1).store(pool)
	ok(b.cast(v(1), crushing, v(3)) and v(1).store(pool) == was - 2 and v(1).energy == 10, "Crushing Blow paid 2 Stamina, no Energy")
	ok(v(1).paid_as(pool, crushing), "and its payment counts as Stamina")
	v(1).set_store(pool, 0)
	ok(fund(v(1), crushing) == "energy", "Stamina gone: Energy pays")


func test_eases_exhaustion() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(1, 1)})
	fit(v(1), 2)
	Exhaustion.on = true
	ok(b.cast(v(1), strike, v(3)), "a Strike")
	ok(is_equal_approx(v(1).exhaustion.of(strike), 1.0 / 3.0) and is_equal_approx(v(1).ap_cost(strike, pool), 3.5), "Stamina II: a use counts a third (3 x 1.1667 AP)")
	v(2).exhaustion.used(strike)
	ok(is_equal_approx(v(2).exhaustion.of(strike), 1.0), "without it, whole")
	Exhaustion.on = false


# Stamina comes back as Energy does (Unit.recover(): (con mod + wis mod) / 2 a turn resting, at least 1;
# half as fast with light activity; none busy), plus its rank on a resting turn - Energy full or not.
func test_recovers() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	fit(v(1), 2)
	v(1).set_store(pool, 0)
	var k := v(1).rounded((v(1).mod(&"constitution") + v(1).mod(&"wisdom")) / 2.0)
	var rate := float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)
	ok(v(1).energy >= v(1).max_energy, "Energy full")
	b.end_turn()
	ok(v(1).store(pool) == floori(rate + 0.0001) + 2, "a rest: Energy's rate (%s) + rank II, Energy full or not: %d" % [rate, v(1).store(pool)])
	b.end_turn()
	v(1).set_store(pool, 0)
	v(1).refresh()
	ok(b.cast(v(1), strike, v(3)), "a Strike: busy")
	v(1).set_store(pool, 0)
	b.end_turn()
	ok(v(1).store(pool) == 0, "busy: none back")


func test_recovers_light() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	fit(v(1), 3)
	v(1).set_store(pool, 0)
	v(1).reserve_rest.clear()
	v(1).refresh()
	v(1).channel = Unit.Channel.new(load("res://Skills/metea.tres"), Vector2i(2, 2))
	ok(v(1).activity() == &"light", "holding a channel: light")
	var k := v(1).rounded((v(1).mod(&"constitution") + v(1).mod(&"wisdom")) / 2.0)
	var rate := float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)
	b.end_turn()
	ok(v(1).store(pool) == floori(rate / 2.0 + 0.0001), "light: half Energy's rate, no rank bonus (%d)" % v(1).store(pool))
