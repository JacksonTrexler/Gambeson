class_name Investigation

# Wisdom checks that see through concealment and trickery. A unit checks on coming into range of
# something new, again at the end of a turn it held still, and for free when something it can't
# make out attacks it. A pass earns suspicion of that area for the rest of the battle.

# DC to see through what hides `target` from `u`: 10 + hidden levels + the hider's dex mod for
# units, 10 + 2 x hidden levels for tiles.
static func dc(b: Battle, u: Unit, target: Variant) -> int:
	var hidden := maxi(-b.read(u, target).net, 0)
	return Battle.DC + (hidden + target.mod(&"dexterity") if target is Unit else hidden * 2)


# Checks `target` (or the nearest lead); see succeed() for what a pass earns.
static func run(b: Battle, u: Unit, target: Variant = null) -> bool:
	if target == null:
		target = lead(b, u)
		if target == null:
			return false
	if not b.check(u, dc(b, u, target)):
		return false
	succeed(b, u, target)
	return true


# A passed observation: max(1, wis mod - distance) levels of suspicion on that area; Detective adds
# its rank in recon on the target itself; a positive cha mod passes a level of suspicion on to that
# many allies within that many tiles.
static func succeed(b: Battle, u: Unit, target: Variant) -> void:
	var c: Vector2i = target.cell if target is Unit else target
	u.suspect(c, maxi(u.mod(&"wisdom") - floori(Battle.dist(u.cell, c)), 1))
	var detective := roundi(u.stat(&"detective"))
	if detective > 0:
		u.marks[target] = u.marks.get(target, 0) + detective
	var m := u.mod(&"charisma")
	if m > 0:
		var near := b.members(u.faction).filter(func(a): return a != u and Battle.dist(a.cell, u.cell) <= m + 0.0001)
		near.sort_custom(func(x, y): return Battle.dist(x.cell, u.cell) < Battle.dist(y.cell, u.cell))
		for a in near.slice(0, m):
			a.suspect(c, 1)


# The nearest thing within investigation range that `u` can tell is obscured: an enemy or tile it
# can only partly make out (net -3..-1), or a unit fooling it. A Detective also observes what isn't
# concealed: units it can't fully read yet, and tiles it hasn't marked. Its own side and its own
# tile don't count (every side knows its own). Null if there's none.
static func lead(b: Battle, u: Unit) -> Variant:
	var span := u.investigation()
	var detective := u.stat(&"detective") > 0
	var found := []
	for o in b.units.values():
		if o.faction != u.faction and Battle.dist(o.cell, u.cell) <= span + 0.0001:
			var r := b.read(u, o)
			if (r.net < 0 and r.net > -4) or r.deceived or (detective and r.net >= 0 and r.net < 3):
				found.append(o)
	var n := floori(span)
	for x in range(u.cell.x - n, u.cell.x + n + 1):
		for y in range(u.cell.y - n, u.cell.y + n + 1):
			var c := Vector2i(x, y)
			if c == u.cell or not b.on_map(c) or Battle.dist(c, u.cell) > span + 0.0001:
				continue
			var r := b.read(u, c)
			if r.net < 0 and r.net > -4 and (b.hidden(c) or b.zones.any(func(z): return c in z.levels)):
				found.append(c)
			elif detective and r.net == 0 and c not in u.marks:
				found.append(c)
	if found.is_empty():
		return null
	var at := func(x) -> Vector2i: return x.cell if x is Unit else x
	return b.contest(found, [func(x) -> float: return -snappedf(Battle.dist(at.call(x), u.cell), 0.0001)])[0]
