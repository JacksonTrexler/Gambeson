extends Test

# Icor (Wizard of Red: Hex III, Mana, Arcanist Perspective), Alabaster (Stone Golem: Strike III,
# Stoneskin, Stonegift), unit bars, the choice template and the entry screen.

var arcanist: Skill = load("res://Skills/arcanist.tres")
var stoneskin: Skill = load("res://Skills/stoneskin.tres")
var stonegift: Skill = load("res://Skills/stonegift.tres")
var mana: Reserve = load("res://Reserves/mana.tres")


func icor() -> Unit:
	return b.get_node("Units/Icor")


func alabaster() -> Unit:
	return b.get_node("Units/Alabaster")


func test_icor() -> void:
	var u := icor()
	ok(u.role.name == "Wizard" and u.title == "of Red" and u.level == 5 and u.race.name == "Human", "Wizard of Red, level 5")
	ok(u.intelligence == 18 and u.constitution == 8, "high int, low con")
	ok(u.store(mana) == 12 and u.energy == 4 and u.hp == 14, "12 mana, a little energy")
	ok(u.rank(hex) == 3 and u.rank(arcanist) == 3 and u.passives == [arcanist], "Hex III, Arcanist Perspective III (on)")
	ok(u.sprite.sprite_frames.get_frame_texture(&"default", 0).resource_path == "res://Units/RedMage.png", "RedMage sprite from the Wizard role")


func test_arcanist() -> void:
	var u := icor()
	ok(u.scaling(&"wisdom", [&"magic"]) == 18 and u.mod(&"wisdom", [&"magic"]) == 4, "rank 3: int 18 stands in for wis 10 (cap 10 / 0.4 = 25)")
	ok(u.scaling(&"wisdom", [&"physical"]) == 10, "only for magic skills")
	ok(u.scaling(&"charisma", [&"magic"]) == 18, "cha too (cap 8 / 0.4 = 20)")
	ok(u.scaling(&"strength", [&"magic"]) == 8, "not other stats")
	var s := u.learned[1]
	s.rank = 1
	u.wisdom = 18
	u.intelligence = 20
	ok(u.scaling(&"wisdom", [&"magic"]) == 20, "rank 1: 18 wis allows 20 int")
	u.intelligence = 25
	ok(is_equal_approx(u.scaling(&"wisdom", [&"magic"]), 22.5), "...capped at 18 / 0.8 = 22.5")
	u.intelligence = 18
	u.wisdom = 0
	s.rank = 4
	ok(u.scaling(&"wisdom", [&"magic"]) == 0, "rank 4 with 0 wis: nothing to stand in for")
	s.rank = 5
	ok(u.scaling(&"wisdom", [&"magic"]) == 18, "rank 5: full int even with 0 wis")
	u.wisdom = 10
	s.rank = 6
	ok(is_equal_approx(u.scaling(&"wisdom", [&"magic"]), 20), "rank 6: + 20% of wis")
	s.rank = 11
	ok(is_equal_approx(u.scaling(&"wisdom", [&"magic"]), 30), "rank 11: + 120% of wis")
	u.intelligence = 6
	ok(u.scaling(&"wisdom", [&"magic"]) == 6 + 12.0, "uses whichever is better")
	s.on = false
	ok(u.scaling(&"wisdom", [&"magic"]) == 10, "toggled off: plain wis")


func test_hex_iii() -> void:
	stage(nemes, {icor(): Vector2i(7, 3), v(1): Vector2i(3, 3)})
	var seen := {}
	for seed in 60:
		b.rng.seed = seed
		v(1).max_hp = 50
		v(1).heal(50)
		v(1).timed.clear()
		icor().set_store(mana, 12)
		icor().refresh()
		ok(b.cast(icor(), hex, v(1)), "Hex III cast")
		seen[50 - v(1).hp] = true
	ok(seen.keys().all(func(d): return d >= 5 and d <= 10) and seen.size() == 6, "d6 + 4 (int for wis): 5-10, all seen (%s)" % [seen.keys()])
	ok(v(1).luck == -2 and v(1).timed[hex.effects[0]].rank == 3, "luck -3 (Favour's +1 -> -2)")
	ok(icor().store(mana) == 10 and icor().energy == 4, "paid 2 mana, no energy")
	ok(is_equal_approx(icor().ap_for(&"skill"), 8.0), "fully paid with mana: AP halved to 2")


