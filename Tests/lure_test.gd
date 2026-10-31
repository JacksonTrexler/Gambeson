extends Test

# The Siren's lure (serene and still until unmasked, singing, drowning and raking what comes close:
# AI._luring(), AI._ambush()), Drown (Battle.drag(), then a grapple: Battle._struggle()) and Rake,
# Sing (allies move further; foes are drawn closer: Battle.pull(); up to rank units, resisted unless
# enraptured), Ramut's Ire building on units stalling a fight (Battle._check_stall()), Personify's
# active half (Battle.personify(), the persona panel: rank changes a use) and the Siren's Allure,
# advertised levels, the words low-wisdom allies use (Perception.traits()), wis mod -3 falling for any
# front, and the player's panel seeing its own allies as its side reads them: their skills by name,
# effects as a "?".

var sing: Skill = load("res://Skills/sing.tres")
var personify: Skill = load("res://Skills/persona.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func test_sing() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(3): Vector2i(8, 4), v(1): Vector2i(3, 6)})
	ok(sing.summary() == "3 AP · 2 cost · range rank + cha mod", "range rank + cha mod (%s)" % sing.summary())
	ok(b.auto_targets(siren(), sing) == [v(3)], "Sing I: the nearest unit in range, no more than its rank")
	ok(not b.cast(siren(), sing, v(3)), "it isn't aimed: used at once")
	var was := v(3).stat(&"movement")
	ok(b.cast(siren(), sing, siren()) and v(3).stat(&"movement") == was + 1.0 and v(1).cell == Vector2i(3, 6), "an ally: +1 movement")
	for x in siren().learned:
		if x.skill == sing:
			x.rank = 2
	siren().refresh()
	ok(b.auto_targets(siren(), sing) == [v(3), v(1)] and b.cast(siren(), sing, siren()) and v(1).cell == Vector2i(5, 6),
			"Sing II: range 2 + cha mod (4), the nearest two - a foe among them, drawn 2 tiles closer")
	ok("Used at once: lands on the nearest 2 units in range, allies and foes alike" in sing.describe(2) and "On a foe: draws it up to 2 tiles toward the caster" in sing.describe(2),
			"described (%s)" % sing.describe(2))
	b.move(v(1), Vector2i(1, 6))
	ok(b.auto_targets(siren(), sing) == [v(3)], "7 tiles off: out of range")
	b.move(v(3), Vector2i(1, 1))
	b.move(v(1), Vector2i(7, 6))
	siren().refresh()
	ok(b.cast(siren(), sing, siren()) and v(1).cell == Vector2i(7, 6), "already beside it: stays")


func test_lure() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(3, 6)})
	var swings := []
	b.attacked.connect(func(c: Unit, _t: Unit, _d: int, _x: int, _df: int): swings.append(c))
	ok(AI._luring(b, siren(), {v(1): b.read(siren(), v(1))}), "fooled and far off: still luring")
	AI.act(b, siren())
	ok(siren().cell == Vector2i(8, 6) and swings.is_empty() and v(1).cell == Vector2i(4, 6), "it stands still and sings, drawing the foe in")
	b.move(v(1), Vector2i(8, 5))
	ok(AI._luring(b, siren(), {v(1): b.read(siren(), v(1))}), "close by, still fooled: the calm holds")
	var used := []
	b.used.connect(func(_c: Unit, s: Skill, _at: Variant, _d: int): used.append(s.name))
	siren().strength = 40  # sure to win the grapple
	v(1).max_hp = 99  # and to live through it
	v(1).hp = 99
	siren().refresh()
	AI.act(b, siren())
	ok(used.size() >= 1 and used[0] == "Drown" and b.terrain(v(1).cell).tags.has(&"water"), "within reach: drowned first (%s)" % ", ".join(used))
	ok("Rake" in used, "then raked with the AP left")
	b.move(v(1), Vector2i(3, 6))
	v(1).afflict(effect("recon", 3), 9)
	ok(not AI._luring(b, siren(), {v(1): b.read(siren(), v(1))}), "unmasked: the calm breaks, and it fights as any unit would")


