extends Test

# Discipline (Battle._discipline(): AP burned into an attack for accuracy, damage and crits), the
# Ranger (its knack, Nature trees learned at -1 until it invests in magic, Natural Talent) and the
# Druid (biomes picked on its own tab, guest trees spared their penalty when kin or elemental, a skill
# shared by two trees reached on each, Beastshape: Battle.form_for(), Unit.shape()).

func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func make(role: String, n: String) -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/%s.tres" % role), name = n})
	b.get_node("Units").add_child(u)
	return u


func choice(u: Unit, n: String) -> TreeChoice:
	return u.role.choices.filter(func(c: TreeChoice): return c.name == n)[0]


func tab(c: TreeChoice, n: String) -> SkillTab:
	return c.all().filter(func(t: SkillTab): return t.name == n)[0]


func first_bonus(u: Unit, t: Unit) -> int:
	var rolls: Array = []
	var log := func(_c, _t, d20: int, total: int, _def): rolls.append(total - d20)
	b.attacked.connect(log)
	b.cast(u, strike, t)
	b.attacked.disconnect(log)
	return rolls[0] if not rolls.is_empty() else -99


func test_discipline() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(4, 3)})
	v(3).max_hp = 999
	v(3).hp = 999
	var d := sk("discipline")
	v(1).learned.append(slot(d, 2))
	v(1).toggle(d)
	v(1).refresh()
	var plain := first_bonus(v(1), v(3))
	ok(v(1).disciplined == 0, "switched off: nothing burned")
	v(1).toggle(d)
	v(1).refresh()
	var before := v(1).ap_for(&"skill")
	var keen := first_bonus(v(1), v(3))
	ok(v(1).disciplined == 2 and is_equal_approx(before - v(1).ap_for(&"skill"), strike.ap + 2.0), "on, rank II: 2 more AP burned into the Strike")
	ok(keen == plain + 2 * Battle.DISCIPLINE_HIT, "+%d to hit a point burned (%d against %d)" % [Battle.DISCIPLINE_HIT, keen, plain])
	ok(Check.attack(0, 10).keen(2).crit_on == 18 and Check.attack(0, 10).crit_on == 20, "and it crits on 18 and up")
	ok(d.describe(2).contains("burns up to 2"), "described: %s" % d.describe(2))
	v(1).refresh()
	v(1).pay(v(1).ap_for(&"skill") - strike.ap, &"skill")
	first_bonus(v(1), v(3))
	ok(v(1).disciplined == 0, "AP spent first: nothing left to burn")
	ok(d in load("res://Roles/paladin.tres").options and d in load("res://Roles/mage.tres").options, "on the Paladin's and the Mage's own trees")
	ok(load("res://Trees/general_specialist.tres").tier_of(d) == 3, "a specialist general skill, tier 3")


func test_ranger() -> void:
	var u := make("ranger", "Wren")
	ok(u.affinity(sk("discipline")) == 1, "Discipline comes easier to a Ranger: Affinity +1")
	var nature := choice(u, "Nature")
	ok(nature.all().map(func(t: SkillTab): return t.name) == ["Astral", "Sylvan", "Montane", "Xeric", "Nival", "Thalassic"], "the Druid's biomes, as Nature trees")
	ok(u.pick_missing(nature, tab(nature, "Montane")) == "Learn Wildcaller first", "Nature waits on its capstone, Wildcaller")
	u.learned.append(slot(sk("first_aid"), 1))
	u.learned.append(slot(sk("wildcaller"), 1))
	ok(u.pick(nature, tab(nature, "Montane")), "picks Montane")
	ok(u.affinity(sk("quake")) == -1 and u.affinity(sk("terestera")) < 1, "magic comes hard: -1")
	ok(u.affinity(sk("stonegift")) == 0, "but Wildcaller I is an efficiency stack up to tier 1: Stonegift at 0")
	u.learned.append(slot(sk("natural_talent"), 1))
	ok(u.affinity(sk("stonegift")) == 1 and u.affinity(sk("quake")) == -1, "Natural Talent I: tier 1 at +1, tier 2 still -1")
	for n in ["terestera", "mage_armor", "astera", "igna"]:
		u.learned.append(slot(sk(n), 1))
	ok(u.magic_learned() == 4 and u.affinity(sk("quake")) == 0 and u.affinity(sk("stonegift")) == 2, "4 magical skills learned: the penalty lifts, the talent and the stack stay")
	var plain := make("fighter", "Fen")
	ok(plain.affinity(sk("discipline")) == 0, "no knack, no ease")


