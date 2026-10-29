extends Test

# The HUD driving a battle: selecting, hover planning and moving, number keys arming skills and
# clicks landing them, toggles, orders to allies in range, the party, the spellbook and hotbar
# drops, allies acting on their own as the turn ends, and a whole battle played through the HUD.

var arcanist: Skill = load("res://Skills/arcanist.tres")


func unit(n: String) -> Unit:
	return b.get_node("Units/" + n)


# A HUD on the test battle, led by `leader`, that leaves other sides alone; ready once a frame passes.
func start(leader: Unit) -> HUD:
	b.player = leader
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	return h


func key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.pressed = true
	return e


func test_select_and_move() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	ok(h.selected == v(1) and h.my_turn(), "the leader is selected as its turn starts")
	h.hover_cell(Vector2i(3, 2))
	ok(h.plan.path.back() == Vector2i(3, 2), "hovering a tile plans the walk there")
	ok("Walk here: 3 of 5" in h.tip_label.text and h.tip.visible, "the tip gives its cost (bramble 1, leaving it 1 + 1)")
	h._refresh()
	ok(Vector2i(3, 2) in h.reach and Vector2i(8, 7) not in h.reach, "reachable tiles are known")
	h.click(Vector2i(3, 2))
	ok(v(1).cell == Vector2i(3, 2) and v(1) in h.command.ordered, "clicking walks there")
	h.click(Vector2i(8, 2), false, true)
	ok(h.selected == v(3) and v(1).cell == Vector2i(3, 2), "shift-clicking a foe selects it rather than attacking")
	h.click(Vector2i(8, 3))
	ok(v(3).cell == Vector2i(8, 2) and h.selected == null, "an enemy takes no orders; clicking away lets go")
	h.free()


func test_keys_and_targets() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var h := await start(v(1))
	h._unhandled_input(key(KEY_1))
	ok(h.armed == strike, "1 arms Strike")
	ok(h.targets().size() == 1 and h.targets()[0] == v(3), "the enemy in reach is its one target")
	h.hover_cell(Vector2i(5, 3))
	ok("Click to use: 3 AP · 100% to hit · 2 damage" in h.tip_label.text, "hovering it forecasts the cost, chance to hit and damage")
	h.click(Vector2i(5, 3))
	ok(v(3).hp == 8 and h.armed == null and v(1) in h.command.ordered, "clicking it strikes (1 + str mod 1)")
	h._unhandled_input(key(KEY_1))
	h.click(Vector2i(6, 6))
	ok(h.armed == strike and h._note.begins_with("Pick a unit"), "an empty tile isn't a target without Ctrl")
	h._unhandled_input(key(KEY_1))
	ok(h.armed == null, "the same key again disarms")
	h._unhandled_input(key(KEY_1))
	h._unhandled_input(key(KEY_ESCAPE))
	ok(h.armed == null and h.selected == v(1), "Esc disarms first")
	h._unhandled_input(key(KEY_ESCAPE))
	ok(h.selected == null, "then lets go")
	h.free()


func test_toggle_from_bar() -> void:
	var icor := unit("Icor")
	stage(nemes, {icor: Vector2i(7, 3), v(1): Vector2i(1, 2)})
	var h := await start(icor)
	h._unhandled_input(key(KEY_2))
	ok(not icor.is_on(arcanist) and h.armed == null, "2 switches Arcanist Perspective off")
	h.use_slot(1)
	ok(icor.is_on(arcanist), "and on again")
	h.free()


func test_orders_in_range() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 3), al: Vector2i(5, 5), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h.click(Vector2i(2, 3))
	h.click(Vector2i(3, 3))
	ok(v(2).cell == Vector2i(3, 3), "an ally a step from the leader takes orders")
	h.click(Vector2i(5, 5))
	h.click(Vector2i(5, 4))
	ok(al.cell == Vector2i(5, 5) and h._note.begins_with("Too far"), "one further off doesn't, and the hint says why")
	h.free()


func test_party() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h.select(v(2))
	h._unhandled_input(key(KEY_P))
	ok(v(2) in h.command.party, "P invites the selected ally")
	h.select(v(1))
	h.click(Vector2i(1, 0))
	h.select(v(2))
	ok(h._orders(v(2)), "2 tiles from the leader, a party member still takes orders")
	h._unhandled_input(key(KEY_P))
	ok(v(2) not in h.command.party and not h._orders(v(2)), "P again lets it go; now it's too far")
	h.free()


