extends Test

# What an item lends (docs/plans/w3-lent.md): enchanted items lend enchanted skills (+1 rank) unless a skill has its own
# enchanted effect (Armor: +1 Defense); armor sets Defense through the equipment skill it lends; and a lent skill is a
# prerequisite - what was learned on it goes down with it (Unit.counts(), leaned, lapsed()).

var armor_skill: Skill = load("res://Skills/armor.tres")
var darkvision: Skill = load("res://Skills/darkvision.tres")
var meander: Skill = load("res://Skills/meander.tres")
var hide: Skill = load("res://Skills/hide.tres")
var sola: Skill = load("res://Skills/sola.tres")
var nadira: Skill = load("res://Skills/nadira.tres")
var astera: Skill = load("res://Skills/astera.tres")
var magic_slot: Skill = load("res://Skills/magic_slot.tres")
var adventurer: Role = load("res://Roles/adventurer.tres")


func lender(skills: Array, slot_name := "trinket") -> Item:
	var it := Item.new()
	it.name = "Lender"
	it.slot = slot_name
	it.skills.assign(skills)
	return it


func shrike() -> Unit:
	var u := b.starter({faction = lancin, role = adventurer, name = "Shrike"})
	b.get_node("Units").add_child(u)
	u.trinket = null
	u.skill_points = 30
	return u


func works(u: Unit, s: Skill) -> bool:
	return s in u.actives or s in u.passives


# Enchanted items lend enchanted skills: +1 rank each, however the item came by it, except the skill with its own
# enchanted effect (Armor), which keeps the item's rank and gives +1 Defense instead. Pray's enchantment doesn't raise
# the item's own rank (armor drag stays); an item authored enchanted (the tag) does, as it always did.
func test_enchanted_lends() -> void:
	var u := shrike()
	for slot_name in ["trinket", "weapon", "armor"]:
		for how in ["pray", "tag"]:
			u.trinket = null
			u.weapon = null
			var it := lender([darkvision, armor_skill], slot_name)
			if how == "tag":
				it.tags.assign([&"enchanted"])
			u.equip(it)
			var label := "%s %s" % [slot_name, how]
			var plain := it.skill_rank(darkvision) - (1 if how == "tag" else 0)
			if how == "pray":
				ok(u.enchant(1) == 1, "%s: Pray enchants it" % label)
			it = u.get(slot_name)
			ok(it.enchanted() and it.skill_rank(darkvision) == 2 and it.skill_rank(armor_skill) == 1, "%s: what it lends is +1 rank, Armor keeps rank 1 (%d, %d)" % [label, it.skill_rank(darkvision), it.skill_rank(armor_skill)])
			ok(u.rank(darkvision) == 2 and u.rank(armor_skill) == 1, "%s: and so does its wearer have them" % label)
			ok(how == "tag" or it.ranked() == (2 if slot_name == "trinket" else 1), "%s: Pray raises the item's own rank only for a trinket (%d)" % [label, it.ranked()])
			u.unequip(slot_name)
	u.free()


# Every armor's Defense, as it was before armor became a skill it lends (rows measured on the old rule): level 1 /
# dex 6 and level 30 / dex 20 (con 12, wis 14), plain then enchanted; Robe adds wis mod as magical Defense.
const DEFENSE := {
	"aethendine": [12, 13, 35, 36], "brigandine": [13, 14, 32, 33], "gambeson": [8, 9, 20, 21], "habergeon": [11, 12, 26, 27],
	"half_plate": [11, 12, 26, 27], "heart_up_link": [-1, 0, 6, 7], "ignauldron": [13, 14, 32, 33], "plate": [13, 14, 32, 33],
	"robe": [10, 11, 15, 16],
}


