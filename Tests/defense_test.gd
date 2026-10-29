extends Test

# Defense (armor, tagged defense), attack rolls against it, weapons, energy recovery, and the
# clover slot luck gives (Unit.defense(), Battle.cast(), Unit.recover(), Unit.clover()).
# Villagers: str/dex/con/wis 12 (+1), luck +1 for Lancin's (Favour).

var gambeson: Item = load("res://Items/gambeson.tres")
var plate: Item = load("res://Items/plate.tres")
var robe: Item = load("res://Items/robe.tres")
var rapier: Item = load("res://Items/rapier.tres")
var mage_armor: Skill = load("res://Skills/mage_armor.tres")


func icor() -> Unit:
	return b.get_node("Units/Icor")


func test_armor() -> void:
	ok(v(1).defense() == 2 and v(3).defense() == 2, "unarmored: dex mod + con mod (1 + 1)")
	v(1).constitution = 4
	ok(v(1).defense() == -2, "...which can go below 0 (con 4: -3)")
	v(1).armor = gambeson
	ok(v(1).defense() == 11, "Gambeson: 10 (more than level / 2) + dex mod")
	v(1).level = 21
	v(3).armor = gambeson
	v(3).level = 21
	ok(v(3).defense() == 11 and v(1).defense() == 12, "level 21: 10.5 rounds down to 10 - up to 11 for the lucky")
	v(1).armor = plate
	ok(v(1).defense() == 21, "Plate: the higher of 20 and level, no dex")
	v(1).level = 1
	ok(v(1).defense() == 20, "...20 at level 1")
	v(1).armor = robe
	ok(v(1).defense() == 8, "Robe: 8 at level 1, no dex")
	v(1).level = 41
	v(3).armor = robe
	v(3).level = 41
	ok(v(1).defense() == 11 and v(3).defense() == 10, "level 41: 10.25 is 11 for the lucky, 10 for the rest")
	ok(gambeson.describe() == "Defense: the higher of 10 and level / 2, + dex mod", "describes itself (%s)" % gambeson.describe())
	ok(plate.describe() == "Defense: the higher of 20 and level" and robe.describe() == "Defense: the higher of 8 and level / 4", "Plate, Robe")


func test_tagged_defense() -> void:
	var u := v(3)
	u.afflict(effect("defense", 2, [&"physical"]), 3)
	ok(u.defense() == 2 and u.defense([&"magical"]) == 2, "physical Defense doesn't count against untagged or magical attacks")
	ok(u.defense([&"physical"]) == 4 and u.defense([&"pierce"]) == 4 and u.defense([&"slash", &"dark"]) == 4,
			"...but does against physical ones and their children")
	u.afflict(effect("defense", 3, [&"pierce"]), 3)
	ok(u.defense([&"pierce"]) == 7 and u.defense([&"physical"]) == 4 and u.defense([&"blunt"]) == 4, "pierce Defense: only against pierces")
	u.afflict(effect("defense", 1), 3)
	ok(u.defense() == 3 and u.defense([&"magical"]) == 3 and u.defense([&"pierce"]) == 8, "untagged: against everything")
	ok(u.tagged_defense() == {&"physical": 2, &"pierce": 5}, "what it has on top, by tag (%s)" % u.tagged_defense())
	ok(effect("defense", 2, [&"physical"]).describe() == "Defense: +2 (physical)", "described")


func test_mage_armor() -> void:
	var u := icor()
	ok(u.defense() == -1, "Icor unarmored: dex 10 (0) + con 8 (-1)")
	u.learned.append(slot(mage_armor))
	ok(u.defense() == 3, "Mage Armor: + int mod (18: +4)")
	ok(u.toggle(mage_armor) and u.defense() == -1, "switched off")
	ok(mage_armor in load("res://Roles/wizard.tres").options, "a Wizard option")
	ok("Defense: +1 per int mod" in mage_armor.describe(), "described (%s)" % mage_armor.describe())