func test_drown() -> void:
	var drown: Skill = load("res://Skills/drown.tres")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(8, 5)})
	ok(b.drag_spot(siren(), drown, v(1)) in [Vector2i(7, 6), Vector2i(9, 6)], "the nearest water to drag it to")
	v(1).strength = 60
	var hp := v(1).hp
	ok(b.cast(siren(), drown, v(1)) and v(1).cell == Vector2i(8, 5) and drown.effects[0] not in v(1).timed, "lost the contest: it breaks free")
	v(1).strength = 5
	siren().strength = 40
	siren().refresh()
	ok(b.cast(siren(), drown, v(1)) and b.terrain(v(1).cell).tags.has(&"water") and Battle.next_to(siren().cell, v(1).cell)
			and b.terrain(siren().cell).tags.has(&"water"), "won: dragged into the water, the Siren beside it, both submerged")
	var held := drown.effects[0]
	ok(held in v(1).timed and v(1).timed[held].by == siren() and v(1).timed[held].lasting and v(1).hp == hp, "Submerged: held till it breaks free, no damage yet")
	ok("Holds it: moving away first takes 1 + the caster's str mod tiles of movement and a str contest. Each turn it ends held, it takes 1d12 + str mod" in drown.describe(1),
			"described (%s)" % drown.describe(1))
	var struggles := []
	var grips := []
	b.struggled.connect(func(_u: Unit, _by: Unit, total: int, against: int): struggles.append([total, against]))
	b.gripped.connect(func(_u: Unit, _by: Unit, dealt: int): grips.append(dealt))
	v(1).max_hp = 99
	v(1).hp = 99
	b.end_turn()  # v(1)'s side's turn
	var away := func() -> Vector2i: return v(1).cell + (v(1).cell - siren().cell) * 2
	ok(b.escape_cost(v(1)) == 16.0 and b.travel(v(1), away.call()).is_empty() and struggles.is_empty(),
			"breaking free takes 1 + the Siren's str mod (15) tiles of movement: more than it has")
	b.end_turn()
	ok(grips.size() == 1 and grips[0] >= 1 + 15 and grips[0] <= 12 + 15 and v(1).hp == 99 - grips[0], "held as its turn ends: 1d12 + str mod (%s)" % [grips])
	b.end_turn()
	siren().strength = 12
	var left := v(1).move_left()
	b.travel(v(1), away.call())
	ok(struggles.size() == 1 and left - v(1).move_left() >= 2.0 - 0.0001, "str mod +1: an attempt takes 2 tiles of movement, and a str contest")
	ok((held in v(1).timed) == (struggles[0][0] <= struggles[0][1]), "won, it's free; lost, still held (%s)" % [struggles])
	v(1).strength = 99
	if held in v(1).timed:
		b.travel(v(1), away.call())
	ok(held not in v(1).timed and struggles[-1][0] > struggles[-1][1], "strong enough: it breaks free")
	b.end_turn()
	v(1).strength = 5
	siren().strength = 40
	b.move(v(1), Vector2i(8, 5))
	b.move(siren(), Vector2i(8, 6))
	ok(b.turn == nemes and b.cast(siren(), drown, v(1)) and held in v(1).timed, "held again")
	b.move(siren(), Vector2i(1, 1))
	var n := grips.size()
	b.end_turn()
	b.end_turn()
	ok(held not in v(1).timed and grips.size() == n, "its holder gone from beside it: let go, nothing taken")
	ok(Battle.drag_penalty(drown, 1, 3) == 3 and Battle.drag_penalty(drown, 2, 3) == 0, "-1 a tile it drags, less rank - 1")
	ok("Str contest in place of an attack roll" in drown.describe(1), "described (%s)" % drown.describe(1))
	stage(nemes, {siren(): Vector2i(1, 1), v(1): Vector2i(2, 1)})
	var ap := siren().ap_left()
	ok(b.drag_spot(siren(), drown, v(1)) == null and not b.cast(siren(), drown, v(1)) and siren().ap_left() == ap, "no water it could walk to: it can't be used")
	var rake: Skill = load("res://Skills/rake.tres")
	ok(b.cast(siren(), rake, v(1)), "Rake, its attack anywhere")