func test_armor_is_a_skill() -> void:
	var u := v(1)
	u.constitution = 12
	u.wisdom = 14
	var seen := 0
	for id in DEFENSE:
		var it: Item = load("res://Items/%s.tres" % id)
		ok(it.skills.has(armor_skill) and armor_skill.is_equipment() and not it.describe().contains("Gives the skill"), "%s lends Armor" % id)
		var en: Item = it.duplicate()
		en.enchant = 1
		for i in 2:
			u.level = [1, 30][i]
			u.dexterity = [6, 20][i]
			u.armor = it
			var plain := u.armor_defense()
			u.armor = en
			ok(plain == DEFENSE[id][i * 2] and u.armor_defense() == DEFENSE[id][i * 2 + 1], "%s at level %d: Defense %d, enchanted %d" % [id, u.level, plain, u.armor_defense()])
			seen += 1
	ok(seen == 18, "every armor")
	u.armor = load("res://Items/robe.tres")
	ok(u.defense([&"magical"]) - u.defense([&"physical"]) == 2, "Robe: wis mod against magic")
	ok(u.armor_skills() == ([armor_skill] as Array[Skill]) and u.traits().is_empty() and not armor_skill in u.hotbar and not u.has_tag(&"trait"), "Armor works without a slot, and isn't listed among its traits")
	u.afflict(load("res://Effects/traits_suppressed.tres"), 2)
	var bare := u.mod(&"dexterity") + u.mod(&"constitution")
	ok(u.armor_defense() == bare and u.defense([&"magical"]) == u.defense([&"physical"]), "traits suppressed: the armor sets nothing, unarmored (%d)" % bare)
	u.armor = null
	ok(u.armor_defense() == bare, "no armor: the same")


# Lent skills count: a skill learned on one is learned for good only while it's lent. Darkvision opens Meander opens Hide
# (a chain, so the loss runs down it); Astera is one of the three Magic skills its capstone wants. Each way of losing
# the skill, and back.
func test_lent_prerequisites() -> void:
	var u := shrike()
	ok(u.missing(meander) != "" and u.missing(magic_slot) != "", "without the lender: not yet")
	var gift := lender([darkvision, astera])
	u.equip(gift)
	ok(u.missing(meander) == "" and u.missing(magic_slot) == "Needs 3 Magic skills (1 so far)", "lent Darkvision opens Meander; lent Astera counts for the capstone (%s)" % u.missing(magic_slot))
	ok(u.unlock(meander) and u.unlock(hide) and u.unlock(sola) and u.unlock(nadira) and u.unlock(magic_slot), "learned on them")
	ok(u.leaned.has(meander) and u.leaned.has(hide) and u.leaned.has(magic_slot) and not u.leaned.has(sola), "those that needed what was lent are marked (Hide through Meander)")
	u.bar_clear(1)
	ok(u.bar_place(meander, 1) and u.bar_place(hide, 2) and u.bar_place(magic_slot, 3), "on the bar: they work")
	var chain := [meander, hide, magic_slot]
	ok(chain.all(func(s: Skill): return not u.lapsed(s) and u.rank(s) > 0), "all there while it's lent")
	var causes := {
		"unequipped": [func(): u.unequip("trinket"), func(): u.equip(gift)],
		"disabled": [func(): u.disable(darkvision, 3); u.disable(astera, 3), func(): u.disabled.clear()],
		"traits suppressed": [func(): darkvision.tags.append(&"trait"); astera.tags.append(&"trait"); u.afflict(load("res://Effects/traits_suppressed.tres"), 2), func(): u.tick(); u.tick(); darkvision.tags.erase(&"trait"); astera.tags.erase(&"trait")],
	}
	for why in causes:
		causes[why][0].call()
		ok(chain.all(func(s: Skill): return u.lapsed(s) and not works(u, s) or s == magic_slot), "%s: what was learned on them stops working, Hide with Meander" % why)
		ok(u.rank(meander) == 1 and not u.lapsed(sola) and u.rank(sola) == 1, "%s: still learned, and what stood on its own is untouched" % why)
		ok(u.missing(meander) != "", "%s: and Meander is out of reach again" % why)
		causes[why][1].call()
		ok(chain.all(func(s: Skill): return not u.lapsed(s)) and works(u, meander) and works(u, hide), "%s: back as they are" % why)
	var own := shrike()  # a skill learned the usual way isn't a dependent
	own.unlock(darkvision)
	ok(own.unlock(meander) and not own.leaned.has(meander) and not own.lapsed(meander), "learned, not lent: nothing leans")
	own.free()
	u.free()
