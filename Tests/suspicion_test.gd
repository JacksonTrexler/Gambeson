extends Test

# Suspicion (Battle.suspect()): stacks a unit builds on another that fools it, each seeing through a
# rank of that one's trickery and concealment - for it alone - and any breaking a front. Units fooled
# by an enemy they can place look harder as their turn starts, and when it hurts them with a hostile
# skill (Battle.doubt()): d20 + wis mod against its d20 + cha mod + persona (to allies) or trickery (to
# enemies) - dissonance. Suspicious tiles - a hint of a hidden trap or unit - are inspected the first
# time they're seen and when resting within wis mod tiles, the mod less a point a tile (Battle.inspect()).
# Sing lands on the nearest rank units: the enraptured walk in, and on suspicious ones it works away at
# their suspicion (Battle._lured()).

var sing: Skill = load("res://Skills/sing.tres")
var rake: Skill = load("res://Skills/rake.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func test_stacks() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(5, 4), v(3): Vector2i(2, 6)})
	var trick := Perception.trickery(siren(), Read.new(), v(1), b)
	v(1).charisma = 1  # too poor a talker to pass the word on (Battle.spread(): word_test)
	b.suspect(v(1), siren())
	ok(v(1).suspects(siren()) == 1 and is_equal_approx(Perception.trickery(siren(), Read.new(), v(1), b), trick - 1.0)
			and is_equal_approx(Perception.trickery(siren(), Read.new(), v(2), b), trick), "a stack sees through a rank of the Siren's trickery, for v(1) alone")
	v(3).afflict(effect("concealment", 2), 9)
	var net := b.read(v(1), v(3)).net
	b.suspect(v(1), v(3))
	ok(b.read(v(1), v(3)).net == net + 1 and b.read(v(2), v(3)).net == net, "and a rank of a hidden one's concealment")
	b.suspect(v(1), v(3), -1)
	ok(v(3) not in v(1).suspicion, "none left: it trusts it again")


func test_breaks_fronts() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(2).afflict(effect("persona", 1), 9)
	v(1).wisdom = 10
	ok(b.read(v(1), v(2)).deceived, "an ally's front fools it")
	b.suspect(v(1), v(2))
	ok(not b.read(v(1), v(2)).deceived, "suspicious of it: it doesn't")


func test_doubt() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(8, 5)})
	var looks := []
	b.doubted.connect(func(by: Unit, of: Unit, total: int, against: int): looks.append([by, of, total, against]))
	ok(b.read(v(2), siren()).deceived, "enraptured")
	v(2).max_hp = 99
	v(2).hp = 99
	v(2).charisma = 1  # keeps what it sees through to itself (Battle.spread())
	siren().strength = 40
	siren().refresh()
	ok(b.cast(siren(), rake, v(2)) and v(2).hp < 99 and looks.size() == 1 and looks[0][0] == v(2), "raked by what fools it: it looks harder")
	ok(b.cast(siren(), sing, siren()) and looks.size() == 1, "sung to: it takes it for support")
	v(1).wisdom = 60
	b.end_turn()  # Lancin's turn starts
	ok(looks.any(func(l: Array): return l[0] == v(1) and l[1] == siren()) and v(1).suspects(siren()) == 1,
			"as its turn starts, the enraptured look harder at what fools them, and grow suspicious")
	v(1).wisdom = 1
	siren().extra_dissonance = 99
	ok(b.doubt(v(1), siren()), "a lie about a lot is a less believable one: easy to doubt")
	siren().extra_dissonance = 0
	siren().charisma = 60
	ok(not b.doubt(v(1), siren()), "a believable one, told well: not")


