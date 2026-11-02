extends Test

# Starting items by class (Role.items, put on a new starter by Entry: Game.outfit), what items cost in
# battle (Item.ap_cost(): rank, x2 medium, x3 heavy; Battle.equip()), skill attributes items change
# (Unit.skill_stat(): a Staff's and a Broadsword's range, a Broadsword's Strike rank), a Dagger's
# opening AP, and potions used up from the trinket slot (Battle.use_item(), Battle.restore()).

var plate: Item = load("res://Items/plate.tres")
var half_plate: Item = load("res://Items/half_plate.tres")
var gambeson: Item = load("res://Items/gambeson.tres")
var broadsword: Item = load("res://Items/broadsword.tres")
var dagger: Item = load("res://Items/dagger.tres")
var staff: Item = load("res://Items/staff.tres")
var health: Item = load("res://Items/health_potion.tres")
var energy_potion: Item = load("res://Items/energy_potion.tres")
var mana_potion: Item = load("res://Items/mana_potion.tres")
var sweet_something: Item = load("res://Items/sweet_something.tres")
var sn: Reserve = load("res://Reserves/sweet_nothings.tres")
var mana: Reserve = load("res://Reserves/mana.tres")


func names(r: Role) -> Array:
	var o := r.outfit()
	return ["armor", "weapon", "trinket"].map(func(k: String): return o[k].name if k in o else "")


func test_starting_items() -> void:
	ok(names(load("res://Roles/fighter.tres")) == ["Half Plate", "Broadsword", "Health Potion"], "Fighter: %s" % [names(load("res://Roles/fighter.tres"))])
	ok(names(load("res://Roles/paladin.tres")) == ["Half Plate", "Broadsword", "Health Potion"], "Paladin: half plate and a broadsword")
	ok(names(load("res://Roles/rogue.tres")) == ["Gambeson", "Dagger", "Energy Potion"], "Rogue: a gambeson and a dagger")
	ok(names(load("res://Roles/bard.tres")) == ["Gambeson", "Dagger", "Energy Potion"], "Bard: the same")
	ok(names(load("res://Roles/adventurer.tres")) == ["Gambeson", "Dagger", "Energy Potion"], "Adventurer: the same")
	ok(names(load("res://Roles/wizard.tres")) == ["Robe", "Staff", "Mana Potion"], "Wizard: a robe, a staff and a mana potion")
	ok(names(load("res://Roles/warlock.tres")) == ["Robe", "Staff", "Sweet Something"], "Warlock: a Sweet Something")
	var was := Game.outfit
	Game.outfit = load("res://Roles/fighter.tres").outfit()
	var u := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Brand"})
	ok(u.armor == half_plate and u.weapon == broadsword and u.trinket == health, "a new starter wears them")
	u.free()
	Game.outfit = was


func test_equip_ap() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	ok(b.phase == Battle.Phase.TURNS, "in battle")
	v(1).unequip("armor")  # villagers wear gambesons
	v(1).refresh()
	ok(dagger.ap_cost() == 1.0 and gambeson.ap_cost() == 1.0 and plate.ap_cost() == 3.0, "rank 1: light 1 AP, heavy (Plate) 3")
	var medium := gambeson.duplicate()
	medium.tags = gambeson.tags + ([&"medium"] as Array[StringName])  # its own array: duplicate() shares it
	medium.rank = 2
	ok(medium.ap_cost() == 4.0, "medium rank 2: 4 AP")
	var ap := v(1).ap_for(&"equip")
	ok(b.equip(v(1), gambeson) and is_equal_approx(ap - v(1).ap_for(&"equip"), 1.0), "a gambeson on: 1 AP")
	ap = v(1).ap_for(&"equip")
	ok(is_equal_approx(b.equip_ap(v(1), plate), 3.0) and b.equip(v(1), plate) and is_equal_approx(ap - v(1).ap_for(&"equip"), 3.0),
			"plate over it: 3 - taking the gambeson off is free")
	ap = v(1).ap_for(&"equip")
	ok(b.unequip(v(1), "armor") == plate and is_equal_approx(ap, v(1).ap_for(&"equip")), "plate off: free")
	ok(half_plate.ap_cost() == 2.0 and half_plate.describe().begins_with("Defense: the higher of 10 and level / 2, + dex / 4"), "Half Plate: medium, 2 AP; %s" % half_plate.describe())
	v(1).dexterity = 13
	v(1).armor = half_plate
	ok(v(1).armor_defense() == 10 + v(1).rounded(13 * 0.25), "Half Plate at level 1: 10 + dex / 4 (%d)" % v(1).armor_defense())
	v(1).armor = null
	v(1).pay(v(1).ap_for(&"equip"), &"equip")
	ok(not b.equip(v(1), plate) and v(1).armor == null, "no AP left: it stays off")
	ok(not b.equip(v(3), plate), "not on the other side's turn")


