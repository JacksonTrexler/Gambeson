extends Test

# Command (the leader's orders and party), the hotbar, toggled passives, skill text, and the walk a
# unit expects before it moves.

var arcanist: Skill = load("res://Skills/arcanist.tres")
var persona: Skill = load("res://Skills/persona.tres")
var tonefoolery: Skill = load("res://Skills/tonefoolery.tres")
var stoneskin: Skill = load("res://Skills/stoneskin.tres")


func unit(n: String) -> Unit:
	return b.get_node("Units/" + n)


func same(x: Array, y: Array) -> bool:
	return x.size() == y.size() and range(x.size()).all(func(i): return x[i] == y[i])


func test_reach() -> void:
	var c := Command.new(b, v(1))
	ok(c.reach() == 1 and c.party_size() == 1 and c.party_reach() == 2.0, "cha 8 (-1): reach 1 at least, party of 1, who hear from 2")
	v(1).charisma = 14
	ok(c.reach() == 2 and c.party_size() == 2 and c.party_reach() == 4.0, "cha 14 (+2): reach 2, party of 2, who hear from 4")
	v(1).afflict(effect("command", 1), 9)
	v(1).afflict(effect("party", 2), 9)
	ok(c.reach() == 3 and c.party_size() == 4, "command and party effects add on")


func test_slots() -> void:
	var al := unit("Alabaster")
	var c := Command.new(b, v(1))
	ok(c.slots() == 0 and not c.slot_open(al, 0) and c.slot_open(v(1), 3), "cha 8: allies take move orders only; the leader uses everything")
	v(1).charisma = 12
	ok(c.slots() == 1 and c.slot_open(al, 0) and not c.slot_open(al, 1), "cha 12 (+1): slot 1")
	ok(c.may_use(al, strike) and not c.may_use(al, load("res://Skills/stonegift.tres")), "Strike sits in slot 1, Stonegift in 2")
	v(1).charisma = 14
	ok(c.slots() == 2, "cha 14 (+2): slots 1-2")


func test_afford_after_walking() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	ok(v(1).can_afford_after(strike, 5.0), "12 AP: walking 5 leaves 7 for Strike's 3")
	ok(not v(1).can_afford_after(strike, 10.0), "walking 10 leaves the wis pool's 1 and 1 general")
	ok(v(1).can_afford_after(strike, 0.0) == v(1).can_afford(strike), "standing still is plain can_afford")


func test_tiles() -> void:
	ok(Command.tiles(Vector2i(0, 0), Vector2i(1, 1)) == 1, "a diagonal step is 1 tile")
	ok(Command.tiles(Vector2i(0, 0), Vector2i(2, 1)) == 2 and Command.tiles(Vector2i(0, 0), Vector2i(2, 2)) == 3, "(2,1) is 2 tiles, (2,2) is 3")


func test_orders() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), v(3): Vector2i(4, 3), al: Vector2i(6, 3)})
	var c := Command.new(b, v(1))
	ok(c.can_order(v(1)) and c.can_order(v(2)), "the leader, and an ally a diagonal step away")
	ok(not c.can_order(v(3)), "never another side")
	ok(not c.can_order(al), "not an ally 3 tiles off")
	b.end_turn()
	ok(not c.can_order(v(1)) and not c.can_order(v(2)), "only on the leader's side's turn")
	b.end_turn()
	v(1).damage(99)
	ok(not c.can_order(v(2)), "no one once the leader falls")


# A turn's caps: the leader gives orders to at most its cha mod allies, and at most its cha mod orders
# to each (at least 1 of each); its own actions aren't capped. A new turn starts them over.
func test_caps() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), al: Vector2i(3, 4)})
	var c := Command.new(b, v(1))
	v(1).charisma = 8  # -1
	ok(c.ally_cap() == 1 and c.order_cap() == 1, "cha -1: still one ally a turn, one order")
	v(1).charisma = 12  # +1
	c.order(v(2))
	ok(not c.can_order(v(2)) and not c.can_order(al), "cha +1: an order to one ally, and that's all: neither takes another")
	for i in 5:
		c.order(v(1))
	ok(c.can_order(v(1)) and c.commanded() == 1, "the leader's own actions aren't capped, nor count as an ally commanded")
	c.new_turn()
	ok(c.can_order(v(2)) and c.can_order(al), "a new turn: orders start over")
	v(1).charisma = 14  # +2
	c.order(v(2))
	ok(c.can_order(v(2)) and c.can_order(al), "cha +2: a second order for the same ally, or one for another")
	c.order(v(2))
	ok(not c.can_order(v(2)) and c.can_order(al) and c.under_caps(al), "its two given: it's done; the other ally isn't")