func test_sing_resisted() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6)})
	var contests := []
	b.contested.connect(func(_c: Unit, t: Unit, total: int, against: int): contests.append([t, total, against]))
	ok(b.cast(siren(), sing, siren()) and contests.is_empty() and v(1).cell == Vector2i(6, 6), "enraptured: it takes the song for support, and doesn't resist")
	b.suspect(v(1), siren())
	v(1).wisdom = 60
	ok(b.cast(siren(), sing, siren()) and contests.size() == 1 and v(1).cell == Vector2i(6, 6) and v(1).suspects(siren()) == 1,
			"suspicious: it won't walk in, and it holds onto its suspicion, wis against cha")
	v(1).wisdom = 1
	siren().charisma = 60
	siren().refresh()
	ok(b.cast(siren(), sing, siren()) and contests.size() == 2 and v(1).cell == Vector2i(6, 6) and v(1).suspects(siren()) == 0,
			"failing, it loses its suspicion - but doesn't walk in yet")
	siren().refresh()
	ok(b.cast(siren(), sing, siren()) and contests.size() == 2 and v(1).cell == Vector2i(7, 6), "enraptured again: the next song draws it in")
	b.move(v(1), Vector2i(5, 6))
	v(1).wisdom = 10  # not so gullible that a front alone fools it
	v(1).afflict(effect("recon", 5), 9)
	siren().refresh()
	ok(not b.read(v(1), siren()).deceived and b.cast(siren(), sing, siren()) and contests.size() == 2 and v(1).cell == Vector2i(5, 6),
			"one that sees it for what it is won't come, with no suspicion to work on")
	v(1).timed.clear()
	v(1).wisdom = 1
	siren().stance = "Passive"
	siren().refresh()
	siren().energy = siren().max_energy
	ok(b.read(v(1), siren()).deceived and b.read(v(1), siren()).attitude(v(1)) == &"ignore" and b.cast(siren(), sing, siren()) and v(1).cell == Vector2i(5, 6),
			"fooled, but not convinced it's an ally (it seems Passive): it won't come either")


func test_inspect() -> void:
	var trap := Vector2i(5, 4)  # the museum's spike trap
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	ok(b.read(v(1), trap).hint != "" and trap in b.suspicious(v(1)), "a hint of something at the trap: suspicious")
	var looks := []
	b.inspected.connect(func(by: Unit, at: Vector2i, total: int, against: int):
		if by == v(1):
			looks.append([by, at, total, against]))
	v(1).noticed.clear()
	v(1).wisdom = 60
	b._first_look(v(1))
	ok(looks.size() == 1 and looks[0][1] == trap and v(1).suspects(trap) == 1 and trap in v(1).noticed, "the first time it sees it, it inspects it")
	ok(b.read(v(1), trap).net == -1, "a stack: a rank of the trap's concealment seen through")
	ok(looks[0][2] <= 25 + 20 - 4 and looks[0][2] >= 25 + 1 - 4, "wis mod 25, less a point for each of the 4 tiles (%d)" % looks[0][2])
	b._first_look(v(1))
	ok(looks.size() == 1, "only the first time")
	v(1).wisdom = 14
	b.end_turn()
	b.end_turn()
	ok(looks.size() == 1, "its turn ends beyond its wis mod (2) + a turn rested in tiles (%d): no look" % Command.tiles(v(1).cell, trap))
	v(1).wisdom = 60
	b.move(v(1), Vector2i(4, 4))
	v(1).refresh()
	b.end_turn()
	ok(looks.size() == 2 and v(1).suspects(trap) == 2 and b.read(v(1), trap).net == 0, "resting beside it: another look, another stack - now it knows it for a trap")
	v(3).afflict(effect("concealment", 2), 9)
	b.end_turn()
	v(1).noticed.clear()
	v(1).suspicion.clear()
	b.move(v(3), Vector2i(1, 4))
	ok(b.read(v(1), v(3)).hint != "", "a vague shape")
	ok(b.inspect(v(1), v(3).cell) and v(1).suspects(Vector2i(1, 4)) == 1 and v(1).suspects(v(3)) == 1, "a hidden unit: suspicious of it, and of its tile")


