extends Test

# Starbuilding (docs/plans/w22-astral1.md): the astral skills that lay star tiles, all through Behaviours/star_place.gd. They need
# Power (Unit.pays_power()); each tile seals Power until it is destroyed (Battle.lay_star(); Unit.seal()); a startile lasts rank
# rounds outside the signal; a Starway pair relocates a unit stepping onto a powered end (Battle.portals).

var void_t: Terrain = load("res://Terrain/astral_void.tres")
var gen_t: Terrain = load("res://Terrain/starpower_generator.tres")


# v(1) at (4,3) with the skill learned at rank r and Power to spend (powered: its Energy is Power).
func _caster(id: String, r := 2, powered := true) -> Unit:
	var u := v(1)
	stage(lancin, {u: Vector2i(4, 3), v(2): Vector2i(1, 8), v(3): Vector2i(9, 8)})
	u.learned.clear(); u.seals.clear(); u.timed.clear()
	u.learned.append(slot(sk(id), r)); u.sync_bar(); u.refresh()
	if powered:
		u.afflict(effect("powered", 1.0), 9)
	u.energy = u.max_energy
	return u


func _cast(u: Unit, id: String, c: Vector2i) -> bool:
	u.refresh()
	return b.cast_at(u, sk(id), c)


# A full generator at c: signal 5 tiles about it.
func _gen(c: Vector2i) -> void:
	b.lay_layer(c, gen_t)
	b.charge[c] = Battle.STAR_CAPACITY


func test_place_seals_and_lapses() -> void:
	var u := _caster("startile", 2, false)
	ok(not _cast(u, "startile", Vector2i(5, 3)) and not b.has_star(Vector2i(5, 3)), "no Power (not powered): nothing is laid, nothing paid")
	u.afflict(effect("powered", 1.0), 9)
	u.energy = u.max_energy
	var most := u.max_energy
	var stamina: Reserve = load("res://Reserves/stamina.tres")
	u.reserves[stamina] = 10
	u.set_exact(stamina, 10)
	ok(u.funding(sk("startile")) is StringName and u.funding(sk("startile")) == &"energy" and u.pays_power(sk("startile")), "powered with Stamina to spare: Stamina never takes a Power skill, Power (Energy) pays it")
	u.reserves.erase(stamina)
	ok(not _cast(u, "startile", Vector2i(7, 3)), "out of range: Startile reaches its rank (2) tiles")
	ok(_cast(u, "startile", Vector2i(5, 3)) and b.top_layer(Vector2i(5, 3)).terrain == Battle.STARTILE, "powered: it lays a startile")
	ok(u.locked(&"energy") == 1 and u.usable_max(&"energy") == most - 1, "...sealing 1 Power (usable max %d of %d)" % [u.usable_max(&"energy"), most])
	var l := b.top_layer(Vector2i(5, 3))
	ok(l.lapse == 2, "it lasts rank (2) rounds unpowered")
	_cast(u, "startile", Vector2i(5, 4))
	ok(u.locked(&"energy") == 2, "each tile seals its own point")
	_gen(Vector2i(5, 6))  # its signal reaches (5, 4) (distance 2) and (5, 3) (3)
	for i in 4:
		b._repair_tiles()
	ok(b.top_layer(Vector2i(5, 3)).terrain == Battle.STARTILE and b.top_layer(Vector2i(5, 4)).terrain == Battle.STARTILE, "in the signal it lasts however long")
	b.charge[Vector2i(5, 6)] = 0
	b._repair_tiles()
	ok(b.top_layer(Vector2i(5, 3)).terrain == Battle.STARTILE and u.locked(&"energy") == 2, "one round dark: still there")
	b._repair_tiles()
	ok(b.top_layer(Vector2i(5, 3)).terrain.name == "Cracked Startile" and u.locked(&"energy") == 0, "a second: it breaks, and both seals lift (%d)" % u.locked(&"energy"))
	_cast(u, "startile", Vector2i(6, 3))
	_cast(u, "startile", Vector2i(4, 4))
	u.set_exact(&"energy", u.usable_max(&"energy"))
	b.expose(Vector2i(6, 3), [&"blunt"] as Array[StringName])
	ok(u.locked(&"energy") == 1, "a tile broken by a blow lifts its seal and only its own (%d)" % u.locked(&"energy"))
	ok(u.energy <= u.usable_max(&"energy") and u.usable_max(&"energy") < most, "lifting doesn't refill Power: it comes back by regen")


