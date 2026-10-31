class_name AI

# Plays a unit's turn from what it perceives, not the truth. It never strikes a unit it reads as
# an ally (sparing the beloved), takes the hit worth most - perceived damage, a likely kill, an
# ominous aura (the hated) - and walks around ground it knows or suspects is bad. Units presenting
# as Aggressive it keeps clear of, and Passive ones it leaves be (Read.attitude()). A craven unit
# won't advance without an ally it reads as a higher level within CRAVEN_REACH tiles, and backs away
# from the Aggressive within that reach before anything else. A luring unit
# (the Siren) stays serene and still until an enemy sees through it: it sings, and whatever comes
# into its reach it drowns or rakes. Healers heal the ally they most want to, by how they tend. A
# held unit tries to break free by moving away, and its holder stays put rather than let go, unless
# the ground it stands on is bad. A traitor posing in another side's party plays along:
# on that side's turn it keeps up with its leader; on its own, it rests unless it can make a kill.
# With no foe to go after, a unit with Observe searches where the clues point.
# Kept small on purpose: score() and the move choice are the places to grow it.

const KILL := 5.0  # bonus for a hit that should finish the target
const HATE := 2.0  # per point of ominous aura
const GUESS_HP := 10.0  # when it can't make out a target's HP
const CRAVEN_REACH := 3  # tiles within which a craven unit wants a higher-level ally before it advances
const COMMANDER := 0.25  # how much most healers favour a commander
const PARTY := 1.0  # how much a loyal healer favours its party
const WOUND := 0.25  # how much a healer wants to clear a wound it can see
const WARY := 10.0  # cost of ending a walk beside a unit it takes for aggressive


static func act(b: Battle, u: Unit) -> Array[String]:
	var log: Array[String] = []
	if not u.is_alive() or u.asleep():
		return log
	var reads := {}
	for o in b.units.values():
		if o != u:
			reads[o] = b.read(u, o)
	if b.held_by(u):
		_escape(b, u, log)
	if b.posing(u):
		if b.turn == u.faction:
			_strike(b, u, reads, log, false, KILL)
		else:
			_keep_up(b, u, log)
		return log
	_heal(b, u, reads, log)
	_support(b, u, reads, log)
	var rooted := _rooted(b, u)
	if not rooted and _flee(b, u, reads, log):
		reads = {}
		for o in b.units.values():
			if o != u:
				reads[o] = b.read(u, o)
	if _luring(b, u, reads):
		if not _ambush(b, u, reads, log):
			_sing(b, u, reads, log)
		return log
	if not _strike(b, u, reads, log):
		var target := _best_target(u, reads)
		if target and _emboldened(u, reads) and not rooted:
			var p := b.travel(u, _approach(b, u, target, reads))
			log.append("%s moves %s" % [u.name, p])
			reads[target] = b.read(u, target)
		elif not target:
			_search(b, u, log)
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
	var value := minf(dmg, hp) + (KILL if dmg >= hp else 0.0) + (1.0 if s.hostile and not s.effects.is_empty() else 0.0) \
			+ (KILL if s.drags_to else 0.0)  # into the water: the Siren's favourite
	return value - _hate(r)


static func _hate(r: Read) -> float:
	return HATE * (r.aura if r.aura != null else 0)


static func _foe(u: Unit, r: Read) -> bool:
	return r.located() and r.attitude(u) == &"foe"


# Ready to advance: not craven, or an ally it takes for one is near, of a level it reads as higher
# (it must make out the level, or have it advertised: Persona II).
static func _emboldened(u: Unit, reads: Dictionary) -> bool:
	if u.behaviour != &"craven":
		return true
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and r.attitude(u) == &"ally" and r.level != null and r.level > u.level and Command.tiles(o.cell, u.cell) <= CRAVEN_REACH:
			return true
	return false


