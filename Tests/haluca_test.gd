extends Test

# Haluca (a Warlock's earth spell): the foe saves (wis) or sees everyone's tags scrambled for cha mod
# + rank turns; investigating an ally may set that one straight (Battle.inspect(): untangled). And
# reading allies: a negative cha mod of the one read counts against the reader's wis mod
# (Perception._dim()).

var haluca: Skill = load("res://Skills/haluca.tres")


func caster() -> void:
	v(3).charisma = 20  # mod 5: range 5 + rank, 5 + rank turns
	v(3).learned.append(slot(haluca, 1))
	v(3).refresh()


func test_scrambled() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(1, 1), v(2): Vector2i(2, 1)})
	caster()
	ok(b.skill_range(v(3), haluca) >= 6.0 and not haluca.attacks(), "range cha mod + rank; no attack roll")
	v(1).wisdom = 1  # mod -5: it fails, sooner or later
	var tries := 0
	while v(1).scrambled() == null and tries < 20:
		v(3).refresh()
		b.cast(v(3), haluca, v(1))
		tries += 1
	var a := v(1).scrambled()
	ok(a != null and a.turns == 5 + 1 and a.roll > 0, "failed its save: scrambled for 5 + 1 turns, against the caster's roll")
	v(1).wisdom = 12
	v(1).afflict(effect("recon", 1), 9)
	var seen := b.read(v(1), v(2)).tags
	ok(not seen.is_empty() and seen == b.read(v(1), v(2)).tags, "an ally's tags, scrambled, the same each look: %s" % [seen])
	ok(v(2).cell in b.suspicious(v(1)), "something's off about it: worth a look")
	a.roll = 99
	ok(not b.inspect(v(1), v(2).cell) and v(1).scrambles(v(2)), "investigated, not seen straight")
	a.roll = 0
	var logged := []
	b.untangled.connect(func(by: Unit, of: Unit, _t: int, _a: int): logged.append([by, of]))
	ok(b.inspect(v(1), v(2).cell) and not v(1).scrambles(v(2)) and b.read(v(1), v(2)).tags != seen, "seen straight: %s" % [b.read(v(1), v(2)).tags])
	ok(logged == [[v(1), v(2)]] and v(2).cell not in b.suspicious(v(1)), "logged, and no longer suspicious")
	ok(v(1).scrambles(v(3)), "everyone else: still scrambled")


func test_saved() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	caster()
	v(3).charisma = 1  # mod -5: range 1 at least
	v(1).wisdom = 42  # mod 16: beats anything the caster rolls
	ok(b.cast(v(3), haluca, v(1)) and v(1).scrambled() == null, "a passed save: nothing")
	ok("The foe saves: d20 + wis mod against d20 + cha mod + 1" in haluca.describe(1) and "for cha mod + 1 turns" in haluca.describe(1), haluca.describe(1))


func test_hard_to_read() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(2, 1)})
	ok(b.read(v(1), v(2)).hp != null, "wis +1, reading cha -1 (villagers): 0, as recon shows")
	v(2).charisma = 6  # mod -2
	ok(b.read(v(1), v(2)).hp == null and b.read(v(1), v(2)).traits.size() > 0, "cha -2: hard to read - only a word or two for it")
	v(1).wisdom = 8
	v(2).charisma = 18
	ok(b.read(v(1), v(2)).hp == null, "high cha doesn't make up for a reader's low wis")
