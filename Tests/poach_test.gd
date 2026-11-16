extends Test

# Poach (Skills/poach.tres, Behaviours/poach.gd): 1d6 + dex. On a bloodied foe it never used a skill on:
# advantage, half its AP and cost back. Its blow neutralizing the foe: 5% x rank of max Energy back,
# 10% x rank of Focus and Stamina.

var poach: Skill = load("res://Skills/poach.tres")
var slam_jam: Skill = load("res://Skills/slam_jam.tres")
var stamina: Skill = load("res://Skills/stamina.tres")
var focus: Reserve = load("res://Reserves/focus.tres")
var stamina_r: Reserve = load("res://Reserves/stamina.tres")


func poacher(r := 1) -> void:
	v(1).learned.append(slot(poach, r))
	v(1).dexterity = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	soak(v(3), 300)


func test_easy() -> void:
	poacher()
	ok(Battle.edge_of(poach, b.cast_of(v(1), poach, v(3), 1, true)) == 0, "a hale foe: no advantage")
	v(3).hp = 150
	ok(v(3).bloodied() and Battle.edge_of(poach, b.cast_of(v(1), poach, v(3), 1, true)) == 1, "bloodied, never aimed at: advantage")
	v(1).energy = 10
	var ap := v(1).ap_left()
	var cost := v(1).price(poach)  # priced (Pricing): 4 AP, 3 Energy at rank I
	var aps := v(1).ap_cost(poach, null)
	ok(cost == 3 and aps == 4.0, "the cost calculator's price: %s AP, %d Energy" % [aps, cost])
	ok(b.cast(v(1), poach, v(3)), "used")
	ok(v(1).energy == 10 - cost + floori(cost * 0.5) and is_equal_approx(ap - v(1).ap_left(), aps / 2.0), "half its cost back: 1 Energy, 2 AP spent (%d, %s)" % [v(1).energy, ap - v(1).ap_left()])
	ok(b.aimed(v(1), v(3)) == 1, "remembered")
	ok(Battle.edge_of(poach, b.cast_of(v(1), poach, v(3), 1, true)) == 0, "aimed at before: no advantage now")
	v(1).energy = 10
	b.cast(v(1), poach, v(3))
	ok(v(1).energy == 10 - cost, "and full price")


# The price shown is the price paid: Behaviour.rebate() (sure share x, on-hit share y) feeds the HUD's drain
# and Battle's payment; Poach's x comes off before the roll, Slam Jam's y stays a refund, shown "on hit".
func test_price_beforehand() -> void:
	poacher()
	v(1).learned.append(slot(slam_jam, 2))
	v(1).energy = 10
	ok(b.rebate(v(1), poach, v(3), true) == Vector2.ZERO, "a hale foe: no discount")
	var h := await hud(v(1))
	h._refresh()
	v(1).hotbar[1] = poach
	v(1).hotbar[2] = slam_jam
	h.slot = 1
	ok(is_equal_approx(h.drain(h.intent(v(3).cell)).get(&"ap", 0.0), 4.0), "...the full 4 AP shows")
	v(3).hp = 150
	ok(b.rebate(v(1), poach, v(3), true) == Vector2(0.5, 0.0), "bloodied and never aimed at: half, sure")
	var d := h.drain(h.intent(v(3).cell))
	ok(is_equal_approx(d.get(&"ap", 0.0), 2.0) and d.get(&"energy", 0.0) == 2.0 and not d.has(&"on_hit"), "so the forecast already shows 2 AP, 2 Energy (%s)" % d)
	var ap := v(1).ap_left()
	b.cast(v(1), poach, v(3))
	ok(is_equal_approx(ap - v(1).ap_left(), 2.0) and v(1).energy == 8, "and Battle pays just that: 2 AP, 2 Energy")
	ok(b.rebate(v(1), slam_jam, v(3), true) == Vector2(0.0, 0.25), "Slam Jam II: nothing sure, 1/4 on a hit")
	v(1).refresh()
	h.slot = 2
	var sj := h.drain(h.intent(v(3).cell))
	ok(sj.get(&"ap", 0.0) == v(1).ap_cost(slam_jam, null) and sj.get(&"on_hit", {}).get(&"ap", 0.0) > 0.0, "its forecast keeps the full price, with an on-hit refund (%s)" % sj)
	h.free()