func test_spellbook_and_bar() -> void:
	var icor := unit("Icor")
	stage(nemes, {icor: Vector2i(7, 3), v(1): Vector2i(1, 2)})
	var h := await start(icor)
	h._unhandled_input(key(KEY_B))
	ok(h.spellbook.visible and h.spellbook.unit == icor, "B opens the selected unit's spellbook")
	var actives := h.spellbook.actives.get_children()
	var passives := h.spellbook.passives.get_children()
	ok(actives.size() == 1 and actives[0].skill == hex and passives.size() == 2 and passives[0].skill == arcanist and passives[1].skill.name == "Mana",
			"Hex under Active; Arcanist Perspective III, then the Wizard's Mana I, under Passive")
	ok(actives[0].get_child(0).get_child(0).text == "III", "ranks in numerals")
	ok(passives[0].draggable and not passives[1].draggable, "a toggled passive can go on the bar")
	var slot: SkillSlot = h.bar.get_child(3)
	var data := {skill = arcanist, from = -1}
	ok(slot._can_drop_data(Vector2.ZERO, data), "a hotbar slot takes it")
	slot._drop_data(Vector2.ZERO, data)
	ok(icor.hotbar[3] == arcanist and icor.hotbar[1] == null, "dropped in slot 4, it leaves slot 2")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	(h.bar.get_child(0) as SkillSlot)._on_gui_input(right)
	ok(icor.hotbar[0] == null, "right-clicking a slot empties it")
	h._unhandled_input(key(KEY_B))
	ok(not h.spellbook.visible, "B closes it")
	h.select(v(1))
	h._unhandled_input(key(KEY_B))
	ok(h.spellbook.unit == icor, "with an enemy selected, B opens your own unit's")
	h.free()
	var h2: HUD = await start(v(1))
	h2._unhandled_input(key(KEY_B))
	ok(not (h2.spellbook.passives.get_child(0) as SkillEntry).draggable, "a passive without a toggle can't go on the bar")
	ok(not (h2.bar.get_child(0) as SkillSlot)._can_drop_data(Vector2.ZERO, {skill = favour, from = -1}), "nor be dropped there")
	h2.free()


func test_end_turn() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 3), al: Vector2i(2, 6), v(3): Vector2i(5, 6), v(4): Vector2i(9, 0)})
	var h := await start(v(1))
	h.select(v(2))
	h._unhandled_input(key(KEY_H))
	ok(v(2) in h.command.ordered, "H holds an ally")
	h._unhandled_input(key(KEY_SPACE))
	ok(al.cell != Vector2i(2, 6) and v(2).cell == Vector2i(1, 3) and v(1).cell == Vector2i(1, 2), "on ending the turn the ally without orders acts; the held one and the leader don't")
	await tree.process_frame
	ok(b.turn == nemes and not h.my_turn(), "then the turn passes")
	h.free()


func test_what_shows() -> void:
	var siren := unit("Siren")
	stage(lancin, {v(1): Vector2i(5, 6), siren: Vector2i(6, 6), v(3): Vector2i(4, 6)})
	v(3).afflict(effect("concealment", 4), 9)
	var h := await start(v(1))
	var info := h._info(siren)
	ok(info.chips[0][0] == "Friendly" and info.name != "Siren", "the Siren's persona: it shows as a friend, not by name")
	ok(not ("Siren" in h._tag(siren)), "nor does the log give it away")
	h.use_slot(0)
	ok(h.targets().is_empty(), "Strike offers neither the 'friend' nor a unit it can't make out")
	h.click(Vector2i(4, 6))
	ok(v(3).hp == 10 and h._note.begins_with("Pick a unit"), "clicking where the hidden one stands finds nothing")
	h.disarm()
	h.click(Vector2i(4, 6))
	ok(h.selected == v(1) and v(1).cell == Vector2i(5, 6), "nor selected: the click is a move, and bumps into it")
	h.free()