# Holding a unit, the Siren stays put rather than walk off and let go - unless its ground is bad.
func test_holds_on() -> void:
	var drown: Skill = load("res://Skills/drown.tres")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(8, 5), v(2): Vector2i(1, 1)})
	v(1).max_hp = 99
	v(1).hp = 99
	v(1).strength = 5
	siren().strength = 40
	siren().refresh()
	ok(b.cast(siren(), drown, v(1)) and drown.effects[0] in v(1).timed, "held")
	for u in [v(1), v(2)]:
		u.afflict(effect("recon", 5), 9)
	siren().refresh()
	var at := siren().cell
	ok(not AI._luring(b, siren(), {v(1): b.read(siren(), v(1)), v(2): b.read(siren(), v(2))}) and AI._rooted(b, siren()), "unmasked, and holding v(1): rooted")
	siren().learned.assign(siren().learned.filter(func(x: Slot): return x.skill.name != "Rake"))  # nothing to strike v(1) with
	AI.act(b, siren())
	ok(siren().cell == at and drown.effects[0] in v(1).timed, "it doesn't go after the foe far off: it keeps its hold")
	b._let_go(v(1), drown)
	b.move(v(1), Vector2i(1, 3))
	siren().refresh()
	AI.act(b, siren())
	ok(siren().cell != at, "holding nothing, it would have")
	b.move(siren(), Vector2i(5, 4))  # the museum's spike trap, sprung: known bad ground
	b.revealed[Vector2i(5, 4)] = true
	ok(b.read(siren(), Vector2i(5, 4)).known_bad() and not AI._rooted(b, siren()), "on bad ground, it would sooner move")


func test_ramuts_ire() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(1, 1)})
	siren().charisma = 60  # a lie v(1) won't see through by looking harder: only the Ire undoes it
	v(1).wisdom = 6
	ok(b.ire_grace == 1.0 and b.grace(lancin) == 1.0, "Ramut's Ire waits out as many stalled turns in a row as the smallest side has units standing: 1")
	var calls := []
	b.stalled.connect(func(u: Unit, rank: int): calls.append([u, rank]))
	var ire: Effect = b.IRE.effects[0]
	b.end_turn()  # Nemes: it sees its foes
	b.end_turn()  # Lancin: it can't make out a single foe
	ok(b.stalled_turns[lancin] == 1 and b.stalling.has(siren()) and calls.is_empty(), "a stalled turn, the Siren stalling it: within the grace, nothing yet")
	var trick := Perception.trickery(siren(), Read.new(), v(1), b)
	b.end_turn()
	b.end_turn()
	ok(b.stalled_turns[lancin] == 2 and calls == [[siren(), 1]] and siren().timed[ire].rank == 1, "past the grace: Ramut's Ire builds on it")
	ok(is_equal_approx(Perception.trickery(siren(), Read.new(), v(1), b), trick - 1.0), "a rank of its trickery defeated, against everyone")
	b.end_turn()
	b.end_turn()
	ok(calls.size() == 2 and calls[1] == [siren(), 2] and siren().timed[ire].rank == 2, "a rank more each turn it stalls")
	for i in 10:
		if not b.read(v(1), siren()).deceived:
			break
		b.end_turn()
		b.end_turn()
	var r := b.read(v(1), siren())
	ok(not r.deceived and r.faction == nemes and AI._foe(v(1), r), "until it's seen for what it is (Ire %s), and the fight can go on" % Skill.roman(siren().timed[ire].rank))
	var rank := siren().timed[ire].rank
	for i in 3:
		b.end_turn()
		b.end_turn()
	ok(not b.stalling.has(siren()) and siren().timed[ire].rank == rank and b.read(v(1), siren()).faction == nemes,
			"no longer stalling, it doesn't build; but what it took stays taken, all battle")
	v(3).afflict(effect("concealment", 2), 9)
	var net := b.read(v(1), v(3)).net
	v(3).afflict(ire, 5, 1)
	ok(b.read(v(1), v(3)).net == net + 1, "it defeats concealment rank for rank too")
	ok(ire.describe(2) == "Ire: 2 ranks of its concealment and trickery defeated, against everyone", ire.describe(2))
	stage(nemes, {siren(): Vector2i(8, 6), v(3): Vector2i(8, 1), v(4): Vector2i(7, 1), v(1): Vector2i(1, 1), v(2): Vector2i(1, 2)})
	ok(b.grace(lancin) == 2.0, "3 standing against 2: 2 stalled turns")
	b.ire_grace = 3.0
	ok(b.grace(lancin) == 6.0, "tuned up for a stealth mission: 6")
	b.hastened[lancin] = 4
	ok(b.grace(lancin) == 2.0 and b.grace(nemes) == 6.0, "less what Lancin's prayers to Ramut took off, for Lancin alone")
	b.hastened.clear()
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(1, 1), v(2): Vector2i(1, 2)})
	b.ire_grace = -1.0
	siren().timed.erase(ire)
	b.stalled_turns.clear()
	for i in 20:
		b.end_turn()
	ok(b.stalled_turns[lancin] >= 10 and ire not in siren().timed, "< 0: never")