func test_druid_biomes() -> void:
	var u := make("druid", "Bryn")
	var biome := choice(u, "Biome")
	ok(u.rank(sk("beastshape")) == 1 and u.class_trees().map(func(t: SkillTab): return t.name) == ["Druid"], "Beastshape from the start; no biome open yet")
	ok(u.pick(biome, tab(biome, "Astral")) and u.pick(biome, tab(biome, "Thalassic")) and not u.pick(biome, tab(biome, "Sylvan")), "two biomes, no more")
	ok(u.biomes() == [&"astral", &"thalassic"], "%s" % [u.biomes()])
	var mana: Reserve = load("res://Reserves/mana.tres")
	ok(u.pools().get(mana, 0) == 10 and u.store(mana) == 10, "Astral grants mana: 10, full")
	var guest := choice(u, "Guest")
	var names: Array = guest.all().map(func(t: SkillTab): return t.name)
	ok(names.has("Stars") and names.has("Battle") and not names.has("Astral"), "guest trees: the Mage's schools and colleges (%s)" % [names])
	ok(u.pick(guest, tab(guest, "Stars")), "a guest tree")
	ok(u.affinity(sk("fortune")) == 0, "Stars is kin to Astral: no penalty")
	var v2 := make("druid", "Ash")
	var b2 := choice(v2, "Biome")
	var g2 := choice(v2, "Guest")
	v2.pick(b2, tab(b2, "Sylvan"))
	v2.pick(g2, tab(g2, "Battle"))
	var battle_skill: Skill = tab(g2, "Battle").roots[0].skills()[0]
	ok(v2.affinity(battle_skill) == -1, "a college, kin to nothing it picked: -1 (%s)" % battle_skill.name)
	var v3 := make("druid", "Oak")
	v3.pick(choice(v3, "Biome"), tab(choice(v3, "Biome"), "Sylvan"))
	v3.pick(choice(v3, "Guest"), tab(choice(v3, "Guest"), "Currents"))
	ok(v3.affinity(sk("hydera")) >= 0, "an elemental (water) guest skill: no penalty either")


# A skill on two trees is one skill; having it from one doesn't skip the way to it on the other.
func test_shared_skill() -> void:
	var u := make("druid", "Bryn")
	u.pick(choice(u, "Biome"), tab(choice(u, "Biome"), "Astral"))
	u.pick(choice(u, "Guest"), tab(choice(u, "Guest"), "Stars"))
	var astral: SkillRoot = load("res://Trees/astral.tres")
	var stars: SkillRoot = load("res://Trees/stars.tres")
	u.learned.append(slot(sk("mana"), 1))
	u.learned.append(slot(sk("fortune"), 1))
	ok(u.reached(astral, sk("fortune")) and not u.reached(stars, sk("fortune")), "Fortune by Astral's way (after Mana): not reached on Stars, where it comes after Astera")
	ok(u.missing(sk("starkind")) == "", "Astral goes on past it")
	u.learned.append(slot(sk("astera"), 1))
	ok(u.reached(stars, sk("fortune")), "Astera learned: Stars' way to Fortune is walked too")
	ok(u.slots.filter(func(x: Slot): return x.skill == sk("fortune")).size() == 1, "one Fortune, ranked once")


func test_beastshape() -> void:
	var u := make("druid", "Bryn")
	var biome := choice(u, "Biome")
	u.pick(biome, tab(biome, "Sylvan"))
	stage(lancin, {u: Vector2i(3, 3), v(3): Vector2i(6, 3)})
	u.refresh()
	var shape := sk("beastshape")
	ok(b.form_for(u) == [&"rabbit", &""], "Sylvan on grass: a rabbit (%s)" % [b.form_for(u)])
	var moves := u.stat(&"movement")
	ok(b.cast(u, shape, u) and u.form == &"rabbit" and u.stat(&"movement") == moves + 1.0, "shaped: haste, +rank movement")
	ok(u.shaped_allows(strike) and u.shaped_allows(shape) and not u.shaped_allows(sk("hide")), "a beast's mind: Strike and Beastshape, not its other skills")
	ok(b.cast(u, shape, u) and u.form == &"" and u.stat(&"movement") == moves, "used again: itself")
	u.ground = [&"stone"] as Array[StringName]
	ok(b.form_for(u) == [&"mole", &""], "on stone: a mole")
	u.ground = [&"star"] as Array[StringName]
	ok(b.form_for(u).is_empty(), "on a startile, nothing of the Sylvan thrives")
	var star := make("druid", "Vela")
	star.pick(choice(star, "Biome"), tab(choice(star, "Biome"), "Astral"))
	star.ground = [&"star", &"glass"] as Array[StringName]
	ok(b.form_for(star) == [&"wisp", &""], "Astral on a startile: a wisp")
	star.ground = [&"water", &"wet"] as Array[StringName]
	ok(b.form_for(star) == [&"mote", &"water"], "Astral on water: a mote of water")
	star.shape(&"mote", &"water", 2, 3)
	ok(star.element == &"water" and star.imbued == 2, "its Strikes carry water, rank uses")
	for i in 3:
		star.refresh()
	ok(star.form == &"", "rank + 1 turns, then itself")
	u.shape(&"mole", &"", 3, 4)
	var stone: Terrain = load("res://Terrain/stone.tres")
	var plain: Terrain = Battle.PLAIN
	ok(b._cost(u, plain, stone) == maxf(b._cost(null, plain, stone) / 3.0, minf(b._cost(null, plain, stone), 1.0)), "a mole tunnels: stone's cost cut by its rank, to 1")
