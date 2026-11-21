extends Test

# Armor slots a skill gives beyond the first (Behaviour.armor_slot(): Power Armor, Scrap Plating; Unit.plating, plates(),
# plated_defense(), armor_drag(); docs/plans/w3-armor.md). Villagers: dex/con/str 12 (+1), level 1, Energy 10. v(1) in a Gambeson
# is Defense 11; a Bulwark (Defense 20, no weight) is the armor worn in the slot unless a row says otherwise.

var power_armor: Skill = load("res://Skills/power_armor.tres")
var scrap_plating: Skill = load("res://Skills/scrap_plating.tres")
var gambeson: Item = load("res://Items/gambeson.tres")
var brigandine: Item = load("res://Items/brigandine.tres")
var dagger: Item = load("res://Items/dagger.tres")


# v(1), cleared of what a row before left, in a Gambeson, having learned s at rank r (on the bar), `worn` (the Bulwark) in
# the slot it gives.
func plated(s: Skill, r: int, worn: Item = null) -> Unit:
	var u := v(1)
	u.learned.clear()
	u.plating.clear()
	u.disabled.clear()
	u.energy = u.max_energy
	u.armor = gambeson
	u.learned.append(slot(s, r))
	roomy(u)
	u.equip(worn if worn else bulwark(), Unit.plate_slot(s))
	return u


# Each skill's slot: absent without it, one with it, only armor goes in it, and what it confers is its skill's rule - the table is
# the rule: Power Armor all of its armor's Defense while Energy is at 100% - 10% x rank or more (else the armor stays on and
# counts for nothing); Scrap Plating no more than rank.
func test_slots() -> void:
	villagers_only()
	ok(v(1).plate_slots().is_empty() and v(1).equip(bulwark(), &"plate_power_armor") == null and v(1).get(&"plate_power_armor") == null, "no skill, no slot")
	# [skill, rank, Energy, the armor's own Defense (0: the Bulwark's 20), Defense added]
	var rows := [
		[power_armor, 3, 10, 0, 20], [power_armor, 3, 7, 0, 20], [power_armor, 3, 6, 0, 0],
		[power_armor, 1, 9, 0, 20], [power_armor, 1, 8, 0, 0], [power_armor, 5, 5, 0, 20], [power_armor, 5, 4, 0, 0],
		[scrap_plating, 3, 10, 0, 3], [scrap_plating, 3, 10, 2, 2], [scrap_plating, 1, 10, 0, 1], [scrap_plating, 5, 0, 0, 5],
	]
	for row in rows:
		var s: Skill = row[0]
		var worn := bulwark()
		if row[3]:
			worn.defense = row[3]
		var u := plated(s, row[1], worn)
		u.energy = row[2]
		var key := Unit.plate_slot(s)
		ok(u.plate_slots() == [key] and u.get(key) == worn and u.defense() == 11 + row[4] and u.plates().size() == (1 if row[4] else 0),
				"%s %d at Energy %d: Defense %d, wanted 11 + %d" % [s.name, row[1], row[2], u.defense(), row[4]])
		ok(u.get(key) == worn, "off or on, the armor stays in it")
		ok(u.equip(dagger, key) == null and u.get(key) == worn and u.equip(bulwark(), &"plate_nothing") == null, "only armor goes in it, and only in a slot it has")
	var u := plated(scrap_plating, 3)
	u.disabled[scrap_plating] = 2
	ok(u.defense() == 11 and u.get(Unit.plate_slot(scrap_plating)) != null, "disabled: off")
	u.disabled.clear()
	u.bar_clear(u.hotbar.find(scrap_plating))
	ok(not u.equipped(scrap_plating) and u.defense() == 11, "off the bar: off")
	u.learned.clear()
	ok(u.plate_slots().is_empty() and u.defense() == 11 and u.get(&"plate_scrap_plating") != null, "unlearned: no slot, but it keeps what it held")
	u = plated(power_armor, 2)
	u.learned.append(slot(scrap_plating, 4))
	u.equip(bulwark(), Unit.plate_slot(scrap_plating))
	ok(u.plate_slots().size() == 2 and u.defense() == 11 + 20 + 4, "both skills: two slots, each by its own rule (%d)" % u.defense())
	u = v(2)
	u.learned.append(slot(scrap_plating, 3))
	roomy(u)
	u.equip(gambeson, Unit.plate_slot(scrap_plating))
	ok(u.defense() == 3, "armor in the slot and none proper: it is armor, not unarmored (%d)" % u.defense())


