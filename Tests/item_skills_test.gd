extends Test

# Skills on items (docs/plans/item-skills.md): Item.skills are lent to the wearer while the item is worn
# (Unit.granted(): a Slot flagged with Slot.from), at the item's rank (Item.skill_rank()), never raised,
# and gone with the item; Pray's enchantment covers trinkets and item skills (Item.scales()); emblems and
# the AI treat them like any other skill.

var kick: Skill = load("res://Skills/kick.tres")
var mana: Skill = load("res://Skills/mana.tres")
var meander: Skill = load("res://Skills/meander.tres")
var pray: Skill = load("res://Skills/pray.tres")
var boots: Item = load("res://Items/hobnail_boots.tres")
var heart_up: Item = load("res://Items/heart_up.tres")


func lender(skills: Array[Skill], slot_name := "trinket", rank := 1) -> Item:
	var it := Item.new()
	it.name = "Lender"
	it.slot = slot_name
	it.rank = rank
	it.skills = skills
	return it


func bare(u: Unit) -> Unit:  # no skills of its own, no gear
	u._role_slots.clear(); u.sync_bar()
	u.innate.clear(); u.sync_bar()
	u.learned.clear(); u.sync_bar()
	u.trinket = null
	u.weapon = null
	u.armor = null
	u.hotbar.clear()
	u._fill_bar()
	return u


func test_grant_and_remove() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	ok(u.rank(kick) == 0 and kick not in u.actives, "without the boots: no Kick")
	u.equip(boots)
	ok(u.rank(kick) == 1 and kick in u.actives and u.slots.any(func(x: Slot): return x.skill == kick and x.from == boots), "worn: Kick, a flagged slot from the boots")
	ok(not u.hotbar.has(kick) and u.slot_cost(kick) == 0 and kick in u.traits() and u.lent_by(kick) == boots.name, "lent free (?214): no slot, it sits beside the bar, and says whose it is")
	ok("Kick" in boots.describe() and "can't be ranked" in boots.describe(), boots.describe())
	u.unequip("trinket")
	ok(u.rank(kick) == 0 and kick not in u.actives and not u.hotbar.has(kick) and u.lent_by(kick) == "", "taken off: the skill and its slot go")
	ok(u.granted().is_empty(), "nothing lent")


func test_no_ranking() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	u.equip(boots)
	u.skill_points = 20
	ok(u.own_rank(kick) == 0 and not u.can_raise(kick) and not u.raise(kick) and u.skill_points == 20, "a lent skill can't be raised, and costs nothing")
	ok(not u.options().values().any(func(l: Array): return kick in l), "nor unlocked while it's worn")
	u.unequip("trinket")
	ok(u.rank(kick) == 0, "no rank left behind")
	u.learned.append(slot(kick, 1)); u.sync_bar()
	u.equip(lender([kick], "trinket", 3))
	ok(u.rank(kick) == 3 and u.own_rank(kick) == 1 and u.can_raise(kick), "learned as well: the higher rank wins, and its own rank is still raised")
	u.raise(kick)
	ok(u.own_rank(kick) == 2 and u.rank(kick) == 3, "raising touches only what it learned")
	u.unequip("trinket")
	ok(u.rank(kick) == 2 and u.hotbar.has(kick), "the item goes, the learned skill stays (and stays on the bar)")


func test_rank_from_the_item() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	var it := lender([kick], "trinket", 2)
	u.equip(it)
	ok(u.rank(kick) == 2, "rank 2 item: rank 2")
	it.tags.assign([&"enchanted"])
	ok(u.rank(kick) == 3, "enchanted: +1 as the item's")
	it.tags.assign([&"honed"])
	ok(u.rank(kick) == 3, "honed: +1")
	it.tags.clear()
	var capped := Skill.new()
	capped.name = "Capped"
	capped.max_rank = 2
	it.rank = 5
	it.skills = [capped]
	ok(u.rank(capped) == 2, "a skill's max rank caps it")


func test_enchant() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	u.equip(heart_up)
	ok(not heart_up.scales() and u.enchant(1) == 0 and u.trinket == heart_up, "Heart Up has nothing to scale: skipped, and it takes none of Pray's count")
	u.equip(boots)
	ok(boots.scales() and u.enchant(1) == 1 and u.trinket != boots and u.trinket.enchant == 1 and boots.enchant == 0, "boots with a skill: enchanted, a copy")
	ok(u.trinket.ranked() == 2 and u.rank(kick) == 2 and u.equipped(kick), "...rank +1 on the item, and so on its skill")
	ok(u.enchant(1) == 0, "once")
	b.disenchant(u, 1)
	ok(u.rank(kick) == 1, "disenchanted: back to its rank")
	var blade := lender([kick], "weapon", 1)
	u.equip(blade)
	u.unequip("trinket")
	ok(u.enchant(1) == 1 and u.weapon.enchant == 1 and u.weapon.ranked() == 1 and u.rank(kick) == 2, "a weapon's +1 is damage; its skills take the rank all the same")
	var armor := Item.new()
	armor.slot = "armor"
	u.equip(armor)
	var ring := lender([], "trinket")
	ring.revives = 0.5
	u.equip(ring)
	ok(ring.scales() and u.enchant(3) == 2 and u.armor.enchant == 1 and u.trinket.enchant == 1, "weapon, armor, then trinket in turn, up to n")
	var plain := lender([], "trinket")
	ok(not plain.scales(), "a trinket with nothing to scale doesn't")
	var own := lender([], "trinket")
	var better := lender([kick], "trinket", 1)
	better.tags.assign([&"enchanted"])
	own.enchanted_as = better
	ok(own.scales(), "...unless it has an enchanted form of its own")
	u.unequip("weapon")
	u.unequip("armor")
	u.equip(own)
	ok(u.enchant(1) == 1 and u.trinket == better and u.rank(kick) == 2, "its own enchanted form, with its skills")


