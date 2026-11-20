extends Test

# Equipping (docs/plans/equipping.md): the hotbar is the equipped set, and only what's equipped works
# (Unit.equipped()). Seams: equip and unequip, auto-equip and its Setting, losing a granting skill's
# slots. That every passive is inert unequipped is sweep_test.test_passives. Traits (the `trait` tag,
# docs/plans/w2-traits.md) are the exception to equipping: test_traits. Bonus slots (Cram, docs/plans/w3-cram.md):
# test_cram.

var magic_slot: Skill = load("res://Skills/magic_slot.tres")
var martial_slot: Skill = load("res://Skills/martial_slot.tres")


func test_equip_unequip() -> void:
	var u := v(1)
	var before := u.stat(&"initiative")
	u.learned.append(slot(wary))
	ok(u.get_equipped() == ([strike, null, wary, favour, null] as Array[Skill]), "a passive learned goes on from the bottom, above Favour (the last slot, a clover, holds none)")
	ok(u.stat(&"initiative") > before and wary in u.passives, "equipped, it works")
	u.bar_clear(2)
	ok(not u.equipped(wary) and wary not in u.passives and is_equal_approx(u.stat(&"initiative"), before), "unequipped: learned still, but it does nothing")
	ok(u.bar_place(wary, 1) and u.stat(&"initiative") > before, "equipped again, anywhere it fits")
	u.learned.append(slot(hex))
	var i := u.get_equipped().find(hex)
	ok(i == 2 and hex in u.actives, "an active goes on from the left")
	u.bar_clear(i)
	ok(hex not in u.actives and hex not in u.kit, "off the bar, nobody (the AI included) can use it")
	var echo := Skill.new()
	echo.name = "Echo ??"
	echo.passive = true
	echo.behaviours = [Behaviour.new()] as Array[Behaviour]
	u.learned.append(slot(echo))
	u.get_equipped()
	ok(Battle.reactions_of(u).size() == 1 and u.hooks().size() == 1, "a passive's behaviours react and hook while equipped")
	u.bar_clear(u.hotbar.find(echo))
	ok(Battle.reactions_of(u).is_empty() and u.hooks().is_empty(), "and not once it's off")
	roomy(u, 2)
	var brutal: Skill = load("res://Skills/brutal_strike.tres")
	u.learned.append(slot(brutal))
	ok(u.skill_name(strike) == "Brutal Strike", "a Strike upgrade renames Strike while equipped")
	u.bar_clear(u.hotbar.find(brutal))
	ok(u.skill_name(strike) == "Strike", "and not once it's off the bar: it does nothing then, the name included")


func test_traits() -> void:
	var u := v(1)
	var bar := u.get_equipped()
	var room := u.free_slot()
	var kin: Skill = wary.duplicate()  # a trait of its own: Wary's initiative, tagged trait
	kin.name = "Kin ??"
	kin.tags = [&"trait"] as Array[StringName]
	var before := u.stat(&"initiative")
	u.learned.append(slot(kin))
	ok(u.get_equipped() == bar and kin not in u.hotbar and u.traits() == ([kin] as Array[Skill]), "a trait takes no slot: the bar is as it was, and the unit lists it apart")
	ok(u.equipped(kin) and kin in u.passives and u.stat(&"initiative") > before, "always equipped, and it works")
	ok(not u.bar_place(kin, 1) and kin not in u.hotbar and u.free_slot() == room, "it can't be placed on the bar, and no slot is spent")
	u.bar_clear(1)
	ok(u.equipped(kin), "nor taken off it: it isn't on it")
	u.disable(kin, 3)
	var order := u.disable_order()
	ok(kin not in u.disabled and kin not in order.reduce(func(a, g): return a + g, []), "skill-disabling passes it by: not disabled, not in the order it walks the bar")
	ok(order == [[favour], [strike]], "and what it does reach is just what it did (%s)" % [order])
	var off: Effect = load("res://Effects/traits_suppressed.tres")
	u.afflict(off, 2)
	ok(u.traits_suppressed() and not u.equipped(kin) and kin not in u.passives and is_equal_approx(u.stat(&"initiative"), before), "suppressed: it does nothing, as if unequipped")
	ok(kin in u.traits() and not u.has_tag(&"trait"), "it's still the unit's trait, but carries no tags while it's off")
	u.tick()
	ok(u.traits_suppressed(), "the status lasts its turns")
	u.tick()
	ok(not u.traits_suppressed() and u.equipped(kin) and u.stat(&"initiative") > before, "and it comes back as the status ends")
	var names: Array = []
	for f in DirAccess.get_files_at("res://Skills"):
		var s: Skill = load("res://Skills/" + f) if f.ends_with(".tres") else null
		if s and s.is_trait():
			names.append(f.get_basename())
			ok(s.passive and not s.toggle and not s.fits_bar(), "%s: a trait is an always-on passive off the bar" % f)
	names.sort()
	ok(names == ["alluring", "reckless_abandon", "skill_slot", "starkind"], "the innate skills that are traits: %s" % [names])
	var h := await hud(u)
	var traits: SlotColumns = h.get_node("%Traits")
	ok(traits.get_child_count() == 1 and (traits.get_child(0) as SkillSlot).skill == kin, "the HUD shows it after the hotbar")
	var shown: SkillSlot = traits.get_child(0)
	ok(shown.trait_slot and shown._get_drag_data(Vector2.ZERO) == null and not shown._can_drop_data(Vector2.ZERO, {skill = hex, from = -1}), "a trait slot can't be dragged, dropped on or cleared")
	ok(h.bar.get_child_count() == u.bar_size() and h.bar.get_children().all(func(c: SkillSlot): return c.skill != kin), "and the hotbar proper is unchanged")
	h.free()