func test_shapes() -> void:
	var u := _caster("starpower_generator", 3)
	var g := Vector2i(6, 3)
	ok(_cast(u, "starpower_generator", g) and b.signal_at(g) == 3 and b.signal_at(g + Vector2i(3, 0)) == 0 and b.signal_at(g + Vector2i(4, 0)) == -1, "a generator shares its skill's rank: signal 3 tiles")
	ok(u.locked(&"energy") == 1 + ceili(0.3 * u.max_energy - 0.0001), "...sealing 1 + 10%% x rank of max Power (%d)" % u.locked(&"energy"))
	ok(b.top_layer(g).lapse == 0, "a source needs no signal to stay")
	b.expose(g, [&"blunt"] as Array[StringName])
	ok(u.locked(&"energy") == 0, "destroyed: sealed Power freed")
	# a line of starpanes
	var w := _caster("starpanel", 3)
	ok(_cast(w, "starpanel", Vector2i(6, 3)) and b.panes.has(Vector2i(5, 3)) and b.panes.has(Vector2i(6, 3)) and w.locked(&"energy") == 2, "Starpanel: a starpane along the line to the tile, each sealing 1")
	# a bridge over void between two powered startiles
	var p := _caster("starbridge", 2)
	_gen(Vector2i(5, 5))
	for c in [Vector2i(4, 3), Vector2i(6, 3)]:
		b.lay_layer(c, Battle.STARTILE)
	for c in [Vector2i(5, 2), Vector2i(5, 3)]:
		b.paint(c, void_t)
	ok(_cast(p, "starbridge", Vector2i(6, 3)), "Starbridge: from a powered tile to the one across the gap")
	ok(b.terrain(Vector2i(5, 3)) == Battle.STARTILE and b.terrain(Vector2i(5, 2)) == Battle.STARTILE and p.locked(&"energy") == 2, "...rank (2) columns of startile over the void, each sealing 1")
	var walker := v(2)
	ok(b._cost(walker, b.terrain(Vector2i(4, 3)), b.terrain(Vector2i(5, 3))) < 99.0, "a walker can cross it")


func test_starway() -> void:
	var u := _caster("starway", 3)
	_gen(Vector2i(5, 5))
	for c in [Vector2i(4, 3), Vector2i(6, 3)]:
		b.lay_layer(c, Battle.STARTILE)
	ok(_cast(u, "starway", Vector2i(6, 3)), "Starway: on a startile it can see, with the one it stands on")
	ok(b.portals.get(Vector2i(4, 3)) == Vector2i(6, 3) and b.portals.get(Vector2i(6, 3)) == Vector2i(4, 3), "a pair of Starway tiles")
	b.move(u, Vector2i(2, 2))
	var w := v(2)
	b.place(w, Vector2i(6, 3))
	ok(w.cell == Vector2i(4, 3), "stepping on one, powered: it comes out on the other (%s)" % w.cell)
	b.move(w, Vector2i(8, 8))
	b.charge[Vector2i(5, 5)] = 0
	b.place(w, Vector2i(6, 3))
	ok(w.cell == Vector2i(6, 3), "unpowered: it is only a tile")
	b.charge[Vector2i(5, 5)] = Battle.STAR_CAPACITY
	b.move(w, Vector2i(3, 3))
	var seen: Array = []
	b.ported.connect(func(_u, f, t): seen.append([f, t]))
	b.travel(w, Vector2i(5, 3))
	ok(w.cell == Vector2i(5, 3) and seen == [[Vector2i(4, 3), Vector2i(6, 3)]], "a walk through one hops at once and goes on from the pair if the next step is beside it (%s)" % w.cell)
	b.move(w, Vector2i(4, 5))
	b.travel(w, Vector2i(4, 1))
	ok(w.cell == Vector2i(6, 3) and seen.size() == 2, "...else it ends on the pair, not hopping back (%s)" % w.cell)
	b.move(w, Vector2i(8, 8))
	b.expose(Vector2i(4, 3), [&"blunt"] as Array[StringName])
	ok(b.portals.is_empty(), "break one end and the pair is gone")
	b.place(w, Vector2i(6, 3))
	ok(w.cell == Vector2i(6, 3), "...the other end is just a tile")