func test_urlo_prays_for_trinkets() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(2): Vector2i(2, 4)})
	bare(v(1))
	bare(v(2))
	v(1).god = &"urlo"
	v(1).learned.append(slot(pray, 2)); v(1).sync_bar()
	v(2).equip(boots)
	v(1).refresh()
	ok(b.cast(v(1), pray, v(1)) and v(2).trinket.enchant == 1 and v(2).rank(kick) == 2, "Pray: the ally's trinket, the skill it lends a rank higher")


func test_emblem_on_an_item_skill() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	var s := Skill.new()
	s.name = "Scaler"
	s.ap = 4.0
	s.cost = 4
	s.tags = [&"magical"]
	s.turns_per_rank = 1
	var t := Tier.new()
	t.dice = Vector2i(1, 6)
	t.stat = &"intelligence"
	s.tiers = [t]
	var plain := Skill.new()
	plain.name = "Plain"
	plain.ap = 1.0
	var lent := lender([plain, s], "weapon", 2)
	u.equip(lent)
	var sigil := Item.new()
	sigil.name = "Sigil"
	sigil.slot = "trinket"
	sigil.emblem = &"rho_up"
	sigil.scope = &"sigil"
	u.equip(sigil)
	ok(not u.hotbar.has(s) and u.traits() == ([plain, s] as Array[Skill]), "both lent free: beside the bar, in the order lent")
	ok(u.mods(s).label() == "ρ↑" and u.mods(plain).empty(), "a Sigil: the leftmost eligible skill on the hotbar, then beside it - Plain scales by nothing, so Scaler")
	lent.optional = [plain, s] as Array[Skill]
	u.refit()
	ok(u.bar_place(s, 0) and u.bar_place(plain, 1) and u.mods(s).label() == "ρ↑", "lent for a slot, and in whatever order it's arranged")
	var badge := Item.new()
	badge.slot = "trinket"
	badge.emblem = &"rho_up"
	badge.scope = &"insignia"
	u.equip(badge)
	ok(u.mods(s).label() == "ρ↑", "an Insignia too: every skill it fits")


func test_the_ai_uses_it() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var u := bare(v(1))
	u.equip(boots)
	u.refresh()
	var log := AI.act(b, u)
	ok(log.any(func(l: String): return "uses Kick" in l), "a unit with nothing but the boots' Kick uses it (%s)" % ", ".join(log))


func test_channel_and_toggle() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var u := bare(v(1))
	var it := lender([mana, meander], "trinket", 1)
	u.equip(it)
	ok(u.is_on(meander) and u.toggle(meander) and not u.is_on(meander), "a lent toggle switches")
	ok(u.toggle(mana) and u.channel != null and u.channel.switch != null, "a switch of what it runs on is a channel")
	u.unequip("trinket")
	ok(u.channel == null, "its item comes off mid-switch: the channel stops")
	u.equip(it)
	ok(u.is_on(meander) and u.channel == null, "worn again: the toggle starts as new")
	var watch := lender([kick], "weapon")
	u.equip(watch)
	var rift := Unit.Channel.new(kick, u.cell)
	u.channel = rift
	u.unequip("weapon")
	ok(u.channel == null, "a channel on a skill that goes ends")
	u.learned.append(slot(kick)); u.sync_bar()
	u.equip(watch)
	u.channel = Unit.Channel.new(kick, u.cell)
	u.unequip("weapon")
	ok(u.channel != null, "...but not one it has of its own")


func test_loot_and_tooltips() -> void:
	var loot: Loot = load("res://Loot/alabaster.tres")
	ok(boots in loot.items and boots.name.ends_with(" ??"), "the example item is in a loot table, named with ?? (an AI's name)")
	ok(boots.icon() != null, "and has its icon")
	var slotter := SkillSlot.new()
	slotter.set_state(0, kick, 1, false, false, true, true)
	slotter.set_lent(boots.name)
	ok(slotter.lent == boots.name and "Lent by" in slotter.tooltip_text and not slotter.modded, "a lent skill's slot is marked, apart from a worn emblem's")
	slotter.free()