# Skill Slot +1 (docs/plans/w3-traits.md): a trait that adds one untyped slot to the hotbar, learned or lent by an
# item. bar_size() is the one read of the hotbar's size (Cram and caster bonus slots will add to it the same way).
func test_skill_slot() -> void:
	var plus: Skill = load("res://Skills/skill_slot.tres")
	var u := v(1)
	var bar := u.bar_size()
	u.learned.append(slot(plus))
	u.get_equipped()
	ok(u.bar_size() == bar + 1 and plus not in u.hotbar and plus in u.traits() and not plus.fits_bar(), "learned: a trait (no slot of its own) that adds one slot to the hotbar (%d -> %d)" % [bar, u.bar_size()])
	ok(u.bar_size() == u.slot_count() + u.granted_slots().size() + (1 if u.lv() % 4 else 0) and u.slot_kind(u.slot_count()) == &"", "the size is one generic read: sure + granted + clover; the new slot is untyped")
	var lent := Item.new()  # an item's version: it lends the trait, so it comes and goes with the item and the trait switch
	lent.name = "Slot Ring ??"
	lent.slot = "trinket"
	lent.skills = [plus] as Array[Skill]
	var w := v(2)
	var wbar := w.bar_size()
	w.trinket = lent
	w.refit()
	ok(w.bar_size() == wbar + 1 and w.equipped(plus) and plus in w.traits(), "lent by an item: the slot is there while it's worn")
	w.afflict(load("res://Effects/traits_suppressed.tres"), 2)
	ok(not w.equipped(plus) and w.bar_size() == wbar, "disabled as equipment is: no longer equipped, so the slot goes with it")
	w.tick()
	w.tick()
	ok(w.bar_size() == wbar + 1, "and returns when it ends")
	w.trinket = null
	w.refit()
	ok(w.bar_size() == wbar, "an item taken off takes the slot")


