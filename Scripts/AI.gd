class_name AI

# Plays a unit's turn from what it perceives, not the truth. It never strikes a unit it reads as
# an ally (sparing the beloved), takes the hit worth most - perceived damage, a likely kill, an
# ominous aura (the hated) - and walks around ground it knows or suspects is bad. Units presenting
# as Aggressive it keeps clear of, and Passive ones it leaves be (Read.attitude()). A craven unit
# (timid) won't advance without an ally it reads as a higher level within CRAVEN_REACH tiles, and backs
# away from the Aggressive within that reach before anything else. A unit's bio sets its temper
# (Bio.BEHAVIOURS): timid as craven; brave and aggressive charge, going for the strongest and the
# weakest; aggressive heals last; helpful goes to the wounded to heal them; stoic holds its ground.
# Where it can't make out a level or an aura it guesses from how the unit looks (_level(), _hate()). A luring unit
# (the Siren) stays serene and still until an enemy sees through it: it sings, and whatever comes
# into its reach it drowns or rakes. Healers heal the ally they most want to, by how they tend. A
# held unit tries to break free by moving away, and its holder stays put rather than let go, unless
# the ground it stands on is bad. A traitor posing in another side's party plays along:
# on that side's turn it keeps up with its leader; on its own, it rests unless it can make a kill.
# With no foe to go after, a unit with Observe searches where the clues point. A skittish unit (a
# Regeneration Probe) only keeps away from its foes. A channeling unit (the Astral Princess's Metea)
# strikes where the blast takes in the most foes, and begins channeling where they gather; with nothing
# to strike yet, it holds still to keep the channel. A unit with a strategy (Unit.strategy: closest, strongest, weakest) goes after targets by it, and one that
# hunts a side (Unit.hunts: Starmen, the Stellar Order) goes after that side's units first. A
# recovering unit (a Starmote) heads for the star lattice and holds there, fighting only when cornered.
# What a skill restores it reads from the skill's behaviours (Behaviour.restores(), _restores()): the
# wounded get what restores HP (Heal, Resuscitate on the Downed), and what is left of a turn goes to
# refilling a pool it runs low on (Energize). A unit running on a reserve that can't pay for anything it
# means to use, with another that can, switches to it (_switch(), a channel it finishes next turn).
# One holding Focus rests to build it when there's nothing to shoot (_steady()), and a ranged attack that
# would empty it is worth a little more (FOCUS). With no foe in sight, no clue and nowhere to hunt, it
# casts Clairvoyance (_scry()); an ally in reach lacking a buff skill's effects (Intervention) gets it (_support()).
# Kept small on purpose: score() and the move choice are the places to grow it.

const KILL := 5.0  # bonus for a hit that should finish the target
const HATE := 2.0  # per point of ominous aura
const GUESS_HP := 10.0  # when it can't make out a target's HP
const OBSERVE := preload("res://Behaviours/observe.gd")  # how far an Observe looks (_search())
const SUSPICIOUS := 1.0  # what a tile it finds suspicious is worth a look, in foes (clues())
const DEBRIS := 1.0  # debris a hiding foe left, fresh; halved a round on
const MARKED := 0.5  # a mark a foe laid that it knows of
const LAST_SEEN := 0.5  # where its side last made a foe out
const REACH := 0.5  # shared among the tiles that foe could have reached since
const HIT := 1.0  # shared among the tiles an unseen attacker could have struck from
const REACH_TURNS := 3  # the most turns of a foe's walking it reckons on
const WORTH := 0.5  # the least a look must take in to be cast
const CRAVEN_REACH := 3  # tiles within which a craven unit wants a higher-level ally before it advances
const COMMANDER := 0.25  # how much most healers favour a commander
const PARTY := 1.0  # how much a loyal healer favours its party
const WOUND := 0.25  # how much a healer wants to clear a wound it can see
const WARY := 10.0  # cost of ending a walk beside a unit it takes for aggressive
const HUNT := 10.0  # how much more a unit wants a target from a side it hunts (Unit.hunts)
const BOLD: Array[StringName] = [&"brave", &"aggressive"]  # tempers that walk up to the aggressive regardless
const LAST := 1000.0  # how much less a unit wants to go after a helpless, Downed foe: the standing come first
const FINISH := 0.5  # the most a blow at a helpless, Downed foe is worth: only when no standing foe is worth one
const FOCUS := 1.0  # per point of attack bonus the Focus a shot would spend the last of gives it (Unit.focus_forecast()), what it is worth over another blow
const AP := 1.5  # what an AP it gets back is worth, in the HP a blow takes (a 3 AP, 1d6 + 2 strike is about 5)
const DEFENSE := 0.5  # what a point of Defense it loses through its next turn costs it, per point (Sutemi's Off Balance)
const RIDER := 1.0  # what each thing riding on a hit is worth (Kick's soaking, blinding, push; Battle.foresee())
const RESCUE := 1.0  # what a skill that brings a Downed unit back up (Behaviour.revives()) is worth over one that only heals it, on that unit
const FLANKING := 0.4  # a tile's pull, a point of Defense the target loses to an attack from there (a rear attack's edge, an effect tagged flank), in tiles of walking (_approach())
const SHOT := 0.5  # the chance to hit below which a ranged attack isn't worth taking now, when resting for Focus would make it one (_steady())
const FOILED := 0.8  # the most of a blow's worth its foes' reactions can take off it in its reckoning (_foiled()): a target it can't hit through them is still a target
const STRONG := 0.5  # per level it reads, how much a unit going for the strongest (or weakest) weighs it against distance