# A copy of a trinket at a rank (its effects go by Item.rank).
func ranked(path: String, r: int) -> Item:
	var it: Item = load(path).duplicate()
	it.rank = r
	return it


# Leadership learned and carried: Strategist and a Strategy Guide add a rank each to the allies a turn,
# Tactician and a Tactician's Playbook to the orders each takes - on top of the floor of 1, so they
# stand in for charisma - and skill and trinket stack.
func test_leadership() -> void:
	var strategist: Skill = load("res://Skills/strategist.tres")
	var tactician: Skill = load("res://Skills/tactician.tres")
	var guide := "res://Items/strategy_guide.tres"
	var playbook := "res://Items/tacticians_playbook.tres"
	var c := Command.new(b, v(1))
	v(1).charisma = 8  # -1
	v(1).learned.append(slot(strategist, 2))
	ok(c.ally_cap() == 3 and c.order_cap() == 1, "cha -1, Strategist II: 1 + 2 allies a turn, still an order each (%d, %d)" % [c.ally_cap(), c.order_cap()])
	v(1).learned.append(slot(tactician, 1))
	ok(c.ally_cap() == 3 and c.order_cap() == 2, "Tactician I: 1 + 1 orders each")
	ok(c.reach() == 1 and c.party_size() == 1 and c.slots() == 0, "neither moves the reach, the party or the slots: allies still only take move orders")
	v(1).equip(ranked(guide, 1))
	ok(c.ally_cap() == 4 and c.order_cap() == 2, "a Strategy Guide: one more ally, on top of the skill")
	v(1).equip(ranked(guide, 3))
	ok(c.ally_cap() == 6, "at rank 3: three more")
	v(1).equip(ranked(playbook, 2))
	ok(c.ally_cap() == 3 and c.order_cap() == 4, "a Tactician's Playbook II in its place (one trinket): 1 + 1 + 2 orders each, the Guide's allies gone")
	v(1).charisma = 14  # +2
	ok(c.ally_cap() == 4 and c.order_cap() == 5, "cha +2: 2 + 2 allies, 2 + 1 + 2 orders")
	v(1).unequip("trinket")
	v(1).learned.clear()
	ok(c.ally_cap() == 2 and c.order_cap() == 2, "without them: its cha mod")
	v(1).afflict(effect("strategy", -5), 9)
	ok(c.ally_cap() == 1, "never fewer than one")
	ok(strategist.describe(2).contains("Allies commanded a turn: +2") and tactician.describe(3).contains("Orders per ally a turn: +3"), strategist.describe(2) + " / " + tactician.describe(3))
	ok(ranked(guide, 2).describe().contains("Allies commanded a turn: +2") and ranked(playbook, 1).describe().contains("Orders per ally a turn: +1"), ranked(guide, 2).describe() + " / " + ranked(playbook, 1).describe())
	var tab: SkillTab = load("res://Trees/general_specialist.tres")
	ok(tab.tier_of(strategist) == 3 and tab.tier_of(tactician) == 3, "both on the Specialist general tree, tier 3: a tier past Synergy")


# The caps as orders are given: a cha -1 leader with Strategist I and Tactician I orders two allies,
# twice each.
func test_leadership_orders() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), al: Vector2i(3, 4)})
	var c := Command.new(b, v(1))
	v(1).charisma = 8
	c.order(v(2))
	ok(not c.can_order(v(2)) and not c.can_order(al), "cha -1 alone: one order to one ally")
	v(1).learned.append(slot(load("res://Skills/tactician.tres"), 1))
	ok(c.can_order(v(2)) and not c.can_order(al), "Tactician I: the same ally takes a second; still no second ally")
	v(1).learned.append(slot(load("res://Skills/strategist.tres"), 1))
	ok(c.can_order(al), "Strategist I: a second ally")
	c.order(v(2))
	c.order(al)
	c.order(al)
	ok(not c.can_order(v(2)) and not c.can_order(al) and c.commanded() == 2, "two each given: both done")