func test_traitor() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 3), v(3): Vector2i(2, 2), v(4): Vector2i(8, 5)})
	b.player = v(1)
	var command := Command.new(b, v(1))
	v(3).afflict(effect("persona", 3), 99)
	v(3).afflict(effect("trickery", 5), 99)
	v(3).stance = "Traitor"
	v(1).charisma = 14
	v(3).refresh()  # what its own side's turn left it
	ok(b.read(v(1), v(3)).attitude(v(1)) == &"ally" and b.teammates(v(1), v(3)), "a Traitor that fools the leader: teammates, as far as it lets on")
	ok(command.join(v(3)) and b.posing(v(3)) and command.can_order(v(3)), "it joins the party, and takes orders on the leader's turn")
	var doubts := []
	b.doubted.connect(func(by: Unit, of: Unit, total: int, against: int): doubts.append([by, of, total, against]))
	var refusals := []
	b.refused.connect(func(u: Unit, lead: Unit): refusals.append([u, lead]))
	ok(b.travel(v(3), Vector2i(2, 1)).size() == 1, "a move order: it goes along with it")
	var ap := v(3).ap_left()
	v(3).charisma = 8
	ok(not b.cast(v(3), strike, v(4)) and refusals.size() == 1 and doubts.size() == 1 and doubts[0][0] == v(1) and v(3).ap_left() == ap,
			"told to strike its real ally: it refuses, and the leader looks harder (at advantage)")
	v(3).charisma = 14
	var hp := v(4).hp
	b.move(v(4), Vector2i(3, 1))
	ok(b.cast(v(3), strike, v(4)) and v(4).hp == hp and doubts.size() == 2 and v(3).ap_left() < ap, "a charming one goes along, and misses on purpose: the leader looks harder")
	b.end_turn()  # Nemes: its own side's turn
	ok(b.turn == nemes and v(3).ap_left() > 0, "its own side's turn: fresh AP")
	b.travel(v(3), Vector2i(3, 2))
	b.end_turn()
	ok(refusals.size() == 2, "it didn't rest on its own side's turn: as good as refusing an order")
	v(1).suspicion[v(3)] = 9
	command.new_turn()
	ok(v(3) not in command.party and v(3).follows == null, "seen through: it's out of the party")


# A traitor whiffing on purpose hardly arouses suspicion: its leader looks harder at disadvantage.
func test_whiff_disadvantage() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(2, 2)})
	v(3).afflict(effect("trickery", 2), 99)
	var tally := func(edge: int) -> int:
		var n := 0
		for i in 400:
			v(1).suspicion.clear()
			n += int(b.doubt(v(1), v(3), edge))
		return n
	var worse: int = tally.call(-1)
	var plain: int = tally.call(0)
	var better: int = tally.call(1)
	ok(worse < plain and plain < better, "the worse of two, one, the better of two: %d < %d < %d (of 400)" % [worse, plain, better])


func test_shown() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	b.player = v(1)
	v(1).wisdom = 10
	v(2).charisma = 10  # cha 8 would make it hard for v(1) to read
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	var sus := func(icons: Array) -> bool: return icons.any(func(x: Array): return x[0] is Texture2D and x[2].begins_with("Suspicious"))
	b.suspect(v(1), v(3))
	ok(sus.call(h._info(v(1)).effects), "the leader's card: Suspicious, a buff")
	b.suspect(v(2), v(3))
	ok(not sus.call(h._info(v(2)).effects), "an ally's, not until its side makes out its effects")
	v(1).afflict(effect("recon", 3), 9)
	ok(sus.call(h._info(v(2)).effects), "net 3: there")
	b.discovered.emit(v(2), v(3))
	b.struggled.emit(v(2), v(3), 5, 12)
	b.gripped.emit(v(2), v(3), 7)
	b.stalled.emit(v(3), 2)
	var text: String = h.log_box.get_parsed_text()
	ok("%s ? %s\n" % [v(2).name, h.known_name(v(2), v(3))] in text, "the log: an ally finds something odd about it (%s)" % text)
	ok("breaks free -x> " in text and " (5)\n" in text, "a grip it can't break, the holder's roll dropped (%s)" % text)
	ok(" --> %s -7" % v(2).name in text or " --> %s\n" % v(2).name in text, "and what it takes")
	ok("Ramut's Ire II --> " in text, "Ramut's Ire building")
	h.free()