func test_drawn_as_seen() -> void:
	var icor := unit("Icor")
	var siren := unit("Siren")
	stage(lancin, {v(1): Vector2i(1, 1), icor: Vector2i(8, 1), v(3): Vector2i(5, 5), v(4): Vector2i(8, 6), siren: Vector2i(3, 6)})
	icor.afflict(effect("concealment", 4), 9)
	v(3).afflict(effect("concealment", 3), 9)
	v(4).afflict(effect("concealment", 1), 9)
	var h := await start(v(1))
	var shadow := func(u: Unit) -> bool: return u.sprite.modulate == Unit.SHAPE
	var edge := func(u: Unit) -> Color: return Color(u.glow.modulate, 1.0) if u.glow.visible else Color.TRANSPARENT
	ok(not icor.visible, "unlocated: not drawn at all")
	ok(not v(3).visible and not h.dubious.is_empty() and h.dubious.keys().all(func(c): return Vector2(c).distance_to(Vector2(5, 5)) < 3),
			"only suspected: not drawn, but the area it may be in is marked")
	ok(v(4).visible and shadow.call(v(4)) and not v(4).hp_bar.visible and edge.call(v(4)) == Unit.SHAPE_EDGE,
			"located, side unknown: a black shape, neutral glow, no bars")
	ok(h._info(v(4)).shape and h._info(v(4)).chips[0][0] == "Unknown", "the card shows a shape too")
	ok(siren.visible and not shadow.call(siren) and edge.call(siren) == lancin.primary, "the Siren wears the side its persona claims")
	ok(v(1).visible and edge.call(v(1)) == lancin.primary and not shadow.call(v(1)), "your own as they are")
	v(4).timed.clear()
	h._refresh()
	ok(not shadow.call(v(4)) and edge.call(v(4)) == nemes.primary and v(4).hp_bar.visible, "in the open again: its side shows")
	h.free()


func test_ctrl_click() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(9, 0)})
	v(3).afflict(effect("concealment", 4), 9)
	var h := await start(v(1))
	h.use_slot(0)
	h.click(Vector2i(5, 3))
	ok(v(3).hp == 10 and h.armed == strike, "a plain click finds nothing to strike")
	h.click(Vector2i(5, 3), true)
	ok(v(3).hp == 8 and v(3).exposed == 1 and h.armed == null, "Ctrl-click strikes the tile and lands")
	h.click(Vector2i(4, 4), true)
	ok(is_equal_approx(v(1).ap_left(), 6.0) and h._note == "Nothing there", "without a skill armed, Ctrl-click uses slot 1; at air, it's spent")
	h.free()


func test_click_attacks() -> void:
	stage(lancin, {v(1): Vector2i(1, 3), v(3): Vector2i(4, 3), v(4): Vector2i(9, 0)})
	var h := await start(v(1))
	h.hover_cell(Vector2i(4, 3))
	ok(h.charge == Vector2i(4, 3) and h.plan.path.back() == Vector2i(3, 3), "hovering a foe plans the walk into reach")
	ok("Click: walk 2, then Strike I" in h.tip_label.text, "and the tip says what a click will do")
	h.click(Vector2i(4, 3))
	ok(v(1).cell == Vector2i(3, 3) and v(3).hp == 8 and v(1) in h.command.ordered, "clicking it walks up and strikes")
	stage(lancin, {v(1): Vector2i(0, 7), v(3): Vector2i(9, 0), v(4): Vector2i(9, 1)})
	h.select(v(1))
	h.click(Vector2i(9, 0))
	ok(v(1).cell != Vector2i(0, 7) and v(3).hp == 8 and h._note == "Out of reach", "too far: it closes in as far as it can")
	h.free()


func test_command_slots() -> void:
	var al := unit("Alabaster")
	stage(lancin, {v(1): Vector2i(1, 2), al: Vector2i(2, 2), v(3): Vector2i(3, 2), v(4): Vector2i(9, 0)})
	var h := await start(v(1))
	h.select(al)
	h.use_slot(0)
	ok(h.armed == null and h._note.begins_with("Allies only take move orders"), "cha 8: an ally can't be told to use a skill")
	h.click(Vector2i(3, 2))
	ok(h.selected == v(3) and v(3).hp == 10, "nor to attack: clicking the foe just selects it")
	h.select(al)
	h.click(Vector2i(2, 3))
	ok(al.cell == Vector2i(2, 3), "but it moves")
	v(1).charisma = 12
	h.select(al)
	h._refresh()
	ok(not (h.bar.get_child(0) as SkillSlot).locked and (h.bar.get_child(1) as SkillSlot).locked, "cha 12: slot 1 open, slot 2 locked")
	h.use_slot(1)
	ok(h.armed == null and "slot 1" in h._note, "Stonegift, in slot 2, stays out of reach")
	h.use_slot(0)
	ok(h.armed == strike, "Strike, in slot 1, is armed")
	h.disarm()
	h.select(v(1))
	h._refresh()
	ok(not (h.bar.get_child(1) as SkillSlot).locked, "the leader's slots are never locked")
	h.free()


