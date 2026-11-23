extends Test

# Self-help books (Items/*.tres with the `book` tag; Battle.study(), HUD._read(), Bio.tweaked()) and the tempers they teach
# (Compliant: AI._orders(), Hungry: AI._hungry(), Pragmatic: heals by cost). Data-driven: every readable item in Items/ is a row.

var transfer: Skill = load("res://Skills/energy_transfer.tres")


func books() -> Array[Item]:
	var out: Array[Item] = []
	for f in ResourceLoader.list_directory("res://Items/"):
		var it := load("res://Items/" + f) as Item
		if it and it.readable():
			out.append(it)
	return out


# v(1) with the check bonus `cha` on charisma checks, `mind` on intelligence ones (a huge one makes a check a sure thing either way).
func reader(cha: int, mind: int) -> Unit:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(1).timed.clear()
	for pair in [[&"charisma", cha], [&"intelligence", mind]]:
		var e := effect("check", pair[1])
		e.checks = [pair[0]] as Array[StringName]
		v(1).afflict(e, 9)
	v(1).refresh()
	return v(1)


# Reading, through the HUD: both medium checks (cha, int) must pass to be offered the book's changes; the book is used up either way; the
# player's pick lands in the bio (a copy: the scene's shared one is untouched); a fail takes the book and changes nothing.
func test_read() -> void:
	var all := books()
	ok(all.size() >= 4, "the four books are readable (%d)" % all.size())
	var h := await hud(v(1))
	for row in [[40, 40, true], [-40, 40, false], [40, -40, false]]:
		for book in all if row[2] else all.slice(0, 1):
			for pick in book.tweaks().size() if row[2] else 1:
				var u := reader(row[0], row[1])
				u.bio = null
				Game.stash.assign([book])
				h._on_used_up(u, book)
				ok(book not in Game.stash, "%s: used up, passed or not (%s)" % [book.name, row])
				var panel := h.get_node_or_null("../Choice")
				panel = panel if panel else h.settings.get_parent().get_node_or_null("Choice")
				ok((panel != null) == row[2], "%s: offered its changes only on passing both checks (%s)" % [book.name, row])
				if panel:
					var buttons := panel.find_children("*", "Button", true, false).filter(func(x: Button): return x.text != "Cancel")
					ok(buttons.size() == book.tweaks().size(), "%s: a button a change (%d)" % [book.name, buttons.size()])
					buttons[pick].pressed.emit()
					ok(Bio.holds(u.bio, book.tweaks()[pick]), "%s: took %s" % [book.name, book.tweaks()[pick].label])
					panel.free()
				else:
					ok(u.bio == null, "%s: a fail changes nothing" % book.name)
	h.free()
	Game.stash.clear()


# A tweak lands on a copy (a scene's bio is shared), a behaviour as the lead temper or one more, a god as its prayer and a lean toward its
# domain; the player's bio is kept in its roster entry; an AI unit takes the first it lacks.
func test_tweaks() -> void:
	var shared := Bio.new()
	shared.behaviour = &"brave"
	var gal: Item = load("res://Items/applied_charizzmatics.tres")
	var offered := gal.tweaks()
	var u := v(1)
	u.bio = shared
	u.tweak(offered[0])
	ok(u.bio != shared and shared.also.is_empty() and u.bio.behaviour == &"brave" and u.tempered(&"flirty"), "a copy: brave stays lead, flirty beside it")
	u.tweak(offered[2])
	ok(u.deity() == &"eros" or u.role.god, "its god: Eros, or the one its class serves (%s)" % u.deity())
	u.role = null
	ok(u.deity() == &"eros" and u.fancy(offered) == offered[1], "no god of its own: Eros; it takes the one it lacks (%s)" % [u.fancy(offered)])
	var kept := Bio.from_kept(u.bio.kept())
	ok(kept.behaviour == &"brave" and kept.also == [&"flirty"] and kept.favours == [&"eros"], "kept as plain words and back")
	ok(books().all(func(it: Item): return it.temper in Bio.BEHAVIOURS and (not it.favours or God.of(it.favours))), "every book teaches a known temper and god")


# Compliant: it wants whom its leader is after (the leader's aim), and, the leader having none, a foe at the leader's side by half.
func test_compliant() -> void:
	stage(lancin, {v(1): Vector2i(1, 5), v(2): Vector2i(2, 5), v(3): Vector2i(3, 4), v(4): Vector2i(5, 5)})
	var u := v(2)
	u.follows = v(1)
	sharp(u)
	u.bio = Bio.new()
	var reads := AI._reads(b, u)
	ok(AI._best_target(u, reads) == v(3) and AI._orders(u, v(4)) == 0.0, "not compliant: the nearest foe, no orders")
	u.bio.behaviour = &"compliant"
	ok(AI._orders(u, v(3)) == AI.ORDERED / 2.0 and AI._orders(u, v(4)) == 0.0, "no aim yet: half for the foe at its leader's side")
	v(1).set_meta(&"aim", v(4))
	ok(AI._orders(u, v(4)) == AI.ORDERED and AI._orders(u, v(3)) == 0.0 and AI._best_target(u, reads) == v(4), "its leader's aim: wanted most, over the nearer foe")
	v(1).remove_meta(&"aim")
	v(1).follows = null


# Hungry: a skill tagged siphon (or drain) is worth more as much more as the target has to give and the likelier it lands (low Defense);
# any other skill, or any other temper, is as it was.
func test_hungry() -> void:
	v(1).learned.append(slot(transfer, 1)); v(1).sync_bar()
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3), v(4): Vector2i(4, 4)})
	sharp(v(1))
	v(1).refresh()
	for t in [v(3), v(4)]:
		t.max_energy = 30
		t.energy = 30
	v(4).afflict(effect("defense", 8), 9)  # armoured: the bolt lands less
	var worth := func(t: Unit, s: Skill) -> float: return AI._hungry(b, v(1), s, b.read(v(1), t), t, 0.0)
	ok(worth.call(v(3), transfer) == 0.0, "not hungry: nothing added")
	v(1).bio = Bio.new()
	v(1).bio.behaviour = &"hungry"
	var soft: float = worth.call(v(3), transfer)
	var hard: float = worth.call(v(4), transfer)
	ok(soft > hard and hard > 0.0, "hungry: a siphon is worth more on the one it lands on (%.2f vs %.2f)" % [soft, hard])
	ok(worth.call(v(3), strike) == 0.0, "a plain strike: nothing added")
	v(3).energy = 0
	ok(worth.call(v(3), transfer) == 0.0, "nothing left to siphon: nothing added")
	ok(v(1).tempered(&"hungry") and AI._hunted(v(1), v(3), b.read(v(1), v(3))) == 0.0, "no orders, no hunger of the Power kind")