func test_broadsword() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 3)})  # as lucky as each other: no near misses
	var reach := b.skill_range(v(1), strike, v(2))
	var hex_reach := b.skill_range(v(1), hex)
	ok(not b.in_reach(v(1), strike, v(2)), "bare-handed, Strike doesn't reach a diagonal")
	v(1).equip(broadsword)
	ok(is_equal_approx(b.skill_range(v(1), strike, v(2)) - reach, 0.5) and b.in_reach(v(1), strike, v(2)), "a broadsword: +0.5 range for damage skills - a diagonal")
	ok(is_equal_approx(b.skill_range(v(1), hex) - hex_reach, 0.5), "Hex deals damage too")
	ok(v(1).rank(strike) == 2 and v(1).base_rank(strike) == 1, "Strike at its rank + the sword's (II), still I as learned")
	var better: Item = broadsword.duplicate()
	better.rank = 2
	v(1).equip(better)
	ok(is_equal_approx(b.skill_range(v(1), strike, v(2)) - reach, 1.0) and v(1).rank(strike) == 3, "rank 2: +1 range, Strike +2")
	ok("Skill rank: +2 (Strike)" in better.describe(), better.describe())
	v(1).unequip("weapon")


func test_staff() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var hex_reach := b.skill_range(v(1), hex)
	var strike_reach := b.skill_range(v(1), strike)
	v(1).equip(staff)
	ok(is_equal_approx(b.skill_range(v(1), hex) - hex_reach, 1.0) and is_equal_approx(b.skill_range(v(1), strike), strike_reach),
			"a staff: magical skills +rank range, Strike none")
	v(1).unequip("weapon")


func test_dagger() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	v(1).turns_taken = 0
	v(1).refresh()
	var plain := v(1).ap[0].amount
	v(1).turns_taken = 0
	v(1).equip(dagger)
	v(1).refresh()
	ok(is_equal_approx(v(1).ap[0].amount, plain * 1.2), "first turn of the battle: 20%% more general AP (%s)" % v(1).ap[0].amount)
	v(1).refresh()
	ok(is_equal_approx(v(1).ap[0].amount, plain), "then as ever")
	v(1).unequip("weapon")


func test_potions() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	v(1).refresh()
	v(1).equip(health)
	v(1).hp = 1
	var want := v(1).rounded(v(1).max_hp * 0.15) + v(1).mod(&"constitution")
	var ap := v(1).ap_for(&"equip")
	ok(b.use_item(v(1), health) and v(1).hp == 1 + want, "a health potion: 15%% of max HP + con mod (%d)" % want)
	ok(v(1).trinket.name == "Health Potion" and v(1).trinket.empty and not health.empty, "emptied, still worn - this one only")
	ok(not b.use_item(v(1), v(1).trinket), "empty: nothing to drink")
	ok(is_equal_approx(ap - v(1).ap_for(&"equip"), 1.0), "1 AP")
	b.phase = Battle.Phase.OVER
	ok(not v(1).trinket.empty, "it fills again as the battle ends")
	b.phase = Battle.Phase.TURNS
	ok(not b.use_item(v(1), plate), "armor isn't drunk")
	v(1).equip(energy_potion)
	v(1).energy = 0
	b.use_item(v(1), energy_potion)
	ok(v(1).energy == maxi(v(1).rounded(v(1).max_energy * 0.15) + v(1).mod(&"constitution"), 0), "an energy potion: Energy")
	v(1).reserves[mana] = 20
	v(1).equip(mana_potion)
	b.use_item(v(1), mana_potion)
	ok(v(1).store(mana) == maxi(v(1).rounded(3.0) + v(1).mod(&"constitution"), 0), "a mana potion: 15% of 20 Mana + con mod")
	v(1).learned.append(slot(load("res://Skills/sweet_nothings.tres")))
	v(1).charisma = 16
	v(1).equip(sweet_something)
	b.use_item(v(1), sweet_something)
	ok(v(1).store(sn) == 1, "a Sweet Something: a Sweet Nothing")
	ok(sweet_something.describe().begins_with("Trinket\nUsed from its slot: gives back 1 Sweet Nothings; emptied, it fills again as the battle ends"), sweet_something.describe())
