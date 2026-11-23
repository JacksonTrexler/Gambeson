extends Test

# Units spend their skill points themselves (Unit.auto_spec(), w21-autospec): an NPC by its bio's preferences (Bio.prefers)
# and spec (exploratory, training, remedial), else its class tree cheapest first; a player's unit only by the skills
# screen's held "Spec Automatically", on Hard, or out of the player's hands (Disturbed: refunded as it's back).

const FIGHTER := "res://Roles/fighter.tres"


# A level 6 Fighter NPC holding its class's first option at rank I, `pts` points, its bio set after: what auto_spec() buys.
func npc(prefers: Array[StringName], spec: StringName, pts := 4) -> Unit:
	var u: Unit = b.from_role(lancin, load(FIGHTER), "npc")
	u.level = 6
	b.get_node("Units").add_child(u)
	roomy(u, 8)
	u.skill_points = 1
	u.unlock(_home(u)[0])
	u.bio = Bio.new()
	u.bio.prefers = prefers
	u.bio.spec = spec
	u.skill_points = pts
	return u


func _home(u: Unit) -> Array:
	return u.options()[&"class"].filter(func(s: Skill): return s in u.role.offered())


# The table: each spec, and a preference, read in what it buys first and where its points go.
func test_modes() -> void:
	var general := func(u: Unit) -> Array:  # a general skill it could learn now, and a tag of it none of its class's options carry
		var home := u.spec_options().filter(func(c: Array): return c[0] in u.role.offered())
		for s: Skill in u.options()[&"class"]:
			if s not in u.role.offered():
				for t in s.tags:
					if not home.any(func(c: Array): return c[0].fits(t, u)):
						return [s, t]
		return []
	# none: class tree only, cheapest first (unlocks before any raise)
	var u := npc([], &"")
	var had := u.purchases.size()
	ok(u.auto_spec() == 4 and u.skill_points == 0, "plain: spends all 4")
	var bought := u.purchases.slice(had)
	ok(bought.all(func(p: Array): return p[0] in u.role.offered()), "plain: its class tree only (%s)" % [bought.map(func(p: Array): return p[0].name)])
	ok(bought.all(func(p: Array): return p[1] == 1), "plain: cheapest first - four unlocks, no rank-up")
	# exploratory: new skills
	u = npc([], &"exploratory")
	had = u.purchases.size()
	u.auto_spec()
	ok(u.purchases.slice(had).all(func(p: Array): return p[1] == 1 and u.own_rank(p[0]) == 1), "exploratory: four new skills")
	# training: ranks in what it has
	u = npc([], &"training")
	var first: Skill = u.purchases[-1][0]
	had = u.purchases.size()
	u.auto_spec()
	ok(u.own_rank(first) == 2 and u.purchases[had][0] == first, "training: its skill to II first (%s %d)" % [first.name, u.own_rank(first)])
	# remedial: what its make-up holds least of
	u = npc([], &"remedial")
	var thin := u._thinnest()
	had = u.purchases.size()
	u.auto_spec()
	var p0: Skill = u.purchases[had][0]
	ok(u._make_up(p0).any(func(x: StringName): return x in thin), "remedial: first fills %s (%s: %s)" % [thin, p0.name, u._make_up(p0)])
	# a preference: a skill outside its class tree that meets it, before any of its own
	u = npc([], &"")
	var g: Array = general.call(u)
	if g:
		u.bio.prefers = [g[1]]
		had = u.purchases.size()
		u.auto_spec()
		ok(u.purchases[had][0].fits(g[1], u) and u.purchases[had][0] not in u.role.offered(), "prefers %s: a general skill first (%s)" % [g[1], u.purchases[had][0].name])
	else:
		ok(false, "a Fighter at level 6 should have a general skill on offer")
	# kinds and postures as words
	ok(strike.fits(&"active") and not strike.fits(&"passive") and strike.fits(&"offensive", u), "Strike: active, offensive")
	# an NPC levelling spends its point at once; a player's unit doesn't
	u = npc([], &"")
	u.level_up()
	ok(u.skill_points == 0, "an NPC's level's point spent at once")
	var pl: Unit = b.from_role(lancin, load(FIGHTER), "pl")
	pl.player_unit = true
	pl.bio = Bio.new()  # a bio of its own: still the player's to spend
	b.get_node("Units").add_child(pl)
	pl.level_up()
	ok(pl.skill_points == 1 and pl.purchases.is_empty(), "a player's unit keeps its point, bio or not")


# Out of the player's hands (Disturbed) a player's unit spends what a level brings; as its side's turn comes round with
# it back, every point comes back and its skills are as they were. On Hard it spends, for good.
func test_refund() -> void:
	var u: Unit = b.from_role(lancin, load(FIGHTER), "pl")
	u.player_unit = true
	u.level = 3
	b.get_node("Units").add_child(u)
	b.move(u, Vector2i(6, 6))
	roomy(u, 8)
	u.skill_points = 1
	u.unlock(_home(u)[0])
	var ranks := u.learned.map(func(x: Slot): return [x.skill, x.rank, x.points])
	var bar := u.hotbar.duplicate()
	var dis: Effect = load("res://Effects/disturbed.tres")
	u.afflict(dis, 5)
	ok(u.enforced() and u.spec_due(), "Disturbed: out of the player's hands")
	u.level_up()
	u.level_up()
	ok(u.skill_points == 0 and u.auto_spent == 2 and u.learned.size() > ranks.size(), "two levels' points spent for it (%d purchases)" % u.auto_spent)
	b.turn = nemes
	b.turn = lancin
	ok(u.auto_spent == 2 and u.skill_points == 0, "still Disturbed as its turn comes: kept")
	u.timed.erase(dis)
	b.turn = nemes
	b.turn = lancin
	ok(u.auto_spent == 0 and u.skill_points == 2, "back in hand at its side's turn: both points back")
	ok(u.learned.map(func(x: Slot): return [x.skill, x.rank, x.points]) == ranks and u.hotbar.filter(func(s): return s) == bar.filter(func(s): return s),
		"its skills and bar as they were (its levels kept: a slot more)")
	Unit.hard = true
	u.level_up()
	Unit.hard = false
	ok(u.skill_points == 0 and u.auto_spent == 0, "Hard: a player's unit spends its points itself, for good")


# Spec Automatically: a long press on the skills screen spends the unit's points; a click does nothing.
func test_button() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await hud(v(1))
	v(1).player_unit = true
	v(1).bio = Bio.new()
	v(1).bio.prefers = [&"active", &"passive", &"toggle"]  # a Villager's class has nothing to buy: its bio leans past it
	v(1).skill_points = 2
	h.toggle_skills()
	var btn: Button = h.skills.auto_button
	ok(btn.visible and btn.text == "Spec Automatically" and not btn.disabled, "the button, on the player's unit with points")
	btn.button_down.emit()
	btn.button_up.emit()
	ok(v(1).skill_points == 2, "a click spends nothing")
	btn.button_down.emit()
	h.skills._held_at -= SkillTree.HOLD_MS
	btn.button_up.emit()
	ok(v(1).skill_points < 2 and btn.disabled == (v(1).skill_points == 0), "held: spent (%d left)" % v(1).skill_points)
	ok(h.get_node("%Hard").text == "Hard", "the Hard toggle in Settings")
	h.free()