# The AI crosses void with Power: Startiles over the gap toward its foe, a Starbridge to a powered tile past it; Starpanel, Starway and
# the generator are the player's (AI._span()).
func test_ai_crosses_void() -> void:
	var u := _caster("startile", 3)
	b.move(u, Vector2i(2, 3))
	b.move(v(3), Vector2i(9, 3))
	for x in range(4, 7):
		b.paint(Vector2i(x, 3), void_t)
	var ground := b.terrain(Vector2i(8, 3))
	var log: Array[String] = []
	ok(AI._span(b, u, Vector2i(9, 3), log), "powered, it lays startiles over the void ahead of it (%s)" % [log])
	ok(b.terrain(Vector2i(4, 3)) == Battle.STARTILE and u.locked(&"energy") >= 1, "...one a tile, each sealing Power")
	b.layers.clear()
	for x in range(4, 7):
		b.paint(Vector2i(x, 3), void_t)
	u.afflict(effect("powered", 0.0), 0)
	var plain := _caster("startile", 3, false)
	b.move(plain, Vector2i(2, 3))
	ok(not AI._span(b, plain, Vector2i(9, 3), log) and b.terrain(Vector2i(4, 3)) == void_t, "with no Power it stays on its side")
	var panel := _caster("starpanel", 3)
	b.move(panel, Vector2i(2, 3))
	ok(not AI._span(b, panel, Vector2i(9, 3), log), "a Starpanel isn't the AI's to cast")
	var bridger := _caster("starbridge", 3)
	b.move(bridger, Vector2i(3, 3))
	_gen(Vector2i(6, 5))
	b.paint(Vector2i(6, 3), ground)
	b.lay_layer(Vector2i(6, 3), Battle.STARTILE)
	b.lay_layer(Vector2i(3, 3), Battle.STARTILE)
	ok(AI._span(b, bridger, Vector2i(9, 3), log) and b.terrain(Vector2i(5, 3)) == Battle.STARTILE, "or a Starbridge to the powered tile on the far side")


# The tree is a tab on four casters. Tiers 1, 2, 2, 3 by what comes first (Role.tier: 1 + its prerequisites); the user's t6 Starway
# is min_tier 6 (Unit.tier()), as the t7 Manifest Starchitecture and t9 Starnest after it are (D2).
func test_tree() -> void:
	var ids := ["startile", "starbridge", "starpanel", "starpower_generator", "starway", "manifest_starchitecture", "starnest"]
	for who in ["wizard", "mage", "sorcerer", "adventurer"]:
		var role: Role = load("res://Roles/%s.tres" % who)
		var u := b.from_role(lancin, role, "Tester")
		var tiers := ids.map(func(id: String): return u.tier(sk(id)))
		ok(tiers == [1, 2, 2, 3, 6, 7, 9] and role.trees().any(func(t: SkillTab): return t.title() == "Starbuilding ??" and ids.all(func(id: String): return t.offers(sk(id)))), "%s: Starbuilding tiers %s" % [who, tiers])


