extends Test

# Focus (Skills/focus.tres, Reserves/focus.tres, the Effect stat focus): a passive giving the Focus
# reserve, (wis mod + 2) x rank, violet; the Ranger's (Bounty) and the Mage's (Commitment). It starts each
# battle empty and builds half its max (rounded up) on each turn its holder rests - only resting, so not
# while holding a channel. It pays first for a ranged attack, for anything else only once Energy can't;
# a ranged attack that spends the last of it gets + its rank to the roll. Jam's damage drains it.

var focus: Skill = load("res://Skills/focus.tres")
var pool: Reserve = load("res://Reserves/focus.tres")
var stamina_pool: Reserve = load("res://Reserves/stamina.tres")
var missile: Skill = load("res://Skills/energy_missile.tres")
var metea: Skill = load("res://Skills/metea.tres")
var jam: Skill = load("res://Skills/jam.tres")
var crushing: Skill = load("res://Skills/crushing_blow.tres")


# What pays for s: a reserve's name, "energy", or "" (nothing can).
func fund(u: Unit, s: Skill) -> String:
	var f: Variant = u.funding(s)
	return f.name if f is Reserve else String(f) if f != null else ""


# v(1) holding Focus at rank r (and Energy Missile), v(3) three tiles off.
func focused(r := 1) -> void:
	v(1).learned.append(slot(focus, r))
	v(1).learned.append(slot(missile))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()


func test_reserve() -> void:
	focused(2)
	ok(focus.passive and not focus.ai and focus.reserve == pool, "a passive, the user's name, giving Focus")
	ok(v(1).pools()[pool] == (v(1).mod(&"wisdom") + 2) * 2, "(wis mod + 2) x rank: %d" % v(1).pools()[pool])
	ok(v(1).store(pool) == 0, "empty as the battle starts")
	var c := pool.color
	for other in [Unit.ENERGY_COLOR, Unit.HP_COLOR, stamina_pool.color, load("res://Reserves/mana.tres").color]:
		ok(absf(c.h - other.h) > 0.1, "violet, apart from Energy, HP, Stamina and Mana: %s vs %s" % [c, other])
	ok("empty as each battle starts" in focus.describe(2) and "50%" in focus.describe(2), focus.describe(2))


func test_who() -> void:
	for role in ["ranger", "mage"]:
		var r: Role = load("res://Roles/%s.tres" % role)
		ok(r.all_roots().any(func(x: SkillRoot): return x.branches.any(func(br: Branch): return br.skill == focus)), "%s offers it" % role)
	var fix: Skill = load("res://Skills/fixation.tres")
	ok(fix.name == "Fixation" and fix.ai, "the Mage's old AI-named stub Focus is Fixation ?? now")


func test_builds_resting() -> void:
	focused()
	var most: int = v(1).pools()[pool]
	b.end_turn()
	ok(v(1).store(pool) == ceili(most / 2.0), "a rest: half its max, rounded up (%d of %d)" % [v(1).store(pool), most])
	b.end_turn()
	b.end_turn()
	b.end_turn()
	ok(v(1).store(pool) == most, "two rests fill it")


func test_not_busy_or_channeling() -> void:
	focused()
	b.travel(v(1), Vector2i(2, 4))
	ok(v(1).activity() != &"rest", "it walked")
	b.end_turn()
	ok(v(1).store(pool) == 0, "walking: none")
	b.end_turn()
	v(1).refresh()
	v(1).channel = Unit.Channel.new(metea, Vector2i(2, 2))
	ok(v(1).idle() and v(1).activity() == &"light", "idle, channeling")
	b.end_turn()
	ok(v(1).store(pool) == 0, "a channeler isn't resting: none")


func test_pays() -> void:
	v(1).learned.append(slot(crushing))
	focused()
	v(1).set_store(pool, 2)
	ok(fund(v(1), missile) == "Focus", "a ranged attack: Focus first")
	ok(fund(v(1), crushing) == "energy", "a melee one (Crushing Blow): Energy, Focus kept")
	v(1).energy = 0
	ok(fund(v(1), crushing) == "Focus", "Energy gone: Focus stands in")
	v(1).learned.append(slot(load("res://Skills/stamina.tres")))
	v(1).set_store(stamina_pool, 5)
	v(1).energy = 10
	ok(fund(v(1), crushing) == "Stamina" and fund(v(1), missile) == "", "with Stamina too: Stamina for Crushing Blow; running on Stamina, nothing pays for a spell (Energy Missile), Focus neither")
	v(1).learned.pop_back()
	ok(fund(v(1), missile) == "Focus", "on Energy again: Focus for the shot")
	v(1).learned.append(slot(load("res://Skills/stamina.tres")))


# The roll's bonus over the d20 on v(1)'s next Energy Missile at v(3).
func shot_bonus() -> int:
	var got := []
	var f := func(_c: Unit, _t: Unit, d20: int, total: int, _def: int): got.append(total - d20)
	b.attacked.connect(f)
	v(1).refresh()
	b.cast(v(1), missile, v(3))
	b.attacked.disconnect(f)
	return got[0] if got else -999


func test_accuracy() -> void:
	focused(3)
	v(3).max_hp = 300
	v(3).hp = 300
	var plain := shot_bonus()
	ok(v(1).paid_with is StringName, "paid with Energy: no Focus")
	v(1).set_store(pool, 3)
	var forecast := Battle.hit_chance(v(1), missile, v(3))
	ok(shot_bonus() == plain and v(1).store(pool) == 2, "Focus paid but not emptied: no bonus")
	v(1).set_store(pool, 1)
	ok(Battle.hit_chance(v(1), missile, v(3)) > forecast or forecast >= 1.0, "the forecast counts the bonus")
	ok(shot_bonus() == plain + 3 and v(1).store(pool) == 0, "the last of it spent on the shot: + rank (III) to the roll")
	v(1).set_store(pool, 0)
	v(1).energy = 10
	ok(v(1).focus_bonus(strike) == 0, "nothing for a skill it didn't just pay for")


func test_jam_drains() -> void:
	v(2).learned.append(slot(jam))
	v(2).dexterity = 40
	v(3).learned.append(slot(focus, 3))
	stage(lancin, {v(2): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(2).refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).set_store(pool, 30)
	var was := v(3).store(pool)
	ok(b.cast(v(2), jam, v(3)), "Jam lands")
	var lost := 300 - v(3).hp
	ok(lost > 0 and v(3).store(pool) == maxi(was - lost, 0), "its Focus drops as much as its HP did (%d, %d -> %d)" % [lost, was, v(3).store(pool)])
	ok("Focus" in jam.describe(1), jam.describe(1))