# Affordability asks the cut too (Battle.can_afford(): Unit.can_afford(s, cut)): with half of Poach's AP, a
# bloodied foe lets it start, a hale one doesn't - the HUD's reason, the AI's strike, a walk's reach, an
# auto or tile cast's payment all ask the same.
func test_afford_the_cut() -> void:
	poacher()
	v(1).energy = 10
	v(1).pay(v(1).ap_for(&"skill") - 2.0, &"skill")  # 2 AP of the 4 it costs
	ok(not v(1).can_afford(poach) and not b.can_afford(v(1), poach, v(3)), "a hale foe: the full price is out of reach")
	var reads := {v(3): b.read(v(1), v(3))}
	var log: Array[String] = []
	ok(not AI._strike(b, v(1), reads, log), "and the AI doesn't strike")
	var h := await hud(v(1))
	ok("Not enough" in h.why_not(v(1), poach, v(3)), "the HUD says so (%s)" % h.why_not(v(1), poach, v(3)))
	ok(not h._approach(v(1), poach, v(3).cell).ready, "a walk plan says not ready")
	v(3).hp = 150
	ok(not v(1).can_afford(poach) and b.can_afford(v(1), poach, v(3)) and v(1).can_afford(poach, 0.5), "bloodied: half the price, so it can")
	ok(h.why_not(v(1), poach, v(3)) == "", "the HUD lets it (%s)" % h.why_not(v(1), poach, v(3)))
	ok(h._approach(v(1), poach, v(3).cell).ready, "and a walk plan calls it ready")
	ok(AI._strike(b, v(1), reads, log) and "Poach" in log[0], "the AI strikes (%s)" % [log])
	ok(is_equal_approx(v(1).ap_for(&"skill"), 0.0), "and paid the 2 AP")
	h.free()
	b._aimed.clear()  # (it has aimed at it now)
	ok(b.price_cut(v(1), poach, [v(3)] as Array[Unit]) == 0.5 and b.price_cut(v(1), poach, [] as Array[Unit]) == 0.0, "the cut a target grants, none with none to ask")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(3, 3)})
	soak(v(2), 300)
	ok(b.price_cut(v(1), poach, [v(3), v(2)] as Array[Unit]) == 0.0, "a price shared by a hale foe too: no cut")
	for how in [&"auto", &"tile"]:  # the one price of an auto cast, or a cast at the foe's tile, takes the cut
		var s: Skill = load("res://Skills/poach.tres").duplicate()
		s.auto = how == &"auto"
		s.channel = how == &"tile"
		v(1).learned.append(slot(s, 1))
		v(1).refresh()
		v(1).energy = 10
		v(1).pay(v(1).ap_for(&"skill") - 2.0, &"skill")
		v(3).hp = 150
		b._aimed.clear()
		ok((b.cast_at(v(1), s, v(3).cell) if s.channel else b.cast(v(1), s, v(1))) and is_equal_approx(v(1).ap_for(&"skill"), 0.0), "%s: 2 AP paid of 4" % how)
		v(1).learned.erase(v(1).learned.back())
		v(1).refresh()


func test_regain() -> void:
	poacher(2)
	v(1).learned.append(slot(stamina, 1))
	v(1).max_energy = 40
	v(1).energy = 10
	v(1).endurance = 5
	var pools := v(1).pools()
	ok(stamina_r in pools, "it has Stamina")
	v(1).set_store(stamina_r, 0)
	v(3).hp = 1
	var got := []
	b.neutralized.connect(func(u: Unit, by: Unit, how: StringName): got.append([u, by, how]))
	ok(b.cast(v(1), poach, v(3)), "used")
	ok(got.size() == 1 and got[0][0] == v(3) and got[0][1] == v(1), "neutralized: %s" % [got])
	var paid := v(1).price(poach) - floori(v(1).price(poach) * 0.5)  # bloodied and new: half back
	ok(v(1).energy == 10 - paid + 4, "10%% of 40 Energy back at rank II, after paying (%d)" % v(1).energy)
	ok(v(1).store(stamina_r) == mini(v(1).rounded(0.2 * pools[stamina_r]), pools[stamina_r]), "20%% of its Stamina back (%d of %d)" % [v(1).store(stamina_r), pools[stamina_r]])
	ok(v(1).endurance == 3, "each a recovery: 2 RE spent (%d)" % v(1).endurance)


func test_rangers() -> void:
	var ranger: Role = load("res://Roles/ranger.tres")
	ok(ranger.choices.any(func(c: TreeChoice): return c.tabs.any(func(t: SkillTab): return t.offers(poach))), "the Ranger's Slayer tab (Prowess, opened by Quarry) offers it")
	ok(not poach.ai and poach.name == "Poach", "the user's")
	ok("bloodied" in poach.describe(1), poach.describe(1))
