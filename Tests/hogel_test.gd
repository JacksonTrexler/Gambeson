extends Test

# Chant (waiting a turn out primes Sweet Nothing gains and the next Warlock skill), Hogel's path (Gasp,
# Breathtaking's Asphyxia, Irradiate), the Cleric (a god per tab), and Synergy within command range
# (a Quartz Ring: no limit).

var chant: Skill = load("res://Skills/chant.tres")
var gasp: Skill = load("res://Skills/gasp.tres")
var breathtaking: Skill = load("res://Skills/breathtaking.tres")
var irradiate: Skill = load("res://Skills/irradiate.tres")
var sweet: Skill = load("res://Skills/sweet_nothings.tres")
var sn: Reserve = load("res://Reserves/sweet_nothings.tres")
var warlock: Role = load("res://Roles/warlock.tres")
var cleric: Role = load("res://Roles/cleric.tres")
var synergy: Skill = load("res://Skills/synergy.tres")


func test_tree() -> void:
	ok(warlock.tier(gasp) == 1 and warlock.tier(breathtaking) == 2 and warlock.tier(irradiate) == 3, "Hogel: Gasp I, Breathtaking II, Irradiate III")
	ok(not chant.stub and chant.passive, "Chant is built")


func test_chant() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	v(3).charisma = 16
	v(3).learned.append_array([slot(sweet), slot(chant, 2), slot(gasp)])
	v(3).set_store(sn, 0)
	v(3).refresh()
	b.end_turn()  # it waited the turn out
	ok(v(3).chant_gains == 2 and v(3).chant_up, "rank II: primed for two gains and a ranked-up skill")
	ok(v(3).rank(gasp) == 2 and v(3).rank(strike) == 1, "its next Warlock skill a rank up (not Strike)")
	v(3).gain(&"patron", 1)
	ok(v(3).store(sn) == 2 and v(3).chant_gains == 1, "a gain of 1 brings 2")
	b.turn = nemes
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	v(3).refresh()
	b.cast(v(3), gasp, v(1))
	ok(not v(3).chant_up and v(3).rank(gasp) == 1, "spent on the next one")


func test_gasp() -> void:
	stage(nemes, {v(3): Vector2i(8, 2), v(1): Vector2i(1, 2)})
	v(3).charisma = 12
	v(3).learned.append(slot(gasp, 2))
	ok(is_equal_approx(gasp.span(v(3)), 12.0 + 2.0), "range: cha itself (12) + rank")
	v(1).armor = bulwark()  # Defense 20: room to tell them apart
	var g := Battle.hit_chance(v(3), gasp, v(1))
	var h := Battle.hit_chance(v(3), load("res://Skills/hex.tres"), v(1))
	ok(g > h, "easier to hit than Hex: advantage, + rank (%s vs %s)" % [g, h])
	v(1).armor = null
	ok(gasp.describe(2).contains("Attack with Advantage (cha mod + 2)"), gasp.describe(2))


func test_asphyxia() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	v(3).charisma = 40
	v(3).learned.append_array([slot(gasp), slot(breathtaking, 3)])
	v(1).max_hp = 100
	v(1).hp = 100
	v(1).refit()
	var max0 := v(1).max_hp
	v(3).refresh()
	b.cast(v(3), gasp, v(1))
	b.cast(v(3), gasp, v(1))
	var a: Unit.Applied = v(1).timed.get(Battle.ASPHYXIA)
	ok(a != null and a.rank == 2 and v(1).max_hp == max0 - 6, "two curses: two stacks of 3%% max HP gone each (%d -> %d)" % [max0, v(1).max_hp])
	for i in 3:
		v(1).tick()
	ok(v(1).timed[Battle.ASPHYXIA].rank == 2, "held for 1 + rank (4) turns")
	v(1).tick()
	ok(v(1).timed[Battle.ASPHYXIA].rank == 1 and v(1).max_hp == max0 - 3, "then falls a stack a turn")


func test_irradiate() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	v(3).charisma = 40  # mod 15
	v(3).learned.append_array([slot(gasp), slot(irradiate, 2)])
	v(1).max_hp = 100
	v(1).hp = 100
	v(3).refresh()
	b.cast(v(3), gasp, v(1))
	ok(100 - v(1).hp > 1 and 100 - v(1).hp <= 1 + 2 + 15, "the roll's overage as light damage too, up to rank + cha mod (%d)" % (100 - v(1).hp))


func test_cleric() -> void:
	var u := b.starter({faction = lancin, role = cleric, name = "Abbot"})
	b.get_node("Units").add_child(u)
	ok(u.rank(load("res://Skills/pray.tres")) == 1 and u.rank(load("res://Skills/renew.tres")) == 1, "Pray and Renew from the start")
	var god: TreeChoice = cleric.choices[0]
	ok(cleric.trees().map(func(t: SkillTab): return t.title()) == ["Cleric", "Divinity: Luun", "Divinity: Sol"] and god.name == "God", "its own tab, then a tab per god to pick")
	ok(u.deity() == &"" and u.class_trees().size() == 1, "no god yet: only its own tab")
	u.skill_points = 2
	var level_down: Skill = load("res://Skills/level_down.tres")
	ok(u.missing(level_down) == "Pick Divinity: Luun first", "Luun's skills wait for Luun")
	ok(u.pick(god, god.tabs[0]) and u.deity() == &"luun" and u.unlock(level_down), "Luun picked: whom it now prays to; Level Down")
	ok(u.pick_missing(god, god.tabs[1]) == "Took up Divinity: Luun" and u.missing(load("res://Skills/level_up.tres")) == "Pick Divinity: Sol first", "Sol stays shut")
	ok(u.funding(level_down) == &"energy", "no Sweet Nothings to need: Energy pays")
	u.wisdom = 18
	ok(u.mod(&"charisma", level_down.tags) == 4, "its magical skills use wis for cha")


func test_synergy_range() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(8, 8), v(3): Vector2i(8, 2)})
	v(2).follows = v(1)
	v(2).learned.append(slot(synergy))
	v(1).charisma = 10  # reach 1, party reach 2
	ok(b.synergized(v(1)).is_empty(), "out of the leader's command range: nothing shared")
	v(1).equip(load("res://Items/quartz_ring.tres"))
	ok(Array(b.synergized(v(1))) == [v(2)], "a Quartz Ring: no limit")
	ok(load("res://Items/quartz_ring.tres").describe().contains("Command: no limit"), load("res://Items/quartz_ring.tres").describe())
