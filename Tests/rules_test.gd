extends Test

# Luck rounding, tags, stats and the passives that feed them, contest() and initiative.


func test_settle() -> void:
	ok(Luck.settle(0.5, 1, true) == 1 and Luck.settle(0.5, 0, true) == 0 and Luck.settle(0.5, -1, true) == 0, "rounds my way only with net luck > 0")
	ok(Luck.settle(1.98, 1, false) == 1 and Luck.settle(1.98, 0, false) == 2, "damage taken: standard rounds up")
	ok(Luck.settle(0.5, 0, true, true) == 1 and Luck.settle(0.5, -1, true, true) == 0, "net 0 follows the standard, net < 0 goes against")
	ok(Luck.settle(100 * 0.01, 0, true) == 1 and Luck.settle(100 * 0.01, 1, false) == 1, "float noise doesn't round")


func test_tags() -> void:
	ok(&"physical" in Tags.expand([&"slash"]) and &"physical" in Tags.expand([&"pierce"]) and &"physical" in Tags.expand([&"blunt"]), "slash/pierce/blunt are physical")
	ok(&"physical" not in Tags.expand([&"dark"]), "dark isn't")


func test_stats() -> void:
	var u := v(1)
	ok(u.stat(&"strength") == 12 and u.mod(&"strength") == 1 and u.mod(&"intelligence") == -1, "d20 mods: 12 -> +1, 8 -> -1")
	u.afflict(effect("strength", 2))
	ok(u.stat(&"strength") == 14 and u.mod(&"strength") == 2, "effects add to core stats")
	ok(u.stat(&"nonsense") == 0.0, "unknown stats are 0")
	u.afflict(effect("mitigate", 0.1))
	ok(is_equal_approx(u.mitigation([&"fire"]), 0.1), "untagged effects apply to every query")


func test_favour() -> void:
	ok(v(1).passives == [favour] and v(1).luck == 1, "Lancin: Favour, luck 1")
	ok(is_equal_approx(v(1).mitigation([&"slash"]), 0.01) and is_equal_approx(v(1).mitigation([&"dark"]), 0.01), "1% vs physical and dark")
	ok(v(1).mitigation([&"fire"]) == 0.0, "nothing vs fire")
	ok(v(1).hit(10, [&"slash"]) == 9, "vs no attacker: 9.9 rounds my way -> 9")
	ok(v(1).hit(10, [&"slash"], v(2)) == 10, "vs an equally lucky attacker: net 0, standard -> 10")


func test_wary() -> void:
	ok(v(3).passives == [wary] and v(3).luck == 0, "Nemes: Wary, luck 0")
	ok(b.initiative_bonus(nemes) == 1 and b.initiative_bonus(lancin) == 0, "+1 initiative, not +2 for two Wary units")
	v(4).damage(99)
	ok(b.initiative_bonus(nemes) == 1, "one living Wary unit is enough")
	v(3).max_hp = 50
	v(3).heal(50)
	ok(v(3).hit(10, [&"ambush"]) == 8 and v(3).hit(7, [&"ambush"]) == 6, "20% off ambushes; 5.6 rounds up to 6")
	ok(v(3).hit(10, [&"slash"]) == 10, "nothing off plain physical")
	v(3).damage(99)
	ok(b.initiative_bonus(nemes) == 0, "dead units don't count")


func test_manifest() -> void:
	var u := v(1)
	u.learned = [manifest]
	u.charisma = 25
	ok(u.luck == 2, "cha 25 -> +2")
	u.charisma = 8
	ok(u.luck == 0, "cha 8 -> +0")
	u.learned = [manifest, favour]
	u.charisma = 19
	ok(u.luck == 2, "stacks with Favour")


func test_contest_chain() -> void:
	b.rolls = {lancin: [10, 5], nemes: [7, 7]}
	ok(b.total(lancin) == 15 and b.total(nemes) == 15, "15-15 (Nemes 14 + Wary)")
	var st := b.rng.state
	ok(b.contest([nemes, lancin], [b.total]) == [lancin, nemes], "tie -> best luck")
	ok(b.rng.state == st, "no coin when luck settles it")
	v(1).afflict(hex.effects[0])
	v(2).afflict(hex.effects[0])
	v(4).dexterity = 13
	ok(b.contest([lancin, nemes], [b.total]) == [nemes, lancin], "luck tie -> dexterity")
	v(4).dexterity = 12
	var wins := 0
	for seed in 400:
		b.rng.seed = seed
		wins += int(b.contest([lancin, nemes], [b.total])[0] == lancin)
	ok(wins > 150 and wins < 250, "full tie -> coin (%d/400)" % wins)


func test_contest_sides() -> void:
	ok(b.contest([v(3), v(1)]) == [v(1), v(3)], "units")
	ok(b.contest([[v(3), v(4)], [v(1), v(2)]]) == [[v(1), v(2)], [v(3), v(4)]], "groups")
	ok(b.contest([v(3), v(1)], [func(x): return 10 if x == v(1) else 10.0]) == [v(1), v(3)], "10 ties 10.0")
	v(1).damage(99)
	ok(b.contest([v(1), v(3)])[0] == v(3), "a dead side has no luck")


func test_initiative() -> void:
	var sums := true
	for seed in 100:
		b.rng.seed = seed
		var o := b.roll_initiative()
		sums = sums and b.rolls[lancin].size() == 2 and b.total(o[0]) >= b.total(o[1])
		sums = sums and b.total(nemes) == b.rolls[nemes][0] + b.rolls[nemes][1] + 1
	ok(sums, "2d20 per faction, Nemes +1, highest first")
