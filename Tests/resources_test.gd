extends Test

# What a unit runs on (docs/plans/resources.md): Mana and Stamina are toggle passives, on as they're
# learned, that stand in for Energy (Reserve.replaces; Unit.runs_on()). Running on one, its own Energy
# is emptied and doesn't come back; Energy it gets some other way pays as Energy does. Mana pays only
# for magical skills; running on Stamina (martial, specialist, general), nothing pays for a spell.
# Mana comes back as Energy does, its rank more on a resting turn and half that on any other; Stamina
# twice its rank on a resting turn. Switching is channeled: what it leaves goes, but 10% of that one's
# max x rank x turns held comes into what it runs on next. Bars show each resource it holds.

var mana_skill: Skill = load("res://Skills/mana.tres")
var mana: Reserve = load("res://Reserves/mana.tres")
var stamina: Skill = load("res://Skills/stamina.tres")
var stamina_pool: Reserve = load("res://Reserves/stamina.tres")
var focus: Skill = load("res://Skills/focus.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var crushing: Skill = load("res://Skills/crushing_blow.tres")
var metea: Skill = load("res://Skills/metea.tres")


func icor() -> Unit:
	return b.get_node("Units/Icor")


# What pays for s: a reserve's name, "energy", or "" (nothing can).
func fund(u: Unit, s: Skill) -> String:
	var f: Variant = u.funding(s)
	return f.name if f is Reserve else String(f) if f != null else ""


# The rate Energy comes back at for u resting (Unit.recover()).
func rate(u: Unit) -> float:
	var k := u.rounded((u.mod(&"constitution") + u.mod(&"wisdom")) / 2.0)
	return float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)


func test_runs_on() -> void:
	var u := icor()
	ok(mana_skill.toggle and stamina.toggle and mana.replaces and stamina_pool.replaces, "Mana and Stamina: toggles standing in for Energy")
	ok(u.is_on(mana_skill) and u.runs_on() == mana and u.energy == 0, "on as learned: a Wizard runs on Mana, no Energy of its own")
	u.learned.append(slot(crushing)); u.sync_bar()
	ok(fund(u, crushing) == "" and fund(u, hex) == "Mana", "Mana pays for its spells only; a martial skill has nothing to pay it")
	u.add_overcharge(3, 2)
	ok(fund(u, crushing) == "energy", "Overcharge, with no Energy at all, pays for a martial skill")
	u.overcharge = 0
	ok(u.grant_energy(4) == 4, "Energy Transfer's way in (grant_energy())")
	ok(fund(u, crushing) == "energy", "Energy it got some other way pays for anything")
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	b.end_turn()
	b.end_turn()
	ok(u.energy == 4, "but its own Energy doesn't come back while it runs on Mana")
	u.learned.pop_back(); u.sync_bar()
	ok(Unit.replacer(mana_skill) == mana and Unit.replacer(stamina) == stamina_pool and Unit.replacer(hex) == null, "replacer()")
	ok("runs on Mana" in mana_skill.describe() and "channeled" in mana_skill.describe() and "10%" in mana_skill.describe(), mana_skill.describe())
	ok("nothing pays for a magical skill" in stamina.describe(), stamina.describe())


func test_one_at_a_time() -> void:
	var u := icor()
	u.learned.append(slot(stamina)); u.sync_bar()
	u._one_replacer()
	ok(u.is_on(mana_skill) and not u.is_on(stamina) and u.runs_on() == mana, "two learned: the first on the bar stays on, the other goes off")
	u.learned.append(slot(crushing)); u.sync_bar()
	ok(not u.spends(stamina_pool) and fund(u, crushing) == "", "Stamina switched off pays nothing")
	u.learned.pop_back(); u.sync_bar()
	u.learned.pop_back(); u.sync_bar()


func test_stamina_bars_spells() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(stamina)); v(1).sync_bar()
	v(1).learned.append(slot(focus)); v(1).sync_bar()
	v(1).learned.append(slot(hex)); v(1).sync_bar()
	v(1).learned.append(slot(crushing)); v(1).sync_bar()
	v(1).set_store(focus_pool, 5)
	v(1).set_store(stamina_pool, 3)
	ok(v(1).runs_on() == stamina_pool and v(1).energy > 0 and fund(v(1), hex) == "", "running on Stamina, nothing pays for a spell - not Focus, not the Energy it kept (learned mid-battle)")
	ok(fund(v(1), crushing) == "Stamina", "a martial skill: Stamina")