func test_ground() -> void:
	stage(lancin, {v(1): Vector2i(2, 4), v(3): Vector2i(8, 1)})
	v(3).afflict(effect("concealment", 3), 9)
	var h := await start(v(1))
	ok(h.grounds[Vector2i(5, 4)] == &"unsure" and h.grounds[Vector2i(2, 2)] == &"safe" and h.grounds[Vector2i(5, 2)] == &"safe",
			"the hidden trap is unsure ground; bramble and the shrine are safe")
	ok(not h.dubious.is_empty() and h.dubious.keys().all(func(c): return h.grounds[c] == &"unsure"), "so is anywhere something may lurk")
	h.hover_cell(Vector2i(6, 4))
	ok(h.tip_label.text.begins_with("Walk here: 4? of 5"), "a walk across unsure ground gets a '?' on its cost")
	ok(h.pane.visible and h.get_node("%TileName").text == "Grass" and h.get_node("%TileCost").text == "Move 1", "the tile pane shows the hovered tile")
	h.hover_cell(Vector2i(5, 4))
	ok(h.get_node("%TileCost").text == "Move ?" and h.get_node("%TileNotes").get_child(0).text == "Disturbed earth?"
			and not h.get_node("%TileScroll").visible, "the trap's tile: cost unknown, no known effects, a hint")
	b.revealed[Vector2i(5, 4)] = true
	h._refresh()
	ok(h.grounds[Vector2i(5, 4)] == &"bad", "sprung, it's known bad ground")
	h.hover_cell(Vector2i(6, 4))
	ok("Stops 1 short (3 move)" in h.tip_label.text and "Steps onto a known trap" in h.tip_label.text, "the plan stops on it, warns, and is sure of its cost")
	h.hover_cell(Vector2i(2, 2))
	var lines: Array = h.get_node("%TileLines").get_children().map(func(l): return l.text)
	ok(h.get_node("%TileName").text == "Bramble" and h.get_node("%TileCost").text == "Move 1" and lines == ["Sticky: +1 to leave"], "bramble: neutral, sticky")
	h._unhandled_input(key(KEY_B))
	ok(not h.pane.visible, "the spellbook hides the pane")
	h.free()


func test_tile_effects() -> void:
	var shrine: Terrain = load("res://Terrain/shrine.tres")
	stage(lancin, {v(1): Vector2i(4, 2), v(3): Vector2i(8, 6)})
	var h := await start(v(1))
	var lines := func() -> Array: return h.get_node("%TileLines").get_children().map(func(l): return l.text)
	h.hover_cell(Vector2i(5, 2))
	ok(lines.call() == ["Heal: 10% each turn"] and h.get_node("%TileLines").get_child(0).get_theme_color(&"font_color") == HUD.FRIEND,
			"the shrine's effect, in a helpful green")
	v(1).afflict(effect("recon", 1), 9)
	h._show_pane()
	ok(lines.call() == ["Beneficial", "Heal: 10% each turn"], "a closer look (recon 1) also tells it's beneficial")
	var extra: Array[Effect] = [effect("luck", 1), effect("mitigate", 0.1), effect("poison", 0.05), effect("movement", -1), effect("reach", 1)]
	var kept := shrine.effects.duplicate()
	shrine.effects.append_array(extra)
	h._show_pane()
	await tree.process_frame
	var scroll: ScrollContainer = h.get_node("%TileScroll")
	ok(lines.call().size() == 7 and scroll.size.y <= HUD.PANE_LIST + 0.5, "a long list is capped")
	ok("Poison: 5% each turn" in lines.call(), "harmful effects listed too")
	var list: Control = h.get_node("%TileLines")
	var span: float = list.get_combined_minimum_size().y - HUD.PANE_LIST
	var travel := maxf(span / HUD.SCROLL_SPEED, 1.0)
	h._scroll_t = 0.0
	h._auto_scroll(HUD.SCROLL_FADE / 2.0)
	ok(scroll.scroll_vertical == 0 and list.modulate.a < 1.0, "it fades in at the top")
	h._auto_scroll(HUD.SCROLL_FADE / 2.0 + HUD.SCROLL_HOLD - 0.05)
	ok(scroll.scroll_vertical == 0 and list.modulate.a == 1.0, "and holds there 3 seconds")
	h._auto_scroll(0.05 + travel / 2.0)
	var mid := scroll.scroll_vertical
	ok(mid > 0 and mid < roundi(span), "then scrolls down")
	h._auto_scroll(travel / 2.0 + HUD.SCROLL_HOLD - 0.05)
	ok(scroll.scroll_vertical == roundi(span) and list.modulate.a == 1.0, "holds at the bottom 3 seconds")
	h._auto_scroll(0.05 + HUD.SCROLL_FADE / 2.0)
	ok(scroll.scroll_vertical == roundi(span) and list.modulate.a < 1.0, "fades out")
	h._auto_scroll(HUD.SCROLL_FADE / 2.0 + 0.01)
	ok(scroll.scroll_vertical == 0 and list.modulate.a < 0.1, "and starts again from the top")
	var speed := func(u: float) -> float: return HUD.slow_middle(u + 0.01) - HUD.slow_middle(u)
	ok(speed.call(0.495) < speed.call(0.25) and speed.call(0.25) < speed.call(0.0) and HUD.slow_middle(1.0) == 1.0,
			"the scroll is slowest in the middle")
	h.hover_cell(Vector2i(5, 3))
	h.hover_cell(Vector2i(5, 2))
	ok(h._scroll_t == 0.0, "a newly hovered tile starts over")
	shrine.effects.assign(kept)
	h.free()