func test_mana_rules() -> void:
	stage(nemes, {icor(): Vector2i(7, 3), v(1): Vector2i(3, 3)})
	icor().set_store(mana, 1)
	ok(b.cast(icor(), hex, v(1)) and icor().energy == 2 and is_equal_approx(icor().ap_for(&"skill"), 6.0), "not enough mana: energy pays, full 4 AP")
	icor().set_store(mana, 12)
	icor().energy = 0
	icor().learned.append(slot(stonegift))
	ok(icor().funding(stonegift) == null, "mana can't pay for non-magic skills")
	icor().learned.pop_back()


func test_alabaster() -> void:
	var u := alabaster()
	ok(u.race.name == "Stone Golem" and u.stat(&"size") == 4 and u.level == 5, "Stone Golem, Large, level 5")
	ok(u.strength == 18 and u.constitution == 20 and u.intelligence == 8 and u.charisma == 8, "str high, con 20, rest 8")
	ok(u.rank(strike) == 3 and u.passives == [stoneskin] and stonegift in u.actives, "Strike III, Stoneskin, Stonegift")
	ok(u.sprite.sprite_frames.get_frame_texture(&"default", 0).resource_path == "res://Units/GolemClay.png", "golem sprite")


func test_strike_iii() -> void:
	stage(lancin, {alabaster(): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).max_hp = 50
	v(3).heal(50)
	ok(b.cast(alabaster(), strike, v(3)) and v(3).hp == 35, "3 hits of 1 + str mod 4 = 15")
	ok(is_equal_approx(b.skill_range(alabaster(), strike, v(3)), 1.26), "size 4: reach 1 + 0.2 + 0.06")
	v(3).max_hp = 10
	stage(lancin, {alabaster(): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(8, 5)})
	alabaster().refresh()
	ok(b.cast(alabaster(), strike, v(3)) and not v(3).is_alive(), "stops hitting once the target falls")


func test_stoneskin() -> void:
	var u := alabaster()
	ok(is_equal_approx(u.mitigation([]), 0.4) and u.stat(&"dexterity") == 4, "full HP: 40% off, dex halved")
	ok(u.hit(10, [&"fire"]) == 6 and u.hp == 24, "10 -> 6")
	ok(u.mitigation([]) == 0.0 and u.stat(&"dexterity") == 8, "at 24/30 (80%): off")
	ok(u.hit(10, [&"fire"]) == 10, "full damage below 85%")
	u.hp = 30
	u.refresh()
	ok(is_equal_approx(u.ap_for(&"skill"), 6.0), "AP from halved dex (mod -3) and wis 8 (-1): 6")


func test_stonegift() -> void:
	stage(lancin, {alabaster(): Vector2i(2, 4), v(1): Vector2i(3, 5), v(3): Vector2i(4, 4)})
	ok(not b.cast(alabaster(), stonegift, v(3)), "allies only")
	ok(b.cast(alabaster(), stonegift, v(1)), "on an ally within 2")
	ok(is_equal_approx(v(1).mitigation([&"slash"]), 0.41) and v(1).stat(&"dexterity") == 6, "ally gets Stoneskin (+ Favour's 1%), dex 12 -> 6")
	ok(v(1).timed[stoneskin.effects[0]].turns == 3 and alabaster().energy == 8, "for 3 turns, 2 energy")
	for i in 6:
		b.end_turn()
	ok(v(1).mitigation([&"slash"]) == 0.01, "worn off after 3 Lancin turns")


func test_bars() -> void:
	var vil := v(1)
	var ic := icor()
	ok(not vil.reserve_bar.visible and vil.energy_bar.modulate.a == 1.0, "villager: just a yellow Energy bar")
	ok((vil.energy_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == Unit.ENERGY_COLOR, "Energy is yellow")
	ok(vil.energy_bar.size.y < vil.hp_bar.size.y and vil.energy_bar.position.y > vil.hp_bar.position.y, "slimmer, under HP")
	ok(ic.reserve_bar.visible and (ic.reserve_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == mana.color, "Icor: blue Mana bar")
	ok(ic.hp_bar.position.y + ic.hp_bar.size.y < ic.reserve_bar.position.y and ic.reserve_bar.position.y + ic.reserve_bar.size.y < ic.energy_bar.position.y, "HP, then Mana, then Energy, not overlapping")
	ok(ic.energy_bar.modulate.a < 1.0, "Energy faded behind Mana")
	ok(ic.reserve_bar.value == 12 and ic.energy_bar.value == 4, "values")
	ic.set_store(mana, 7)
	ok(ic.reserve_bar.value == 7, "Mana bar follows")
	var top := -ic.sprite.sprite_frames.get_frame_texture(&"default", 0).get_height() / 2.0
	ok(ic.energy_bar.position.y + ic.energy_bar.size.y <= top, "bars clear the (taller) sprite's head")


func test_choice() -> void:
	var c: Choice = load("res://Scenes/UI/choice.tscn").instantiate()
	c.prompt = "Pick"
	tree.root.add_child(c)
	var got := []
	c.changed.connect(func(was, now): got.append([was, now]))
	var a := c.add("A", null, 1)
	var bb := c.add("B", null, 2)
	bb.button_pressed = true
	a.button_pressed = true
	ok(got == [[null, 2], [2, 1]] and c.value == 1 and c.get_node("Prompt").text == "Pick", "emits each pick, keeps the last")
	c.free()


func test_entry() -> void:
	var e: Control = load("res://Scenes/entry.tscn").instantiate()
	e.next_scene = ""
	tree.root.add_child(e)
	var side: Choice = e.get_node("%Side")
	var role: Choice = e.get_node("%Role")
	var nm: LineEdit = e.get_node("%Name")
	var play: Button = e.get_node("%Play")
	var sides := side.get_node("Options").get_children()
	var roles := role.get_node("Options").get_children()
	ok(sides.map(func(x): return x.text) == ["Lancin", "Nemes"], "sides")
	ok(sides[0].icon.resource_path.ends_with("GolemClay.png") and sides[1].icon.resource_path.ends_with("RedMage.png"), "Alabaster stands for Lancin, Icor for Nemes")
	ok(roles.map(func(x): return x.text) == ["Adventurer", "Fighter", "Paladin\nHalfling"], "classes")
	ok(roles.map(func(x): return x.icon.resource_path.get_file()) == ["Journeyer.png", "Mountaineer.png", "Pallas.png"], "class sprites")
	ok(play.disabled, "Play starts disabled")
	sides[1].button_pressed = true
	roles[2].button_pressed = true
	ok(play.disabled, "still needs a name")
	nm.text_changed.emit("   ")
	ok(play.disabled, "blank names don't count")
	nm.text = "Pip"
	nm.text_changed.emit("Pip")
	ok(not play.disabled, "enabled once everything's chosen")
	play.pressed.emit()
	ok(Game.starter.faction == nemes and Game.starter.role.name == "Paladin" and Game.starter.name == "Pip", "Play records the choices")
	e.free()

	var scene: Node = load("res://Scenes/museum.tscn").instantiate()
	tree.root.add_child(scene)
	var pip: Unit = scene.get_node("Battle/Units/Pip")
	ok(pip.faction == nemes and pip.cell == Vector2i(8, 4) and scene.get_node("Battle").unit_at(Vector2i(8, 4)) == pip, "the starter joins Nemes at its spawn")
	ok(pip.nick == "Pip" and pip.race.name == "Halfling" and pip.stat(&"size") == 2 and pip.charisma == 13, "a halfling Paladin with the role's stats")
	ok(strike in pip.actives and pip.sprite.sprite_frames.get_frame_texture(&"default", 0).resource_path.ends_with("Pallas.png"), "Strike from the role, Pallas sprite")
	ok(Game.starter.is_empty(), "the starter is used up")
	scene.free()


func test_own_slots() -> void:
	v(1).learned[0].on = false
	ok(v(1).luck == 0 and v(2).luck == 1, "toggling one villager's Favour leaves the other's alone")
	v(1).learned[0].on = true
	icor().learned[0].rank = 1
	var other: Unit = load("res://Scenes/icor.tscn").instantiate()
	tree.root.add_child(other)
	ok(other.rank(hex) == 3, "another Icor keeps Hex III")
	other.free()


func test_stonegift_no_double() -> void:
	stage(lancin, {alabaster(): Vector2i(2, 4), v(1): Vector2i(3, 4)})
	ok(b.cast(alabaster(), stonegift, alabaster()), "self-gift goes through...")
	ok(is_equal_approx(alabaster().mitigation([]), 0.4) and alabaster().stat(&"dexterity") == 4, "...but doesn't stack on its own Stoneskin")


func test_starter_names() -> void:
	Game.starter = {faction = nemes, role = load("res://Roles/fighter.tres"), name = "Icor"}
	var scene: Node = load("res://Scenes/museum.tscn").instantiate()
	tree.root.add_child(scene)
	var mine: Array = scene.get_node("Battle/Units").get_children().filter(func(u): return u.nick == "Icor")
	ok(mine.size() == 1 and mine[0].name != "Icor" and scene.get_node("Battle/Units/Icor").title == "of Red", "a starter named Icor keeps it as its nick; the real Icor is untouched")
	scene.free()
	Game.starter = {}
