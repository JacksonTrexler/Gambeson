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
	ok(names == ["alluring", "armor", "reckless_abandon", "skill_slot", "starkind"], "the innate skills that are traits: %s" % [names])
	var h := await hud(u)
	var traits: VBoxContainer = h.get_node("%Traits")
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