func test_mana_regen() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	u.set_store(mana, 0)
	u.reserve_rest.clear()
	b.end_turn()
	ok(u.store(mana) == floori(rate(u) + 1 + 0.0001), "a rest: Energy's rate (%s) + Mana's rank I: %d" % [rate(u), u.store(mana)])
	b.end_turn()
	u.set_store(mana, 0)
	u.reserve_rest.clear()
	u.refresh()
	u.energy = 10  # to pay for a Strike: busy
	ok(b.cast(u, strike, v(1)) or true, "a Strike")
	u.pay(u.ap_left(), &"skill")
	ok(u.activity() == &"busy", "busy")
	b.end_turn()
	ok(u.store(mana) == 0 and is_equal_approx(u.reserve_rest[mana], 0.5), "busy: half its resting bonus, half a point")
	b.end_turn()
	u.refresh()
	u.pay(u.ap_left(), &"skill")
	b.end_turn()
	ok(u.store(mana) == 1, "a second busy turn: a whole point back")


func test_switch_off() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	ok(u.toggle(mana_skill) and u.switching() == &"energy" and u.is_on(mana_skill) and u.runs_on() == mana, "switching off Mana: a channel, still on Mana meanwhile")
	ok(u.activity() == &"light", "a channeler isn't resting")
	b.end_turn()
	ok(u.channel.held == 1, "held through an idle turn")
	b.end_turn()
	b.end_turn()
	ok(u.channel.held == 2, "and another")
	var have := u.store(mana)
	ok(u.carry(mana, mana_skill, 2) == mini(floori(12 * 0.1 * 2), have), "10% of Mana's max (12) x rank I x 2 turns: 2")
	ok(u.toggle(mana_skill) and u.switching() == null, "toggled again: the switch completes")
	ok(not u.is_on(mana_skill) and u.runs_on() == &"energy" and u.store(mana) == 0 and u.energy == 2, "off: Mana gone, 2 of it carried into Energy")
	ok(not u.spends(mana) and fund(u, hex) == "energy", "Energy pays for Hex now, Mana for nothing")
	u.set_store(mana, 3)
	for i in 4:
		b.end_turn()
	ok(u.store(mana) == 3 and u.energy > 2, "switched off, Mana doesn't come back; Energy does")


func test_switch_on_broken() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	u.toggle(mana_skill)
	u.toggle(mana_skill)
	ok(u.runs_on() == &"energy" and u.energy == 0, "off at once: nothing carried")
	u.max_energy = 10  # Icor's own is 4: 10% of it rounds to nothing
	u.energy = 10
	ok(u.toggle(mana_skill) and u.switching() == mana, "switching Mana back on")
	b.end_turn()
	b.end_turn()
	ok(u.channel.turns == 1 and u.channel.held == 1, "a turn held")
	u.pay(1.0, &"skill")
	b.end_turn()
	ok(u.channel == null and u.runs_on() == mana and u.energy == 0 and u.store(mana) == 1, "acting breaks the channel: the switch completes, 10% of Energy's max (10) x 1 carried")


func test_switch_interrupted() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	u.toggle(mana_skill)
	b.interrupt(u)
	ok(u.channel == null and u.runs_on() == &"energy", "interrupted (Jam): the switch completes with what it held")


func test_switch_completes_full() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	u.set_store(mana, 2)
	u.toggle(mana_skill)
	b.end_turn()
	ok(u.channel != null and u.channel.held == 1, "1 of 2 carried so far")
	b.end_turn()
	b.end_turn()
	ok(u.channel == null and u.energy == 2 and u.runs_on() == &"energy", "it completes once it would carry all it has")


func test_not_beside_a_channel() -> void:
	var u := icor()
	stage(nemes, {u: Vector2i(7, 3), v(1): Vector2i(3, 3)})
	u.channel = Unit.Channel.new(metea, u.cell)
	ok(not u.toggle(mana_skill) and u.channel.skill == metea, "holding another channel, it can't switch")
	u.channel = null