func test_attack_roll() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(strike.attacks() and strike.stat() == &"strength" and hex.stat() == &"wisdom", "Strike rolls str, Hex wis (their tags)")
	ok(Battle.hit_chance(v(1), strike, v(3)) == 1.0, "d20 + 1 against Defense 2: always")
	v(3).armor = plate
	ok(is_equal_approx(Battle.hit_chance(v(1), strike, v(3)), 0.1), "against Plate (20): 19 and 20 only")
	v(3).max_hp = 500
	v(3).heal(500)
	var rolls := []
	b.attacked.connect(func(c: Unit, t: Unit, d20: int, total: int, defense: int): rolls.append([c, t, d20, total, defense]))
	var dealt := {}
	for i in 80:
		v(1).refresh()
		var was := v(3).hp
		ok(b.cast(v(1), strike, v(3)), "cast, hit or miss")
		var r: Array = rolls[-1]
		ok(r[0] == v(1) and r[1] == v(3) and r[3] == r[2] + 1 and r[4] == 20, "rolled d20 + 1 against 20")
		var hit: bool = r[2] >= 19
		ok((was - v(3).hp > 0) == hit, "damage only on a hit (d20 %d)" % r[2])
		dealt[r[2]] = was - v(3).hp
	ok(dealt.get(19) == 2 and dealt.get(20) == 4, "a hit does 1 + str mod; a natural 20 doubles it (%s)" % dealt)
	ok(dealt.keys().any(func(d): return d < 19), "and there were misses")


func test_nat_20_beats_any_defense() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).afflict(effect("defense", 50), 3)
	ok(is_equal_approx(Battle.hit_chance(v(1), strike, v(3)), 0.05), "Defense 52: a natural 20 still hits")


func test_miss() -> void:
	stage(nemes, {v(3): Vector2i(4, 3), v(1): Vector2i(5, 3)})
	v(1).armor = plate
	v(1).afflict(effect("concealment", 2), 3)
	v(3).afflict(effect("concealment", 2), 3)
	var d20 := [0]
	b.attacked.connect(func(_c, _t, d: int, _total, _def): d20[0] = d)
	for seed in 40:
		b.rng.seed = seed
		v(3).refresh()
		v(1).timed.erase(hex.effects[0])
		var luck := v(1).luck
		v(1).exposed = 0
		v(3).exposed = 0
		v(3).energy = 10
		ok(b.cast(v(3), hex, v(1)), "Hex cast")
		if d20[0] + 1 < 20 and d20[0] != 20:
			ok(v(1).luck == luck and v(1).exposed == 1 and v(3).exposed == 0,
					"a miss: no luck lost; the target gives itself away, the caster doesn't")
			return
	ok(false, "no miss in 40 seeds")


func test_damage_floor() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).strength = 1
	for seed in 10:
		b.rng.seed = seed
		v(1).refresh()
		var was := v(3).hp
		b.cast(v(1), strike, v(3))
		var lost := was - v(3).hp
		ok(lost in [0, 1, 2], "str 1 (-5): 1 + -5 floors at 1 (2 on a natural 20), or a miss (%d)" % lost)


func test_weapon() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).dexterity = 18
	ok(v(1).attack_mod(strike) == 1, "Strike: str mod")
	v(1).weapon = rapier
	ok(v(1).wielded(&"strength") == &"dexterity" and v(1).attack_mod(strike) == 4, "a rapier lets it use dex instead")
	ok(v(1).wielded(&"wisdom") == &"wisdom", "only for strength")
	v(1).strength = 20
	ok(v(1).attack_mod(strike) == 5, "whichever is better")
	v(1).strength = 12
	v(3).max_hp = 50
	v(3).heal(50)
	b.rng.seed = 3
	b.cast(v(1), strike, v(3))
	ok(50 - v(3).hp in [5, 10], "damage uses it too: 1 + 4 (%d)" % (50 - v(3).hp))
	ok(rapier.describe() == "Weapon: strength attacks may use dexterity", "described")


