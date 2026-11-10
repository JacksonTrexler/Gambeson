extends Test

# Exhaustion (Scripts/Exhaustion.gd): a unit's uses of each skill counted, whole against the skill
# used and half against its others of the same broad kind; AP and cost both rising with the count; a
# channel and its strike one use; a use got over as each turn ends, more for a turn rested (by con
# mod); a Strike of three hits against three Strikes; a raised cost a unit can't pay; and what the
# HUD says of it. A villager has 11 AP for skills (10, and 1 from its wis mod) and 10 Energy.

var crushing: Skill = load("res://Skills/crushing_blow.tres")  # martial, like Strike: 4 AP, 2 cost
var missile: Skill = load("res://Skills/energy_missile.tres")  # of no broad kind: 3 AP, 1 cost
var metea: Skill = load("res://Skills/metea.tres")  # magical, like Hex; channeled: 6 AP, 5 cost, then 2 AP, 1 cost to strike
var mana: Reserve = load("res://Reserves/mana.tres")


# stage(), with exhaustion on (staged tests run without it: Test.calm()).
func worn(f: Faction, placed: Dictionary) -> void:
	stage(f, placed)
	Exhaustion.on = true


# The side whose turn it is ends it, and the other side its own: the first side's turn again.
func round_passes() -> void:
	b.end_turn()
	b.end_turn()


# u's uses of s not yet got over.
func uses(u: Unit, s: Skill) -> float:
	return u.exhaustion.uses.get(s, 0.0)


func same(a: float, x: float) -> bool:
	return is_equal_approx(a, x)


func test_counts() -> void:
	for s in [crushing, missile, hex]:
		v(1).learned.append(slot(s))
	worn(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).max_hp = 100
	v(3).hp = 100
	var e := v(1).exhaustion
	ok(Exhaustion.kinds(strike) == [&"martial"] and Exhaustion.kinds(hex) == [&"magical"] and Exhaustion.kinds(missile).is_empty(), "a skill's broad kinds: its category tags")
	ok(same(e.of(strike), 0.0) and same(e.rate(strike), 1.0) and e.note(strike) == "", "fresh: nothing counted")
	ok(b.cast(v(1), strike, v(3)), "a Strike")
	ok(same(e.of(strike), 1.0) and same(e.of(crushing), 0.5), "a use counts whole against the skill used, half against another martial skill")
	ok(same(e.of(hex), 0.0) and same(e.of(missile), 0.0), "and not against a magical skill, or one of no kind")
	ok(same(v(1).ap_cost(crushing, &"energy"), 5.0) and v(1).cost_from(crushing, &"energy") == 3, "Crushing Blow after a Strike: 4 x 1.25 = 5 AP, 2 x 1.25 = 2.5 -> 3 Energy")
	ok(b.cast(v(1), crushing, v(3)) and v(1).energy == 7 and same(v(1).ap_for(&"skill"), 3.0), "paid at that: 3 + 5 of 11 AP, 3 Energy")
	ok(same(e.of(strike), 1.5) and same(e.of(crushing), 1.5), "each now wears on the other")
	ok(e.note(strike) == "exhausted x1.5", e.note(strike))
	ok(b.cast(v(1), missile, v(3)) and same(e.of(missile), 1.0) and v(1).energy == 6, "a skill of no kind, at its plain cost: it wears on itself alone")
	ok(same(e.of(strike), 1.5) and same(e.of(hex), 0.0), "and on no other")
	ok(same(v(3).exhaustion.of(strike), 0.0), "each unit keeps its own count")
	Exhaustion.on = false
	ok(same(e.of(strike), 0.0) and same(v(1).ap_cost(strike, &"energy"), 3.0), "switched off (staged tests), nothing costs more")