# Cram (docs/plans/w3-cram.md): a pillar that grants Caster Skill Slots (1 + rank) and converts rank sure slots, from
# the right past its pillars, into caster bonus slots - a non-caster there doesn't work, nor does anything there while
# a pillar skill on the bar is disabled; wear there is x rank (Burnout.penalty()); a Density emblem's rank reaches all
# of it; auto-equip keeps non-casters out of them.
func test_cram() -> void:
	var cram: Skill = load("res://Skills/cram.tres")
	var sola: Skill = load("res://Skills/sola.tres")
	var kick: Skill = load("res://Skills/kick.tres")
	var strike: Skill = load("res://Skills/strike.tres")
	var powerful: Skill = load("res://Skills/powerful.tres")
	var u := v(1)
	u.extra_slots += 3
	u._arrange()
	var grants := u.granted_slots().size()
	u.learned.append(slot(cram, 2))
	u.get_equipped()
	var sure := u.slot_count()
	var c := u.hotbar.find(cram)
	ok(c >= sure - 2 and c < sure and u.granted_slots().size() - grants == 3 and u.granted_slots().count(&"magical") >= 3, "a pillar at the bottom of the sure slots; Caster Skill Slot +1 + rank: 3 caster slots at rank II")
	var bonus := u.bonus_slots()
	ok(bonus.size() == 2 and bonus.get(c - 1) == [&"magical", 2] and bonus.has(c - 2), "rank sure slots to its left become caster bonus slots")
	u.bar_clear(c - 1)
	for i in u.slot_count():  # only bonus slots left free
		if not u.hotbar[i] and not bonus.has(i):
			u.hotbar[i] = Skill.new()
	u.learned.append(slot(kick))
	u.get_equipped()
	ok(u.hotbar.find(kick) >= u.slot_count() and not u.hotbar[c - 1], "auto-equip leaves a non-caster out of a bonus slot")
	for i in u.slot_count():
		if u.hotbar[i] and u.hotbar[i].resource_path == "":
			u.hotbar[i] = null
	ok(u.bar_place(strike, c - 1) and u.hotbar[c - 1] == strike and not u.equipped(strike) and strike not in u.actives and u.bonus_why(c - 1) != "", "a non-caster can be slotted there, but doesn't work")
	u.learned.append(slot(sola))
	u.get_equipped()
	ok(u.bar_place(sola, c - 1) and u.equipped(sola) and sola in u.actives, "a caster skill works there")
	ok(is_equal_approx(u.slot_penalty(sola), 2.0) and is_equal_approx(Burnout.penalty(u, sola), 2.5) and is_equal_approx(Burnout.penalty(u, kick), 1.0), "its Burnout penalty x rank there (1.25 x 2); elsewhere untouched")
	u.learned.append(slot(powerful))
	u.get_equipped()
	u.disabled[powerful] = 1  # any pillar skill on the bar, not only Cram (disable() takes them all together anyway)
	ok(powerful in u.hotbar and not u.equipped(sola) and sola not in u.actives, "a disabled pillar skill disables every bonus slot")
	u.disabled.erase(powerful)
	u.disable(cram, 1)
	ok(cram in u.disabled and powerful in u.disabled and not u.equipped(sola), "Cram disabled: so is every pillar, and the bonus slots")
	u.tick()
	ok(u.equipped(sola), "back as it ends")
	var badge := Item.new()  # a Density emblem: its rank reaches the slots granted, the slots converted and the penalty alike
	badge.slot = "trinket"
	badge.emblem = &"rho_up"
	badge.scope = &"insignia"
	badge.rank = 3
	var was := u.granted_slots().size()
	u.equip(badge)
	var r := u.mods(cram).irank(2, &"rank_impact")
	ok(r > 2 and u.bonus_slots().size() == mini(r, c - 1) and is_equal_approx(u.slot_penalty(sola), float(r)) and u.granted_slots().size() - was == r - 2, "under Density (rank %d): more slots granted and converted, the penalty x %d" % [r, r])