# A craven unit backs away from units it takes for aggressive within CRAVEN_REACH tiles: to the
# tile it can reach (as it expects the walk to go) furthest from the nearest of them. False if
# there's none near, or nowhere better.
static func _flee(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	if u.behaviour != &"craven":
		return false
	var scary: Array[Vector2i] = []
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and r.located() and r.attitude(u) == &"avoid" and Command.tiles(r.cell, u.cell) <= CRAVEN_REACH:
			scary.append(r.cell)
	if scary.is_empty():
		return false
	var gap := func(c: Vector2i) -> int:
		return scary.map(func(x: Vector2i): return Command.tiles(x, c)).min()
	var best := u.cell
	var reach := ceili(u.move_left())
	for dx in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			var c := u.cell + Vector2i(dx, dy)
			if c == u.cell or not b.on_map(c):
				continue
			var path: Array = b.walk(u, c, true).path
			if not path.is_empty() and gap.call(path[-1]) > gap.call(best):
				best = path[-1]
	if best == u.cell:
		return false
	var p := b.travel(u, best)
	log.append("%s backs away %s" % [u.name, p])
	return not p.is_empty()


# Casts the best hostile skill it can right now; false if nothing is in reach and affordable. The
# beloved are spared only while there are other foes to fight. attacks_only: skip dual skills (Sing).
# least: only a strike worth more than this (a traitor keeping its cover: a kill).
static func _strike(b: Battle, u: Unit, reads: Dictionary, log: Array[String], attacks_only := false, least := 0.0) -> bool:
	var best := []
	var best_score := least
	var spared := []
	for s in u.actives.filter(func(x: Skill): return x.for_foes() and not x.on_tile() and not x.auto and not (attacks_only and x.dual)):
		for t in reads:
			var r: Read = reads[t]
			if not _foe(u, r) or not t.is_alive() or not b.in_reach(u, s, t) or not u.can_afford(s):
				continue
			if s.drags_to and (b.drag_spot(u, s, t) == null or s.effects.any(func(e: Effect): return e in t.timed)):
				continue
			var v := score(u, s, r) - (1.0 if s.hostile and not s.effects.is_empty() and s.effects[0] in r.effects else 0.0)
			if v > best_score:
				best = [s, t]
				best_score = v
			elif spared.is_empty() and _hate(r) > 0.0:
				spared = [s, t]
	if best.is_empty() and not spared.is_empty() and reads.keys().all(
			func(t: Unit): return not t.is_alive() or not _foe(u, reads[t]) or _hate(reads[t]) > 0.0):
		best = spared
	if best.is_empty():
		return false
	if not b.cast(u, best[0], best[1]):
		return false
	log.append("%s uses %s on %s -> %d" % [u.name, best[0].name, best[1].name, best[1].hp])
	reads[best[1]] = b.read(u, best[1])
	return true


# With no foe to go after, it searches (Observe) where the clues point: the tile in reach whose look
# would take in the most of them - what it finds suspicious (Battle.suspicious()) and the debris enemies
# left hiding (Battle.evidence()) - nearest itself on a tie. No clues, no search: it can't know where
# to look.
static func _search(b: Battle, u: Unit, log: Array[String]) -> void:
	var clues := b.suspicious(u) + b.evidence(u)
	if clues.is_empty():
		return
	for s in u.actives.filter(func(x: Skill): return x.observes and u.can_afford(x)):
		var look := maxi(u.mod(&"wisdom"), 1) + mini(u.rank(s), roundi(u.stat(&"wisdom")))
		var reach := b.area_reach(u, s)
		var best: Variant = null
		var most := 0
		for c in b.map.get_used_cells():
			if Vector2(u.cell).distance_to(Vector2(c)) > reach + 0.0001:
				continue
			var n := clues.filter(func(k: Vector2i): return Command.tiles(c, k) <= look).size()
			if n > most or (n == most and n > 0 and Command.tiles(u.cell, c) < Command.tiles(u.cell, best)):
				best = c
				most = n
		if best != null and b.cast_at(u, s, best):
			log.append("%s uses %s at %s" % [u.name, s.name, best])
			return


# Support skills (Stonegift) on allies it reads as allies and that don't have the effect yet.
static func _support(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return not x.hostile and x.grants):
		for t in reads:
			var r: Read = reads[t]
			if r.attitude(u) == &"ally" and s.grants.effects[0] not in r.effects and b.cast(u, s, t):
				log.append("%s gives %s to %s" % [u.name, s.name, t.name])
				return


# Still luring: no enemy has seen it for what it is.
static func _luring(b: Battle, u: Unit, reads: Dictionary) -> bool:
	if u.behaviour != &"lure":
		return false
	for o: Unit in reads:
		if o.faction == u.faction or not o.is_alive():
			continue
		var r := b.read(o, u)
		if not r.deceived and r.net >= 0:
			return false
	return true


# A luring unit strikes whatever has come into its reach, without moving: its best skill while it has
# the AP (Drown, where there's water to drag the foe to), then whatever it can still afford (Rake).
static func _ambush(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var struck := false
	for s in u.actives.filter(func(x: Skill): return x.drags_to and u.can_afford(x)):
		for t: Unit in reads:
			if not struck and t.is_alive() and _foe(u, reads[t]) and b.in_reach(u, s, t) and b.drag_spot(u, s, t) != null \
					and not s.effects.any(func(e: Effect): return e in t.timed) and b.cast(u, s, t):  # not one it already holds
				log.append("%s uses %s on %s" % [u.name, s.name, t.name])
				reads[t] = b.read(u, t)
				struck = true
	while _strike(b, u, reads, log, true):
		struck = true
	return struck


# Heals the ally it most wants to (itself included), from what it reads of them, by how it tends
# (Unit.tends, else its class's: Role.tends; benevolent with neither). Only those it reads as hurt
# (HP short, or bloodied) or carrying a wound it can see and clear.
static func _heal(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return x.heals() and not x.hostile and u.can_afford(x)):
		var best: Unit = null
		var best_score := 0.0
		for t: Unit in [u] + reads.keys():
			var r: Read = b.read(u, u) if t == u else reads[t]
			if not t.is_alive() or (t != u and r.attitude(u) != &"ally") or not b.in_reach(u, s, t):
				continue
			var v := want(b, u, s, t, r)
			if v > best_score:
				best = t
				best_score = v
		if best and b.cast(u, s, best):
			log.append("%s heals %s" % [u.name, best.name])
			if best != u:
				reads[best] = b.read(u, best)
			return


# How much u wants to heal t (read as r) with s; 0: not at all.
#   benevolent: the share of its HP it seems to be missing (bloodied: half).
#   pragmatic: the level it reads (unknown: 0), then that share - but not where most of the heal would
#     go to waste on HP it isn't missing. Advertising a high level draws its heals.
#   loyal: that share, + PARTY for its party (its leader, and others following it).
# Seen wounds it can clear add WOUND each; a commander (the player's leader, or one with a party)
# adds COMMANDER.
static func want(b: Battle, u: Unit, s: Skill, t: Unit, r: Read) -> float:
	var share := 0.0
	var lost: Variant = null
	if r.hp != null and r.max_hp:
		lost = r.max_hp - r.hp
		share = float(lost) / r.max_hp
	elif r.healthy == false:
		share = 0.5
	var wounds := 0
	for e in r.effects:
		if e.wound and e in t.timed and t.timed[e].rank <= s.clears(u.rank(s)):
			wounds += 1
	if share <= 0.0 and wounds == 0:
		return 0.0
	var heal := s.healing(u) if s.heal_mods or s.heal_bonus else 0
	var v := share
	match u.tends if u.tends else (u.role.tends if u.role and u.role.tends else &"benevolent"):
		&"pragmatic":
			if wounds == 0 and lost != null and lost * 2 < heal:
				return 0.0
			v += float(r.level if r.level != null else 0)
		&"loyal":
			var party := u.follows if u.follows else u
			if t != u and (t == party or t.follows == party):
				v += PARTY
	v += WOUND * wounds
	if t == b.player or b.units.values().any(func(o: Unit): return o.follows == t):
		v += COMMANDER
	return v


# Sings where it stands (an automatic skill that pulls: Sing), when the nearest units it would reach
# include a foe, or an ally that hasn't had it yet.
static func _sing(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return x.auto and x.pull > 0 and u.can_afford(x)):
		var to := b.auto_targets(u, s)
		if to.any(func(t: Unit): return _foe(u, reads[t]) or (reads[t].attitude(u) == &"ally" and s.effects[0] not in t.timed)) and b.cast(u, s, u):
			log.append("%s sings to %s" % [u.name, ", ".join(to.map(func(t: Unit): return t.name))])
			return


# Held, it tries to break free by moving away from its holder: two tiles straight off, or one.
static func _escape(b: Battle, u: Unit, log: Array[String]) -> void:
	var by := b.held_by(u).by
	if by == null:
		return
	for c in [u.cell + (u.cell - by.cell) * 2, u.cell + (u.cell - by.cell)]:
		if b.on_map(c) and not b.travel(u, c).is_empty():
			log.append("%s breaks free" % u.name)
			return


# Holding a unit (a grapple: Drown), it won't walk off and let go - unless it reads its own tile as
# bad ground.
static func _rooted(b: Battle, u: Unit) -> bool:
	return b.units.values().any(func(o: Unit): return o.is_alive() and b.held_by(o) and b.held_by(o).by == u) \
			and not b.read(u, u.cell).known_bad()


# A traitor posing in another side's party, on that side's turn: it stays beside its leader.
static func _keep_up(b: Battle, u: Unit, log: Array[String]) -> void:
	var lead := u.follows
	if Command.tiles(u.cell, lead.cell) <= 1:
		return
	var p := b.travel(u, _approach(b, u, lead, {lead: b.read(u, lead)}))
	log.append("%s keeps up %s" % [u.name, p])


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
# path crosses the least ground it knows or suspects is bad, then the nearest, away from units it
# takes for aggressive. Never where it already stands. Planning mustn't use up the battle's rng, so it's restored.
static func _approach(b: Battle, u: Unit, t: Unit, reads: Dictionary) -> Vector2i:
	var r: Read = reads[t]
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
			for o in reads:
				var ro: Read = reads[o]
				if ro.attitude(u) == &"avoid" and ro.located() and Command.tiles(ro.cell, c) <= 1:
					v += WARY
			if v < best_cost:
				best = c
				best_cost = v
	b.rng.state = state
	return best