func test_party_help() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h._refresh()
	var help: String = h.party_title.tooltip_text
	ok("press P to invite" in help and "Orders reach allies within 1 tile" in help and "only take move orders" in help,
			"the party header's tooltip explains the party, orders and command slots")
	ok(h.party_title.mouse_filter != Control.MOUSE_FILTER_IGNORE, "and the header can be hovered for it")
	var open: Array = h.roster.get_children().filter(func(c): return c is Label)
	ok(open.size() == 1 and open[0].tooltip_text == help, "an open party slot shows, with the same tooltip")
	ok(not h.has_node("%Reach"), "the description is off the panel")
	h.free()


func test_stew_pane() -> void:
	stage(lancin, {v(1): Vector2i(3, 0), v(2): Vector2i(2, 0), v(3): Vector2i(8, 6)})
	var h := await start(v(1))
	h.hover_cell(Vector2i(4, 0))
	var lines: Array = h.get_node("%TileLines").get_children().map(func(l): return l.text)
	ok(h.get_node("%TileName").text == "Magic Stew" and h.get_node("%TileCost").text == "Move 4", "the magic stew: 4 to enter")
	ok(lines == ["Heal: 15% each turn",
			"Poison: 5% each turn · 3 turns · at turn end",
			"Sleep: can't act till an ally ends the turn beside it · 1 turn · at turn end",
			"Haste: AP +10%, Dex AP +20% · 3 turns · at turn end",
			"Moist"], "its effects, Haste as one condition (%s)" % [lines])
	h.click(Vector2i(4, 0))
	ok(v(1).cell == Vector2i(4, 0) and not v(1).asleep(), "wading in, the leader's still awake")
	b.end_turn()
	b.end_turn()
	await tree.process_frame
	h._refresh()
	ok(v(1).asleep() and v(1) in h.sleepers and h._info(v(1)).chips.any(func(c): return c[0] == "Asleep"), "it ended the turn there: asleep, and it shows")
	h.select(v(1))
	h.click(Vector2i(4, 1))
	ok(v(1).cell == Vector2i(4, 0) and h._note.begins_with("Asleep"), "a sleeper can't be ordered, and the hint says why")
	h.free()


func test_play_scene() -> void:
	Game.starter = {faction = lancin, role = load("res://Roles/fighter.tres"), name = "Tess"}
	var scene: Node = load("res://Scenes/play.tscn").instantiate()
	var pb: Battle = scene.get_node("Museum/Battle")
	pb.rng.seed = 3
	var h: HUD = scene.get_node("HUD")
	h.pace = 0.0
	tree.root.add_child(scene)
	ok(h.command.leader == pb.player and pb.player.nick == "Tess", "the starter leads")
	var frames := 0
	while pb.phase == Battle.Phase.TURNS and frames < 500:
		await tree.process_frame
		frames += 1
		if h.my_turn():
			h.end_turn()
	await tree.process_frame
	ok(pb.phase == Battle.Phase.OVER and h.over.visible, "ending every turn, the battle plays out and says who won (%d frames)" % frames)
	scene.free()