# Takes u's turn. `posture` restricts it to abilities that serve one aim, for a unit a commander could
# only direct by intent (HUD default orders): &"offensive" strike only, &"supportive" heal and support
# only, &"defensive" a self-protective skill only. The default (&"") is a full, self-directed turn.
static func act(b: Battle, u: Unit, posture := &"") -> Array[String]:
	var log: Array[String] = []
	if not u.is_alive() or u.stopped():
		return log
	var reads := {}
	for o in b.units.values():
		if o != u:
			reads[o] = b.read(u, o)
	_remember(b, u, reads)
	if b.held_by(u):
		_escape(b, u, log)
	if u.dbno:  # Downed and fighting on (Grudge): what's left of it goes into blows
		_last_blows(b, u, reads, log)
		return log
	if b.posing(u):
		if b.turn == u.faction:
			_strike(b, u, reads, log, false, KILL)
		else:
			_keep_up(b, u, log)
		return log
	_unshackle(b, u, log)
	if posture == &"defensive":
		_defend(b, u, log)
		return log
	if posture == &"":
		_finish_switch(u, log)
		if _switch(b, u, reads, log):  # begun: the turn goes to it, idle
			return log
	var temper := u.temper() if posture == &"" else &""  # a self-directed turn goes by its temper (Bio)
	if posture != &"offensive" and temper != &"aggressive":  # a full turn, or HELP: heal and support (the aggressive strike first)
		var healed := log.size()
		_heal(b, u, reads, log)
		if temper == &"helpful" and log.size() == healed:
			_tend(b, u, reads, log)
		_support(b, u, reads, log)
	if posture == &"supportive":
		_replenish(b, u, log)  # a HELP order to one that only restores its own Energy or reserve: it does that
		return log
	var rooted := _rooted(b, u)
	if posture == &"":  # phases for a self-directed turn only - an ATTACK order presses on regardless
		if u.behaviour == &"skittish":
			_keep_away(b, u, reads, log)
			return log
		if u.behaviour == &"recovering":
			_recover(b, u, reads, log)
			return log
		_channel(b, u, reads, log)
		if u.channel and u.channel.turns > 0 and not u.channel.skill.behaviours.any(func(x: Behaviour): return x.senses()):  # still holding one it began before (Clairvoyance isn't held: it acts on what it sensed): moving or acting would end it (Battle.end_turn())
			log.append("%s holds still, channeling %s" % [u.name, u.channel.skill.name])
			return log
		if not rooted and _flee(b, u, reads, log):
			reads = {}
			for o in b.units.values():
				if o != u:
					reads[o] = b.read(u, o)
		if u.behaviour == &"undine" and _undine(b, u, reads, log, rooted):
			return log
		if _luring(b, u, reads):
			if not _ambush(b, u, reads, log):
				if not rooted and _out_of_song(b, u, reads):  # too far away to lure anyone: it closes in
					var near := _best_target(u, reads)
					if near:
						log.append("%s closes in %s" % [u.name, b.travel(u, _approach(b, u, near, reads))])
						reads[near] = b.read(u, near)
						if _ambush(b, u, reads, log):
							return log
				_sing(b, u, reads, log)
			return log
	if posture == &"" and (_steady(b, u, reads, log) or _starve(b, u, reads, log)):
		return log
	if not _strike(b, u, reads, log) and temper != &"stoic":  # the stoic hold, striking only what comes into reach
		var target := _best_target(u, reads)
		if target and _emboldened(u, reads) and not rooted:
			_rally(b, u, log)  # lay its marks first, then walk onto them
			var p := b.travel(u, _approach(b, u, target, reads))
			log.append("%s moves %s" % [u.name, p])
			reads[target] = b.read(u, target)
		elif not target:
			var looked := _search(b, u, log)  # it looks where the clues point, then heads for where its side last saw a foe
			if not looked and _scry(b, u, log):
				pass
			elif not rooted and _emboldened(u, reads):
				_hunt(b, u, reads, log)
	while _strike(b, u, reads, log):
		pass
	if temper == &"aggressive":  # what it has left, it spends on its side
		_heal(b, u, reads, log)
		_support(b, u, reads, log)
	if posture == &"":
		_replenish(b, u, log)
	return log


# u's interrupt (Battle.interrupter: Final Act), one free skill use, no walking: its best blow at a foe
# in reach; with none, the heal it wants most (itself among those it weighs: back above 0 HP, it lives);
# with neither, it passes. Reactions needing no choice the battle resolves itself (Battle.react()).
static func interrupt(b: Battle, u: Unit) -> Array[String]:
	var log: Array[String] = []
	if b.interrupter != u:
		return log
	var reads := {}
	for o in b.units.values():
		if o != u:
			reads[o] = b.read(u, o)
	if not _strike(b, u, reads, log):
		_heal(b, u, reads, log)
	if b.interrupter == u:
		log.append("%s passes" % u.name)
		b.end_interrupt()
	return log