func test_costs() -> void:
	worn(nemes, {v(3): Vector2i(5, 3), v(1): Vector2i(4, 3)})
	var u := v(3)
	ok(same(u.ap_cost(hex, &"energy"), 4.0) and u.cost_from(hex, &"energy") == 2, "Hex fresh: 4 AP, 2 Energy")
	ok(b.cast(u, hex, v(1)) and u.energy == 8 and same(u.ap_for(&"skill"), 7.0), "paid")
	ok(same(u.ap_cost(hex, &"energy"), 6.0) and u.cost_from(hex, &"energy") == 3 and u.price(hex) == 3, "used once: half as much again, 6 AP and 3 Energy")
	ok(same(u.ap_cost(strike, &"energy"), 3.0) and u.price(strike) == 0, "Strike, martial, is as it was")
	ok(b.cast(u, hex, v(1)) and u.energy == 5 and same(u.ap_for(&"skill"), 1.0), "paid at the raised cost: both AP and Energy")
	ok(same(u.ap_cost(hex, &"energy"), 8.0) and u.cost_from(hex, &"energy") == 4, "used twice: 8 AP, 4 Energy")
	ok(same(u.ap_cost(hex, mana), 4.0), "a reserve's saving and exhaustion multiply: half AP with Mana, doubled")
	ok(not u.can_afford(hex) and not b.cast(u, hex, v(1)), "1 AP left of the 8 it takes now: it can't")
	ok(u.energy == 5 and same(u.ap_for(&"skill"), 1.0) and same(uses(u, hex), 2.0), "nothing spent, and no use counted")
	u.ap[0].amount = 20.0
	ok(b.cast(u, hex, v(1)) and u.energy == 1 and same(u.ap_for(&"skill"), 12.0), "with the AP, a third: 8 AP, 4 Energy")
	ok(u.price(hex) == 5 and u.funding(hex) == null and not b.cast(u, hex, v(1)), "a fourth costs 5 Energy: with 1 left it can't, whatever its AP")
	ok(u.energy == 1 and same(u.ap_for(&"skill"), 12.0) and same(uses(u, hex), 3.0), "nothing spent")
	ok(b.cast(u, strike, v(1)) and same(u.ap_for(&"skill"), 9.0), "a cost of 0 stays 0: Strike still goes")
	ok(b.cast(u, strike, v(1)) and same(u.ap_for(&"skill"), 4.5) and u.energy == 1, "its AP rises all the same: 4.5")


func test_channel_is_one_use() -> void:
	v(3).learned.append(slot(metea))
	worn(nemes, {v(3): Vector2i(8, 2), v(1): Vector2i(1, 7)})
	var u := v(3)
	var at := Vector2i(5, 2)
	ok(b.cast_at(u, metea, at) and u.channel != null and u.energy == 5 and same(u.ap_for(&"skill"), 5.0), "Metea begun: 6 AP, 5 Energy")
	ok(same(uses(u, metea), 1.0) and same(u.exhaustion.of(hex), 0.5), "one use, half against Hex")
	ok(same(u.strike_ap(metea), 2.0) and u.strike_cost(metea) == 1, "its strike is part of that use: its plain 2 AP and 1 Energy")
	ok(b.cast_at(u, metea, at) and u.channel == null and u.energy == 4 and same(u.ap_for(&"skill"), 3.0), "struck, for that")
	ok(same(uses(u, metea), 1.0), "channel and strike: still one use")
	u.energy = 10
	u.ap[0].amount = 30.0
	ok(same(u.ap_cost(metea, &"energy"), 9.0) and u.cost_from(metea, &"energy") == 8, "a second Metea: 9 AP, 5 x 1.5 = 7.5 -> 8 Energy")
	ok(b.cast_at(u, metea, at) and u.energy == 2 and same(uses(u, metea), 2.0), "begun: a second use")
	ok(same(u.strike_ap(metea), 3.0) and u.strike_cost(metea) == 2, "its strike at the rate its channel was paid at: 3 AP, 1.5 -> 2 Energy")
	u.exhaustion.used(hex)
	ok(same(u.exhaustion.of(metea), 2.5) and same(u.strike_ap(metea), 3.0), "whatever else it uses meanwhile")
	ok(b.cast_at(u, metea, at) and u.energy == 0 and same(uses(u, metea), 2.0), "struck: two Meteas, two uses")


func test_recovery() -> void:
	worn(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).max_hp = 100
	v(3).hp = 100
	var u := v(1)
	ok(b.cast(u, strike, v(3)) and b.cast(u, strike, v(3)) and same(uses(u, strike), 2.0), "two Strikes in a turn")
	b.end_turn()
	ok(same(uses(u, strike), 1.0), "its turn ends: one use of each skill got over")
	b.end_turn()
	ok(same(uses(u, strike), 1.0), "not as another side's turn ends")
	ok(same(u.ap_cost(strike, &"energy"), 4.5), "next turn, a Strike still costs 4.5 AP")
	u.exhaustion.uses[strike] = 3.0
	u.exhaustion.uses[hex] = 1.0
	ok(b.cast(u, strike, v(3)), "a busy turn")
	round_passes()
	ok(same(uses(u, strike), 3.0) and same(uses(u, hex), 0.0) and hex not in u.exhaustion.uses, "busy: one off every skill's count, and no more (4 - 1; 1 - 1)")