func test_auto_equip() -> void:
	var u := v(1)
	Unit.auto_equip = false
	u.learned.append(slot(hex))
	ok(hex not in u.hotbar and u.rank(hex) == 1 and hex not in u.actives, "auto-equip off: learned, not equipped")
	u.extra_slots += 1
	u._arrange()
	ok(hex not in u.hotbar, "nor when slots appear")
	Unit.auto_equip = true
	u.extra_slots += 1
	u._arrange()
	ok(hex in u.hotbar, "on: new slots fill with what's left off")
	var h := await hud(u)
	var box: CheckButton = h.get_node("%AutoEquip")
	ok(box.button_pressed, "the Setting is on by default")
	box.button_pressed = false
	ok(not Unit.auto_equip and Prefs.get_pref("auto_equip", true) == false, "switched off, it's saved")
	var wren := b.starter({faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Wren"})
	b.get_node("Units").add_child(wren)
	h.skills.open(wren, "Wren", false)
	var view := h.skills.view()
	var learned: Array = view.skills().filter(func(s: Skill): return wren.base_rank(s) > 0)
	var unknown: Array = view.skills().filter(func(s: Skill): return wren.base_rank(s) == 0)
	var data: Variant = view._get_drag_data(view.spot(learned[0]))
	ok(data is Dictionary and data.skill == learned[0] and data.from == -1, "the skills screen: a skill it has drags onto the hotbar (%s)" % learned[0].name)
	ok(unknown.is_empty() or view._get_drag_data(view.spot(unknown[0])) == null, "one it hasn't learned doesn't")
	await tree.process_frame
	ok(not h.skills.visible, "while it's dragged the skills screen steps aside, baring the hotbar")
	h.skills.notification(Control.NOTIFICATION_DRAG_END)
	ok(h.skills.visible, "and comes back as the drag ends")
	h.free()


func test_losing_slots() -> void:
	var u := roomy(v(1), 2)  # 6 sure slots: room for the granting skills themselves
	var lost: Array = []
	u.lost_skills.connect(func(_u: Unit, s: Array[Skill]): lost.append_array(s))
	var other: Skill = magic_slot.duplicate()  # a second Magic slot skill: each one's slot is its own
	other.name = "Magic Slot ??"
	u.learned.append(slot(magic_slot))
	u.learned.append(slot(other))
	u.learned.append(slot(martial_slot))
	var kinds := u.slot_kinds()
	ok(kinds.slice(6) == ([&"magical", &"magical", &"martial", &"clover"] as Array[StringName]), "three granting skills, three typed slots (%s)" % [kinds])
	u.learned.append(slot(hex))
	ok(u.bar_place(hex, 7) and u.hotbar[7] == hex, "Hex in the second Magic slot")
	u.bar_clear(u.hotbar.find(magic_slot))
	ok(u.slot_kinds().slice(6) == ([&"magical", &"martial", &"clover"] as Array[StringName]) and u.hotbar[6] == hex, "the first Magic slot goes; the second keeps Hex")
	u.bar_clear(u.hotbar.find(martial_slot))
	u.bar_clear(u.hotbar.find(other))
	ok(u.bar_size() == 7 and hex not in u.hotbar and not u.equipped(hex), "the last Magic slot goes, taking Hex off the bar")
	ok(hex in lost and magic_slot in lost and other in lost, "what came off is announced (lost_skills: Battle ends a channel on one)")


# A copy of Strike, tagged `tag` (a rarity: Skill.slots_taken()), for the multi-slot tests.
func fat(name: String, tag := &"") -> Skill:
	var s: Skill = strike.duplicate()
	s.name = name + " ??"
	if tag != &"":
		s.tags = s.tags + ([tag] as Array[StringName])
	return s


# Skills that take several hotbar slots (docs/plans/w6-slots.md): the price (a rarity tag, SlotCost over it, a pillar or
# a trait never), where it goes (a run of slots of one kind, each fit for it), what it takes with it and what takes it
# (displacing, clearing from any of its slots, the sort when slots come and go), that it works while all its slots do
# (typed and bonus slots), is disabled whole by one slot's worth, and rides a save through its first slot alone.
func test_multi_slot() -> void:
	var cost := func(tag: StringName) -> int: return fat("T", tag).slots_taken()
	ok([&"", &"rare", &"epic", &"very_rare", &"legendary", &"mythic"].map(cost) == [1, 2, 3, 3, 4, 5], "a rarity tag sets what a skill takes: rare 2, epic and very rare 3, legendary 4, mythic 5, none 1")
	var two := fat("Two")
	two.behaviours = [load("res://Behaviours/slot_cost.gd").new()] as Array[Behaviour]
	two.behaviours[0].slots = 2
	var cheap := fat("Cheap", &"mythic")
	cheap.behaviours = [load("res://Behaviours/slot_cost.gd").new()] as Array[Behaviour]
	var pillar := fat("Pillar", &"mythic")
	pillar.tags = pillar.tags + ([&"pillar"] as Array[StringName])
	var both := fat("Both", &"rare")
	both.tags = both.tags + ([&"legendary"] as Array[StringName])
	ok(two.slots_taken() == 2 and cheap.slots_taken() == 1 and pillar.slots_taken() == 1 and both.slots_taken() == 4, "SlotCost stands over the rarity either way; a pillar always takes 1; two rarities, the dearer")
	ok("Takes 2 hotbar slots" in two.markup(1) and "Takes 4 hotbar slots" in both.markup(1) and "hotbar slots" not in strike.markup(1), "the description says the cost, from a rarity or from SlotCost")
	var u := roomy(v(1), 6)
	var rare := fat("Rare", &"rare")
	var epic := fat("Epic", &"epic")
	var small := fat("Small")
	for s in [rare, epic, small, two]:
		u.learned.append(slot(s))
	u.get_equipped()  # they go on by themselves (auto-equip): the test arranges its own bar
	for i in u.bar_size():
		u.bar_clear(i)
	var lost: Array = []
	u.lost_skills.connect(func(_u: Unit, s: Array[Skill]): lost.append_array(s))
	u.hotbar[1] = small  # a one-slot gap at 0, a two-slot gap 2-3, a long one from 5
	u.hotbar[4] = favour
	ok(u.free_slot(rare) == 2 and u.free_slot(epic) == 5 and u.free_slot(small) == 0 and u.slot_cost(epic) == 3, "it goes where its run is free: the first gap it fits")
	ok(u.bar_place(rare, 2) and u.hotbar[2] == rare and u.hotbar[3] == null and u.covered() == {3: 2} and u.anchor(3) == 2 and u.skill_at(3) == rare, "placed in its first slot, it covers the next")
	ok(not u.slot_free(3) and u.free_slot(small) == 0 and u.equipped(rare) and rare in u.actives and u.span(rare) == ([2, 3] as Array[int]), "the covered slot is nobody's to fill; it works")
	ok(not u.bar_place(rare, u.slot_count() - 1) and u.slot_kind(u.slot_count()) == &"clover" and u.hotbar[2] == rare, "no run, no place: not over the edge into a slot of another kind (here the clover slot)")
	var bar := u.get_equipped()
	ok(bar.slice(0, 5) == ([null, small, rare, null, favour] as Array[Skill]) and bar.slice(5).all(func(x): return x == null), "a save keeps the first slot alone: skill ids, none repeated")
	u.set_equipped(bar)
	ok(u.get_equipped() == bar and u.equipped(rare), "and set_equipped() puts it back whole")
	ok(u.bar_place(small, 3) and u.hotbar[3] == small and u.span(rare) == ([1, 2] as Array[int]), "dropped on a slot another's run covers, a skill from the bar takes the run's place; the run takes the slots it left")
	u.bar_clear(3)
	ok(u.bar_place(small, 2) and rare not in u.hotbar and u.slot_free(1) and rare in lost, "one from off the bar displaces a run whole, announced")
	u.bar_place(rare, 0)
	ok(u.bar_place(epic, 1) and rare not in u.hotbar and small not in u.hotbar and u.span(epic) == ([1, 2, 3] as Array[int]), "a run drops everyone with a slot in it, those it only half covers too")
	ok(u.bar_place(rare, 2) and epic not in u.hotbar and u.span(rare) == ([2, 3] as Array[int]), "...and a shorter one over it, the same")
	u.bar_place(epic, 5)
	u.bar_place(small, 8)
	ok(u.bar_place(epic, 6) and u.span(epic) == ([6, 7, 8] as Array[int]) and u.hotbar[5] == small and rare in u.hotbar, "moved on the bar, it leaves its old slots: the skill in the way takes the first")
	u.bar_clear(7)
	ok(epic not in u.hotbar and u.slot_free(6) and u.slot_free(8), "cleared from any slot it spans, it goes whole")
	u.bar_clear(5)
	u.bar_place(epic, 5)
	var sure := u.slot_count()
	u.extra_slots += 1
	u._arrange()
	ok(u.hotbar[2] == rare and u.hotbar[5] == epic and u.span(epic) == ([5, 6, 7] as Array[int]) and u.slot_count() == sure + 1, "a slot more: the runs hold")
	u.extra_slots -= 1
	u._arrange()
	ok(u.hotbar[5] == epic and u.span(epic) == ([5, 6, 7] as Array[int]) and u.slot_count() == sure, "a slot fewer, the same")
	u.extra_slots -= 3  # the bar shrinks under it: a run cut short comes off the bar, not left half a skill
	u._arrange()
	ok(u.slot_count() == sure - 3 and epic not in u.hotbar and epic in lost and rare in u.hotbar, "a run the bar no longer holds comes off whole, announced")
	# one disabling slot takes it whole: one entry in the order, whatever its slots
	u.extra_slots += 3
	u._arrange()
	u.bar_place(epic, 5)
	var order := u.disable_order()
	ok(order.reduce(func(n, g): return n + g.count(epic), 0) == 1 and order.size() == u.hotbar.filter(func(s): return s != null).size(), "disabling: a skill spanning several slots is one slot's worth in the order")
	u.disable(epic, 2)
	ok(epic in u.disabled and epic not in u.actives, "and it is disabled whole")
	# the HUD: a covered slot says whose it is, and clears the skill whole
	var h := await hud(u)
	u.bar_place(rare, 2)
	h._refresh_bar()
	var covered_slot: SkillSlot = h.bar.get_child(3)
	ok(covered_slot.skill == null and covered_slot.cover == rare and (h.bar.get_child(2) as SkillSlot).skill == rare, "the HUD draws the slot after a two-slot skill as its continuation")
	covered_slot.cleared.emit(3)
	ok(rare not in u.hotbar, "unequipping from the covered slot takes the whole skill")
	h.free()
	# an item's free link makes it slotless whatever its rarity; an optional one charges its price
	var calm: Skill = wary.duplicate()
	calm.name = "Calm ??"
	calm.tags = calm.tags + ([&"epic"] as Array[StringName])
	var ring := Item.new()
	ring.slot = "trinket"
	ring.skills = [calm] as Array[Skill]
	var w := roomy(v(2), 3)
	w.equip(ring)
	ok(w.slot_cost(calm) == 0 and calm not in w.hotbar and w.equipped(calm), "a rare skill lent free takes no slot")
	ring.optional = [calm] as Array[Skill]
	w.refit()
	ok(w.slot_cost(calm) == 3 and calm not in w.hotbar and w.bar_place(calm, w.free_slot(calm)) and w.span(calm).size() == 3 and w.equipped(calm), "lent optional it takes its three, once its wearer slots it")
	w.unequip("trinket")
	# typed and bonus slots (Cram): every slot of the run must carry the type
	var cram: Skill = load("res://Skills/cram.tres")
	w.learned.append(slot(cram, 2))
	w.get_equipped()
	var c := w.hotbar.find(cram)
	var g := w.slot_count()
	var mage := fat("Mage", &"rare")
	mage.tags = mage.tags + ([&"magical"] as Array[StringName])
	var brute := fat("Brute", &"rare")
	brute.tags = brute.tags + ([&"martial"] as Array[StringName])
	w.learned.append(slot(mage))
	w.learned.append(slot(brute))
	w.get_equipped()
	for i in w.slot_count():
		if i != c and w.hotbar[i] and w.hotbar[i] != cram:
			w.bar_clear(i)
	ok(w.slot_kind(g) == &"magical" and w.bar_place(mage, g) and w.span(mage) == ([g, g + 1] as Array[int]) and not w.bar_place(brute, g + 1), "a typed slot holds only its type, each slot of a run too")
	w.bar_clear(g)
	ok(w.bonus_slots().keys() == [c - 1, c - 2] and w.bar_place(brute, c - 2) and w.span(brute) == ([c - 2, c - 1] as Array[int]) and not w.equipped(brute) and w.bonus_why(c - 1) != "", "a bonus slot holds anything, but a skill spanning it works only if it carries the type")
	ok(w.bar_place(mage, c - 2) and w.equipped(mage) and is_equal_approx(w.slot_penalty(mage), 2.0) and w.skill_at(c - 1) == mage, "a caster skill works across two, its wear x the bonus rank")
	ok(w.bar_place(mage, c - 3) and w.equipped(mage) and w.bar_place(brute, c - 3) and not w.equipped(brute), "across one bonus slot and one plain: still every slot must carry the type")
	w.bar_clear(c - 3)
	for i in w.slot_count():
		if i != c and i != c - 3 and i != c - 2 and not w.hotbar[i]:
			w.hotbar[i] = Skill.new()  # fillers: only c-3 and c-2 stay free of the sure slots
	ok(w.free_slot(brute) == -1 and w.free_slot(mage) == c - 3 and w.slot_cost(mage) == 2, "auto-placement leaves a skill out of a run a bonus slot would idle")
	var badge := Item.new()  # a Density emblem doubles what slots rank grants, not what a skill takes
	badge.slot = "trinket"
	badge.emblem = &"rho_up"
	badge.scope = &"insignia"
	badge.rank = 3
	w.equip(badge)
	ok(w.slot_cost(mage) == 2 and mage.slots_taken() == 2, "Density leaves a skill's price alone")
	u.free()


# The hotbar slot shows the on/off dot for a toggle only; an always-on passive just works.
func test_slot_switch_dot() -> void:
	var sl := SkillSlot.new()
	sl.skill = load("res://Skills/stamina.tres")
	ok(sl.shows_switch(), "a toggle shows its dot")
	sl.skill = wary
	ok(not sl.shows_switch(), "an always-on passive doesn't")
	sl.skill = null
	ok(not sl.shows_switch(), "an empty slot doesn't")
	sl.skill = wary
	sl.usable = false  # its unit can't act now (another's turn): an always-on passive is still just working
	sl.on = false
	ok(is_equal_approx(sl.brightness(), 1.0), "an always-on passive is drawn the same unusable or not: nothing says on or off")
	sl.off = 2
	ok(sl.brightness() < 0.5, "only a disabling dims it")
	sl.off = 0
	sl.skill = load("res://Skills/stamina.tres")
	ok(sl.brightness() < 1.0 and not is_equal_approx(sl.brightness(), 1.0), "a toggle that's off is dimmed, as an unusable active is")
	sl.free()