func test_skills_screen() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/paladin.tres"), name = "Pip"})
	b.get_node("Units").add_child(u)
	stage(lancin, {u: Vector2i(1, 2), v(1): Vector2i(1, 3), v(3): Vector2i(8, 2)})
	var h := await start(u)
	var relay: Skill = load("res://Skills/relay.tres")
	h._unhandled_input(key(KEY_S))
	ok(h.skills.visible and h.skills.unit == u and not h.spellbook.visible, "S opens the leader's skills")
	var species: Array = h.get_node("%SpeciesList").get_children()
	ok(h.get_node("%SpeciesTitle").text == "SPECIES · HALFLING" and species.size() == 1, "Relay on offer from its species")
	var unlock: Button = species[0].get_child(0).get_child(2)
	ok(unlock.text == "Unlock" and unlock.disabled, "but there's no point to spend")
	h.skills.leveled.emit()
	h._refresh()
	ok(u.skill_points == 1 and h.get_node("%SkillsIcon").badge, "a level up: a point, and the dock's branch lights up")
	ok(h._info(u).chips.any(func(c): return c[0] == "1 skill point"), "the card says so too")
	h.skills.unlocked.emit(relay)
	h._refresh()
	ok(u.rank(relay) == 1 and u.skill_points == 0 and not h.get_node("%SkillsIcon").badge, "unlocking Relay spends it")
	h._unhandled_input(key(KEY_B))
	ok(h.spellbook.visible and not h.skills.visible, "the spellbook and skills don't overlap")
	h._unhandled_input(key(KEY_ESCAPE))
	ok(not h.spellbook.visible, "Esc closes it")
	h.get_node("%SkillsIcon").pressed.emit()
	ok(h.skills.visible, "the dock's branch opens skills")
	h.get_node("%CogIcon").pressed.emit()
	ok(h.settings.visible and not h.skills.visible, "the cog opens Settings, closing skills")
	ok("Ctrl-click a tile" in h.get_node("%Guide").text and not h.hint.visible, "with the Guide; no instructions sit on screen")
	h.get_node("%CogIcon").pressed.emit()
	ok(not h.settings.visible, "and closes it")
	h.toggle_skills()
	h.select(v(1))
	h._refresh()
	ok(h.skills.unit == v(1) and not h.get_node("%LevelUp").visible, "another ally's skills show, but aren't yours to spend")
	h.select(u)
	h._close_panels()
	h.hover_cell(Vector2i(1, 3))
	var notes: Array = h.get_node("%TileNotes").get_children().map(func(l): return l.text)
	ok(notes.has("Pip through Villager1: +2.4 move"), "the tile pane gives the cost of moving through a unit: 3 x (1 - 0.1 dex - 0.1 Relay) (%s)" % [notes])
	h.free()


func test_snare_ui() -> void:
	var snare: Skill = load("res://Skills/snare.tres")
	v(1).learned.append(slot(snare, 2))
	v(1).hotbar[1] = snare
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 6)})
	var h := await start(v(1))
	h.use_slot(1)
	h.hover_cell(Vector2i(3, 3))
	ok(h.armed == snare and "Click to use" in h.tip_label.text, "armed, a tile in reach is a place for it")
	h.click(Vector2i(3, 3))
	h._refresh()
	ok(Vector2i(3, 3) in b.snares and h.traps.get(Vector2i(3, 3)) == true, "laid, and marked as your own")
	h.hover_cell(Vector2i(4, 3))
	h.hover_cell(Vector2i(3, 3))
	var lines: Array = h.get_node("%TileLines").get_children().map(func(l): return l.text)
	var notes: Array = h.get_node("%TileNotes").get_children().map(func(l): return l.text)
	ok("Trap: 1d4 x2 +1 pierce" in lines and "Set by Villager1" in notes, "the pane gives its damage and who set it (%s %s)" % [lines, notes])
	h.free()


func test_initiative_and_turns() -> void:
	var icor := unit("Icor")
	icor.afflict(effect("concealment", 4), 9)
	var h := await start(v(1))
	var rows := h.initiative_rows()
	ok(rows.size() == 2 and rows[0][0] == b.order[0], "sides in turn order")
	for row in rows:
		var sum: int = row[1].reduce(func(t, d): return t + d[1], 0)
		ok(sum + row[2] == row[3], "%s: the dice and bonus make the total" % row[0].name)
	var nemes_row: Array = rows.filter(func(r): return r[0] == nemes)[0][1]
	ok(nemes_row.any(func(d): return d[0] == null) and not nemes_row.any(func(d): return d[0] == icor), "a unit you can't make out rolls as '?'")
	ok(not nemes_row.any(func(d): return d[0] == unit("Siren")), "nor does the Siren's persona slip: its side isn't shown")
	h._transition(nemes, false)
	ok(h.get_node("%BandTitle").text == "Nemes" and h.get_node("%BandSub").text.begins_with("Their turn"), "the turn change names the side")
	h.free()