func test_resting() -> void:
	ok(same(Exhaustion.resting(3), 3.0) and same(Exhaustion.resting(1), 1.0), "resting takes off the con mod more")
	ok(same(Exhaustion.resting(0), 1.0) and same(Exhaustion.resting(-1), 0.5) and same(Exhaustion.resting(-3), 0.25), "below 1, a part of a use: 1 / (1 - mod)")
	worn(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 5)})
	var u := v(1)
	u.exhaustion.uses[strike] = 10.0
	ok(u.mod(&"constitution") == 1 and u.activity() == &"rest", "a villager, con mod +1, resting")
	round_passes()
	ok(same(uses(u, strike), 8.0), "a turn rested: 1, and its con mod 1 more")
	u.constitution = 16
	round_passes()
	ok(same(uses(u, strike), 4.0), "con mod +3: 1 + 3")
	u.constitution = 10
	u.exhaustion.uses[strike] = 10.0
	round_passes()
	ok(same(uses(u, strike), 8.0), "con mod 0: 1 + 1 / (1 - 0)")
	u.constitution = 4
	u.exhaustion.uses[strike] = 10.0
	ok(u.mod(&"constitution") == -3, "con 4: mod -3")
	round_passes()
	ok(same(uses(u, strike), 8.75), "con mod -3: 1, and a quarter of a use more")
	for i in 3:
		round_passes()
	ok(same(uses(u, strike), 5.0), "four turns rested: 4, and one use more")
	for i in 4:
		round_passes()
	ok(same(uses(u, strike), 0.0) and same(u.ap_cost(strike, &"energy"), 3.0), "it never falls below nothing: fresh again")


func test_strike_ranks() -> void:
	v(1).learned.append(slot(strike, 3))
	worn(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(4, 6), v(4): Vector2i(5, 6)})
	for t in [v(3), v(4)]:
		t.max_hp = 100
		t.hp = 100
	var rolls := [0]
	b.attacked.connect(func(_c: Unit, _t: Unit, _d20: int, _total: int, _def: int): rolls[0] += 1)
	ok(v(1).rank(strike) == 3 and v(2).rank(strike) == 1, "Strike III, and Strike I")
	ok(b.cast(v(1), strike, v(3)) and rolls[0] >= 1 and rolls[0] <= 3, "Strike III: up to three hits")
	ok(same(uses(v(1), strike), 1.0) and same(v(1).ap_for(&"skill"), 8.0), "one use, 3 AP")
	v(2).ap[0].amount = 20.0
	var before := v(2).ap_for(&"skill")
	ok(b.cast(v(2), strike, v(4)) and b.cast(v(2), strike, v(4)) and b.cast(v(2), strike, v(4)), "three Strikes at rank I")
	ok(same(uses(v(2), strike), 3.0) and same(before - v(2).ap_for(&"skill"), 13.5), "three uses: 3 + 4.5 + 6 = 13.5 AP for the same three hits")
	ok(same(v(1).ap_cost(strike, &"energy"), 4.5) and same(v(2).ap_cost(strike, &"energy"), 7.5), "and the next costs the one 4.5 AP, the other 7.5")


func test_ai_and_hud() -> void:
	worn(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).max_hp = 100
	v(3).hp = 100
	var log := AI.act(b, v(1))
	ok(log.filter(func(l: String): return "uses Strike" in l).size() == 2 and same(v(1).ap_for(&"skill"), 3.5), "the AI Strikes while it can pay: 3 + 4.5 of its 11 AP, not the 6 a third would take (%s)" % [log])
	b.end_turn()
	b.end_turn()
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	h._refresh()
	ok("4.5 AP (exhausted x1)" in h._forecast(v(1), strike, v(3)), h._forecast(v(1), strike, v(3)))
	var tip := Glossary.plain((h.bar.get_child(v(1).hotbar.find(strike)) as SkillSlot).tooltip_text)
	ok(tip.begins_with("Exhausted x1: 4.5 AP now\n") and "3 AP" in tip, "its slot says why, and what it costs now (%s)" % tip)
	ok(&"exhaustion" in Glossary.TERMS and "Exhaustion" in Guide.text(&"skills") and "Exhaustion" in Guide.text(&"conditions"), "and the Guide explains it")
	h.free()
