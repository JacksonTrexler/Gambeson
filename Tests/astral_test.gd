extends Test

# The Astral Envoy and its Princess: Power (Powerful: Energy that never comes back on its own), energy
# damage (Smite: Energy first, then a share on to HP), a channeled spell (Metea: cast, then strike
# within a tile a turn of where it was cast), persona descriptors (intention, strategy) that insight
# reads and the AI follows, and the scenario itself played through by the AI.

var princess: PackedScene = load("res://Scenes/astral_princess.tscn")
var smite: Skill = load("res://Skills/smite.tres")
var metea: Skill = load("res://Skills/metea.tres")


func her(at: Vector2i) -> Unit:
	var p: Unit = princess.instantiate()
	p.faction = nemes
	p.cell = at
	b.get_node("Units").add_child(p)
	b.move(p, at)
	return p


func test_princess() -> void:
	var p := her(Vector2i(9, 7))
	ok(p.level == 18 and p.lives() == 2 and p.weapon.name == "Starblade" and p.trinket.name == "Heart Up", "level 18, two lives: Heart Up-Link (con mod 1) and Heart Up")
	ok(p.powered() and p.recover() == 0, "Powerful: its Energy is Power, which doesn't come back by resting")
	ok(p.pillars().size() == 2 and p.disable_order()[0].size() == 2, "Powerful and Physical Intelligence: pillars, the first slot a curse reaches")
	ok(p.alias.split(" ")[0] in p.shows_adjectives and p.alias.split(" ")[1] in p.shows_nouns, "goes by a name from her pools: %s" % p.alias)


func test_smite() -> void:
	var p := her(Vector2i(5, 3))
	stage(nemes, {p: Vector2i(5, 3), v(1): Vector2i(4, 3)})
	v(1).max_hp = 200
	v(1).hp = 200
	v(1).max_energy = 5
	v(1).energy = 5
	var hit := false
	for i in 20:
		p.refresh()
		var was := v(1).hp
		var energy := v(1).energy
		b.cast(p, smite, v(1))
		if v(1).energy < energy:
			hit = true
			ok(v(1).energy == 0 and v(1).hp < was, "rank V: Energy first, then on to HP (%d -> %d)" % [was, v(1).hp])
			break
	ok(hit, "it landed")
	ok(Battle.hit_tags(p, smite).has(&"energy"), "her god is Urlo: Smite's damage is energy")
	ok("Urlo (energy): drains Energy (or Power) first, then 80% of the rest goes on to HP" in smite.describe(5), smite.describe(5))
	ok(smite.describe(1).contains("first") and not smite.describe(1).contains("of the rest"), "rank I: no carry")


func test_metea() -> void:
	var p := her(Vector2i(9, 3))
	stage(nemes, {p: Vector2i(9, 3), v(1): Vector2i(4, 3), v(2): Vector2i(4, 4), v(3): Vector2i(1, 7)})
	p.refresh()
	ok(b.cast_at(p, metea, Vector2i(4, 3)) and p.channel and p.channel.at == Vector2i(4, 3) and p.channel.turns == 0, "cast: channeling on the tile")
	ok(b.strike_tiles(p) == [Vector2i(4, 3)], "the turn it's cast: only that tile")
	b.end_turn()
	b.end_turn()
	ok(p.channel.turns == 1 and b.strike_tiles(p).size() == 9, "a turn later: a tile from it")
	ok(not b.cast_at(p, metea, Vector2i(6, 3)), "not further")
	var hp1 := v(1).hp
	var hp2 := v(2).hp
	var energy := p.energy
	ok(b.cast_at(p, metea, Vector2i(4, 4)) and p.channel == null, "it strikes, and the channel's spent")
	ok(v(1).hp < hp1 and v(2).hp < hp2 and v(3).hp == v(3).max_hp, "everything within rank (2) tiles takes it")
	ok(p.energy == energy - metea.strike_cost, "for its strike cost")
	ok("Channels on a tile" in metea.describe(2) and "2d12" in metea.describe(2), metea.describe(2))


# The channel rule: moving a turn after the cast loses Metea; holding still keeps it (Battle.end_turn()).
func test_metea_held() -> void:
	var p := her(Vector2i(9, 3))
	stage(nemes, {p: Vector2i(9, 3), v(1): Vector2i(4, 3), v(3): Vector2i(1, 7)})
	p.refresh()
	b.cast_at(p, metea, Vector2i(4, 3))
	b.end_turn()
	b.end_turn()
	b.end_turn()
	b.end_turn()
	ok(p.channel != null and p.channel.turns == 2, "held still: still channeling, two turns on")
	b.travel(p, Vector2i(9, 4))
	b.end_turn()
	ok(p.channel == null, "a turn it moved: the channel's lost")


