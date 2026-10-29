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
	ok(same(unit("Icor").hotbar, [hex, arcanist, null, null, null, null]), "Icor (level 5): 5 slots and a clover slot; Hex, then its toggled Arcanist Perspective")
	ok(same(siren.hotbar, [strike, tonefoolery, persona, null, null]), "Siren: Strike, then its toggles; Oceanic has none")
	ok(same(v(1).hotbar, [strike, null, null, null, null]) and v(1).slot_count() == Unit.SLOTS, "4 slots and a clover one; Favour stays off the bar")


func test_bar_place() -> void:
	var u := unit("Icor")
	ok(u.bar_place(arcanist, 3) and same(u.hotbar, [hex, null, null, arcanist, null, null]), "a skill on the bar moves, swapping with the empty slot")
	ok(u.bar_place(hex, 3) and same(u.hotbar, [arcanist, null, null, hex, null, null]), "...or with the skill there")
	ok(not u.bar_place(strike, 1), "not a skill it doesn't have")
	ok(not v(1).bar_place(favour, 1), "not a passive without a toggle")
	ok(u.bar_place(hex, 4) and not u.bar_place(hex, 5) and not u.bar_place(hex, 6), "a fifth slot at level 5; not the clover slot while unlucky, nor past it")
	u.bar_clear(0)
	ok(same(u.hotbar, [null, null, null, null, hex, null]), "cleared")


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
	ok("3 hits of 1 + str" in strike.describe(3) and "hits" not in strike.describe(1), "Strike III")
	ok("Damage taken: -40%, above 85% HP" in stoneskin.describe() and "Dexterity: x0.5" in stoneskin.describe(), "Stoneskin")
	ok(hex.summary() == "4 AP · 2 cost · range 5" and arcanist.summary() == "Toggle" and favour.summary() == "Always on", "one-liners")


func test_tile_reads() -> void:
	var bramble := b.read(v(1), Vector2i(2, 2))
	ok(bramble.cost == 1 and bramble.exit == 1 and same(bramble.tags, [&"bramble", &"sticky"]), "a seen tile: costs and what the ground is")
	var shrine := b.read(v(1), Vector2i(5, 2))
	ok(same(shrine.tags, [&"shrine"]) and shrine.worth == null, "beneficial or detrimental takes a closer look than recon 0")
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