func test_clover_bar() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(v(1))
	h.select(v(1))
	h._refresh()
	var c := h.bar.get_child(4) as SkillSlot
	ok(h.bar.get_child_count() == 5 and c.clover and c.works, "a lucky leader: 4 slots and a working clover fifth")
	ok(not (h.bar.get_child(3) as SkillSlot).clover and "Clover slot" in c.tooltip_text, "only the fifth; it says what it is")
	v(1).afflict(effect("luck", -1), 3)
	h._refresh()
	ok(h.bar.get_child_count() == 4, "luck gone, nothing in it: hidden")
	v(1).timed.clear()
	ok(v(1).bar_place(strike, 4), "Strike moved into it")
	v(1).afflict(effect("luck", -1), 3)
	h._refresh()
	c = h.bar.get_child(4) as SkillSlot
	ok(h.bar.get_child_count() == 5 and c.clover and not c.works and not c.usable and c.skill == strike,
			"luck gone with a skill in it: shown, greyed out")
	h.use_slot(4)
	ok(h.armed == null and h._note == SkillSlot.NO_LUCK, "and it can't be used: %s" % h._note)
	h.free()


func test_attack_feedback() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).armor = load("res://Items/plate.tres")
	var h := await start(v(1))
	h.select(v(1))
	h._refresh()
	ok(h._info(v(1)).rows.any(func(r): return r[0] == "DF" and r[1] == "2 · unarmored"), "the card shows Defense: 2, unarmored")
	ok(h._info(v(3)).rows.any(func(r): return r[0] == "DF" and r[1] == "20 · Plate"), "...and a foe's it can make out: Plate, 20")
	h.use_slot(0)
	h.hover_cell(Vector2i(5, 3))
	ok("10% to hit" in h.tip_label.text, "the forecast: 10%% against Plate (%s)" % h.tip_label.text)
	var rolled := []
	b.attacked.connect(func(_c, _t, d20: int, _total, _def): rolled.append(d20))
	h.click(Vector2i(5, 3))
	var text := h.log_box.get_parsed_text()
	ok(rolled.size() == 1, "one attack roll")
	if rolled[0] == 20:
		ok("natural 20" in text, "a natural 20 is logged: %s" % text)
	else:
		ok("(rolls %d vs Defense 20)" % (rolled[0] + 1) in text, "the roll is logged against Defense: %s" % text)
		ok(("misses" in text) == (rolled[0] < 19), "and whether it missed")
	h.free()


func test_hidden_defense() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).afflict(effect("concealment", 1), 9)
	var h := await start(v(1))
	h.select(v(1))
	h._refresh()
	ok(h.view(v(3)).net < 0 and not h._info(v(3)).rows.any(func(r): return r[0] == "DF"), "a foe it can't identify: no Defense on the card")
	ok("?% to hit" in h._forecast(v(1), strike, v(3)), "nor a chance to hit")
	h.free()


func shrike() -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/adventurer.tres"), name = "Shrike"})
	b.get_node("Units").add_child(u)
	return u