func test_metea_ai_holds() -> void:
	var p := her(Vector2i(9, 3))
	stage(nemes, {p: Vector2i(9, 3), v(1): Vector2i(1, 7), v(3): Vector2i(9, 7)})
	p.refresh()
	b.cast_at(p, metea, Vector2i(4, 3))
	b.end_turn()
	b.end_turn()
	var log := AI.act(b, p)
	ok(p.cell == Vector2i(9, 3) and p.idle() and "holds still" in " ".join(log), "nothing in reach to strike: the AI holds still to keep it (%s)" % [log])
	b.end_turn()
	ok(p.channel != null, "and keeps it")


func test_strategy() -> void:
	var p := her(Vector2i(5, 3))
	stage(nemes, {p: Vector2i(5, 3), v(1): Vector2i(3, 3), v(2): Vector2i(8, 3)})
	v(2).level = 12
	var reads := {v(1): b.read(p, v(1)), v(2): b.read(p, v(2))}
	reads[v(2)].level = 12
	reads[v(1)].level = 1
	ok(AI._best_target(p, reads) == v(2), "the strongest, a few tiles further, over the closest")
	p.strategy = []
	ok(AI._best_target(p, reads) == v(1), "without a strategy: the closest")
	p.strategy.assign([&"closest", &"strongest"])
	v(1).wisdom = 16
	v(1).afflict(effect("recon", 3), 9)
	var r := b.read(v(1), p)
	ok(r.intention == p.intention and r.strategy == p.strategy, "insight reads her intention and strategy")
	v(1).wisdom = 8
	ok(b.read(v(1), p).intention == "", "without it, nothing")


func test_envoy() -> void:
	Game.starter = {faction = nemes, role = load("res://Roles/warlock.tres"), name = "Vex"}
	var scene: Node = load("res://Scenes/astral_envoy.tscn").instantiate()
	scene.get_node("Battle").rng.seed = 3
	tree.root.add_child(scene)
	var e: Battle = scene.get_node("Battle")
	var shade: Unit = e.get_node("Units/Shade1")
	ok(e.player.faction == nemes and shade.faction == nemes and e.get_node("Units/Villager1").faction == nemes, "the villagers and shades join the player's side")
	ok(shade.uncontrolled and e.get_node("Units/AstralPrincess").faction.name == "Stellar Order", "the shades act on their own; the Princess is of the Stellar Order")
	ok(e.terrain(Vector2i(4, 4)).name == "Tall grass" and e.terrain(Vector2i(5, 2)).name == "Rough", "a meadow with tall grass and rocks")
	var turns := 0
	var revivals := 0
	e.revived.connect(func(_u: Unit, _c: Unit): revivals += 1)
	while e.phase == Battle.Phase.TURNS and turns < 120:
		for u in e.members(e.turn):
			AI.act(e, u)
			if e.phase != Battle.Phase.TURNS:
				break
		for u: Unit in e.get_node("Units").get_children():
			ok(u.hp >= 0 and u.hp <= u.max_hp and (u.is_alive() or u.reviving) == (e.unit_at(u.cell) == u), "%s: hp in range, on the board iff alive or down" % u.name)
		e.end_turn()
		turns += 1
	ok(e.phase == Battle.Phase.OVER, "the battle ends (%d turns, %d revivals)" % [turns, revivals])
	print("  envoy: %d turns, %d revivals, %s left" % [turns, revivals, ", ".join(e.units.values().map(func(u: Unit): return u.name))])
	scene.free()


func test_smite_eros() -> void:
	var pip := b.starter({faction = lancin, role = load("res://Roles/paladin.tres"), name = "Pip"})
	b.get_node("Units").add_child(pip)
	stage(lancin, {pip: Vector2i(4, 3), v(3): Vector2i(5, 3)})
	pip.learned.append(slot(smite))
	pip.refresh()
	var tags := Battle.hit_tags(pip, smite)
	ok(&"love" in tags and &"energy" not in tags, "a Paladin of Eros: Smite's damage is love (%s)" % [tags])
	v(3).max_hp = 200
	v(3).hp = 200
	v(3).energy = 5
	for i in 20:
		pip.refresh()
		b.cast(pip, smite, v(3))
		if v(3).hp < 200:
			break
	ok(v(3).hp < 200 and v(3).energy == 5, "it hurts HP straight away: no Energy drained")