func test_stall_lifts() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(1, 1)})
	b.end_turn()
	ok(b.stalling.is_empty() and b.stalled_turns[nemes] == 0, "Nemes sees its foes: its turn isn't stalled")
	b.end_turn()
	ok(b.stalling.has(siren()) and b.stalled_turns[lancin] == 1, "Lancin can't make out one: stalled, by the Siren")
	b.end_turn()
	b.end_turn()
	ok(b.stalled_turns[lancin] == 2, "two in a row")
	v(1).afflict(effect("recon", 3), 9)
	b.end_turn()
	b.end_turn()
	ok(not b.stalling.has(siren()) and b.stalled_turns[lancin] == 0, "seen through by its turn's end: let off, and the count starts over")


func test_personify() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(1).learned.append(slot(personify, 1))
	v(1).refresh()
	var ap := v(1).ap_left()
	ok(b.personify(v(1), personify, {stance = "Friendly"}) and v(1).ap_left() == ap - 2.0, "costs 2 AP")
	ok(v(1).stance == "", "Persona I: no stances yet")
	v(1).learned[-1].rank = 3
	ok(Battle.stances(3).size() == 6 and b.personify(v(1), personify, {stance = "Traitor", shows_level = 7}) and v(1).stance == "Traitor" and v(1).shows_level == 7,
			"Persona III: the wrong team, and a level it claims")
	v(2).wisdom = 10
	ok(b.read(v(2), v(1)).level == 7, "an ally it fools takes it for level 7")
	v(1).shows_level = 0
	ok(b.read(v(2), v(1)).level == v(1).level, "advertising its own level shows the truth")
	v(1).learned[-1].rank = 1
	v(1).refresh()
	var ap2 := v(1).ap_left()
	ok(not b.personify(v(1), personify, {vibe = ["Kind", "Gentle"]}) and v(1).ap_left() == ap2, "Personify I: one change a use - two don't take, nor cost AP")
	ok(b.personify(v(1), personify, {vibe = ["Kind"]}) and v(1).shows_vibe.size() == 1 and v(1).shows_vibe[0] == "Kind" and v(1).is_on(personify),
			"one: a vibe word put on (Persona I) - and it advertises")
	v(1).learned[-1].rank = 3
	v(1).refresh()
	var change := {vibe = ["Gentle"], tags = [&"holy"]}
	ok(Battle.persona_changes(v(1), personify, change) == 3, "a word swapped is two changes, a tag put on one")
	ok(b.personify(v(1), personify, change) and v(1).shows_vibe[0] == "Gentle" and v(1).shows_tags.size() == 1 and v(1).shows_tags[0] == &"holy",
			"Personify III: three changes, identity among them")
	v(1).refresh()
	ok(Battle.persona_changes(v(1), personify, {clear = true}) == 1 and b.personify(v(1), personify, {clear = true})
			and v(1).shows_vibe.is_empty() and v(1).stance == "" and v(1).shows_level == 0 and not v(1).is_on(personify),
			"cleared, as one change: nothing put forward, and it stops advertising")
	stage(nemes, {siren(): Vector2i(8, 6)})
	ok(siren().rank(personify) == 0 and not b.personify(siren(), personify, {stance = ""}) and roundi(siren().stat(&"persona")) == 4
			and siren().alias != "", "the Siren doesn't personify: its persona is its nature (Alluring IV), its name picked as it's set up")


