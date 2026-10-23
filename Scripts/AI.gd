class_name AI

# Plays a unit's turn from what it perceives, not the truth. It never strikes a unit it reads as
# an ally (sparing the beloved), takes the hit worth most - perceived damage, a likely kill, an
# ominous aura (the hated) - and walks around ground it knows or suspects is bad. With no foe in
# sight it goes to look at whatever doesn't add up, and holds still there to look harder.
# Ambushers (the Siren) hold their ground until something hits them: drowning or raking whoever is
# beside them, luring the fooled over, singing at those onto them.
# Kept small on purpose: score() and the move choice are the places to grow it.

const KILL := 5.0  # bonus for a hit that should finish the target
const HATE := 2.0  # per point of ominous aura
const GUESS_HP := 10.0  # when it can't make out a target's HP


static func act(b: Battle, u: Unit) -> Array[String]:
	var log: Array[String] = []
	if not u.is_alive():
		return log
	var reads := {}
	for o in b.units.values():
		if o != u:
			reads[o] = b.read(u, o)
	if u.ai == "ambusher" and not u.provoked:
		_lie_in_wait(b, u, reads, log)
		return log
	_support(b, u, reads, log)
	if not _strike(b, u, reads, log) and not _sing(b, u, reads, log):
		var target := _best_target(u, reads)
		if target:
			var p := b.travel(u, _approach(b, u, reads[target].cell))
			log.append("%s moves %s" % [u.name, p])
			reads[target] = b.read(u, target)
		else:
			_look_into(b, u, reads, log)
	while _strike(b, u, reads, log):
		pass
	return log


# An unmade ambusher stays put: whoever is beside it gets drowned (if there's water close enough to
# drag them to) or raked; failing that it lures the fooled over, or sings at those onto it.
static func _lie_in_wait(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	var near := reads.keys().filter(func(t): return _foe(u, reads[t]) and Battle.steps(u.cell, t.cell) <= 1)
	var grabs := u.actives.filter(func(s: Skill): return s.drown)
	var claws := u.actives.filter(func(s: Skill): return s.crit_trusting)
	for t in near:
		var water: bool = &"water" in t.ground or b.pool_near(t.cell, floori(u.stat(&"movement") - u.moved)) != null
		for s in (grabs if water else []) + claws:  # drown when water's close, otherwise rake
			if b.cast(u, s, t):
				log.append("%s uses %s on %s -> %d" % [u.name, s.name, t.name, t.hp])
				return
	if not _sing(b, u, reads, log, true):
		_sing(b, u, reads, log)


# Sing at the nearest foe in reach that it's fooling (to lure it over), or that has seen through
# it (to scrub that).
static func _sing(b: Battle, u: Unit, reads: Dictionary, log: Array[String], fooled := false) -> bool:
	var foes := reads.keys().filter(func(t): return _foe(u, reads[t]) and b.read(t, u).deceived == fooled)
	foes.sort_custom(func(x, y): return Battle.dist(u.cell, x.cell) < Battle.dist(u.cell, y.cell))
	for s in u.actives.filter(func(x: Skill): return x.sing):
		for t in foes:
			if b.in_reach(u, s, t) and b.cast(u, s, t):
				log.append("%s sings at %s, now at %s" % [u.name, t.name, t.cell])
				return true
	return false


# Nothing to fight: walk up to something that doesn't add up - a unit it can't place (even just an
# area of suspicion), or an "ally" that isn't on its own roster (every side knows its own) - and stop
# within investigation range, so holding still there looks harder.
static func _look_into(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	var odd: Unit = null
	var spot := Vector2i.ZERO
	for t in reads:
		var r: Read = reads[t]
		var where: Variant = r.cell if r.located() else (r.area[r.area.size() / 2] if not r.area.is_empty() else null)  # its middle
		var strange: bool = where != null and (r.faction == null or (r.faction == u.faction and t.faction != u.faction))
		if strange and (odd == null or Battle.dist(u.cell, where) < Battle.dist(u.cell, spot)):
			odd = t
			spot = where
	if odd and Battle.dist(u.cell, spot) > u.investigation() + 0.0001:
		var p := b.travel(u, _approach(b, u, spot))
		log.append("%s goes to look at %s %s" % [u.name, odd.name, p])


# Perceived worth of using a hostile skill on a unit read as `r`.
static func score(u: Unit, s: Skill, r: Read) -> float:
	var t := s.tier(u.rank(s))
	var dmg := 0.0
	if t:
		dmg = (t.power + t.dice.x * (t.dice.y + 1) / 2.0 + (u.mod(t.stat, s.tags) if t.stat else 0)) * (u.rank(s) if s.hits_per_rank else 1)
	var hp: float = r.hp if r.hp != null else GUESS_HP
	var value := minf(dmg, hp) + (KILL if dmg >= hp else 0.0) + (1.0 if not s.effects.is_empty() else 0.0)
	return value - _hate(r)


static func _hate(r: Read) -> float:
	return HATE * (r.aura if r.aura != null else 0)


static func _foe(u: Unit, r: Read) -> bool:
	return r.located() and r.faction != null and r.faction != u.faction


# Casts the best damaging or afflicting skill it can right now; false if nothing is in reach and
# affordable.
static func _strike(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var best := []
	var best_score := 0.0
	for s in u.actives.filter(func(x: Skill): return x.hostile and (not x.tiers.is_empty() or not x.effects.is_empty())):
		for t in reads:
			var r: Read = reads[t]
			if not _foe(u, r) or not t.is_alive() or not b.in_reach(u, s, t) or not u.can_afford(s):
				continue
			var v := score(u, s, r) - (1.0 if not s.effects.is_empty() and s.effects[0] in r.effects else 0.0)
			if v > best_score:
				best = [s, t]
				best_score = v
	if best.is_empty():
		return false
	b.cast(u, best[0], best[1])
	log.append("%s uses %s on %s -> %d" % [u.name, best[0].name, best[1].name, best[1].hp])
	reads[best[1]] = b.read(u, best[1])
	return true


# Support skills (Stonegift) on allies it reads as allies and that don't have the effect yet.
static func _support(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return not x.hostile and x.grants):
		for t in reads:
			var r: Read = reads[t]
			if r.faction == u.faction and s.grants.effects[0] not in r.effects and b.cast(u, s, t):
				log.append("%s gives %s to %s" % [u.name, s.name, t.name])
				return


static func _best_target(u: Unit, reads: Dictionary) -> Unit:
	var best: Unit = null
	var best_score := -INF
	for t in reads:
		if not _foe(u, reads[t]):
			continue
		var v: float = -Battle.dist(u.cell, reads[t].cell) - _hate(reads[t])
		if v > best_score:
			best = t
			best_score = v
	return best


# Where to head for a target: a cell beside it (side-on first: diagonals can be near misses) whose
# path crosses the least ground it knows or suspects is bad, then the nearest. Never where it
# already stands. Planning mustn't use up the battle's rng, so it's restored.
static func _approach(b: Battle, u: Unit, at: Vector2i) -> Vector2i:
	var state := b.rng.state
	var best: Vector2i = at
	var best_cost := INF
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c: Vector2i = at + Vector2i(dx, dy)
			if c == at or c == u.cell or not b.on_map(c) or b.unit_at(c):
				continue
			var risk := 0
			for p in b.line(u.cell, c, u.luck, u):
				var tr := b.read(u, p)
				risk += int(tr.known_bad() or tr.hint != "")
			var v := risk * 10.0 + Battle.dist(u.cell, c) + (0.5 if dx and dy else 0.0)
			if v < best_cost:
				best = c
				best_cost = v
	b.rng.state = state
	return best