# Helpful (Bio): with no one to heal in reach, it goes to the ally it most wants to heal (want()) and
# heals it. Other healers heal only whom they happen to reach.
static func _tend(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	var heals := u.actives.filter(func(x: Skill): return _mends(b, u, x) and u.can_afford(x))
	if heals.is_empty() or _rooted(b, u):
		return
	var best: Unit = null
	var best_score := 0.0
	for t: Unit in reads:
		var r: Read = reads[t]
		if not t.is_alive() or r.attitude(u) != &"ally" or not r.located():
			continue
		var v := want(b, u, heals[0], t, r)
		if v > best_score:
			best = t
			best_score = v
	if best == null or b.in_reach(u, heals[0], best):
		return
	log.append("%s goes to %s %s" % [u.name, best.name, b.travel(u, _approach(b, u, best, reads))])
	reads[best] = b.read(u, best)
	_heal(b, u, reads, log)


# Downed and still acting (Grudge; Scripts/Downed.gd): it closes with the nearest foe and strikes one
# beside it - the melee attack each of its rounds asks for - with no more skill uses than its rule
# leaves it, but in its last round, when one too many costs it nothing.
static func _last_blows(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	if _save_self(b, u, log):
		return
	var target := _best_target(u, reads)
	if target and not Battle.next_to(u.cell, reads[target].cell) and not _rooted(b, u):
		log.append("%s closes in %s" % [u.name, b.travel(u, _approach(b, u, target, reads))])
	var near := {}
	for o: Unit in reads:
		if Battle.next_to(u.cell, o.cell):
			near[o] = b.read(u, o)
	while u.dbno and (u.dbno.spare() != 0 or u.dbno.left <= 1) and _strike(b, u, near, log, true):
		pass


# Downed and acting (Grudge) with a heal that, by what it declares it restores, would bring it back above 0
# HP: it casts the strongest, saved and standing rather than spent in its last rounds. A use against its
# allowance, but the one that saves it. False if it has none, or none enough (a gamble it doesn't take).
static func _save_self(b: Battle, u: Unit, log: Array[String]) -> bool:
	var best: Skill = null
	var most := 0
	for s in u.actives.filter(func(x: Skill): return _mends(b, u, x) and u.can_afford(x) and b.in_reach(u, x, u)):
		if not s.behaviours.all(func(x: Behaviour): return x.fits(b, u, u)):
			continue
		var n: int = _restores(b, u, s, u).get(&"hp", 0)
		if n > -u.hp and n > most:
			best = s
			most = n
	if best and b.cast(u, best, u):
		log.append("%s heals itself back up" % u.name)
		return true
	return false


# A foe Downed and fighting on (Grudge) that must make a melee attack this round or die of it
# (Downed.rule.melee), which u can place.
static func _starving(u: Unit, reads: Dictionary) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in reads:
		if o.is_alive() and o.dbno and o.dbno.rule.acts and o.dbno.rule.melee and not o.dbno.meleed and _foe(u, reads[o]) and reads[o].located():
			out.append(o)
	return out


# The cheap half of starving a Grudge unit of melee: with it the one foe left, u doesn't hand it a blow -
# it keeps beyond its walk and one tile (its movement + 1), or, out of its reach already, holds where it
# stands rather than close - unless it can finish it with a blow (its low roll past the Downed limit) or
# shoot from beyond that reach. It does not plan for allies in reach, nor for a second round. True if the
# turn is spent so.
static func _starve(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var owing := _starving(u, reads)
	if owing.is_empty() or _rooted(b, u) or reads.keys().any(func(o: Unit): return o.is_alive() and o not in owing and _foe(u, reads[o]) and reads[o].located() and not o.helpless()):
		return false
	for g in owing:
		for s in u.foe_actives(true):
			if b.in_reach(u, s, g) and Battle.damage_range(u, s, g, b).get("lo", 0) > g.hp + g.dbno.limit:
				return false  # one blow ends it
	var threat := func(g: Unit) -> bool: return Command.tiles(u.cell, g.cell) <= ceili(g.stat(&"movement")) + 1
	if not owing.any(threat):
		return not _could_strike(b, u, reads)  # out of its reach: shoot if it can, else wait
	var from: Array[Vector2i] = []
	for g in owing:
		from.append(g.cell)
	if _away(b, u, from):
		log.append("%s keeps from %s's reach, starving it of a blow" % [u.name, owing[0].name])
		return true
	return false


# Shackled (a binding trinket): off with them if they're unlocked; locked, one try at whichever of
# picking (dex) and prying (str) its mods favour - its turn's AP are worth it to be rid of the weight.
static func _unshackle(b: Battle, u: Unit, log: Array[String]) -> void:
	var it := u.trinket
	if not it or not it.binding:
		return
	var odds := func(stat: StringName, diff: StringName) -> int: return u.mod(stat) - Difficulty.dc(diff, it.ranked()) if diff else -999
	var how := &"unlock" if not u.shackled() else (&"pick" if odds.call(&"dexterity", it.picks) >= odds.call(&"strength", it.prised) else &"pry")
	if b.unshackle(u, how):
		log.append("%s gets its %s off" % [u.name, it.name])


# DEFEND: uses u's best self-protective skill on itself (Skill.serves defensive), if it has one it can
# afford; otherwise it holds. One aimed at a tile (Shields Up!) is aimed at the nearest foe it makes out.
static func _defend(b: Battle, u: Unit, log: Array[String]) -> void:
	var s := u.intent_skill(&"defensive")
	if s and s.on_tile():
		var near: Variant = null
		for o: Unit in b.units.values():
			var r := b.read(u, o)
			if o != u and o.is_alive() and _foe(u, r) and (near == null or Command.tiles(u.cell, r.cell) < Command.tiles(u.cell, near)):
				near = r.cell
		if near != null and b.cast_at(u, s, near):
			log.append("%s %s, facing %s" % [u.name, s.name, near])
	elif s and b.cast(u, s, u):
		log.append("%s %s" % [u.name, s.name])


# Perceived worth of using a hostile skill on a unit read as `r`. Given the battle and the unit (`t`, the
# one `r` reads), it reads what the player's forecast shows: the chance to hit (Battle.hit_chance(): the
# skill's edge, its behaviours' edge() and guard() - Gank's ambush, Spike's Defense - the target's
# Defense), the damage (damage_range()) and what rides on it (Battle.foresee(): Kick's tile). Then what
# those can't say, from hooks any behaviour joins: the AP it gives back (refunds(): Poach, Slam Jam) and
# the Defense it costs its caster (unguarded(): Sutemi's Off Balance).
static func score(u: Unit, s: Skill, r: Read, b: Battle = null, t: Unit = null) -> float:
	var d := Battle.damage_range(u, s, t, b) if b and t else Battle.damage_range(u, s)  # as cast() deals it: through u's modifiers
	var dmg: float = d.get("avg", 0.0)
	var hp: float = maxf(r.hp, 1.0) if r.hp != null else GUESS_HP  # (one Downed, at 0 or below: any blow may be its last)
	var p := 1.0
	var riders := 0
	var saved := 0.0
	var toll := 0
	if b and t:
		p = Battle.hit_chance(u, s, t, b)
		var more := b.foresee(u, s, t)
		if not more.is_empty():
			dmg += (more.lo + more.hi) / 2.0
			riders = more.notes.size()
		if not s.behaviours.is_empty():
			var c := b.cast_of(u, s, t, u.rank(s), true)
			var share := 0.0
			for bh in s.behaviours:
				share += bh.refunds(c, p)
				toll += bh.unguarded(c)
			saved = minf(share, 1.0) * u.ap_cost(s, u.funding(s)) * AP
	var value := minf(dmg, hp) + (KILL if dmg >= hp else 0.0) + (1.0 if s.hostile and (not s.effects.is_empty() or s.disables) else 0.0) \
			+ (KILL if s.drags() else 0.0) + RIDER * riders  # into the water: the Siren's favourite
	return p * value + saved - DEFENSE * toll - _hate(r)


# HUNT for a target it reads as one of a side it hunts.
static func _hunted(u: Unit, r: Read) -> float:
	return HUNT if r.faction != null and r.faction in u.hunts else 0.0


static func _hate(r: Read) -> float:
	return HATE * (r.aura if r.aura else Bio.aura(r.looks))  # no aura to go by: how it looks (Horrific, Beautiful)


# The level u takes t (read as r) for: what it makes out, else a guess from how it looks - its own level,
# give or take what its appearance and adjectives suggest (Bio.standing(): a Knight 2 more). null: no idea.
static func _level(u: Unit, r: Read) -> Variant:
	if r.level != null:
		return r.level
	return u.lv() + Bio.standing(r.looks) if r.looks else null


static func _foe(u: Unit, r: Read) -> bool:
	return r.located() and r.attitude(u) == &"foe"


# Ready to advance: not timid (craven), or an ally it takes for one is near, of a level it reads as
# higher (it must make out the level, have it advertised - Persona II - or guess it from how the ally
# looks: _level()).
static func _emboldened(u: Unit, reads: Dictionary) -> bool:
	if u.temper() != &"timid":
		return true
	for o: Unit in reads:
		var r: Read = reads[o]
		var lv: Variant = _level(u, r)
		if o.is_alive() and r.attitude(u) == &"ally" and lv != null and lv > u.lv() and Command.tiles(o.cell, u.cell) <= CRAVEN_REACH:
			return true
	return false


# A craven unit backs away from units it takes for aggressive within CRAVEN_REACH tiles: to the
# tile it can reach (as it expects the walk to go) furthest from the nearest of them. False if
# there's none near, or nowhere better.
static func _flee(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	if u.temper() != &"timid":
		return false
	var scary: Array[Vector2i] = []
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and not o.stopped() and r.located() and r.attitude(u) == &"avoid" and Command.tiles(r.cell, u.cell) <= CRAVEN_REACH:
			scary.append(r.cell)
	if scary.is_empty() or not _away(b, u, scary):
		return false
	log.append("%s backs away" % u.name)
	return true


# Casts the best hostile skill it can right now; false if nothing is in reach and affordable. The
# beloved are spared only while there are other foes to fight. attacks_only: skip dual skills (Sing).
# least: only a strike worth more than this (a traitor keeping its cover: a kill).
static func _strike(b: Battle, u: Unit, reads: Dictionary, log: Array[String], attacks_only := false, least := 0.0) -> bool:
	var best := []
	var best_score := least
	var spared := []
	for s in u.foe_actives().filter(func(x: Skill): return not (attacks_only and x.dual)):
		for t in reads:
			var r: Read = reads[t]
			if not _foe(u, r) or not t.is_alive() or not b.in_reach(u, s, t) or not u.can_afford(s):
				continue
			if not s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
				continue  # not one it can be used on (Gank: no ally near it; Sutemi: no way through)
			if s.drags() and (b.drag_spot(u, s, t) == null or s.effects.any(func(e: Effect): return e in t.timed)):
				continue
			var v := score(u, s, r, b, t) + FOCUS * u.focus_forecast(s) - (1.0 if s.hostile and not s.effects.is_empty() and s.effects[0] in r.effects else 0.0) + _hunted(u, r)
			if v > 0.0:
				v *= 1.0 - _foiled(b, u, s, t, reads)  # what its foes' reactions would likely take off it
			if t.dbno != null and t.stopped():
				v = minf(v, FINISH)  # down and no threat: finished off only when there's nothing better to do
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


# The share (0-1, at most FOILED) of a blow of s on t that t's side's reactions would likely take from u: each
# passive of a unit beside the fight that u reads t's side as having (Read.skills, Read.kit: what it makes out
# of them; an unread one it can't weigh) is asked, through the hook the reaction itself uses (Behaviour.foils()),
# about each moment the blow would bring - attacked, hit, and fallen when it would kill - and what each leaves
# standing multiplies. Cheap: nothing is asked unless such a passive is read.
static func _foiled(b: Battle, u: Unit, s: Skill, t: Unit, reads: Dictionary) -> float:
	if not s.hostile or t == u:
		return 0.0
	var held := []  # [holder, its slot]
	for o: Unit in reads:
		var r: Read = reads[o]
		if o == u or not o.is_alive() or not o.reacts() or not Faction.friends(o.faction, t.faction):
			continue
		for x in Battle.reactions_of(o):
			if x.skill in r.skills or x.skill in r.kit:
				held.append([o, x])
	if held.is_empty():
		return 0.0
	var moments: Array[StringName] = [&"attacked", &"hit"]
	var hp: float = maxf(reads[t].hp, 1.0) if reads[t].hp != null else GUESS_HP
	if float(Battle.damage_range(u, s, t, b).get("avg", 0.0)) >= hp:
		moments.append(&"fallen")
	var m := b.cast_of(u, s, t, u.rank(s), true)
	var keep := 1.0
	for trigger in moments:
		var r := Behaviour.Reaction.new()
		r.battle = b
		r.trigger = trigger
		r.subject = t
		r.by = u
		r.cast = m
		for h in held:
			r.skill = h[1].skill
			for bh in r.skill.behaviours:
				keep *= 1.0 - clampf(bh.foils(r, h[0], h[1].rank), 0.0, 1.0)
	return minf(1.0 - keep, FOILED)


# With no foe to go after, it searches (Observe) where the clues point: the tile in reach whose look
# takes in the most of their weight (clues()), nearest itself on a tie, if that is WORTH a look. No clue
# worth it, no search: it can't know where to look. True if it searched.
static func _search(b: Battle, u: Unit, log: Array[String]) -> bool:
	var looks := u.actives.filter(func(x: Skill): return x.behaviour(&"observe") and u.can_afford(x))
	if looks.is_empty():
		return false
	var clues := clues(b, u)
	if clues.is_empty():
		return false
	for s in looks:
		var look := OBSERVE.reach(u, u.mods(s).irank(u.rank(s), &"rank_impact"))  # as it looks when cast
		var reach := b.area_reach(u, s)
		var best: Variant = null
		var most := 0.0
		for c in b.map.get_used_cells():
			if Vector2(u.cell).distance_to(Vector2(c)) > reach + 0.0001:
				continue
			var n := 0.0
			for k: Vector2i in clues:
				if Command.tiles(c, k) <= look:
					n += clues[k]
			if n >= WORTH and (best == null or n > most + 0.0001 or (absf(n - most) <= 0.0001 and Command.tiles(u.cell, c) < Command.tiles(u.cell, best))):
				best = c
				most = n
		if best != null and b.cast_at(u, s, best):
			log.append("%s uses %s at %s" % [u.name, s.name, best])
			return true
	return false


# What u has to go on in a search: tile -> weight (a foe's worth, about 1), summed over every clue, each
# read from what u's side knows - Perception's reads, its sightings, the blows it took - never the map. A
# later clue joins by adding its tiles with `_clue()`. Tiles u's side searched lately (Battle.swept_lately())
# lose the guesses (last seen, where it could have got, where a blow came from), not the signs left behind.
#  - what it finds suspicious (Battle.suspicious()): SUSPICIOUS each;
#  - debris foes left hiding (Battle.evidence()): DEBRIS, less as it ages;
#  - marks of foes it knows of: MARKED each;
#  - where its side last made a foe out: LAST_SEEN there, and REACH shared among the tiles that foe could have
#    reached by now (Battle.reckon_reach(): its movement as read, a turn's worth for each round since, to REACH_TURNS);
#  - where it was struck from by one it couldn't place (Battle.attacks_on()): HIT shared among the tiles on
#    the side the blow landed that its skill reached.
static func clues(b: Battle, u: Unit) -> Dictionary[Vector2i, float]:
	var out: Dictionary[Vector2i, float] = {}
	for c in b.suspicious(u):
		_clue(out, c, SUSPICIOUS)
	for c in b.evidence(u):
		_clue(out, c, DEBRIS / (1.0 + b.rounds_since(b.debris[c].since)))
	for c in b.marks:
		for m: Battle.Mark in b.known_marks(u, c):
			if not Faction.friends(m.faction, u.faction):
				_clue(out, c, MARKED)
	var guess: Dictionary[Vector2i, float] = {}
	var seen := b.last_seen(u.faction) if u.faction else {}
	for t: Unit in seen:
		var at: Vector2i = seen[t]
		var info: Dictionary = b.sighted_when.get(u.faction, {}).get(t, {since = b.turns_begun, moves = 0.0})
		var moves: float = info.moves if info.moves > 0.0 else u.stat(&"movement")  # as far as it walks itself, unless it read it
		var tiles := b.reckon_reach(u, t, at, moves * mini(b.rounds_since(info.since), REACH_TURNS))
		_clue(guess, at, LAST_SEEN)
		for c in tiles:
			_clue(guess, c, REACH / tiles.size())
	for a in b.attacks_on(u.faction) if u.faction else []:
		for c in a.tiles:
			_clue(guess, c, HIT / a.tiles.size())
	for c in guess:
		if u.faction and b.swept_lately(u.faction, c):
			continue
		var there := b.unit_at(c)
		if there and there != u and b.read(u, there).located():
			continue  # it sees someone there, and not the one it's after
		_clue(out, c, guess[c])
	return out


static func _clue(out: Dictionary, c: Vector2i, w: float) -> void:
	out[c] = out.get(c, 0.0) + w


# Its side remembers where it makes out each foe, or something it can't tell the side of (Battle.sightings).
static func _remember(b: Battle, u: Unit, reads: Dictionary) -> void:
	if not u.faction:
		return
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and (_foe(u, r) or (r.located() and r.faction == null)):
			b.sighted(u.faction, o, r.cell, float(r.stats.get(&"movement", 0.0)))


# No foe in sight: it heads for where its side last made one out, the nearest first. Reaching the spot
# and finding no one there, its side forgets it and it tries the next. False with nowhere to go.
static func _hunt(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var seen := b.last_seen(u.faction) if u.faction else {}
	while not seen.is_empty():
		var best: Unit = null
		for t: Unit in seen:
			if best == null or Vector2(u.cell).distance_to(Vector2(seen[t])) < Vector2(u.cell).distance_to(Vector2(seen[best])):
				best = t
		var at: Vector2i = seen[best]
		if Command.tiles(u.cell, at) <= 1:
			seen.erase(best)
			continue
		var r := Read.new()
		r.cell = at
		var p := b.travel(u, _approach(b, u, best, {best: r}))
		if p.is_empty():
			return false
		log.append("%s hunts %s" % [u.name, p])
		for o in reads:
			reads[o] = b.read(u, o)
		_remember(b, u, reads)
		return true
	return false


# Support skills on allies it reads as allies (itself too, for one that reaches itself) that don't have
# the effect yet: one that grants an effect (Stonegift), or a buff for allies with effects of its own
# (Intervention, Rally; not self_only or dual ones).
static func _support(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return not x.hostile and (x.grants or (not x.for_foes() and not x.self_only and not x.effects.is_empty())) and u.can_afford(x)):
		var e: Effect = s.grants.effects[0] if s.grants else s.effects[0]
		for t: Unit in reads.keys() + [u]:
			var r: Read = b.read(u, u) if t == u else reads[t]
			if t.is_alive() and (t == u or r.attitude(u) == &"ally") and e not in r.effects and s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)) \
					and b.cast(u, s, t):
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


# An Undine's turn: its fog kept up as the turn opens (Waltz of Vapors); inside a foe's tile, it holds
# on; bloodied, it turns to mist (Vaporize); a mist closes in on its best target and Coalesces into it;
# otherwise it floods the tile of a foe in reach that isn't under water yet (Well Up), and strikes and
# closes in as any unit would (false: the usual turn goes on).
static func _undine(b: Battle, u: Unit, reads: Dictionary, log: Array[String], rooted: bool) -> bool:
	for s in u.actives.filter(func(x: Skill): return x.behaviour(&"waltz") and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s waltzes in a fog" % u.name)
	if b.inside.has(u):
		return true  # holding on inside its prey
	var vapor: Slot = null
	for x in u.slots:
		if x.skill.toggle and x.skill.effects.any(func(e: Effect): return e.stat == "mist"):
			vapor = x
	if vapor and not vapor.on and u.hp * 2 < u.max_hp:
		u.toggle(vapor.skill)
		log.append("%s vaporizes" % u.name)
	if u.stat(&"mist") > 0.0:
		var target := _best_target(u, reads)
		for s in u.actives.filter(func(x: Skill): return x.mist_only and x.engulfs):
			if target and not b.in_reach(u, s, target) and not rooted:
				log.append("%s drifts %s" % [u.name, b.travel(u, _approach(b, u, target, reads))])
			if target and b.in_reach(u, s, target) and u.can_afford(s) and b.cast(u, s, target):
				log.append("%s coalesces into %s" % [u.name, target.name])
		return true
	for s in u.actives.filter(func(x: Skill): return x.behaviour(&"well_up") and u.can_afford(x)):
		for t: Unit in reads:
			var r: Read = reads[t]
			if t.is_alive() and _foe(u, r) and not b.submerged(t) and Vector2(u.cell).distance_to(Vector2(r.cell)) <= b.area_reach(u, s) + 0.0001 \
					and b.cast_at(u, s, r.cell):
				log.append("%s wells up under %s" % [u.name, t.name])
				break
	return false


# No foe within reach of any song it could lure with (Sing: Skill.auto, pulling): a Siren too far away
# to lure moves in on them instead.
static func _out_of_song(b: Battle, u: Unit, reads: Dictionary) -> bool:
	for s in u.actives.filter(func(x: Skill): return x.auto and Displace.draws(x)):
		if b.auto_targets(u, s).any(func(t: Unit): return reads.has(t) and _foe(u, reads[t])):
			return false
	return true


# A luring unit strikes whatever has come into its reach, without moving: its best skill while it has
# the AP (Drown, where there's water to drag the foe to), then whatever it can still afford (Rake).
static func _ambush(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	var struck := false
	for s in u.actives.filter(func(x: Skill): return x.drags() and u.can_afford(x)):
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
# (HP short, or bloodied) or carrying a wound it can see and clear. Among all it can use that restore HP
# (_mends()), the best (skill, ally) by want(), the first skill on a tie; a skill only works where its
# behaviours say it fits (Resuscitate: the Downed).
static func _heal(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	var best: Unit = null
	var how: Skill = null
	var best_score := 0.0
	for s in u.actives.filter(func(x: Skill): return _mends(b, u, x) and u.can_afford(x)):
		for t: Unit in [u] + reads.keys():
			var r: Read = b.read(u, u) if t == u else reads[t]
			if not t.is_alive() or (t != u and r.attitude(u) != &"ally") or not b.in_reach(u, s, t) \
					or not s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
				continue
			var v := want(b, u, s, t, r) + (RESCUE if _revives(b, u, s, t) else 0.0)
			if v > best_score:
				best = t
				how = s
				best_score = v
	if best and b.cast(u, how, best):
		log.append("%s heals %s" % [u.name, best.name])
		if best != u:
			reads[best] = b.read(u, best)


# What u using s on t would give back, by pool (&"hp", &"energy", a Reserve): what its behaviours declare
# (Behaviour.restores()), and the HP of a heal's own fields (Skill.healing()). Empty: nothing.
static func _restores(b: Battle, u: Unit, s: Skill, t: Unit) -> Dictionary:
	var out := {}
	if s.heal_mods or s.heal_bonus:
		out[&"hp"] = s.healing(u)
	var c := Behaviour.Cast.new()
	c.battle = b
	c.caster = u
	c.target = t
	c.skill = s
	c.rank = u.rank(s)
	c.foe = false
	for x in s.behaviours:
		var more := x.restores(c)
		for k in more:
			out[k] = out.get(k, 0) + more[k]
	return out


# Whether s is help u gives, because it restores something (_restores()): not hostile, not a passive,
# and some pool comes back. What the HUD's HELP order reads, since Skill.serves() can't see behaviours.
static func restoring(b: Battle, u: Unit, s: Skill) -> bool:
	return not s.passive and not s.hostile and not _restores(b, u, s, u).is_empty()


# A skill for an ally that mends HP: a heal, or whatever declares it restores some (_restores()).
static func _mends(b: Battle, u: Unit, s: Skill) -> bool:
	return not s.hostile and (s.heals() or _restores(b, u, s, u).has(&"hp"))


# Whether s, used by u on t, brings a Downed t back up (a behaviour's revives(): Resuscitate).
static func _revives(b: Battle, u: Unit, s: Skill, t: Unit) -> bool:
	if t.dbno == null or s.behaviours.is_empty():
		return false
	var c := b.cast_of(u, s, t, u.rank(s), false)
	return s.behaviours.any(func(x: Behaviour): return x.revives(c))


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
	elif r.healthy == false or (r.healthy == null and Bio.hurt(r.looks)):  # bloodied, or looks it (Injured)
		share = 0.5
	var wounds := 0
	for e in r.effects:
		if e.wound and e in t.timed and t.timed[e].rank <= s.clears(u.mods(s).irank(u.rank(s), &"rank_impact")):
			wounds += 1
	if share <= 0.0 and wounds == 0:
		return 0.0
	var heal: int = _restores(b, u, s, t).get(&"hp", 0)
	var v := share
	match u.tends if u.tends else (u.role.tends if u.role and u.role.tends else &"benevolent"):
		&"pragmatic":
			if wounds == 0 and lost != null and lost * 2 < heal:
				return 0.0
			var lv: Variant = _level(u, r)
			v += float(lv if lv != null else 0)
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
	for s in u.actives.filter(func(x: Skill): return x.auto and Displace.draws(x) and u.can_afford(x)):
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


# A skittish unit keeps away from the foes it can place: to the tile it can reach furthest from the
# nearest of them.
static func _keep_away(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	var foes: Array[Vector2i] = []
	for o: Unit in reads:
		if o.is_alive() and _foe(u, reads[o]):
			foes.append(reads[o].cell)
	if not foes.is_empty() and _away(b, u, foes):
		log.append("%s keeps away" % u.name)


# Walks to the tile it can reach (as it expects the walk to go) furthest from the nearest of `from`.
# False if there's nowhere better.
static func _away(b: Battle, u: Unit, from: Array[Vector2i]) -> bool:
	var gap := func(c: Vector2i) -> int:
		return from.map(func(x: Vector2i): return Command.tiles(x, c)).min()
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
	return best != u.cell and not b.travel(u, best).is_empty()


# A recovering unit (a Starmote): off the star lattice, it heads for the nearest free lattice tile;
# on it, it holds. Only cornered - a foe beside it, and nowhere further from its foes to go - does it
# fight (its energy missiles).
static func _recover(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	if not b.on_lattice(u.cell):
		var best: Variant = null
		for c: Vector2i in b.panes.keys() + b.starpower.keys():
			if not b.unit_at(c) and (best == null or Command.tiles(u.cell, c) < Command.tiles(u.cell, best)):
				best = c
		if best != null and not b.travel(u, best).is_empty():
			log.append("%s heads for the stars" % u.name)
	var foes: Array[Vector2i] = []
	for o: Unit in reads:
		if o.is_alive() and _foe(u, reads[o]):
			foes.append(reads[o].cell)
	var near := foes.any(func(c: Vector2i): return Command.tiles(c, u.cell) <= 1)
	if near and (b.on_lattice(u.cell) or not _away(b, u, foes)):
		while _strike(b, u, reads, log):
			pass


# A channeled skill (Metea): holding one, it strikes the tile it can that takes in the most foes it can
# place (less its allies); not yet, it begins where foes gather within its reach - where a blast
# would take in the most of them, a tile further out to allow for their moving.
static func _channel(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> void:
	for s: Skill in u.actives.filter(func(x: Skill): return x.channel):
		var radius := s.blast * u.mods(s).rank(u.rank(s), &"rank_range")  # as Battle._detonate() reads it

		var striking := u.channel != null and u.channel.skill == s
		if not striking and (u.channel != null or not u.can_afford(s)):
			continue
		var cells: Array = b.strike_tiles(u) if striking else b.map.get_used_cells().filter(
				func(c: Vector2i): return Vector2(u.cell).distance_to(Vector2(c)) <= b.area_reach(u, s) + 0.0001)
		var best: Variant = null
		var most := 0.0
		for c: Vector2i in cells:
			var v := 0.0
			for o: Unit in reads:
				var r: Read = reads[o]
				if o.is_alive() and r.located() and Vector2(r.cell).distance_to(Vector2(c)) <= radius + (0.0 if striking else 1.0) + 0.0001:
					v += 1.0 if _foe(u, r) else (-1.0 if r.attitude(u) == &"ally" else 0.0)
			if v > most:
				best = c
				most = v
		if best != null and b.cast_at(u, s, best):
			log.append("%s %s %s at %s" % [u.name, "strikes with" if striking else "channels", s.name, best])
			for o in reads:
				reads[o] = b.read(u, o)


# A traitor posing in another side's party, on that side's turn: it stays beside its leader.
static func _keep_up(b: Battle, u: Unit, log: Array[String]) -> void:
	var lead := u.follows
	if Command.tiles(u.cell, lead.cell) <= 1:
		return
	var p := b.travel(u, _approach(b, u, lead, {lead: b.read(u, lead)}))
	log.append("%s keeps up %s" % [u.name, p])


# The foe to go after: the nearest, the hated last - and by its strategy, the strongest (or weakest) it
# reads, a level against STRONG tiles.
static func _best_target(u: Unit, reads: Dictionary) -> Unit:
	var best: Unit = null
	var best_score := -INF
	for t in reads:
		if not _foe(u, reads[t]) or not t.is_alive():
			continue
		var guess: Variant = _level(u, reads[t])
		var lv: float = guess if guess != null else 0.0
		var v: float = -Vector2(u.cell).distance_to(Vector2(reads[t].cell)) - _hate(reads[t]) + _hunted(u, reads[t]) \
				+ STRONG * lv * _leaning(u) - (LAST if t.dbno != null and t.stopped() else 0.0)
		if v > best_score:
			best = t
			best_score = v
	return best


# Which way u leans between the strongest foe (+1) and the weakest (-1): its strategy, else its temper -
# the brave go for the strongest, the aggressive for the weakest.
static func _leaning(u: Unit) -> int:
	if &"strongest" in u.strategy or &"weakest" in u.strategy:
		return int(&"strongest" in u.strategy) - int(&"weakest" in u.strategy)
	return {&"brave": 1, &"aggressive": -1}.get(u.temper(), 0)


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
			var pull := 0.0
			for p in b.line(u.cell, c, u.luck, u):
				var tr := b.read(u, p)
				risk += int(tr.known_bad() or tr.hint != "")
				pull += b.lure(u, p)  # a known helpful mark on the way (Charge!) draws it a little
			var v := risk * 10.0 + Vector2(u.cell).distance_to(Vector2(c)) + (0.5 if dx and dy else 0.0) - FLANKING * _opening(t, c) - pull
			for o in reads:
				var ro: Read = reads[o]
				if ro.attitude(u) == &"avoid" and ro.located() and Command.tiles(ro.cell, c) <= 1 and u.temper() not in BOLD:
					v += WARY
			if v < best_cost:
				best = c
				best_cost = v
	b.rng.state = state
	return best


# The points of Defense t loses to an attack made from tile c, by the side of t it lies on (Unit.side_of(): rear,
# flank) - the same Defense an attack's hit chance reads (Battle.hit_chance()), so an effect tagged rear or flank
# counts as well as the rear's own edge. A tile it would take its approach by, other things equal.
static func _opening(t: Unit, c: Vector2i) -> int:
	var side := t.side_of(c)
	return t.defense() - t.defense([side] as Array[StringName]) if side != &"front" else 0


# What it has left, after its blows, it spends on refilling a pool it runs low on: a skill that restores
# Energy or a reserve (Behaviour.restores(): Energize), on itself, once that pool is at half or less -
# Energy only if it runs on Energy, a reserve only if it spends from it. After its strikes, so it never
# costs it a blow.
static func _replenish(b: Battle, u: Unit, log: Array[String]) -> void:
	for s in u.actives.filter(func(x: Skill): return not x.hostile and not x.for_foes() and u.can_afford(x)):
		var got := _restores(b, u, s, u)
		for pool in got:
			if pool != &"hp" and got[pool] > 0 and _low(u, pool) and b.cast(u, s, u):
				log.append("%s uses %s" % [u.name, s.name])
				return


# Whether pool (&"energy" or a Reserve) is a pool u draws on that is at half or less.
static func _low(u: Unit, pool: Variant) -> bool:
	if pool is Reserve:
		var most: int = u.pools().get(pool, 0)
		return most > 0 and u.spends(pool) and u.store(pool) * 2 <= most
	return pool == &"energy" and u.runs_on() == &"energy" and u.max_energy > 0 and u.energy * 2 <= u.max_energy


# A switch of what it runs on that it began on an earlier turn (Unit.toggle()), it finishes as this one
# opens: held a turn idle, it carries over what it can.
static func _finish_switch(u: Unit, log: Array[String]) -> void:
	if u.channel and u.channel.switch != null and u.toggle(u.channel.skill):
		log.append("%s finishes switching" % u.name)


# Running on a reserve (Mana, Stamina) or Energy that can't pay for any skill worth its cost that it has -
# a blow or a heal - while another it could run on could (_pays()), and nothing it can strike now: it
# begins the switch (channeled: it holds the turn idle, and finishes next turn). True if it did.
static func _switch(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	if u.channel or _could_strike(b, u, reads):
		return false
	var worth := u.actives.filter(func(x: Skill): return u.price(x) > 0 and (x.for_foes() or _mends(b, u, x)))
	if worth.any(func(x: Skill): return u.can_afford(x)):
		return false
	for x in u.slots:
		var to: Variant = &"energy" if x.on else Unit.replacer(x.skill)
		if Unit.replacer(x.skill) and x.skill not in u.disabled and worth.any(func(w: Skill): return _pays(u, to, w)) and u.toggle(x.skill):
			log.append("%s switches to %s" % [u.name, to.name if to is Reserve else "Energy"])
			return true
	return false


# Whether a unit running on pool (a Reserve, or &"energy") could pay for s with what it holds in it now
# (Reserve.only, Reserve.bars, Unit.cost_from()).
static func _pays(u: Unit, pool: Variant, s: Skill) -> bool:
	if pool is Reserve and (not (pool.only.is_empty() or pool.only.any(func(t): return s.tagged(t))) \
			or (pool.bars.any(func(t): return s.tagged(t)) and u.price(s) > 0)):
		return false
	return u.covers(pool, u.cost_from(s, pool))


# Whether it could strike a foe it reads from where it stands, with a skill it can pay for.
static func _could_strike(b: Battle, u: Unit, reads: Dictionary) -> bool:
	for s in u.foe_actives(true):
		for t: Unit in reads:
			if t.is_alive() and _foe(u, reads[t]) and b.in_reach(u, s, t):
				return true
	return false


# Holding Focus (Reserve.aims, which builds only on a turn it rests) short of full, with a ranged attack it
# would pay for from it: it rests rather than walk up, building it for the shot (a ranged attack that
# empties it gets + rank to hit). When nothing is in reach to strike. Or when what is in reach is not worth
# it now - only ranged attacks, none likelier than SHOT to hit - and a rest would give Focus enough to pay
# for one it can't pay for from Focus now (and a Focus stat to add). Bounded: a rest or two fills it.
# True if it rested.
static func _steady(b: Battle, u: Unit, reads: Dictionary, log: Array[String]) -> bool:
	if not u.idle():
		return false
	var weak := false
	for s in u.foe_actives(true):
		for t: Unit in reads:
			if t.is_alive() and _foe(u, reads[t]) and b.in_reach(u, s, t):
				if not u.ranged(s) or Battle.hit_chance(u, s, t, b) >= SHOT:
					return false
				weak = true
	var pools := u.pools()
	for f: Reserve in pools:
		if not f.aims or not u.spends(f) or u.store(f) >= pools[f]:
			continue
		var gain := mini(u.store(f) + ceili(f.builds * pools[f]), pools[f])
		if u.actives.any(func(x: Skill): return u.ranged(x) and u.cost_from(x, f) > 0 and (not weak or (u.store(f) < u.cost_from(x, f) and gain >= u.cost_from(x, f) and u.stat(&"focus") > 0.0))):
			log.append("%s steadies itself, building %s" % [u.name, f.name])
			return true
	return false


# About to advance on a foe, it casts a skill that lays tile marks (Behaviour.marks(): Warcry) that would
# do something now, so its walk passes over them. True if it did.
static func _rally(b: Battle, u: Unit, log: Array[String]) -> bool:
	for s in u.actives.filter(func(x: Skill): return x.behaviours.any(func(bh: Behaviour): return bh.marks(b, u)) and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s uses %s" % [u.name, s.name])
			return true
	return false


# With no foe in sight, no clue to search and nowhere its side last saw one to hunt, it casts a skill that
# senses unseen foes (Clairvoyance: Behaviour.senses()), unless it holds a channel already.
static func _scry(b: Battle, u: Unit, log: Array[String]) -> bool:
	if u.channel or (u.faction and not b.last_seen(u.faction).is_empty()):
		return false
	for s in u.actives.filter(func(x: Skill): return x.behaviours.any(func(bh: Behaviour): return bh.senses()) and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s uses %s" % [u.name, s.name])
			return true
	return false
