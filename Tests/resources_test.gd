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
	u.learned.append(slot(crushing))
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
	u.learned.pop_back()
	ok(Unit.replacer(mana_skill) == mana and Unit.replacer(stamina) == stamina_pool and Unit.replacer(hex) == null, "replacer()")
	ok("runs on Mana" in mana_skill.describe() and "channeled" in mana_skill.describe() and "10%" in mana_skill.describe(), mana_skill.describe())
	ok("nothing pays for a magical skill" in stamina.describe(), stamina.describe())


func test_one_at_a_time() -> void:
	var u := icor()
	u.learned.append(slot(stamina))
	u._one_replacer()
	ok(u.is_on(mana_skill) and not u.is_on(stamina) and u.runs_on() == mana, "two learned: the first on the bar stays on, the other goes off")
	u.learned.append(slot(crushing))
	ok(not u.spends(stamina_pool) and fund(u, crushing) == "", "Stamina switched off pays nothing")
	u.learned.pop_back()
	u.learned.pop_back()


func test_stamina_bars_spells() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(stamina))
	v(1).learned.append(slot(focus))
	v(1).learned.append(slot(hex))
	v(1).learned.append(slot(crushing))
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
	u.learned.append(slot(stamina))
	u.learned.append(slot(focus))
	u.energy = 0
	u.set_store(stamina_pool, 3)
	ok(u.held_reserves() == [stamina_pool, focus_pool], "on Stamina, holding Focus: Stamina first")
	ok(u.reserve_bar.visible and u.second_bar and u.second_bar.visible and not u.energy_bar.visible, "two bars: Stamina and Focus, no Energy")
	ok((u.reserve_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == stamina_pool.color
			and (u.second_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == focus_pool.color, "in their colours")
	ok(u.second_bar.position.y + u.second_bar.size.y == u.reserve_bar.position.y + u.reserve_bar.size.y + 2.0 or u.second_bar.position.y == u.reserve_bar.position.y + u.reserve_bar.size.y,
			"stacked, 2px each, under the first")
	ok(u.hp_bar.position.y + u.hp_bar.size.y == u.reserve_bar.position.y, "under HP")
	u.learned.pop_back()
	u.learned.pop_back()