# Grand Design: +1 a rank to the leader's cha mod wherever Command reads it - reach, party size, slots,
# both caps, Synergy's range - and nowhere else.
func test_grand_design() -> void:
	var design := "res://Items/grand_design.tres"
	var c := Command.new(b, v(1))
	v(1).charisma = 8  # -1
	v(1).equip(ranked(design, 1))
	ok(Command.cha_of(v(1)) == 0 and c.reach() == 1 and c.party_size() == 1 and c.slots() == 0 and c.ally_cap() == 1 and c.order_cap() == 1,
			"cha -1, Grand Design I: commanding at +0 - the floors hold, no slots yet")
	v(1).equip(ranked(design, 3))
	ok(c.cha() == 2 and c.reach() == 2 and c.party_reach() == 4.0 and c.party_size() == 2 and c.slots() == 2 and c.ally_cap() == 2 and c.order_cap() == 2,
			"rank 3: commanding at +2 - reach 2, a party of 2 who hear from 4, slots 1-2, 2 allies, 2 orders each")
	ok(Command.party_reach_of(v(1)) == 4.0, "Synergy's range goes by it too")
	ok(v(1).mod(&"charisma") == -1 and v(1).stat(&"charisma") == 8.0, "its charisma itself is as it was: checks and skills go by -1")
	v(1).learned.append(slot(load("res://Skills/strategist.tres"), 1))
	v(1).learned.append(slot(load("res://Skills/tactician.tres"), 2))
	ok(c.ally_cap() == 3 and c.order_cap() == 4, "all together: 2 + Strategist I allies, 2 + Tactician II orders")
	ok(ranked(design, 2).describe().contains("Cha mod when commanding: +2") and ranked(design, 2).describe().begins_with("Trinket\nLegendary"), ranked(design, 2).describe())
	ok(c.basis() == "charisma +2 as it commands" and c.basis(c.order_bonus()) == "charisma +2 as it commands, +2 from skills and items", c.basis(c.order_bonus()))


# What the HUD says of a refused order and shows on a unit's card, once a skill has raised a cap.
func test_refusal_words() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 4), unit("Alabaster"): Vector2i(3, 4)})
	v(1).charisma = 8
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	h.command.order(v(2))
	ok(h._why_no_orders(v(2)) == "%s gives an ally 1 order a turn (charisma -1)" % h._name(v(1)), h._why_no_orders(v(2)))
	ok(h._why_no_orders(unit("Alabaster")) == "%s commands 1 ally a turn (charisma -1)" % h._name(v(1)), h._why_no_orders(unit("Alabaster")))
	ok(h._why_locked() == "Allies only take move orders from %s (charisma -1)" % h._name(v(1)), h._why_locked())
	v(1).learned.append(slot(load("res://Skills/tactician.tres"), 2))
	ok(h.command.can_order(v(2)) and h._why_no_orders(v(2)) == "", "Tactician II: it takes more")
	ok(h._info(v(2)).chips.any(func(c): return c[0] == "Ordered 1/3"), "its card counts against the raised limit: %s" % [h._info(v(2)).chips.map(func(c): return c[0])])
	h.command.order(v(2))
	h.command.order(v(2))
	ok(h._why_no_orders(v(2)) == "%s gives an ally 3 orders a turn (charisma -1, +2 from skills and items)" % h._name(v(1)), h._why_no_orders(v(2)))
	ok(h._why_no_orders(unit("Alabaster")) == "%s commands 1 ally a turn (charisma -1)" % h._name(v(1)), h._why_no_orders(unit("Alabaster")))
	v(1).equip(ranked("res://Items/strategy_guide.tres", 1))
	h.command.order(unit("Alabaster"))
	ok(h._why_no_orders(unit("Alabaster")) == "", "a Strategy Guide: a second ally, with orders left")
	h.free()


func test_party() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3), al: Vector2i(3, 4), v(3): Vector2i(8, 2)})
	var c := Command.new(b, v(1))
	ok(c.join(v(2)), "an ally in range joins")
	ok(not c.join(al) and same(c.party, [v(2)]), "the party is full at 1 (cha 8)")
	ok(not c.join(v(3)) and not c.join(v(1)), "not enemies, not the leader")
	b.move(v(2), Vector2i(5, 3))
	ok(c.can_order(v(2)) and c.ours(v(2)), "party members take orders from 2 tiles")
	b.move(v(2), Vector2i(6, 3))
	ok(not c.can_order(v(2)), "...not 3")
	c.leave(v(2))
	b.move(v(2), Vector2i(5, 3))
	ok(not c.can_order(v(2)) and not c.ours(v(2)), "out of the party, 2 tiles is too far")
	v(1).charisma = 14
	ok(not c.join(v(3)) and c.join(al) and c.join(v(2)), "cha 14: room for 2, joining from within 2 tiles")
	v(2).damage(99)
	c.new_turn()
	ok(same(c.party, [al]), "the fallen leave the party")


func test_idle() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), al: Vector2i(5, 5), v(3): Vector2i(8, 2)})
	var c := Command.new(b, v(1))
	ok(same(c.idle(), [v(2), al]), "allies without orders, never the leader")
	c.order(v(2))
	ok(same(c.idle(), [al]), "an order takes one off the list")
	c.new_turn()
	ok(c.idle().size() == 2, "orders last a turn")