# Ends Lancin's turn and Nemes' after it, so Lancin's next turn starts.
func round_trip() -> void:
	b.end_turn()
	b.end_turn()


func test_energy_recovery() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): Vector2i(8, 2), v(4): Vector2i(8, 5)})
	for u in [v(1), v(2), v(3)]:
		u.energy = 2
	ok(v(1).activity() == &"rest", "nothing done yet: resting")
	b.travel(v(2), Vector2i(1, 6))
	ok(v(2).activity() == &"light", "a step on its dex AP alone: light activity")
	b.travel(v(1), Vector2i(1, 0))
	ok(v(1).activity() == &"busy", "two steps, into its general AP: busy")
	b.end_turn()
	ok(v(1).energy == 2, "busy: nothing back")
	ok(v(2).energy == 2 and is_equal_approx(v(2).rest, 0.5), "light: half a point, banked")
	b.end_turn()
	ok(v(3).energy == 3, "the other side recovers as its turn ends")
	b.travel(v(2), Vector2i(1, 7))
	b.end_turn()
	ok(v(2).energy == 3, "two light turns: a point")
	ok(v(1).energy == 3, "resting: (con mod + wis mod) / 2 = 1 a turn")
	b.end_turn()
	v(1).constitution = 14
	v(3).constitution = 14
	b.end_turn()
	ok(v(1).energy == 5, "(2 + 1) / 2 = 1.5: 2 for the lucky")
	b.end_turn()
	ok(v(3).energy == 5, "...1 for the rest")
	v(1).constitution = 4
	v(1).wisdom = 4
	v(1).energy = 0
	var got := []
	for i in 8:
		round_trip()
		got.append(v(1).energy)
	ok(got == [0, 0, 0, 1, 1, 1, 1, 2], "(-3 + -3) / 2 = -3: a point every 4 turns rested (%s)" % [got])
	v(1).constitution = 12
	v(1).wisdom = 12
	v(1).energy = v(1).max_energy
	round_trip()
	ok(v(1).energy == v(1).max_energy and v(1).rest == 0.0, "full: nothing banked")


func test_clover_slot() -> void:
	var u := v(1)
	ok(u.slot_count() == 4 and u.clover() == 4 and u.bar_size() == 5 and u.slot_works(4), "lucky at level 1: 4 + 1/4 rounds up, a clover slot")
	ok(v(3).clover() == 4 and not v(3).slot_works(4) and v(3).bar_size() == 5, "unlucky: the clover slot is there, but doesn't work")
	ok(u.bar_place(strike, 4) and u.hotbar[4] == strike, "a skill can go in it")
	u.afflict(effect("luck", -1), 3)
	ok(u.luck == 0 and not u.slot_works(4) and u.hotbar[4] == strike, "luck gone: it stops working, keeping its skill")
	ok(not u.bar_place(strike, 4), "nothing new goes in")
	u.timed.clear()
	ok(u.slot_works(4), "lucky again: back")
	u.level_up()
	u.level_up()
	u.level_up()
	ok(u.level == 4 and u.clover() == -1 and u.slot_count() == 5 and u.bar_size() == 5, "level 4: nothing to round, a plain fifth slot")
	u.afflict(effect("luck", -1), 3)
	ok(u.slot_works(4), "...that works without luck")
	u.level_up()
	ok(u.clover() == 5 and u.bar_size() == 6 and u.hotbar.size() == 6 and not u.slot_works(5), "level 5: 5 slots, and a clover sixth (not working while unlucky)")
	u.hotbar.assign([strike, strike, strike, strike, strike, null])
	u.skill_points = 1
	u.lore.append(hex)
	ok(u.unlock(hex) and u.rank(hex) == 1 and hex not in u.hotbar, "learned, but kept off the bar: its only free slot is a clover one that isn't working")
	u.timed.clear()
	u.bar_clear(1)
	u.skill_points = 1
	u.lore.append(wary)
	ok(u.free_slot() == 1, "the first free slot that works")