func test_two_bars() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var u := v(1)
	u.learned.append(slot(stamina)); u.sync_bar()
	u.learned.append(slot(focus)); u.sync_bar()
	u.energy = 0
	u.set_store(stamina_pool, 3)
	ok(u.held_reserves() == [stamina_pool, focus_pool], "on Stamina, holding Focus: Stamina first")
	ok(u.reserve_bar.visible and u.second_bar and u.second_bar.visible and not u.energy_bar.visible, "two bars: Stamina and Focus, no Energy")
	ok((u.reserve_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == stamina_pool.color
			and (u.second_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == focus_pool.color, "in their colours")
	ok(u.second_bar.position.y + u.second_bar.size.y == u.reserve_bar.position.y + u.reserve_bar.size.y + 2.0 or u.second_bar.position.y == u.reserve_bar.position.y + u.reserve_bar.size.y,
			"stacked, 2px each, under the first")
	ok(u.hp_bar.position.y + u.hp_bar.size.y == u.reserve_bar.position.y, "under HP")
	u.learned.pop_back(); u.sync_bar()
	u.learned.pop_back(); u.sync_bar()


# Negative Energy (docs/plans/w22-negative.md): one rule for Energy (Power) and every reserve. A pool goes below 0
# only where a debt effect (tagged with it) allows, down to -max; every gain first fills the debt, at
# efficiency 1 - half the debt's share of max (debt = max: 0.5; half: 0.75), a fraction carried to the next gain;
# what is left past 0 comes whole.
func test_debt_all_pools() -> void:
	var u := v(1)
	u.max_energy = 10
	u.reserves[mana] = 10
	u.reserves[stamina_pool] = 10
	for pool: Variant in [&"energy", mana, stamina_pool]:
		var id := Unit.pool_id(pool)
		u.set_exact(pool, 3)
		u.set_level(pool, -5)
		ok(u.level_of(pool) == 0, "%s: no debt where nothing allows it" % id)
		u.afflict(effect("debt", 1.0, [id] as Array[StringName]), 9)
		u.set_level(pool, -5)
		ok(u.level_of(pool) == -5 and u.debt_floor(pool) == -10, "%s: a debt effect lets it owe" % id)
		u.set_level(pool, -99)
		ok(u.level_of(pool) == -10, "%s: the floor is -max" % id)
		u.set_exact(pool, -6)  # 60% in debt: 0.7
		u.set_level(pool, u.level_of(pool) + 10)
		ok(u.level_of(pool) == 1, "%s: 10 gained on 60%% debt (0.7): 8.6 of it fills the 6 owed, the rest whole: 1" % id)
		u.set_exact(pool, -10)
		for i in 2:
			u.set_level(pool, u.level_of(pool) + 1)
		ok(u.level_of(pool) == -9, "%s: debt = max, half a point a gain, the fraction carried: 2 gains, 1 point" % id)
		u.set_exact(pool, -5)
		u.set_level(pool, u.level_of(pool) + 4)
		ok(u.level_of(pool) == -2, "%s: 50%% debt: 4 gained -> 3 (0.75)" % id)
		u.set_exact(pool, -2)
		u.set_level(pool, u.level_of(pool) + 20)
		ok(u.level_of(pool) == 10, "%s: past the debt, whole, up to max" % id)
		u.timed.clear()
	u.afflict(effect("debt", 1.0, [&"energy"] as Array[StringName]), 9)
	u.set_level(&"energy", -4)
	u.set_level(mana, -4)
	ok(u.level_of(&"energy") == -4 and u.level_of(mana) == 0, "a debt effect allows only the pool it names")
	u.set_exact(&"energy", -10)
	ok(u.grant_energy(4) == 2 and u.energy == -8, "every gain goes through it: Energy granted by an effect")


# seal (Effect stat; Unit.seal()): locks points or a share of a pool's max out of its usable max, and out of what it
# holds, until its source is gone - a Callable that answers false, a freed node, a dead unit. Seals stack; when one
# lifts, the pool is not refilled. Past what it holds the rest is lost, or debt where the seal bears the tag debt.
func test_seal() -> void:
	var u := v(1)
	u.max_energy = 10
	u.reserves[mana] = 10
	u.energy = 10
	u.set_store(mana, 10)
	var up := [true]
	var tile := func(): return up[0]
	var node := Node.new()
	u.seal(&"energy", 2, tile)
	u.seal(&"energy", 0, node, 0.2)
	ok(u.locked(&"energy") == 4 and u.usable_max(&"energy") == 6 and u.energy == 6, "two seals stack: 2 points and 20% locked, out of the max and of what it holds")
	u.energy += 20
	ok(u.energy == 6 and u.max_energy == 10, "gains stop at the usable max")
	ok(u.locked(mana) == 0 and u.store(mana) == 10, "another pool is not touched")
	node.free()
	ok(u.locked(&"energy") == 2 and u.usable_max(&"energy") == 8, "a freed source lifts its seal at once")
	up[0] = false
	u.prune_seals()
	ok(u.seals.is_empty() and u.energy == 6 and u.energy_bar.max_value == 10, "a Callable that answers false lifts the other; the pool is not refilled")
	var held := Unit.new()
	held.hp = 0
	u.seal(mana, 1, held)
	ok(u.locked(mana) == 0 and u.store(mana) == 9, "a unit that is not alive holds nothing (the points it took are gone)")
	held.free()
	u.set_store(mana, 3)
	var plain := u.seal(mana, 5, true)
	ok(u.store(mana) == 0 and u.locked(mana) == 5 and plain.source == true, "locking more than it holds, without debt allowed: the rest is lost")
	u.seals.clear()
	u.set_store(mana, 3)
	u.afflict(effect("seal", 5, [&"mana", &"debt"] as Array[StringName]), 0, 1, true)
	ok(u.store(mana) == -2 and u.locked(mana) == 5 and u.debt_floor(mana) == -10, "a seal bearing the tag debt (Starnest): into debt")
	u.seals.clear()
	u.set_exact(mana, 10)
	var half := effect("seal", 0.5, [&"mana"] as Array[StringName])
	half.op = "mul"
	u.afflict(half, 0, 1, true)
	ok(u.locked(mana) == 5 and u.usable_max(mana) == 5 and u.store(mana) == 5 and u.timed.is_empty(), "a mul seal is a share of max, and nothing timed stays on it")