# A skill that lapsed (waived by a skill that no longer holds) works no slot: the armor stays worn, counts for nothing, and
# the unit card still shows it (HUD.trims()); the waiver back, it works again.
func test_lapsed() -> void:
	villagers_only()
	var u := plated(scrap_plating, 3)
	ok(u.defense() == 14 and u.plates().size() == 1, "Scrap Plating works")
	u.waived[scrap_plating] = load("res://Skills/generalist.tres")  # (never learned: the waiver doesn't hold)
	ok(u.lapsed(scrap_plating) and u.plates().is_empty() and u.defense() == 11, "lapsed: off")
	ok(u.get(Unit.plate_slot(scrap_plating)) != null and HUD.trims(u).any(func(t: Array) -> bool: return t[1] == "Bulwark (Scrap Plating)"), "the armor stays worn, and on the card as the slot's")
	u.waived.clear()
	ok(u.defense() == 14, "waiver gone: works")


# Armor in the slots drags in full on top of the armor proper's, each worked out alone - and weighs - whatever caps its Defense.
func test_drag() -> void:
	villagers_only()
	var heavy: Item = brigandine.duplicate()
	heavy.rank = 3
	var u := plated(scrap_plating, 1, heavy)
	u.armor = heavy
	var weight := u.weight()
	ok(u.armor_drag(&"move") == 4.0 and u.armor_drag(&"skill") == 4.0, "two heavy rank III: 3 less con (str) mod 1 each, 2 + 2 (%s)" % u.armor_drag(&"move"))
	u.unequip(String(Unit.plate_slot(scrap_plating)))
	ok(u.armor_drag(&"move") == 2.0 and weight - u.weight() == heavy.heft() and heavy.heft() > 0, "one: 2, and the second's weight gone")
	u.equip(heavy, Unit.plate_slot(scrap_plating))
	u.learned.clear()
	ok(u.armor_drag(&"move") == 2.0, "no skill, no slot, no drag")
	u = plated(power_armor, 1, heavy)
	u.armor = null
	ok(u.armor_drag(&"move") == 2.0, "armor in a slot alone drags all the same")
	u.energy = 0
	ok(u.armor_drag(&"move") == 0.0, "...unless the slot is off")


# A missed attack the armor in a slot made the difference to - it would have hit without it - blocked it: Power Armor takes the
# blow's damage / rank off its Power (Battle._plate_blocks()). Rolled by hand, then through real casts.
func test_blocks() -> void:
	villagers_only()
	var u := plated(power_armor, 2)
	var foe := v(3)
	foe.strength = 20  # +5: Strike is 1 + 5
	var att := Check.attack(0, 31)
	var shot := func(total: int) -> int:
		var r := Check.Roll.new()
		r.d20 = total
		r.total = total
		r.target = 31
		r.check = att
		u.energy = 10
		var vol := Behaviour.Volley.new()
		vol.skill = strike
		b._plate_blocks(foe, u, att, r, vol)
		return 10 - u.energy
	ok(shot.call(10) == 0 and shot.call(11) == 3 and shot.call(30) == 3, "11 would have hit Defense 11 alone, 10 would not: 6 / rank 2 = 3 off Power")
	u = plated(scrap_plating, 3)
	ok(shot.call(30) == 0, "Scrap Plating blocks, and costs nothing")
	u = plated(power_armor, 2)
	soak(u)
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var seen := []
	b.attack_rolled.connect(func(_c: Unit, _t: Unit, r: Check.Roll) -> void: seen.append([r.hit, r.total]))
	for i in 80:
		foe.refresh()
		b.cast(foe, strike, u)
		if u.energy < 10:
			break
	ok(not seen.is_empty() and not seen.back()[0] and seen.back()[1] >= 11 and u.energy == 7 and u.defense() == 11,
			"a real miss that would have hit Defense 11: Energy 10 -> 7, and under 80%% the armor is off (%s, Energy %d)" % [seen.back() if seen else "no rolls", u.energy])


