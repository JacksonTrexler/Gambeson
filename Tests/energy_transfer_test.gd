extends Test

# Energy Transfer (Skills/energy_transfer.tres, Behaviours/energy_transfer.gd): a low-damage energy bolt
# (1d4, 1d6 from III, no mod) tagged siphon, on the general Caster tree. Its damage comes off the foe's
# resources, never its HP; the caster gets what it drained as Energy (Power, if it's powered) up to its
# max, and what doesn't fit - a full bar, or none - as Overcharge at rank x 20%, for rank of its turns.
# Also Powerful's grant routing: every effect giving Energy goes through Unit.grant_energy().

var transfer: Skill = load("res://Skills/energy_transfer.tres")
var powerful: Skill = load("res://Skills/powerful.tres")


# v(1) transferring at rank r, sure to hit, at v(3) two tiles off with 30 Energy to take.
func caster(r := 1) -> void:
	v(1).learned.append(slot(transfer, r))
	v(1).intelligence = 40
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).refresh()
	v(3).max_energy = 30
	v(3).energy = 30


func test_energy_transfer() -> void:
	caster()
	v(1).max_energy = 20
	v(1).energy = 10
	var hp := v(3).hp
	ok(b.cast(v(1), transfer, v(3)), "it lands")
	var d := 30 - v(3).energy
	ok(d >= 1 and d <= 4 and v(3).hp == hp, "1d4 off the foe's Energy (%d), none off its HP" % d)
	ok(v(1).energy == 10 - 1 + d and v(1).overcharge == 0, "the caster: its cost (1) paid, all %d back as Energy" % d)
	ok(transfer.describe(1).contains("Overcharge") and transfer.describe(2).contains("40%"), "it says what it does: %s" % Glossary.plain(transfer.describe(2)))


func test_full() -> void:
	caster(5)
	v(1).energy = v(1).max_energy
	ok(b.cast(v(1), transfer, v(3)), "it lands")
	var d := 30 - v(3).energy
	ok(d >= 1 and d <= 6, "1d6 at V (%d)" % d)
	ok(v(1).energy == v(1).max_energy, "its cost made room for 1")
	ok(v(1).overcharge == d - 1, "the rest at V x 20%% = 100%% as Overcharge (%d of %d)" % [v(1).overcharge, d - 1] if d > 1 else "nothing past it")
	if d > 1:
		var a: Unit.Applied = v(1).timed[Unit.OVERCHARGE]
		ok(a.total == 5 and a.turns == 6, "for 5 turns, its own one not counting")


func test_no_bar() -> void:
	caster(5)
	v(1).max_energy = 0
	v(1).add_overcharge(1, 9)
	ok(v(1).can_afford(transfer), "no Energy at all: Overcharge pays")
	ok(b.cast(v(1), transfer, v(3)), "it lands")
	var d := 30 - v(3).energy
	ok(v(1).energy == 0 and v(1).overcharge == d, "no bar: all %d, at V, as Overcharge (%d)" % [d, v(1).overcharge])


func test_low_rank() -> void:
	caster(1)
	v(1).energy = v(1).max_energy
	v(3).energy = 0
	ok(b.cast(v(1), transfer, v(3)) and v(1).overcharge == 0, "nothing to drain: nothing back")
	v(3).energy = 30
	v(1).refresh()
	v(1).energy = v(1).max_energy
	b.cast(v(1), transfer, v(3))
	var d := 30 - v(3).energy
	ok(v(1).overcharge == floori((d - 1) * 0.2), "at I, 20%% of what's past full, rounded down: %d of %d" % [v(1).overcharge, d - 1])


func test_powerful() -> void:
	caster()
	v(1).learned.append(slot(powerful))
	ok(v(1).powered(), "Powerful: its Energy is Power")
	v(1).energy = 3
	ok(b.cast(v(1), transfer, v(3)), "it lands")
	var d := 30 - v(3).energy
	ok(v(1).energy == mini(3 - 1 + d, v(1).max_energy), "what it drains arrives as Power (%d)" % v(1).energy)
	ok(powerful.describe(1).contains("grants Power"), "Powerful says so: %s" % Glossary.plain(powerful.describe(1)))


func test_grants() -> void:
	caster()
	v(1).afflict(effect("powered", 1.0), 99)
	v(1).energy = 2
	ok(v(1).grant_energy(3) == 3 and v(1).energy == 5, "a grant on a powered unit: Power")
	ok(v(1).grant_energy(99) == v(1).max_energy - 5 and v(1).energy == v(1).max_energy, "up to its max, returning what it got")
	v(1).energy = 0
	b.end_turn()
	ok(v(1).energy == 0, "regen isn't a grant: Power never comes back on its own")
	var potion: Item = load("res://Items/energy_potion.tres")
	ok(b.restore(v(1), potion) > 0 and v(1).energy > 0, "an Energy Potion grants it Power")


func test_who() -> void:
	var caster_tree: SkillTab = load("res://Trees/general_caster.tres")
	ok(caster_tree.offers(transfer) and caster_tree.tier_of(transfer) == 2, "on the general Caster tree, tier 2")
	ok(transfer.tagged(&"siphon") and transfer.tagged(&"energy") and transfer.tagged(&"magical"), "energy, siphon, magical")
	for r in ["mage", "wizard", "druid"]:
		var role: Role = load("res://Roles/%s.tres" % r)
		ok(&"magical" in role.general, "%s, a Mana user, reaches it" % r)