func test_persona_panel() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	v(1).learned.append(slot(personify, 3))
	v(1).refresh()
	var p := PersonaPanel.new()
	tree.root.add_child(p)
	p.open(v(1), personify, Battle.persona_rank(v(1), personify))
	ok(p.visible and p.changes().stance == "" and p.changes().vibe.is_empty(), "opens on its persona as it stands")
	ok(p._vibe and p._tags and p._count.text == "Changes: 0 / 3", "vibe and identity pickers, no changes yet")
	p._stance.select(2)
	p._recount()
	ok(p.changes().stance == "Enemy" and p._count.text == "Changes: 1 / 3" and not p._ok.disabled, "a stance picked: one change of three")
	p._vibe.filter.text = "ser"
	p._vibe._refilter()
	ok(p._vibe.options()[0] == "Serene", "typed: the list filters (%s)" % [p._vibe.options()])
	p._vibe.filter.text_submitted.emit("ser")
	ok(p._vibe.picked == ["Serene"] and p._vibe.filter.text == "" and p._count.text == "Changes: 2 / 3", "Enter takes the top match")
	p._vibe.add("Safe")
	p._tags.add(&"holy")
	ok(p._count.text == "Changes: 4 / 3" and p._ok.disabled, "past its rank: Done is off")
	p._vibe.remove("Safe")
	ok(p._count.text == "Changes: 3 / 3" and not p._ok.disabled, "a chip taken off")
	p.clear_all()
	ok(p.changes() == {clear = true} and p._count.text == "Changes: 1 / 3" and p._vibe.picked.is_empty(), "held Clear: everything off, as one change")
	p.free()


func test_traits() -> void:
	var u := v(1)
	for s in Unit.CORE.slice(0, 6):
		u.set(s, 16)
	ok(Perception.traits(u, {}) == ["Imposing", "Charming"], "strong all round, and charming")
	for s in Unit.CORE.slice(0, 6):
		u.set(s, 6)
	ok(Perception.traits(u, {}) == ["Insignificant", "Nervous"], "weak all round, and nervous")
	for s in Unit.CORE.slice(0, 6):
		u.set(s, 10)
	ok(Perception.traits(u, {}) == ["Average"], "even and unremarkable")
	u.strength = 17
	ok(Perception.traits(u, {}) == ["Strong"], "one stat stands out")
	ok(Perception.traits(u, {&"intelligence": 2.0}) == ["Smart"], "as they seem (an int that seems doubled)")


func test_gullible() -> void:
	v(1).afflict(effect("persona", 1), 9)
	v(3).wisdom = 6
	ok(not b.read(v(3), v(1)).deceived, "wis mod -2: an enemy's front needs trickery")
	v(3).wisdom = 4
	ok(b.read(v(3), v(1)).deceived and b.read(v(3), v(1)).twist == 0.0, "wis mod -3: it falls for the front alone")


func test_ally_kit() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	ok(h.skill_sense(v(1), strike, null) == 2, "the leader knows its own skills")
	ok(h.skill_sense(v(2), strike, h.view(v(2))) == 1, "an ally's, by name: allies tell each other what they can do")
	v(2).afflict(effect("luck", 1), 9)
	ok(h._info(v(2)).effects.is_empty(), "net 0: it misses effects altogether")
	v(1).afflict(effect("recon", 1), 9)
	var e: Array = h._info(v(2)).effects
	ok(e.size() == 1 and e[0][0] == "?", "net 1: something's on it, not what")
	v(1).timed.clear()
	v(1).afflict(effect("recon", 3), 9)
	ok(h.skill_sense(v(2), strike, h.view(v(2))) == 2 and h._info(v(2)).effects[0][0] != "?", "net 3: the details")
	v(1).timed.clear()
	v(1).wisdom = 8
	ok(h.skill_sense(v(2), strike, h.view(v(2))) == 0, "an unperceptive leader misses its skills wholly")
	h.select(v(2))
	h.use_slot(0)
	ok(h.armed == null, "and can't order them used")
	h.free()


func test_own_panel() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	var mine := h._info(v(1))
	ok(mine.chips[0][0] == "Leader" and mine.rows[0][1] == v(1).hp, "the leader knows itself")
	v(1).wisdom = 8
	var ally := h._info(v(2))
	ok(ally.rows[0][1] == "Healthy" and ally.chips.any(func(c): return c[0] == Perception.traits(v(2), {})[0]),
			"a low-wisdom leader sees its ally as it reads it: healthy, a word, no numbers")
	ok(ally.rows.any(func(row): return row[0] == "AP"), "but knows what it has left to follow orders with")
	h.free()
