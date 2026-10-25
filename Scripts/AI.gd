class_name AI

# Plays a unit's turn from what it perceives, not the truth. It never strikes a unit it reads as
# an ally (sparing the beloved), takes the hit worth most - perceived damage, a likely kill, an
# ominous aura (the hated) - and walks around ground it knows or suspects is bad.
# Kept small on purpose: score() and the move choice are the places to grow it.

const KILL := 5.0  # bonus for a hit that should finish the target
const HATE := 2.0  # per point of ominous aura
const GUESS_HP := 10.0  # when it can't make out a target's HP


static func act(b: Battle, u: Unit) -> Array[String]:
	var log: Array[String] = []
	if not u.is_alive() or u.asleep():
		return log
	var reads := {}
	for o in b.units.values():
		if o != u:
			reads[o] = b.read(u, o)
	_support(b, u, reads, log)
	if not _strike(b, u, reads, log):
		var target := _best_target(u, reads)
		if target:
			var p := b.travel(u, _approach(b, u, target, reads[target]))
			log.append("%s moves %s" % [u.name, p])
			reads[target] = b.read(u, target)
	while _strike(b, u, reads, log):
		pass
	return log


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


# Casts the best hostile skill it can right now; false if nothing is in reach and affordable.
static func _strike(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var best := []
	var best_score := 0.0
	for s in u.actives.filter(func(x: Skill): return x.hostile and x.zone == &""):
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
	if not b.cast(u, best[0], best[1]):
		return false
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
		var v: float = -Vector2(u.cell).distance_to(Vector2(reads[t].cell)) - _hate(reads[t])
		if v > best_score:
			best = t
			best_score = v
	return best


# Where to head for a target: a cell beside it (side-on first: diagonals can be near misses) whose
# path crosses the least ground it knows or suspects is bad, then the nearest. Never where it
# already stands. Planning mustn't use up the battle's rng, so it's restored.
static func _approach(b: Battle, u: Unit, t: Unit, r: Read) -> Vector2i:
	var state := b.rng.state
	var best: Vector2i = r.cell
	var best_cost := INF
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c: Vector2i = r.cell + Vector2i(dx, dy)
			if c == r.cell or c == u.cell or not b.on_map(c) or b.unit_at(c):
				continue
			var risk := 0
			for p in b.line(u.cell, c, u.luck, u):
				var tr := b.read(u, p)
				risk += int(tr.known_bad() or tr.hint != "")
			var v := risk * 10.0 + Vector2(u.cell).distance_to(Vector2(c)) + (0.5 if dx and dy else 0.0)
			if v < best_cost:
				best = c
				best_cost = v
	b.rng.state = state
	return best