func test_default_bar() -> void:
	var siren := unit("Siren")
	ok(same(unit("Icor").hotbar, [strike, hex, arcanist, null, null, null]), "Icor (level 5): 5 slots and a clover slot; Strike (every class's), Hex, then its toggled Arcanist Perspective")
	ok(same(siren.hotbar, [load("res://Skills/rake.tres"), load("res://Skills/drown.tres"), load("res://Skills/sing.tres"), tonefoolery, null]),
			"Siren: Rake, Drown and Sing, then a toggle; Oceanic has none, Personify is left for want of a slot (the last is its clover slot)")
	ok(same(v(1).hotbar, [strike, null, null, null, null]) and v(1).slot_count() == Unit.SLOTS, "4 slots and a clover one; Favour stays off the bar")


func test_bar_place() -> void:
	var u := unit("Icor")
	ok(u.bar_place(arcanist, 3) and same(u.hotbar, [strike, hex, null, arcanist, null, null]), "a skill on the bar moves, swapping with the empty slot")
	ok(u.bar_place(hex, 3) and same(u.hotbar, [strike, arcanist, null, hex, null, null]), "...or with the skill there")
	ok(not u.bar_place(load("res://Skills/snare.tres"), 2), "not a skill it doesn't have")
	ok(not v(1).bar_place(favour, 1), "not a passive without a toggle")
	ok(u.bar_place(hex, 4) and not u.bar_place(hex, 5) and not u.bar_place(hex, 6), "a fifth slot at level 5; not the clover slot while unlucky, nor past it")
	u.bar_clear(0)
	ok(same(u.hotbar, [null, arcanist, null, null, hex, null]), "cleared")


func test_toggle() -> void:
	var u := unit("Icor")
	ok(u.toggle(arcanist) and not u.is_on(arcanist) and u.scaling(&"wisdom", [&"magical"]) == 10, "switched off: plain wis")
	ok(u.toggle(arcanist) and u.is_on(arcanist) and u.scaling(&"wisdom", [&"magical"]) == 18, "and back on")
	ok(not v(1).toggle(favour) and v(1).is_on(favour), "Favour has no toggle")
	ok(not u.toggle(hex), "actives don't toggle")


func test_text() -> void:
	ok(Skill.roman(1) == "I" and Skill.roman(4) == "IV" and Skill.roman(9) == "IX" and Skill.roman(14) == "XIV", "numerals")
	ok("Deals 1d6 + wis" in hex.describe(3) and "Luck: -3 for 3 turns" in hex.describe(3), "Hex III: d6 + wis, luck -3")
	ok("Deals 1, unblockable" in hex.describe(1), "Hex I: 1 direct")
	ok("3 hits of 1 + str mod" in strike.describe(3) and "hits" not in strike.describe(1), "Strike III")
	ok("Damage taken: -40%, above 85% HP" in stoneskin.describe() and "Dexterity: x0.5" in stoneskin.describe(), "Stoneskin")
	ok(hex.summary() == "Foe · range 5 · 4 AP · 2 cost" and arcanist.summary() == "Passive · Toggle" and favour.summary() == "Passive · Always on", "one-liners")


func test_tile_reads() -> void:
	var bramble := b.read(v(1), Vector2i(2, 2))
	ok(bramble.cost == 1 and bramble.exit == 1 and same(bramble.tags, [&"bramble", &"sticky", &"shrubbery"]), "a seen tile: costs and what the ground is")
	var shrine := b.read(v(1), Vector2i(5, 2))
	ok(same(shrine.tags, [&"shrine", &"stone"]) and shrine.worth == null, "beneficial or detrimental takes a closer look than recon 0")
	var trap := b.read(v(1), Vector2i(5, 4))
	ok(trap.cost == null and trap.exit == null and trap.tags.is_empty() and trap.hint == "disturbed earth?", "a hidden trap gives away only a hint")


func test_expected_walk() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var state := b.rng.state
	var seen: Array = b.walk(v(1), Vector2i(6, 2), true).path
	ok(b.rng.state == state, "planning leaves the rng alone")
	ok(same(seen, b.travel(v(1), Vector2i(6, 2))), "on open ground the plan is the walk")
	stage(lancin, {v(1): Vector2i(4, 4)})
	ok(b.walk(v(1), Vector2i(7, 4), true).path.back() == Vector2i(7, 4), "an unknown trap doesn't show in the plan")
	ok(b.revealed.is_empty() and v(1).hp == 10, "and planning springs nothing")
	ok(b.travel(v(1), Vector2i(7, 4)).back() == Vector2i(5, 4), "the real walk stops on it")
	stage(lancin, {v(2): Vector2i(4, 4)})
	ok(b.walk(v(2), Vector2i(7, 4), true).path.back() == Vector2i(5, 4), "once sprung, plans stop there too")