# The AI: a unit with armor in its pack dresses a plate slot of its own when it has no blow to strike (the armor that adds most
# under the slot's rules, the old one back in the pack, one a turn), and prices a foe's Power Armor blocks (Power off it).
func test_ai() -> void:
	villagers_only()
	var u := plated(scrap_plating, 3)
	u.plating.clear()
	var weak := bulwark()
	weak.defense = 2
	u.pack.assign([weak, bulwark()])
	stage(lancin, {u: Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var log := AI.act(b, u)
	ok(u.get(Unit.plate_slot(scrap_plating)) != weak and u.defense() == 14 and u.pack == [weak] and log.any(func(l: String) -> bool: return "puts on Bulwark, +3 Defense" in l),
			"out of reach: it puts on the one that adds most under Scrap Plating's cap (%s)" % [log])
	u.pack.assign([bulwark()])
	ok(u.get(Unit.plate_slot(scrap_plating)) != null and AI.act(b, u).all(func(l: String) -> bool: return "puts on" not in l) and u.pack.size() == 1, "nothing more to gain: it keeps what it has")
	u.plating.clear()
	u.refresh()
	stage(lancin, {u: Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var fight := AI.act(b, u)
	ok(fight.any(func(l: String) -> bool: return "uses Strike" in l) and fight.all(func(l: String) -> bool: return "puts on" not in l) and u.get(Unit.plate_slot(scrap_plating)) == null,
			"with a foe to strike it strikes, with its AP, and does not dress first (%s)" % [fight])
	var power := v(4)  # (plated() dresses v(1) only)
	var scrap := v(3)
	for foe in [power, scrap]:
		foe.learned.clear()
		foe.plating.clear()
		foe.armor = null
		soak(foe)
	power.learned.append(slot(power_armor, 3))
	power.equip(bulwark(), Unit.plate_slot(power_armor))
	scrap.armor = bulwark()
	var me := v(1)
	ok(b.read(me, power).defense == 20 and power.defense() == 20 and scrap.defense() == 20, "two foes of Defense 20, read")
	var worth := func(foe: Unit) -> float: return AI.score(me, strike, b.read(me, foe), b, foe)
	ok(worth.call(power) > worth.call(scrap) and AI._blocks(b, me, strike, b.read(me, scrap), scrap, 5.0) == 0.0, "its Power Armor's blocks are worth something to a foe striking it, Scrap Plating's nothing")
	power.energy = 0
	ok(AI._blocks(b, me, strike, b.read(me, power), power, 5.0) == 0.0, "off (no Power left): no blocks to count")


# What a plate's blocks cost its wearer is weighed when it dresses (AI._plated(): Behaviour.slot_toll()): armor of Defense 6 fits
# Power Armor I (all 6, but each block takes the blow's damage off its Power: half its worth) and Scrap Plating IV (4, no toll): the
# slot with the toll loses to the one with none, though it adds more Defense. Without the toll, Power Armor.
func test_ai_weighs_tolls() -> void:
	villagers_only()
	var u := plated(power_armor, 1)
	u.learned.append(slot(scrap_plating, 4))
	u.plating.clear()
	var mid := bulwark()
	mid.defense = 6
	u.pack.assign([mid])
	stage(lancin, {u: Vector2i(1, 2), v(3): Vector2i(8, 2)})
	ok(u.plate_defense(power_armor, mid) == 6 and u.plate_defense(scrap_plating, mid) == 4 and AI._plated(u, power_armor, 6) == 3.0 and AI._plated(u, scrap_plating, 4) == 4.0, "6 in Power Armor I is worth 3 for its tolls, 4 in Scrap Plating 4")
	var log := AI.act(b, u)
	ok(u.get(Unit.plate_slot(scrap_plating)) == mid and u.get(Unit.plate_slot(power_armor)) == null, "it puts it in the slot with no toll (%s)" % [log])


# The sheet: a row for the slot, an Equip button into it for armor, kept in the outfit and the save.
func test_sheet() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var u := plated(scrap_plating, 3)
	u.plating.clear()
	var plate: Item = load("res://Items/plate.tres")
	var h := await hud(v(1))
	Game.stash.assign([plate])
	h.select(v(1))
	h.toggle_sheet()
	var texts := h.sheet.find_children("*", "Label", true, false).map(func(x: Label) -> String: return x.text)
	var buttons := h.sheet.find_children("*", "Button", true, false).map(func(x: Button) -> String: return x.text)
	ok("Scrap Plating: none" in texts and buttons.any(func(x: String) -> bool: return x.begins_with("Scrap Plating")), "a row for the slot, and a way to put armor in it (%s)" % [buttons])
	h._on_equipped(v(1), plate, &"plate_scrap_plating")
	ok(u.get(&"plate_scrap_plating") == plate and u.armor == gambeson and plate not in Game.stash and Game.outfit.get("plate_scrap_plating") == plate, "equipped into it, the armor proper untouched, and kept for next battle")
	Game.hero = {faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Wren"}
	Save.unpack(Save.pack())
	ok(Game.outfit.get("plate_scrap_plating") != null and Game.outfit["plate_scrap_plating"].name == plate.name, "and saved")
	h._on_unequipped(v(1), "plate_scrap_plating")
	ok(u.get(&"plate_scrap_plating") == null and plate in Game.stash, "taken off: back in the stash")
	h.free()
	Game.stash.clear()
	Game.outfit = {}
	Game.hero = {}


# The units that carry a pack (Scenes/scrapper.tscn, bulwarker.tscn): out of reach of any foe, each dresses its plate slot from it on its
# turn, the better of its spares under its skill's rules.
func test_packs() -> void:
	for id in [&"scrapper", &"bulwarker"]:
		var u: Unit = b.summon(load("res://Scenes/%s.tscn" % id), nemes, Vector2i(8, 6))
		ok(not u.pack.is_empty() and not u.plate_skills().is_empty(), "%s carries a pack and has a plate slot" % id)
		var n := u.pack.size()
		stage(nemes, {u: Vector2i(8, 6), v(1): Vector2i(0, 0)})
		var log := AI.act(b, u)
		var slot := Unit.plate_slot(u.plate_skills()[0])
		ok(u.get(slot) != null and u.pack.size() == n - 1 and log.any(func(l: String) -> bool: return "puts on" in l), "%s dresses from its pack (%s)" % [id, log])