# Manifest Starchitecture (docs/plans/w22-astral2.md): a toggle pillar with an alt_bar effect (Unit.show_bar()). Switched on (paid:
# cheap), the bar's slots but its pillars and always-on passives become a second bar of power skills, set up by hand and kept;
# switched off (free) the regular bar comes back as it was. While on, power skills cost / its rank (cost_div; Unit.price()), but
# what they seal stays whole.
func test_starchitect_bar() -> void:
	var u := _caster("manifest_starchitecture", 2)
	var m := sk("manifest_starchitecture")
	var plain := sk("strike")
	for id in ["startile", "starpanel"]:
		u.learned.append(slot(sk(id), 2))
	u.learned.append(slot(plain, 1))
	u.sync_bar()
	u.hotbar.fill(null)
	u.auto_fill()
	var regular := u.get_equipped()
	ok(plain in regular and m in regular and m.pillar(), "the regular bar: Strike, and Manifest pinned as a pillar")
	var base := Pricing.cost_for(u, sk("startile"))
	ok(u.price(sk("startile")) == base, "off: Startile costs its own %d" % base)
	u.refresh()
	var ap := u.ap_for(&"skill")
	var en := u.energy
	var fee := u.price(m)
	ok(fee > 0 and u.toggle(m) and u.is_on(m) and u.energy == en - fee and u.ap_for(&"skill") < ap, "switching it on is paid (%d Power, %s AP)" % [en - u.energy, ap - u.ap_for(&"skill")])
	ok(sk("startile") in u.hotbar and sk("starpanel") in u.hotbar and m in u.hotbar and plain not in u.hotbar and not u.equipped(plain), "the Starchitect bar: its power skills, Manifest still pinned, Strike off (%s)" % [u.hotbar])
	ok(u.get_equipped() == regular, "a save keeps the regular bar")
	var spare := u.free_slot()
	ok(spare >= 0 and not u.bar_place(plain, spare), "only power skills go on it")
	ok(u.bar_place(sk("starpanel"), 0) and u.hotbar[0] == sk("starpanel"), "it is set up by hand like the regular bar")
	ok(u.price(sk("startile")) == floori(base / 2.0), "on at rank 2: a power skill costs / 2 (%d)" % u.price(sk("startile")))
	en = u.energy
	ok(_cast(u, "startile", Vector2i(5, 3)) and u.locked(&"energy") == 1 and u.energy == en - floori(base / 2.0) - 1, "its seal stays whole: 1 Power locked (%d -> %d)" % [en, u.energy])
	ap = u.ap_for(&"skill")
	en = u.energy
	ok(u.toggle(m) and not u.is_on(m) and u.energy == en and u.ap_for(&"skill") == ap, "switching it off is free")
	ok(u.hotbar == regular and u.equipped(plain) and u.price(sk("startile")) == base, "the regular bar is back as it was, at full cost")
	u.refresh()
	u.energy = u.max_energy
	u.toggle(m)
	ok(u.hotbar[0] == sk("starpanel"), "switched on again, the Starchitect bar is as it was left")
	# Brainfog: a disabled Manifest drops the second bar; the regular one returns, and comes back up when it ends
	u.disable(m, 1)
	ok(u.bar_key == &"" and u.equipped(plain), "disabled, the Starchitect bar drops and the regular bar returns")
	u.disabled.clear()
	u.sync_alt_bar()
	ok(u.bar_key == &"power", "no longer disabled, the toggle is still on: the bar is back up")
	# a skill learned (auto-equipped) while it is up goes to the regular bar unless it is a power skill
	var late := sk("blink")
	u.bars[&""][u.bars[&""].find(plain)] = null  # room on the regular bar
	u.learned.append(slot(late, 1))
	u.sync_bar()
	ok(late not in u.hotbar and late in u.bars[&""], "a plain skill learned with the bar up lands on the regular bar (%s)" % [u.hotbar])
	u.toggle(m)
	ok(late in u.hotbar, "...and is there when the regular bar returns")


# Starnest: rank generators (power 5, full) from the cell, each a straight row or column of starpanes from the one it grew from,
# star flooring laid over the ground by the Nexus's rules (AstralNexus.layout()); one seal of 20% x rank of max Power that
# bears debt, so it may take the pool below 0, while plain spending can't.
func test_starnest() -> void:
	var u := _caster("starnest", 2)
	u.set_exact(&"energy", 1)
	var c := Vector2i(2, 3)  # the test map is 10 x 8: the other generator has room only to the right
	ok(_cast(u, "starnest", c), "cast with 1 Power, just its cost")
	var gens: Array = b.layers.keys().filter(func(at: Vector2i): return b.top_layer(at).terrain == gen_t)
	ok(gens.size() == 2 and c in gens and b.signal_at(c) == 5, "rank 2: two full generators, the first on the cell (%s)" % [gens])
	var g: Vector2i = gens[0] if gens[1] == c else gens[1]
	var d := g - c
	ok((d.x == 0 or d.y == 0) and absi(d.x + d.y) == AstralNexus.SPACING, "...%d apart in a row or a column (%s)" % [AstralNexus.SPACING, d])
	var linked := true
	for k in range(1, AstralNexus.SPACING):
		linked = linked and b.has_star(c + d.sign() * k)
	ok(linked and b.panes.has(c + d.sign() * 3), "linked: star tiles all the way, a starpane between the platforms")
	ok(b.top_layer(c + Vector2i(0, 1)).terrain == Battle.STARTILE or b.top_layer(c - Vector2i(0, 1)).terrain == Battle.STARTILE, "a startile platform laid over the ground about each")
	var sealed := ceili(0.4 * u.max_energy - 0.0001)
	ok(u.locked(&"energy") == sealed and u.energy == -sealed, "seals 40%% of max Power and the empty pool goes into debt (%d)" % u.energy)
	u.refresh()
	ok(not u.can_afford(sk("starnest")) and u.funding(sk("starnest")) == null, "in debt, nothing pays for a skill: plain spending can't go below 0")
	for at: Vector2i in b.layers.keys():
		for l: Battle.Layer in b.layers[at].duplicate():
			b._lift(at, l, &"test")
	ok(u.locked(&"energy") == 0, "all of it gone: the seal lifts")