func test_adventurer_skills_screen() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var h := await start(u)
	var igna: Skill = load("res://Skills/igna.tres")
	var sola: Skill = load("res://Skills/sola.tres")
	var hazard: Skill = load("res://Skills/hazard_expert.tres")
	h.toggle_skills()
	await tree.process_frame
	var w: SkillWheel = h.get_node("%Wheel")
	ok(w.is_visible_in_tree() and not h.get_node("%ClassCol").visible and h.get_node("%DetailCol").visible,
			"the Adventurer's class skills: a wheel, not a list")
	ok(w.skills().size() == 23 and w.spot(load("res://Skills/skill_slot.tres")).is_equal_approx(w.size / 2.0),
			"every skill on it (%d), Skill Slot +1 at the centre" % w.skills().size())
	ok(h.skills.size.x >= SkillTree.TREE_SIZE.x - 0.5, "a wider panel for it (%s)" % h.skills.size)
	ok(h.skills.picked == hex and h.get_node("%DetailName").text == "Hex" and h.get_node("%DetailState").text == "Tier 1 · Can be learned now",
			"Hex shows first: the first it can learn")
	var act: Button = h.get_node("%DetailButton")
	ok(act.text == "Unlock · 1 pt" and act.disabled and act.tooltip_text == "Needs 1 skill point", "no point yet (%s)" % act.text)
	u.skill_points = 3
	h._refresh()
	ok(not act.disabled, "a point: it can be unlocked")
	act.pressed.emit()
	h._refresh()
	ok(u.rank(hex) == 1 and u.skill_points == 2 and "learns Hex" in h.log_box.get_parsed_text(), "unlocked from the detail column")
	ok(h.get_node("%DetailName").text == "Hex I" and act.text == "Rank II · 2 pts" and not act.disabled, "then it can go up a rank, for 2")
	act.pressed.emit()
	h._refresh()
	ok(u.rank(hex) == 2 and u.skill_points == 0 and "raises Hex to rank II" in h.log_box.get_parsed_text(), "rank II")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = w.spot(sola)
	w._gui_input(click)
	ok(h.skills.picked == sola and w.selected == sola and h.get_node("%DetailName").text == "Sola", "clicking a skill on the wheel shows it")
	ok("On an ally" in h.get_node("%DetailText").text, "with what it does")
	h.skills.pick(hazard)
	ok(h.get_node("%DetailState").text == "Tier 2 · Learn Snare first" and act.disabled, "Hazard Expert: tier 2, after Snare")
	h.skills.pick(igna)
	ok(h.get_node("%DetailState").text == "Tier 1 · Not built yet. Waits on open question 10 (todo.md)" and not act.visible
			and h.get_node("%DetailText").text == igna.plan, "a stub: the question it waits on, and its plan")
	ok(w._get_tooltip(w.spot(igna)).begins_with("Igna · tier 1\n") and "Waits on open question 10" in w._get_tooltip(w.spot(igna)) and w._get_tooltip(Vector2(-50, -50)) == "", "the wheel's tooltips")
	ok(w.state_of(igna) == &"stub" and w.state_of(hex) == &"learned" and w.state_of(sola) == &"open" and w.state_of(hazard) == &"locked",
			"how each is drawn")
	h._refresh()
	ok(h.skills.picked == igna, "the pick survives a refresh")
	h.free()


func test_dual_spell_ui() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(1): Vector2i(5, 3), v(3): Vector2i(4, 4)})
	var sola: Skill = load("res://Skills/sola.tres")
	u.skill_points = 1
	u.unlock(sola)
	var h := await start(u)
	h.select(u)
	h._refresh()
	h.use_slot(1)
	h._refresh()
	ok(h.armed == sola and v(1) in h.marked and v(3) in h.marked, "Sola armed: an ally and a foe in reach are both targets")
	h.hover_cell(Vector2i(5, 3))
	ok("3 AP, 2 energy · Persona: +1, 1 turn" in h.tip_label.text and "to hit" not in h.tip_label.text, "on the ally: its cost, and what it gets (%s)" % h.tip_label.text)
	h.hover_cell(Vector2i(4, 4))
	ok("to hit" in h.tip_label.text and "1-4 damage" in h.tip_label.text, "on the foe: the chance to hit, and damage (%s)" % h.tip_label.text)
	h.click(Vector2i(5, 3))
	ok(v(1).stat(&"persona") == 1.0 and h.armed == null, "clicked on the ally: it gets the persona")
	h.free()


func test_typed_slot_bar() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(3): Vector2i(8, 6)})
	var sola: Skill = load("res://Skills/sola.tres")
	u.skill_points = 10
	for k in ["sola", "nadira", "astera", "magic_slot"]:
		u.unlock(load("res://Skills/%s.tres" % k))
	var h := await start(u)
	h.select(u)
	h._refresh()
	var m := h.bar.get_child(4) as SkillSlot
	ok(h.bar.get_child_count() == 5 and m.kind == &"magical" and "Magic slot: holds only magic skills" in m.tooltip_text,
			"a Magic slot on the bar; the unlucky clover slot after it is hidden")
	h._on_dropped(4, strike, 0)
	ok(u.hotbar[4] == null and h._note == "Magic slots hold only magic skills", "Strike won't go in (%s)" % h._note)
	h._on_dropped(4, sola, 1)
	ok(u.hotbar[4] == sola and u.hotbar[1] == null, "Sola will")
	h.free()
