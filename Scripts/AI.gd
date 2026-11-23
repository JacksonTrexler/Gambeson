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
# A calm follower of a skilled leader (_calm()) skips all of that and drills (_drill()): it reads only
# what is near, heals or strikes, else goes after what its leader went after, else keeps up with it.
# Kept small on purpose: score() and the move choice are the places to grow it.

const KILL := 5.0  # bonus for a hit that should finish the target
const HATE := 2.0  # per point of ominous aura
const GUESS_HP := 10.0  # when it can't make out a target's HP
const OBSERVE := preload("res://Behaviours/observe.gd")  # how far an Observe looks (_search())
const SUSPICIOUS := 1.0  # what a tile it finds suspicious is worth a look, in foes (clues())
const SEEN := 0.9  # a hiding skill foes would see through at least this often isn't worth casting (Battle.seen_odds())
const DEBRIS := 3.0  # debris a hiding foe left, fresh; halved a round on
const MARKED := 0.5  # a mark a foe laid that it knows of
const LAST_SEEN := 0.5  # where its side last made a foe out
const LOST := 0.35  # (below WORTH: it adds to another guess at the tile but is never cast alone; docs/plans/w8-misc.md) a foe its side made out once and has lost track of (the sighting forgotten at the spot): a look where the hunter stands, after the sweep lapses
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
const GRUDGE := 2.0  # per blow a foe has landed on a vindictive unit or its side this fight (Unit.wrongs), up to GRUDGES: how much more it wants that foe (_grudge())
const GRUDGES := 3
const GRUDGED := 5.0  # how much more a vindictive unit wants a target its grudges name (Bio.grudges): under GRUDGES blows' worth, so a foe that keeps striking it ("otherwise aggressed") comes first
const SMITTEN := 2.0  # what a soft skill (no damage, or love) is worth more on a foe a flirty unit fancies; a damaging one is worth half there (_smitten())
const HUNGER := 4.0  # how much more a power hungry unit wants a target, at a full bar of what it would drain (_hunger()): less than a grudge's HUNT
const FEED := 0.25  # the share of its bar a target must hold for a power hungry unit to go and drain it (_richest())
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
const GUESS_DEFENSE := 12  # the Defense it takes a foe to have when it can't make it out (Read.defense null): a medium armor's floor
const BODY := 5.0  # what a body a summon adds is worth, in the HP a blow takes (a Skeleton: 6 HP and a weak Strike; two of them repay its 4 AP, 3 cost)
const SUMMON_SEEN := 10  # tiles a foe it makes out may stand for it to raise a host (_summon())
const POINT := 0.5  # what a point of Energy or other cost it gets back is worth, in the HP a blow takes (a 3 AP strike costs a few)
const STARVE := 5.0  # what starving a Grudge unit to death is worth, as a kill (KILL), shared by the allies it must keep from its reach (_starve())
const WORN := 0.8  # the most of a blow's worth the extra its cost has risen by (exhaustion) can take off it in its reckoning (_wear()): a worn skill is still better than none
const CC := 0.5  # the share of a foe's next turn a cc takes when what carries it can't say (no foresee() afflicts: Brainfog, Interdict, a grip's drowning): a guess (_afflicting())
const BLOCKS := 3  # the blows a plate is taken to block before its holder rests (_plated(): a slot that lapses part way is worth that share)
const BLOW := 5.0  # what a foe's best blow is taken to do to it when it can't make out the foe's skills (Read.skills): a 3 AP, 1d6 + 2 strike (_afflicting())
const ATTACK_STATS: Array[StringName] = [&"strength", &"dexterity", &"intelligence", &"wisdom", &"charisma"]  # what a foe's blows scale on, for a guess at them from its stats (_threat())
const DELAY := 0.5  # the share of a disable's worth left it when its target postpones disablings (the postpone stat: Coyote Charm): it lands as the postpone ends, and one more held adds less (_held()); a guess
const STRUCK := 0.5  # what an HP of a blow a foe's reaction strikes it with on ending a walk beside it costs, in tiles of walking (_struck())
const DREAD := 4.0  # what a cc certain to land costs a tile it would end a turn on, in tiles of walking (_approach(), _retreat(): _dread()); a guess
const STRONG := 0.5  # per level it reads, how much a unit going for the strongest (or weakest) weighs it against distance
const LINE_UP_MARGIN := 2.0  # tiles past its walk and a skill's reach a foe may stand for _line_up() to weigh it (ground can lengthen a reach)
const APPROACH_FAR := 3.0  # tiles past its walk a foe must stand for _approach() to take the nearest free tile beside it, unpriced: where it ends this turn is short of it either way
const HUNT_FAR := 2.0  # tiles past its walk a hunt's goal must lie for it to head straight there (_hunt()), not by the tile beside it (_approach())
const DRILL_MARGIN := 2.0  # tiles past its walk and its longest reach a drilling follower still reads units within (_drill())
const HERD := 3  # like units (_kind()) a side must field, alive, to move as a herd on one plan a side turn (_herd_plan())
const COHESION := 3.0  # tiles a herd member may get ahead of its herd's centre toward the goal before it waits for the rest (_herd())


# What u makes out of every other unit now.
# A typed reads map from a plain dictionary of unit -> Read (the planners take Dictionary[Unit, Read]; tests build theirs by hand).
static func reads_from(d: Dictionary) -> Dictionary[Unit, Read]:
	var out: Dictionary[Unit, Read] = {}
	out.assign(d)
	return out


# `near` >= 0: an ally farther than that many tiles is not read (a foe, or any other unit, always is).
static func _reads(b: Battle, u: Unit, near := -1.0) -> Dictionary[Unit, Read]:
	var reads: Dictionary[Unit, Read] = {}
	Unit.begin_read()  # all reads, nothing changed: each unit's effects are found once (Unit._effects())
	for o: Unit in b.units.values():
		if o != u and (near < 0.0 or not Faction.friends(u.faction, o.faction) or Command.tiles(u.cell, o.cell) <= near):
			reads[o] = b.read(u, o)
	Unit.end_read()
	return reads


# The farthest u's skills reach from where it stands (Battle.skill_reach()).
static func _reach(b: Battle, u: Unit) -> float:
	var reach := 0.0
	for s: Skill in u.actives:
		reach = maxf(reach, b.skill_reach(u, s))
	return reach


# Takes u's turn. `posture` restricts it to abilities that serve one aim, for a unit a commander could
# only direct by intent (HUD default orders): &"offensive" strike only, &"supportive" heal and support
# only, &"defensive" a self-protective skill only. The default (&"") is a full, self-directed turn.
static func act(b: Battle, u: Unit, posture := &"") -> Array[String]:
	var log: Array[String] = []
	b.looks_done(u)  # its opening look, if it still owes it (Battle.lazy_looks)
	if not u.is_alive() or u.stopped():
		return log
	var herd := {}
	if posture == &"" and _calm(b, u):
		_drill(b, u, log)
	elif posture == &"" and _herded(b, u, herd):
		_herd(b, u, herd, log)
	elif posture == &"" and _far(b, u):
		_prowl(b, u, log)
	else:
		_full(b, u, posture, log)
	u.set_meta(&"calm_hp", u.hp)  # what it ended its turn on: less next turn, it was hurt (_calm())
	return log


# The full, self-directed (or posture-restricted) turn: every phase, every preference.
static func _full(b: Battle, u: Unit, posture: StringName, log: Array[String]) -> Array[String]:
	var plain := posture == &"" and u.behaviour == &"" and u.temper() == &"" and u.faction != null  # no nature or temper: allies beyond its reach are of no use to its phases
	var reads := _reads(b, u, _reach(b, u) + 1.0 if plain else -1.0)
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
	if u.restless():  # Restless Dead ??: whatever it was told, whatever its side
		_restless(b, u, reads, log)
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
		if temper == &"flippant":  # not yet punished for it (Unit.temper()): it drains whom it can reach this turn, else skirts the field
			if not (u.tempered(&"power_hungry") and _feed(b, u, reads, log, true)) and not rooted:
				_skirt(b, u, reads, log)
			return log
		_channel(b, u, reads, log)
		if u.channel and u.channel.turns > 0 and not u.channel.skill.behaviours.any(func(x: Behaviour): return x.senses()):  # still holding one it began before (Clairvoyance isn't held: it acts on what it sensed): moving or acting would end it (Battle.end_turn())
			log.append("%s holds still, channeling %s" % [u.name, u.channel.skill.name])
			return log
		if not rooted and _flee(b, u, reads, log):
			reads = _reads(b, u)
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
					else:
						_hunt(b, u, reads, log)  # no one it makes out to lure: toward where its side last saw a foe (a vague shape far off isn't one)
				_sing(b, u, reads, log)
			return log
	if posture == &"" and (_steady(b, u, reads, log) or _starve(b, u, reads, log)):
		return log
	if posture == &"" and not u.pack.is_empty() and not _could_strike(b, u, reads):  # nothing to strike from here: armor first, then the walk
		_dress(b, u, log)
	if posture != &"defensive" and temper != &"stoic":
		while _summon(b, u, reads, log):
			pass
	if temper != &"stoic" and not rooted and _emboldened(u, reads):
		_line_up(b, u, reads, log)  # to the tile its shoves tell most from, if there is one
	if not _strike(b, u, reads, log) and temper != &"stoic":  # the stoic hold, striking only what comes into reach
		var target := _best_target(u, reads)
		if target and _emboldened(u, reads) and not rooted:
			_rally(b, u, log)  # lay its marks first, then walk onto them
			_stretch(b, u, target, log)  # and the tiles that bring a blow in reach this turn
			u.set_meta(&"aim", target)
			_notable(b, u, target, reads[target])
			var dest := _approach(b, u, target, reads)
			_leap(b, u, dest, log)  # a jump first, if it has one that brings it nearer (Hop)
			var p := b.travel(u, dest)
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
		_dress(b, u, log)
	return log


# A follower calm enough to drill (_drill()) rather than weigh its every preference: in the party (Unit.follows)
# of a skilled leader on its own side (Command.skilled(): tagged leader, or high charisma), one that
# is up, not Disturbed, and whose orders carry to it (Command.hears()), and that it makes out. Not calm, and so a
# full turn: hurt since its last turn (calm_hp, act()), cc'd or held, Downed, Restless, struck last by its own side
# or party (betrayed), channeling, or a creature of a special behaviour (Unit.behaviour: skittish, a Siren...).
static func _calm(b: Battle, u: Unit) -> bool:
	var l := u.follows
	if l == null or l.faction != u.faction or not l.is_alive() or l.stopped() or not Command.skilled(l) or not Command.hears(l, u):
		return false
	if u.hp < int(u.get_meta(&"calm_hp", u.max_hp)) or u.dbno != null or u.channel or u.behaviour != &"" or u.restless():
		return false
	var by := u.last_hit_by
	if by != null and by != u and (by.faction == u.faction or by.follows == l or by == l):
		return false
	if not u.afflicted(&"cc").is_empty() or b.held_by(u) or not b.holding(u).is_empty():
		return false
	return b.read(u, l).located()


# A calm follower's turn (_calm()): it reads only the units within its walk, its longest reach and DRILL_MARGIN
# tiles, heals what it would, strikes what it can, else walks on what its leader last went after (the aim meta:
# act(), _strike()) or, with that gone or out of its sight, the foe it would pick, and strikes again; with no foe
# near, it keeps up with its leader. No temper, tending, support, summons, shoves, searching or switching.
static func _drill(b: Battle, u: Unit, log: Array[String]) -> void:
	var l := u.follows
	var near := u.move_left() + DRILL_MARGIN
	Unit.begin_read()
	var reach := 0.0
	for s: Skill in u.actives:
		reach = maxf(reach, b.skill_reach(u, s))
	var reads: Dictionary[Unit, Read] = {}
	for o: Unit in b.units.values():
		if o != u and (o == l or Command.tiles(u.cell, o.cell) <= (reach + 1.0 if Faction.friends(u.faction, o.faction) else near + reach)):  # an ally is only cared for within reach (_heal(), _support()), a foe within its walk too
			reads[o] = b.read(u, o)
	Unit.end_read()
	_remember(b, u, reads)
	_heal(b, u, reads, log)
	if not _strike(b, u, reads, log) and not _rooted(b, u):
		var aim: Variant = l.get_meta(&"aim") if l.has_meta(&"aim") else null
		var target: Unit = aim if is_instance_valid(aim) and aim in reads and aim.is_alive() and _foe(u, reads[aim]) else _best_target(u, reads)
		if target:
			log.append("%s moves %s" % [u.name, b.travel(u, _approach(b, u, target, reads))])
			reads[target] = b.read(u, target)
		else:
			_keep_up(b, u, log)
	while _strike(b, u, reads, log):
		pass


# A plain turn, sure of itself and far from any foe: it has no nature (Unit.behaviour, temper()) and nothing holds or ails
# it, and it makes out no foe - every one is beyond its side's sight, or only a vague shape in it (Battle._plain():
# nothing hides it and u's recon would make it out if it were near) - so there is nothing to strike, weigh or flee,
# and a full turn would only read everyone to find that out.
static func _far(b: Battle, u: Unit) -> bool:
	if not b.sight or not _ordinary(b, u):
		return false
	Unit.begin_read()
	var far := true
	for t: Unit in b.units.values():
		if t != u and t.is_alive() and not Faction.friends(u.faction, t.faction) and b._plain(u, t) not in [0, 1]:
			far = false
			break
	Unit.end_read()
	return far


# Nothing in it or on it that a shortcut turn would miss: no nature or temper (Unit.behaviour, temper()), a side and
# no assumed one, not Downed, channeling, Restless or posing, not cc'd, held or holding (_far(), _herded()).
static func _ordinary(b: Battle, u: Unit) -> bool:
	if u.behaviour != &"" or u.temper() != &"" or u.dbno != null or u.channel or u.faction == null or not u.assumed.is_empty() or u.restless() or b.posing(u):
		return false
	return u.afflicted(&"cc").is_empty() and not b.held_by(u) and b.holding(u).is_empty()


# What a herd is: units of a side alike in class and race (rats, goblins, a line of soldiers): _herd_plan().
static func _kind(u: Unit) -> Array:
	return [u.faction, u.role, u.race]


# u's herd's plan this side turn, made once for all of its kind (_kind()) by the first of them to ask: its members (HERD or
# more, alive), their centre, the foes its side can place (Battle.in_range() >= 1), the longest walk and reach of a member,
# and its goal: the foe its side plainly sees within that walk and reach (plus COHESION) of the centre that is lowest in
# what the herd's blows test (Battle.ranks: HP for the weakest-minded, else its physical or magical Defense, by most of its
# skills) - a walk from the front of a sorted list, no reads - else the plainly seen foe nearest the centre. {} for no herd.
static func _herd_plan(b: Battle, u: Unit) -> Dictionary:
	var cache: Dictionary = b.get_meta(&"herds") if b.has_meta(&"herds") else {}
	if cache.get(&"turn", -1) != b.turns_begun or cache.get(&"side") != u.faction:
		var kinds := {}
		for m: Unit in b.members(u.faction):
			if m.is_alive():
				kinds.get_or_add(_kind(m), []).append(m)
		cache = {&"turn": b.turns_begun, &"side": u.faction, &"kinds": kinds, &"plans": {}}
		b.set_meta(&"herds", cache)
	var k := _kind(u)
	if not cache.plans.has(k):
		cache.plans[k] = _plan(b, cache.kinds.get(k, []))
	return cache.plans[k]


static func _plan(b: Battle, members: Array) -> Dictionary:
	if members.size() < HERD:
		return {}
	var rep: Unit = members[0]
	var centre := Vector2.ZERO
	var walk := rep.stat(&"movement") + _reach(b, rep)  # its kind's (they share a class), whether or not rep has walked yet
	var key := &"hp" if &"weakest" in rep.strategy else &""
	var magic := 0
	for m: Unit in members:
		centre += Vector2(m.cell)
	centre /= members.size()
	if key == &"":
		for s: Skill in rep.foe_actives():
			magic += 1 if &"magical" in Tags.expand(s.tags) else (-1 if &"physical" in Tags.expand(s.tags) else 0)
		key = &"magical" if magic > 0 else &"physical"
	var foes: Array[Unit] = []
	var sides := {}
	var target: Unit = null
	Unit.begin_read()  # the side's eyes once (Battle._eyes())
	for t: Unit in b.units.values():
		if t.is_alive() and not Faction.friends(rep.faction, t.faction) and b.in_range(rep, t) >= 1:
			foes.append(t)
			if t.faction:
				sides[t.faction] = true
	var best := INF
	for f: Faction in sides:
		for t: Unit in b.ranks.lowest(b, f, key):  # lowest first: the first in the herd's reach is its pick from that side
			if t.is_alive() and t in foes and centre.distance_to(Vector2(t.cell)) <= walk + COHESION and b.in_range(rep, t) == 2:
				if Ranks.value(t, key) < best:
					best = Ranks.value(t, key)
					target = t
				break
	var near := INF
	for t: Unit in foes if target == null else []:  # none near: the nearest plainly seen, else the nearest shape
		var d := centre.distance_to(Vector2(t.cell)) + (0.0 if b.in_range(rep, t) == 2 else 1000.0)
		if d < near:
			near = d
			target = t
	Unit.end_read()
	var goal: Variant = target.cell if target else null
	if goal == null:  # no foe it can place: where its side last made one out, nearest the centre (_hunt())
		var seen := b.last_seen(rep.faction)
		for t: Unit in seen:
			if goal == null or centre.distance_to(Vector2(seen[t])) < centre.distance_to(Vector2(goal)):
				goal = seen[t]
	if goal == null:
		return {}
	return {&"members": members, &"centre": centre, &"foes": foes, &"walk": walk, &"target": target, &"goal": goal, &"key": key}


# A herd member that can take its herd's plan (_herd_plan()) in place of a turn of its own: ordinary (_ordinary()), not hurt
# since its last turn (calm_hp, as _calm()) nor struck last by its own side, no side it hunts (Unit.hunts) and no strategy
# but the weakest (the plan's pick), and no foe its side can place within the herd's walk and reach (plus a tile) of it:
# that is a fight, and a full turn. Fills `plan`.
static func _herded(b: Battle, u: Unit, plan: Dictionary) -> bool:
	if not _ordinary(b, u) or not u.hunts.is_empty() or u.strategy.any(func(x: StringName): return x != &"weakest"):
		return false
	if u.hp < int(u.get_meta(&"calm_hp", u.max_hp)) or (u.last_hit_by != null and u.last_hit_by != u and u.last_hit_by.faction == u.faction):
		return false
	var p := _herd_plan(b, u)
	if p.is_empty() or u not in p.members or (p.target != null and not p.target.is_alive()):  # its pick fell this turn: a turn of its own
		return false
	for t: Unit in p.foes:
		if t.is_alive() and Command.tiles(u.cell, t.cell) <= p.walk + 1.0:
			return false
	plan.merge(p)
	return true


# A herd member's turn (_herded()): it heads for the tile beside its herd's goal nearest it (_beside()), no reads and no
# route pricing; one that has got more than COHESION tiles ahead of the herd's centre waits for the rest. The herd keeps
# together by sharing one goal from one centre. Its goal becomes its aim (_drill(): what a follower of it would go after).
static func _herd(b: Battle, u: Unit, plan: Dictionary, log: Array[String]) -> void:
	var goal: Vector2i = plan.goal
	var centre: Vector2 = plan.centre
	var ahead := centre.distance_to(Vector2(goal)) - Vector2(u.cell).distance_to(Vector2(goal))
	if plan.target:
		u.set_meta(&"aim", plan.target)
	if ahead > COHESION:
		log.append("%s waits for its herd" % u.name)
		return
	if not _rooted(b, u) and Command.tiles(u.cell, goal) > 1:
		log.append("%s herds %s" % [u.name, b.travel(u, _beside(b, u, goal))])


# A far turn (_far()): it reads the foes it can place (a vague shape: cheap) and the allies within its longest
# reach (as _drill()), heals and supports as it would, and goes where its side last made a foe out
# or where the clues point (_search(), _scry(), _hunt()); a foe it comes to make out on the way is struck. No weighing
# of temper, tending, summons, shoves, steadying, switching or starving: nothing there is in sight to weigh them on.
static func _prowl(b: Battle, u: Unit, log: Array[String]) -> void:
	var reads := _reads(b, u, _reach(b, u) + 1.0)
	_remember(b, u, reads)
	_heal(b, u, reads, log)
	_support(b, u, reads, log)
	var rooted := _rooted(b, u)
	if not _search(b, u, log) and not _scry(b, u, log) and not rooted:
		_hunt(b, u, reads, log)
	while _strike(b, u, reads, log):
		pass
	_replenish(b, u, log)
	_dress(b, u, log)


# u's interrupt (Battle.interrupter: Final Act), one free skill use, no walking: its best blow at a foe
# in reach; with none, the heal it wants most (itself among those it weighs: back above 0 HP, it lives);
# with neither, it passes. Reactions needing no choice the battle resolves itself (Battle.react()).
static func interrupt(b: Battle, u: Unit) -> Array[String]:
	var log: Array[String] = []
	if b.interrupter != u:
		return log
	var reads := _reads(b, u)
	if not _strike(b, u, reads, log):
		_heal(b, u, reads, log)
	if b.interrupter == u:
		log.append("%s passes" % u.name)
		b.end_interrupt()
	return log


# Helpful (Bio): with no one to heal in reach, it goes to the ally it most wants to heal (want()) and
# heals it. Other healers heal only whom they happen to reach.
static func _tend(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
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
static func _last_blows(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	if _save_self(b, u, log):
		return
	var target := _best_target(u, _reachable(b, u, reads))
	if target and not Battle.next_to(u.cell, reads[target].cell) and not _rooted(b, u):
		log.append("%s closes in %s" % [u.name, b.travel(u, _approach(b, u, target, reads))])
	var near: Dictionary[Unit, Read] = {}
	for o: Unit in reads:
		if Battle.next_to(u.cell, o.cell):
			near[o] = b.read(u, o)
	while u.dbno and (u.dbno.spare() != 0 or u.dbno.left <= 1) and _strike(b, u, near, log, true):
		pass


# The foes it could walk up to this round, of reads: the ones beside it, and those with a tile beside them its walk (as
# it expects it) ends on (_approach()). A Grudge unit makes its blow this round or dies of it, so it goes for what it
# can reach rather than the foe it would otherwise want most (the nearest, the strongest). With none in reach: all of them.
static func _reachable(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> Dictionary[Unit, Read]:
	var out: Dictionary[Unit, Read] = {}
	for t: Unit in reads:
		var r: Read = reads[t]
		if not t.is_alive() or not _foe(u, r) or not r.located():
			continue
		if Battle.next_to(u.cell, r.cell):
			out[t] = r
			continue
		var c := _approach(b, u, t, reads)
		var path: Array = b.walk(u, c, true).path
		if not path.is_empty() and path[-1] == c:
			out[t] = r
	return reads if out.is_empty() else out


# Downed and acting (Grudge) with a heal that, by what it declares it restores, would bring it back above 0
# HP: it casts the strongest, saved and standing rather than spent in its last rounds. A use against its
# allowance, but the one that saves it. False if it has none, or none enough (a gamble it doesn't take).
static func _save_self(b: Battle, u: Unit, log: Array[String]) -> bool:
	var best: Skill = null
	var most := 0
	for s: Skill in u.actives.filter(func(x: Skill): return _mends(b, u, x) and u.can_afford(x) and b.in_reach(u, x, u)):
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
static func _starving(u: Unit, reads: Dictionary[Unit, Read]) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in reads:
		if o.is_alive() and o.dbno and o.dbno.rule.acts and o.dbno.rule.melee and not o.dbno.meleed and _foe(u, reads[o]) and reads[o].located():
			out.append(o)
	return out


# Starving a Grudge unit of melee: it must make one this round or die (Downed.rule.melee), so u doesn't hand it
# the blow - it keeps beyond its walk and one tile (its movement + 1), or, out of its reach already, holds
# where it stands rather than close - unless it can finish it with a blow (its low roll past the Downed limit)
# or shoot from beyond that reach. Whether that is worth the strikes it gives up (starve_worth()): the foes
# it would turn from, or the allies it would be asking to do the same, weigh against it. True if the turn is
# spent so.
static func _starve(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	var owing := _starving(u, reads)
	if owing.is_empty() or _rooted(b, u):
		return false
	for g in owing:
		for s: Skill in u.foe_actives():
			if b.in_reach(u, s, g) and b.can_afford(u, s, g) and Battle.damage_range(u, s, g, b).get("lo", 0) > g.hp + g.dbno.limit:
				return false  # one blow ends it
	var worth := 0.0
	for g in owing:
		worth += starve_worth(b, u, g)
	if worth <= _best_strike(b, u, owing, reads):
		return false
	var threat := func(g: Unit) -> bool: return Command.tiles(u.cell, g.cell) <= ceili(g.stat(&"movement")) + 1
	if not owing.any(threat):
		return not _could_strike(b, u, reads)  # out of its reach: shoot if it can, else wait
	var from: Array[Vector2i] = []
	for g in owing:
		from.append(g.cell)
	var safe := 0  # beyond the farthest reach among them it is out of all; short of that, room to back off wins
	for g in owing:
		safe = maxi(safe, ceili(g.stat(&"movement")) + 2)
	if _away(b, u, from, safe, reads):
		log.append("%s keeps from %s's reach, starving it of a blow" % [u.name, owing[0].name])
		return true
	return false


# What starving the Downed Grudge unit g of its melee is worth u, in the score's own HP: STARVE (a kill, as
# KILL is) shared by the units of u's side, itself too, standing in g's reach (its movement + 1): each
# would have to keep out of it, or g takes the blow from one of them. Nothing once g dies of its rounds
# anyway (Downed.State.left: 1 or fewer, the several rounds a longer Grudge lasts are starved one by one,
# each as this one is, since the turn is judged afresh).
static func starve_worth(b: Battle, u: Unit, g: Unit) -> float:
	if g.dbno == null or g.dbno.left <= 1:
		return 0.0
	var reach := ceili(g.stat(&"movement")) + 1
	var n := 0
	for o: Unit in b.units.values():
		if o.is_alive() and not o.helpless() and Faction.friends(o.faction, u.faction) and Command.tiles(o.cell, g.cell) <= reach:
			n += 1
	return STARVE / maxf(n, 1.0)


# The best strike u could make now at a standing foe it reads other than `besides`, by score(): what holding
# back from a Grudge unit gives up. 0 with none.
static func _best_strike(b: Battle, u: Unit, besides: Array[Unit], reads: Dictionary[Unit, Read]) -> float:
	var best := 0.0
	for s: Skill in u.foe_actives(true):
		for t: Unit in reads:
			if t not in besides and t.is_alive() and not t.helpless() and _foe(u, reads[t]) and reads[t].located() and b.in_reach(u, s, t) \
					and s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
				best = maxf(best, score(u, s, reads[t], b, t))
	return best


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


# The chance u's s hits t, as the player's own forecast would show it: t's Defense as r has it, or
# GUESS_DEFENSE where u can't make it out (Read.defense: its armor doesn't show). A lie about it (Perception._lie())
# is believed, as the HUD's odds believe it.
static func _chance(u: Unit, s: Skill, r: Read, b: Battle, t: Unit) -> float:
	return Battle.hit_chance(u, s, t, b, r.believed(GUESS_DEFENSE))


# Perceived worth of using a hostile skill on a unit read as `r`. Given the battle and the unit (`t`, the
# one `r` reads), it reads what the player's forecast shows: the chance to hit (Battle.hit_chance(): the
# skill's edge, its behaviours' edge() and guard() - Gank's ambush, Spike's Defense - the target's
# Defense as r has it, else GUESS_DEFENSE), the damage (damage_range()) and what rides on it (Battle.foresee():
# Kick's tile and blast, Poach's regain, Slam Jam's interrupt at its odds; each rider RIDER, `spill` as it is).
# Then what those can't say, from hooks any behaviour joins: the AP and cost it gives back (refunds(): Poach,
# Slam Jam; a cost point is worth POINT) and the Defense it costs its caster (unguarded(): Sutemi's Off Balance).
static func score(u: Unit, s: Skill, r: Read, b: Battle = null, t: Unit = null) -> float:
	var d := Battle.damage_range(u, s, t, b) if b and t else Battle.damage_range(u, s)  # as cast() deals it: through u's modifiers
	var dmg: float = d.get("avg", 0.0)
	var hp: float = maxf(r.hp, 1.0) if r.hp != null else GUESS_HP  # (one Downed, at 0 or below: any blow may be its last)
	var p := 1.0
	var riders := 0.0
	var spill := 0.0
	var saved := 0.0
	var toll := 0
	var cc := 0.0
	var blocked := 0.0
	if b and t:
		p = _chance(u, s, r, b, t)
		if s.attacks() and not (s.check and not s.check.suspicion) and not s.levels_down and p > 0.0:
			var glance := Battle.attack_odds(u, s, t, b, r.believed(GUESS_DEFENSE))[2] / p  # (the share of its hits that are glances)
			dmg *= (2.0 if s.sure_crit else 1.0) * (1.0 - glance) + 0.5 * glance  # a glance lands half; a use whose hits all crit (Jugular) lands the rest double, as_rolled() does
			dmg *= _use_ratio(b, u, s, t, r, d)  # friction on its rolls, a pool its passives make of them
		blocked = _blocks(b, u, s, r, t, float(d.get("avg", 0.0)))
		var more := b.foresee(u, s, t)
		cc = _afflicting(b, u, s, r, t, more)
		if not more.is_empty():
			dmg += (more.lo + more.hi) / 2.0
			riders = more.riders
			spill = more.spill
		if not s.behaviours.is_empty():
			var c := b.cast_of(u, s, t, u.rank(s), true)
			var share := 0.0
			for bh in s.behaviours:
				share += bh.refunds(c, p)
				toll += bh.unguarded(c)
			var fund: Variant = u.funding(s)
			saved = minf(share, 1.0) * (u.ap_cost(s, fund) * AP + u.cost_from(s, fund) * POINT)
	var held := _held(r, t) if s.disables else 1.0  # (a disable that waits)
	var value := minf(dmg, hp) + (KILL if dmg >= hp else 0.0) + ((1.0 if not s.effects.is_empty() else held) if s.hostile and (not s.effects.is_empty() or s.disables) and &"cc" not in u.skill_tags(s) else 0.0) + cc * held \
			+ (KILL if s.drags() else 0.0) + RIDER * riders + spill  # into the water: the Siren's favourite
	return p * value + saved + blocked - DEFENSE * toll - _hate(r)


# A self-directed turn with no blow to strike from where it stands, and what is left of one that struck, go to armor it carries (Unit.pack): the one that adds most (_plated(): its Defense, less its
# tolls) to an armor slot its skills give (Unit.plate_slots()) that works now, over what is worn in it (Unit.plate_defense(): that slot's rules, so
# Scrap Plating's cap and Power Armor's gate are read, not guessed). One a turn (armor takes most of one: Item.ap_cost());
# none where nothing would add any, or the AP is short (Battle.equip()). What it takes off goes back in the pack.
static func _dress(b: Battle, u: Unit, log: Array[String]) -> void:
	if u.pack.is_empty():
		return
	var best: Array = []
	var gain := 0
	var net := 0.0001
	for s: Skill in u.plate_skills():
		if not u.plate_works(s):
			continue
		var slot := Unit.plate_slot(s)
		var worn: Item = u.get(slot)
		var now := 0
		if worn:
			now = maxi(u.plate_defense(s, worn), 0) if u.can_wear(worn) else 0
		for it in u.pack:
			var d := u.plate_defense(s, it) if it and it.slot == "armor" and u.can_wear(it) else Behaviour.NO_ARMOR
			if d != Behaviour.NO_ARMOR and d > now and _plated(u, s, d) - _plated(u, s, now) > net:
				net = _plated(u, s, d) - _plated(u, s, now)
				gain = d - now
				best = [slot, it]
	if not best.is_empty():
		var worn: Item = u.get(best[0])
		if b.equip(u, best[1], best[0]):
			u.pack.erase(best[1])
			if worn:
				u.pack.append(worn)
			log.append("%s puts on %s, +%d Defense" % [u.name, best[1].name, gain])


# What `defense` points in the slot skill s gives are worth u, in Defense, for what its blocks cost it: each blow the plate blocks
# saves the blow (BLOW) and takes its skill's toll off u's Power (Behaviour.slot_toll() at that blow, POINT a point), so the Defense
# keeps the share of a block's worth the toll leaves (none, at a toll of BLOW / POINT or more). Scrap Plating's toll is 0: all of it.
# Each block also runs its holder's Power down, so the slot works for only the first of BLOCKS blows its rules (Behaviour.slot_works()
# `spent`) still let it, and the Defense is worth that share of itself: a Power Armor with Power just over its gate is worth one block.
static func _plated(u: Unit, s: Skill, defense: int) -> float:
	var toll := 0
	for bh in s.behaviours:
		toll += bh.slot_toll(u, u.own_rank(s), roundi(BLOW)) if bh else 0
	var blocks := 0
	while blocks < BLOCKS and u.plate_works(s, blocks * toll):
		blocks += 1
	return float(defense) * clampf(1.0 - toll * POINT / BLOW, 0.0, 1.0) * blocks / BLOCKS


# What the plates t wears cost it when they block u's s: each armor slot its skills give it (Unit.plated_defense(), seen once
# its armor shows: Read.defense) blocks the blows that would have hit without it - the chance s has with its Defense, less
# the plate's, over the chance it has - and each block takes its skill's toll (Behaviour.slot_toll(): Power Armor's Power) off t
# at POINT a point, for an attack of `dmg`. 0 for a foe in no plate, one whose armor isn't read, or a plate that takes nothing.
static func _blocks(b: Battle, u: Unit, s: Skill, r: Read, t: Unit, dmg: float) -> float:
	if t.plating.is_empty() or r.defense == null or not s.attacks() or (s.check and not s.check.suspicion) or s.levels_down:
		return 0.0
	var worth := 0.0
	var with := Battle.hit_chance(u, s, t, b, r.believed(GUESS_DEFENSE))
	for pair in t.plated_defense():
		var toll := 0
		for bh in pair[0].behaviours:
			toll += bh.slot_toll(t, t.own_rank(pair[0]), roundi(dmg)) if bh else 0
		if toll > 0 and pair[1] > 0:
			worth += maxf(Battle.hit_chance(u, s, t, b, r.believed(GUESS_DEFENSE) - pair[1]) - with, 0.0) * toll * POINT
	return worth


# What is left of a disable's worth against t: all of it, unless r reads t to postpone disablings (Unit.postponing_in(): a status
# with the postpone stat, so any source of one, not the Coyote Charm alone). Then it is held, not working, till that ends: DELAY, and
# less for each disabling t already holds (Unit.postponed: what its side cast into the wait).
static func _held(r: Read, t: Unit) -> float:
	if t == null or not Unit.postponing_in(r.effects):
		return 1.0
	return DELAY / (1.0 + t.postponed.size())


# What a skill's cc takes from the foe t's next turn, in HP: the share of the turn it takes (what its behaviours foresee,
# Battle.foresee() `afflicts`: as likely as it lands; CC where only the skill's cc tag says it is one) of what that turn
# is worth - the most blow t reads to have against u (_threat()) - and less for the cc t already bears: none from a
# unit that is stopped, a share fewer for each status bearing cc it is read to have (Unit.bearing(): what r has of its
# effects). 0 for a skill that isn't hostile, or carries none.
static func _afflicting(b: Battle, u: Unit, s: Skill, r: Read, t: Unit, more: Dictionary) -> float:
	var share: float = more.get("afflicts", 0.0)
	if share <= 0.0 and s.hostile and &"cc" in u.skill_tags(s):
		share = CC
	if share <= 0.0 or t.stopped():
		return 0.0
	return share * _threat(b, u, r, t) / (1.0 + Unit.bearing(r.effects, &"cc").size())


# What a turn of t's is worth to it against u: the average blow of the best hostile skill it reads to have (r.skills,
# at its hit chance on u, as it would be cast); else, from its stats if they show (the best attack stat's modifier
# added to BLOW), else BLOW alone. Never more than u has left.
static func _threat(b: Battle, u: Unit, r: Read, t: Unit) -> float:
	var best := -1.0
	for s: Skill in r.skills:
		if s.hostile and s.attacks():
			best = maxf(best, float(Battle.damage_range(t, s, u, b).get("avg", 0.0)) * Battle.hit_chance(t, s, u, b))
	if best < 0.0:
		best = BLOW
		for k in ATTACK_STATS:
			if r.stats.has(k):
				best = maxf(best, BLOW + floorf((float(r.stats[k]) - 10.0) / 2.0))
	return minf(best, float(u.hp))


# How much more or less a use of s is expected to deal than score() reckons by its first roll's odds (hit chance x
# every hit's damage): its rolls' own odds (friction: a use that loops, Chaser's chase, runs the later rolls at
# disadvantage, Battle.friction_ahead(); a chain stops at its first miss), what its holder's passives make of them
# (Behaviour.forecasting(): Heavy Strike pools them behind a last roll) and the uses a critical sets off (Forecast.loops:
# a Chaser's chases, a Jugular's recasts): each as likely as the crits before it, and itself a use like this one, the rolls
# its chain has made so far at friction (Forecast.rolled), against the same reckoned without any of it.
# 1 for the plain case, which it doesn't work out. `d`: s's damage_range().
static func _use_ratio(b: Battle, u: Unit, s: Skill, t: Unit, r: Read, d: Dictionary) -> float:
	var f := _forecast(b, u, s, t, r, d, -1)
	var worth := f.worth
	if worth < 0.0:
		if f.loops == 0 and b.friction_ahead(u, f.rolls - 1) == 0:
			return 1.0
		worth = f.landings()
	var live := 1.0
	var more := f
	for k in f.loops:
		live *= more.crits()
		if live < 0.001:
			break
		more = _forecast(b, u, s, t, r, d, k * f.rolls)
		worth += live * (more.worth if more.worth >= 0.0 else more.landings())
	f.flat = true
	var plain := f.landings()
	return worth / plain if plain > 0.0 else 1.0


# A use of s as the Forecast reads it, the passives of u asked what they make of it (a follow-up a crit sets off: rolled).
static func _forecast(b: Battle, u: Unit, s: Skill, t: Unit, r: Read, d: Dictionary, rolled: int) -> Behaviour.Forecast:
	var f := Behaviour.Forecast.new()
	f.battle = b
	f.caster = u
	f.skill = s
	f.target = t
	f.tags = Battle.hit_tags(u, s, t, b)
	f.guess = r.believed(GUESS_DEFENSE)
	f.rolls = 1 if not s.chain else (1 if u.stat(&"single") > 0.0 else u.mods(s).irank(u.rank(s), &"rank_impact"))
	f.per = float(d.get("avg", 0.0)) / f.rolls
	f.rolled = rolled
	if s.recast_on_crit:  # (a flag of the skill's, read as Battle.cast() reads it)
		f.loops = Battle.RECAST_LIMIT
		f.grace = u.mods(s).irank(u.rank(s), &"rank_impact")
	for h in u.hooks():
		h[0].forecasting(b, u, h[1], f)
	return f


static func _hunted(u: Unit, t: Unit, r: Read) -> float:
	return (HUNT if r.faction != null and r.faction in u.hunts else 0.0) + _grudge(u, t, r) + _hunger(u, t, r)


# A vindictive unit's grudge against t (read as r): GRUDGE per blow t has landed this fight on it or its side (Unit.wrongs:
# word of a blow on its own travels), up to GRUDGES, and GRUDGED if its grudges name t (Bio.grudges, Bio.names(): a Starman's "astral", a
# standing grudge on every astral foe, which a few blows from anyone else outweigh). 0 for any other temper (Unit.tempered()).
static func _grudge(u: Unit, t: Unit, r: Read) -> float:
	if not u.tempered(&"vindictive"):
		return 0.0
	var n := 0
	for f: Faction in t.wrongs:
		if Faction.friends(u.faction, f):
			n += t.wrongs[f]
	return GRUDGE * mini(n, GRUDGES) + (GRUDGED if u.bio and Bio.names(u.bio.grudges, r) else 0.0)


# A power hungry unit's appetite for t (read as r): HUNGER times the share of its bar t holds (_fill()). 0 for any other temper.
static func _hunger(u: Unit, t: Unit, r: Read) -> float:
	return HUNGER * _fill(t, r)[1] if u.tempered(&"power_hungry") else 0.0


# What a power hungry unit sees in t (read as r): [rank, share] - rank 2 for Power (Unit.powered()), 1 for Energy, 0 for
# reserves only; share, of its max, what it holds as read (Read.energy; reserves: any held, 1). [-1, 0.0]: nothing it makes out.
static func _fill(t: Unit, r: Read) -> Array:
	if r.energy != null and int(r.energy) > 0 and t.max_energy > 0:
		return [2 if t.powered() else 1, float(r.energy) / t.max_energy]
	if r.stores.values().any(func(n: int): return n > 0):
		return [0, 1.0]
	return [-1, 0.0]


# The unit a power hungry one would drain: of those it makes out that aren't its own side (foes and neutrals alike), the one with the
# most Power, else Energy, else reserves (_fill()), holding at least FEED of its bar. null: none.
static func _richest(u: Unit, reads: Dictionary[Unit, Read]) -> Unit:
	var best: Unit = null
	var best_fill := [-1, 0.0]
	for o: Unit in reads:
		var r: Read = reads[o]
		if o == u or not o.is_alive() or not r.located() or Faction.friends(u.faction, o.faction) or r.attitude(u) == &"ignore":
			continue
		var f := _fill(o, r)
		if f[0] >= 0 and f[1] >= FEED and (f[0] > best_fill[0] or (f[0] == best_fill[0] and f[1] > best_fill[1])):
			best = o
			best_fill = f
	return best


# A skill of u's it can pay for now that drains what a unit holds (tagged siphon: Energy Transfer). null: none.
static func _siphon(u: Unit) -> Skill:
	for s: Skill in u.actives:
		if s.hostile and not s.on_tile() and &"siphon" in u.skill_tags(s) and u.can_afford(s):
			return s
	return null


# Power Hungry: to the tile beside the richest unit it makes out (_richest()), by a jump if that brings it nearer (_leap()), then it
# drains it (_siphon()) as often as it can. `near`: only one it can come beside this turn. Whether it did anything.
static func _feed(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String], near := false) -> bool:
	var s := _siphon(u)
	var t: Unit = _richest(u, reads) if s else null
	if t == null:
		return false
	var jump := _jump(u)
	var far := Command.tiles(u.cell, t.cell)
	if near and far > ceili(u.move_left() + (b.area_reach(u, jump) if jump else 0.0) + b.skill_range(u, s, t)):
		return false
	var acted := false
	if far > 1 and not _rooted(b, u):
		var goal := _beside(b, u, t.cell)
		acted = _leap(b, u, goal, log)
		if Command.tiles(u.cell, t.cell) > 1:
			acted = not b.travel(u, goal).is_empty() or acted
	while s and Vector2(u.cell).distance_to(Vector2(t.cell)) <= b.skill_range(u, s, t) + 0.0001 and b.cast(u, s, t):
		log.append("%s drains %s" % [u.name, t.name])
		acted = true
		s = _siphon(u) if t.is_alive() and _fill(t, b.read(u, t))[1] >= FEED else null
	return acted


# A jump it can make now (a tile skill tagged jump: Hop). null: none.
static func _jump(u: Unit) -> Skill:
	for s: Skill in u.actives:
		if s.on_tile() and &"jump" in u.skill_tags(s) and u.can_afford(s):
			return s
	return null


# Jumps (_jump()) to the landing nearest `goal` (Behaviour.fits_at(): not onto void), if that is nearer than it could walk. Whether it did.
static func _leap(b: Battle, u: Unit, goal: Vector2i, log: Array[String]) -> bool:
	var s := _jump(u)
	if s == null:
		return false
	var walked := maxf(Command.tiles(u.cell, goal) - u.move_left(), 0.0)  # about how far short a walk leaves it
	var best := u.cell
	var best_d := walked
	for c in b.cells_near(u.cell, b.area_reach(u, s)):
		var d := float(Command.tiles(c, goal))
		if d < best_d - 0.5 and s.behaviours.all(func(x: Behaviour): return not x or x.fits_at(b, u, c)):
			best = c
			best_d = d
	if best == u.cell or not b.cast_at(u, s, best):
		return false
	log.append("%s jumps to %s" % [u.name, best])
	return true


# Flippant: skirts the field aimlessly, out of its foes' reach (their walk and a tile) - a tile picked at random among the few it
# tries (a walk, or a jump when no walk will do), never scored, so the turn costs little; none safe, it backs off (_away()).
static func _skirt(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	var foes := []
	for o: Unit in reads:
		if o.is_alive() and _foe(u, reads[o]):
			foes.append([reads[o].cell, ceili(o.stat(&"movement")) + 1])
	var safe := func(c: Vector2i) -> bool: return foes.all(func(f: Array): return Command.tiles(c, f[0]) > f[1])
	var picks: Array[Vector2i] = []
	for c in b.cells_near(u.cell, u.move_left()):
		if c != u.cell and not b.unit_at(c) and b.footing(u, c) and safe.call(c):
			picks.append(c)
	for i in mini(picks.size(), 4):  # a few at random: the first it can walk to whole
		var c: Vector2i = picks.pop_at(b.rng.randi_range(0, picks.size() - 1))
		var path: Array = b.walk(u, c, true).path
		if not path.is_empty() and path[-1] == c:
			log.append("%s skirts %s" % [u.name, b.travel(u, c)])
			return
	var s := _jump(u)
	if s:
		var lands: Array[Vector2i] = []
		for c in b.cells_near(u.cell, b.area_reach(u, s)):
			if safe.call(c) and s.behaviours.all(func(x: Behaviour): return not x or x.fits_at(b, u, c)):
				lands.append(c)
		if not lands.is_empty() and b.cast_at(u, s, lands[b.rng.randi_range(0, lands.size() - 1)]):
			log.append("%s hops off to %s" % [u.name, u.cell])
			return
	var from: Array[Vector2i] = []
	for f in foes:
		from.append(f[0])
	if not from.is_empty() and _away(b, u, from, 0, reads):
		log.append("%s skirts away" % u.name)


# Whether a flirty unit feels for the unit it reads as r: its fancies name it (Bio.fancies), or, naming none, its charisma as read
# is high on the ladder (Difficulty.stat_at("high")), or, with no stats read, it looks it (a benevolent look: Beautiful, Radiant).
static func _fancies(u: Unit, r: Read) -> bool:
	if not u.tempered(&"flirty") or r == null:
		return false
	if u.bio and not u.bio.fancies.is_empty():
		return Bio.names(u.bio.fancies, r)
	if r.stats.has(&"charisma"):
		return r.stats[&"charisma"] >= Difficulty.stat_at(&"high")
	return Bio.aura(r.looks) > 0


# A soft skill: one that does no damage, or love.
static func _soft(u: Unit, s: Skill) -> bool:
	return s.tiers.is_empty() or &"love" in u.skill_tags(s)


# v, the worth of s on a foe read as r, as a flirty unit that fancies it weighs it: a soft skill SMITTEN more, a damaging one half.
static func _smitten(u: Unit, s: Skill, r: Read, v: float) -> float:
	if not _fancies(u, r):
		return v
	return v + SMITTEN if _soft(u, s) else v * 0.5


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
static func _emboldened(u: Unit, reads: Dictionary[Unit, Read]) -> bool:
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
static func _flee(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	if u.temper() != &"timid":
		return false
	var scary: Array[Vector2i] = []
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and not o.stopped() and r.located() and r.attitude(u) == &"avoid" and Command.tiles(r.cell, u.cell) <= CRAVEN_REACH:
			scary.append(r.cell)
	if scary.is_empty() or not _away(b, u, scary, 0, reads):
		return false
	log.append("%s backs away" % u.name)
	return true


# Casts the best hostile skill it can right now; false if nothing is in reach and affordable. The
# beloved are spared only while there are other foes to fight. attacks_only: skip dual skills (Sing).
# least: only a strike worth more than this (a traitor keeping its cover: a kill).
static func _strike(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String], attacks_only := false, least := 0.0) -> bool:
	var best := []
	var best_score := least
	var spared := []
	Unit.begin_read()  # weighing only, nothing changes until it casts: each unit's effects are found once (Unit._effects())
	for s: Skill in u.foe_actives().filter(func(x: Skill): return not (attacks_only and x.dual)):
		for t: Unit in reads:
			var r: Read = reads[t]
			if not _foe(u, r) or not t.is_alive() or not b.in_reach(u, s, t) or not b.can_afford(u, s, t):
				continue
			if not s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
				continue  # not one it can be used on (Gank: no ally near it; Sutemi: no way through)
			if s.drags() and (b.drag_spot(u, s, t) == null or s.effects.any(func(e: Effect): return e in t.timed)):
				continue
			var v := score(u, s, r, b, t) + FOCUS * u.focus_forecast(s) - (1.0 if s.hostile and not s.effects.is_empty() and s.effects[0] in r.effects else 0.0) + _hunted(u, t, r)
			v = _smitten(u, s, r, v)
			if v > 0.0:
				v *= 1.0 - _foiled(b, u, s, t, reads)  # what its foes' reactions would likely take off it
				v = maxf(v - _reprisal(b, u, s, t, reads), v * (1.0 - FOILED))  # and what they would cost it
				v = maxf(v - _wear(u, s, b, t, r), v * (1.0 - WORN))  # and what its own wear adds to the price
				v += _relief(b, u, s, t, r)  # and what a death gives its other counts back
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
	Unit.end_read()
	if best.is_empty():
		return false
	var was: Read = reads[best[1]]
	if not b.cast(u, best[0], best[1]):
		return false
	log.append("%s uses %s on %s -> %d" % [u.name, best[0].name, best[1].name, best[1].hp])
	_notable(b, u, best[1], was, best[0])
	u.set_meta(&"aim", best[1])  # what it went after: its followers' aim (_drill())
	reads[best[1]] = b.read(u, best[1])
	return true


# Restless Dead ?? (Unit.restless()): the nearest living unit it sees (a foe to it: Read.dead_eye), in tiles, its
# own side's on a tie; it strikes that one with its best blow, else walks up to it first. Nothing else.
static func _restless(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	var prey := _prey(u, reads)
	if prey == null:
		return
	var only := reads_from({prey: reads[prey]})
	if not _strike(b, u, only, log) and not _rooted(b, u):
		log.append("%s lurches %s" % [u.name, b.travel(u, _approach(b, u, prey, reads))])
		only[prey] = b.read(u, prey)
	while _strike(b, u, only, log):
		pass


static func _prey(u: Unit, reads: Dictionary[Unit, Read]) -> Unit:
	var prey: Unit = null
	for t: Unit in reads:
		var r: Read = reads[t]
		if not t.is_alive() or not _foe(u, r) or not r.seen:
			continue
		var d := Command.tiles(u.cell, r.cell)
		var pd := Command.tiles(u.cell, reads[prey].cell) if prey else 0
		if prey == null or d < pd or (d == pd and t.faction == u.faction and prey.faction != u.faction):
			prey = t
	return prey


# Raises a host: a tile skill whose cast adds bodies (Behaviour.bodies(): Skeleton) cast near itself, toward the nearest foe
# it makes out within SUMMON_SEEN, while the bodies it would keep (Behaviour.bodies(): under a summon's soft cap) at BODY each are worth more than what
# the cast costs it (AP, POINT, as score() weighs a rebate) and its wear. The best such skill; false if none was cast.
static func _summon(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	var foe: Variant = null
	for t: Unit in reads:
		var r: Read = reads[t]
		if t.is_alive() and _foe(u, r) and r.located() and Command.tiles(u.cell, r.cell) <= SUMMON_SEEN \
				and (foe == null or Command.tiles(u.cell, r.cell) < Command.tiles(u.cell, foe)):
			foe = r.cell
	if foe == null:
		return false
	var best: Skill = null
	var best_net := 0.0
	for s: Skill in u.actives:
		if not s.on_tile() or not u.can_afford(s) or s.hostile:
			continue
		var n := 0
		var c := b.cast_of(u, s, null, u.rank(s), true)
		for bh in s.behaviours:
			n += bh.bodies(c)
		if n <= 0:
			continue
		var fund: Variant = u.funding(s)
		var net := n * BODY - (u.ap_cost(s, fund) * AP + u.cost_from(s, fund) * POINT) - _wear(u, s)
		if net > best_net:
			best = s
			best_net = net
	if best == null:
		return false
	var spot: Variant = null
	for c: Vector2i in b.cells_near(u.cell, b.area_reach(u, best)):
		if b.unit_at(c) == null and b.on_map(c) and Vector2(u.cell).distance_to(Vector2(c)) <= b.area_reach(u, best) + 0.0001 \
				and (spot == null or Command.tiles(c, foe) < Command.tiles(spot, foe)):
			spot = c
	if spot == null or not b.cast_at(u, best, spot):
		return false
	log.append("%s raises %s at %s" % [u.name, best.name, spot])
	return true


# What s's cost has risen by since it was fresh (Exhaustion), in the HP a blow takes: the AP and the cost
# points it pays beyond the first-use price, weighed as score() weighs a rebate (AP, POINT). It takes the
# worn skill's share off the score, so a unit with another blow nearly as good varies its skills.
# A blow that would kill t (its average damage meets t's HP) keeps the use unworn as far as its passives'
# wearing() hooks say (Deathlust: a killing skill gains no use), asked as Battle settles a use, not by name.
static func _wear(u: Unit, s: Skill, b: Battle = null, t: Unit = null, r: Read = null) -> float:
	var rate := u.exhaustion.rate(s)
	if rate <= 1.0001:
		return 0.0
	var fund: Variant = u.funding(s)
	var cost := (1.0 - 1.0 / rate) * (u.ap_cost(s, fund) * AP + u.cost_from(s, fund) * POINT)
	if t and r and r.hp != null and Battle.damage_range(u, s, t, b).get("avg", 0.0) >= r.hp:
		var w := Exhaustion.Wear.new()
		w.skill = s
		w.caster = u
		w.target = t
		w.gain = 1.0
		w.uses = 1.0
		w.felled[t] = &"killed"
		for h in u.hooks():
			h[0].wearing(b, u, h[1], w)
		cost *= clampf(w.uses / w.gain, 0.0, 1.0)  # the share of the use it keeps
	return cost


# What a death it would cause gives its other skills' counts back, in the HP their extra cost is worth (_wear()'s terms): a blow of s
# that would kill t (its average meets t's HP) is asked of u's passives as Battle.neutralize() asks them, neutralized() with the dying
# unit and how = killed, on u's own counts (any other holder is not weighed), and the most any other skill's extra cost falls by is the
# worth (it spends its next blow on one of them: the largest, not the sum). The counts are put back after. Not by name: any passive
# whose neutralized() eases its holder's exhaustion joins. 0 for a blow that wouldn't kill, a unit with no passive, or nothing worn.
static func _relief(b: Battle, u: Unit, s: Skill, t: Unit, r: Read) -> float:
	if not Exhaustion.on or u.exhaustion.uses.is_empty() or r.hp == null or u.on_passives.is_empty() or Battle.damage_range(u, s, t, b).get("avg", 0.0) < r.hp:
		return 0.0
	var extra := func(k: Skill) -> float:
		var fund: Variant = u.funding(k)
		return (1.0 - 1.0 / u.exhaustion.rate(k)) * (u.ap_cost(k, fund) * AP + u.cost_from(k, fund) * POINT)
	var was: Dictionary[Skill, float] = u.exhaustion.uses.duplicate()
	var before := {}
	for k in was:
		if k != s and not k.passive:
			before[k] = extra.call(k)
	var best := 0.0
	for h in u.hooks():
		h[0].neutralized(b, u, h[1], t, u, &"killed")
	for k in before:
		best = maxf(best, before[k] - extra.call(k))
	u.exhaustion.uses = was
	return best


# What share of its worth a skill keeps for what exhaustion has added to its cost: 1 fresh, 1 / rate worn, never
# below 1 - WORN (_wear() for a blow, in HP: a heal's worth is a share of an ally's HP, a support's has no HP
# to take it off, so these weigh it as a share): of two skills that do alike, the fresher is picked.
static func _fresh(u: Unit, s: Skill) -> float:
	return maxf(1.0 / maxf(u.exhaustion.rate(s), 1.0), 1.0 - WORN)


# What s's blow on t would add beyond its damage, from where u stands, in score()'s terms: the riders (Kick's
# soaking, a shove's tiles), the slam of a push stopped short, the unit struck if it is its side's against it.
static func _driven(b: Battle, u: Unit, s: Skill, t: Unit) -> float:
	var more := b.foresee(u, s, t)
	return 0.0 if more.is_empty() else RIDER * more.riders + (more.lo + more.hi) / 2.0 + more.spill


# Before it strikes, it walks to the tile where a blow it holds does the most beyond its damage (_driven(): a shove
# that ends against a wall slams, one into the open only moves it, one into its own side costs it), if that is a
# tile's drive (Battle.PUSH x RIDER) better than where it stands - or, with nothing in reach from here, than the
# poorest tile in reach of a foe it could walk to: what every tile alike gives (a rider that needs no lining up)
# cancels out. Read through Battle.foresee() from each tile (Battle.standing()), so a behaviour's own foresee
# (Kick's ground, Displace) and a shove effect are asked alike, and any skill that tells more from one side joins.
# Only a tile it can walk to at the price route() puts on it (no more than the movement it has: not through
# ground it dreads) and still pay its blow from. True if it walked.
static func _line_up(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	Unit.begin_read()  # planning only until it walks (Battle.standing() puts it back): each unit's effects are found once (Unit._effects())
	var skills := u.foe_actives(true).filter(func(s: Skill): return not s.behaviours.is_empty() or s.effects.any(func(e: Effect): return Battle.DRIVES.has(StringName(e.stat))))
	if skills.is_empty() or u.move_left() < 1.0:  # (asked before the foes: those are a read apiece)
		Unit.end_read()
		return false
	var foes: Array[Unit] = []
	for t: Unit in reads:
		if t.is_alive() and not t.helpless() and _foe(u, reads[t]) and reads[t].located():
			foes.append(t)
	if foes.is_empty():
		Unit.end_read()
		return false
	var longest := 0.0
	for s: Skill in skills:
		longest = maxf(longest, b.skill_reach(u, s))
	var within := ceili(u.move_left()) + longest + LINE_UP_MARGIN
	foes = foes.filter(func(t: Unit): return Command.tiles(u.cell, t.cell) <= within + 0.02 * t.stat(&"size"))  # a foe farther than its walk and a drive's reach (plus a margin for the ground) can't be driven from any tile it reaches
	if foes.is_empty():
		Unit.end_read()
		return false
	var sizes: Array[float] = []
	for t in foes:
		sizes.append(t.stat(&"size"))
	var state := b.rng.state  # planning mustn't use up the battle's rng
	var worth := {}  # tile -> [the most a blow from it adds, that skill]
	for c in b.cells_near(u.cell, ceili(u.move_left())):
		var best: Variant = b.standing(u, c, func() -> Variant:
			var top: Variant = null
			var away: Array[float] = []  # each foe's distance from here
			for t in foes:
				away.append(Vector2(u.cell).distance_to(Vector2(t.cell)))
			for s: Skill in skills:
				var reach := b.skill_reach(u, s)  # from here: the same for every foe but for its size
				for i in foes.size():
					var t := foes[i]
					if away[i] <= reach + 0.02 * sizes[i] + 0.0001 and s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
						var v := _driven(b, u, s, t)
						if top == null or v > top[0]:
							top = [v, s]
			return top)
		if best != null:
			worth[c] = best
	Unit.end_read()
	if worth.is_empty():
		b.rng.state = state
		return false
	var strikers := _strikers(b, u, u.cell, ceili(u.move_left()) + 1, reads)
	if not strikers.is_empty():
		for c: Vector2i in worth:  # ending beside a foe's reaction is struck for its blow (in score()'s terms, HP): the drive is net of it
			worth[c] = [worth[c][0] - _struck(b, u, c, strikers), worth[c][1]]
	var base: float = worth[u.cell][0] if u.cell in worth else worth.values().map(func(w: Array): return w[0]).min()
	var tiles := worth.keys()
	tiles.sort_custom(func(x: Vector2i, y: Vector2i): return worth[x][0] > worth[y][0] or (worth[x][0] == worth[y][0] and Command.tiles(u.cell, x) < Command.tiles(u.cell, y)))
	b.rng.state = state
	for c: Vector2i in tiles:
		if c == u.cell or worth[c][0] - base < Battle.PUSH * RIDER:
			return false
		var walk := b.walk(u, c, true)
		if walk.path.is_empty() or walk.path[-1] != c:
			continue
		var price := {&"wary": true}
		b.route(u, c, b.line(u.cell, c, u.luck, u), price)
		var steps: float = walk.costs.reduce(func(a: float, x: float): return a + x, 0.0)
		b.rng.state = state
		if price.cost > u.move_left() + 0.0001 or not u.can_afford_after(worth[c][1], steps):
			continue
		log.append("%s lines up %s %s" % [u.name, worth[c][1].name, b.travel(u, c)])
		return true
	return false


# Each reaction moment a blow of s on t would bring that a passive of t's side u can make out (Read.skills,
# Read.kit: an unread one it can't weigh) would be asked about - attacked, hit, and fallen when the blow's
# average kills - as [behaviour, the Reaction, its holder, its rank], what foils() and reprisal() are asked of.
static func _moments(b: Battle, u: Unit, s: Skill, t: Unit, reads: Dictionary[Unit, Read]) -> Array:
	var held := []  # [holder, its slot]
	for o: Unit in reads:
		var r: Read = reads[o]
		if o == u or not o.is_alive() or not o.reacts() or not Faction.friends(o.faction, t.faction):
			continue
		for x in Battle.reactions_of(o):
			if x.skill in r.skills or x.skill in r.kit:
				held.append([o, x])
	var out := []
	if held.is_empty():
		return out
	var moments: Array[StringName] = [&"attacked", &"hit"]
	var hp: float = maxf(reads[t].hp, 1.0) if reads[t].hp != null else GUESS_HP
	if float(Battle.damage_range(u, s, t, b).get("avg", 0.0)) >= hp:
		moments.append(&"fallen")
	var m := b.cast_of(u, s, t, u.rank(s), true)
	for trigger in moments:
		for h in held:
			var r := Behaviour.Reaction.new()
			r.battle = b
			r.trigger = trigger
			r.subject = t
			r.by = u
			r.cast = m
			r.skill = h[1].skill
			for bh in r.skill.behaviours:
				out.append([bh, r, h[0], h[1].rank])
	return out


# The share (0-1, at most FOILED) of a blow of s on t that t's side's reactions would likely take from u: each
# passive of a unit beside the fight that u reads t's side as having is asked, through the hook the reaction
# itself uses (Behaviour.foils()), about each moment the blow would bring (_moments()), and what each leaves
# standing multiplies. Cheap: nothing is asked unless such a passive is read.
static func _foiled(b: Battle, u: Unit, s: Skill, t: Unit, reads: Dictionary[Unit, Read]) -> float:
	if not s.hostile or t == u:
		return 0.0
	var keep := 1.0
	for m in _moments(b, u, s, t, reads):
		keep *= 1.0 - clampf(m[0].foils(m[1], m[2], m[3]), 0.0, 1.0)
	return minf(1.0 - keep, FOILED)


# What those reactions would cost u in HP, on top (Behaviour.reprisal(): Final Act's free action against the
# unit that finishes it). _strike() takes it off the blow's worth, but never more than FOILED of it: a lone
# Final Act unit is still finished, it is just left for last.
static func _reprisal(b: Battle, u: Unit, s: Skill, t: Unit, reads: Dictionary[Unit, Read]) -> float:
	if not s.hostile or t == u:
		return 0.0
	var cost := 0.0
	for m in _moments(b, u, s, t, reads):
		cost += maxf(m[0].reprisal(m[1], m[2], m[3]), 0.0)
	return cost


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
	for s: Skill in looks:
		var look := OBSERVE.reach(u, u.mods(s).irank(u.rank(s), &"rank_impact"))  # as it looks when cast
		var reach := b.area_reach(u, s)
		var best: Variant = null
		var most := 0.0
		for c in b.cells_near(u.cell, reach):
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
#  - a foe its side once made out, living, that no sighting places now (the hunter reached the spot and found no one): LOST, where u stands.
#    A guess like the rest, so a look there rules it out for SWEEP_TURNS and it looks again after, not standing by a hider for good;
#  - where it was struck from by one it couldn't place (Battle.attacks_on()): HIT shared among the tiles on
#    the side the blow landed that its skill reached.
static func clues(b: Battle, u: Unit) -> Dictionary[Vector2i, float]:
	var out: Dictionary[Vector2i, float] = {}
	for c in b.suspicious(u):
		_clue(out, c, SUSPICIOUS)
	for c in b.evidence(u):
		_clue(out, c, DEBRIS / (1.0 + b.rounds_since(b.debris[c].since)))
	for c: Vector2i in b.marks:
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
		for c: Vector2i in tiles:
			_clue(guess, c, REACH / tiles.size())
	for a in b.attacks_on(u.faction) if u.faction else []:
		for c in a.tiles:
			_clue(guess, c, HIT / a.tiles.size())
	if u.faction:
		for t: Unit in b.sighted_when.get(u.faction, {}):
			if is_instance_valid(t) and t.is_alive() and not Faction.friends(t.faction, u.faction) and not seen.has(t):
				_clue(guess, u.cell, LOST)
				break
	for c: Vector2i in guess:
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
static func _remember(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> void:
	if not u.faction:
		return
	for o: Unit in reads:
		var r: Read = reads[o]
		if o.is_alive() and (_foe(u, r) or (r.located() and r.faction == null)):
			b.sighted(u.faction, o, r.cell, float(r.stats.get(&"movement", 0.0)))


# No foe in sight: it heads for where its side last made one out, the nearest first. Reaching the spot
# and finding no one there, its side forgets it and it tries the next. False with nowhere to go.
static func _hunt(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
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
		var p := b.travel(u, at if Command.tiles(u.cell, at) > u.move_left() + HUNT_FAR else _approach(b, u, best, {best: r}))  # past its walk, a beeline: the tile beside it can't be reached this turn
		if p.is_empty():
			return false
		log.append("%s hunts %s" % [u.name, p])
		Unit.begin_read()  # all reads, nothing changed: each unit's effects are found once
		for o: Unit in reads:
			reads[o] = b.read(u, o)
		Unit.end_read()
		_remember(b, u, reads)
		return true
	return false


# Support skills on allies it reads as allies (itself too, for one that reaches itself) that don't have
# the effect yet: one that grants an effect (Stonegift), or a buff for allies with effects of its own
# (Intervention, Rally; not self_only or dual ones). Not one whose effects harm (Effect.helps(): fear, shove,
# entrance drive the ally about): that lands on foes, through score().
static func _support(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	var gives := u.actives.filter(func(x: Skill): return not x.hostile and (x.grants or (not x.for_foes() and not x.self_only and not x.effects.is_empty())) and not x.effects.any(func(e: Effect): return e.helps() < 0) and u.can_afford(x))
	var order := range(gives.size())  # the least worn first (its own order on a tie): of two that give alike, the fresher
	order.sort_custom(func(i: int, j: int): return _fresh(u, gives[i]) > _fresh(u, gives[j]) or (_fresh(u, gives[i]) == _fresh(u, gives[j]) and i < j))
	for i in order:
		var s: Skill = gives[i]
		var e: Effect = s.grants.effects[0] if s.grants else s.effects[0]
		var whom: Array = reads.keys() + [u]
		if u.tempered(&"flirty"):  # whom it fancies first
			whom = whom.filter(func(o: Unit): return o != u and _fancies(u, reads[o])) + whom.filter(func(o: Unit): return o == u or not _fancies(u, reads[o]))
		for t: Unit in whom:
			var r: Read = b.read(u, u) if t == u else reads[t]
			if t.is_alive() and (t == u or r.attitude(u) == &"ally") and e not in r.effects and s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)) \
					and not (s.investigated and Battle.seen_odds(u, s, t, b.watchers(t), b) >= SEEN) and b.cast(u, s, t):
				log.append("%s gives %s to %s" % [u.name, s.name, t.name])
				if t != u:
					_notable(b, u, t, r, s)
				return


# What its temper made of going after (or giving s to) t, read as r, signed the first time this fight (Battle.first_time()):
# a vindictive unit's grudge ("Grudge"), a flirty unit's soft touch or support for one it fancies ("Smitten").
static func _notable(b: Battle, u: Unit, t: Unit, r: Read, s: Skill = null) -> void:
	if _grudge(u, t, r) > 0.0:
		b.first_time(u, &"grudge")
	elif s != null and _fancies(u, r) and (not s.hostile or _soft(u, s)):
		b.first_time(u, &"smitten")


# Still luring: no enemy has seen it for what it is.
static func _luring(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> bool:
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
static func _undine(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String], rooted: bool) -> bool:
	for s: Skill in u.actives.filter(func(x: Skill): return x.behaviour(&"waltz") and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s waltzes in a fog" % u.name)
	if b.inside.has(u):
		return true  # holding on inside its prey
	var vapor: Slot = null
	for x in u.slots:
		if x.skill.toggle and u.equipped(x.skill) and x.skill.effects.any(func(e: Effect): return e.stat == "mist"):
			vapor = x
	if vapor and not vapor.on and u.hp * 2 < u.max_hp:
		u.toggle(vapor.skill)
		log.append("%s vaporizes" % u.name)
	if u.stat(&"mist") > 0.0:
		var target := _best_target(u, reads)
		for s: Skill in u.actives.filter(func(x: Skill): return x.mist_only and x.engulfs):
			if target and not b.in_reach(u, s, target) and not rooted:
				log.append("%s drifts %s" % [u.name, b.travel(u, _approach(b, u, target, reads))])
			if target and b.in_reach(u, s, target) and u.can_afford(s) and b.cast(u, s, target):
				log.append("%s coalesces into %s" % [u.name, target.name])
		return true
	for s: Skill in u.actives.filter(func(x: Skill): return x.behaviour(&"well_up") and u.can_afford(x)):
		for t: Unit in reads:
			var r: Read = reads[t]
			if t.is_alive() and _foe(u, r) and not b.submerged(t) and Vector2(u.cell).distance_to(Vector2(r.cell)) <= b.area_reach(u, s) + 0.0001 \
					and b.cast_at(u, s, r.cell):
				log.append("%s wells up under %s" % [u.name, t.name])
				break
	return false


# No foe within reach of any song it could lure with (Sing: Skill.auto, pulling): a Siren too far away
# to lure moves in on them instead.
static func _out_of_song(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> bool:
	for s: Skill in u.actives.filter(func(x: Skill): return x.auto and Displace.draws(x)):
		if b.auto_targets(u, s).any(func(t: Unit): return reads.has(t) and _foe(u, reads[t])):
			return false
	return true


# A luring unit strikes whatever has come into its reach, without moving: its best skill while it has
# the AP (Drown, where there's water to drag the foe to), then whatever it can still afford (Rake).
static func _ambush(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	var struck := false
	for s: Skill in u.actives.filter(func(x: Skill): return x.drags() and u.can_afford(x)):
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
static func _heal(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	var best: Unit = null
	var how: Skill = null
	var best_score := 0.0
	for s: Skill in u.actives.filter(func(x: Skill): return _mends(b, u, x) and u.can_afford(x)):
		for t: Unit in [u] + reads.keys():
			var r: Read = b.read(u, u) if t == u else reads[t]
			if not t.is_alive() or (t != u and r.attitude(u) != &"ally") or not b.in_reach(u, s, t) \
					or not s.behaviours.all(func(x: Behaviour): return x.fits(b, u, t)):
				continue
			var v := (want(b, u, s, t, r) + (RESCUE if _revives(b, u, s, t) else 0.0)) * _fresh(u, s)  # a worn one is worth less than a fresh one that does as well
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
static func _sing(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	for s: Skill in u.actives.filter(func(x: Skill): return x.auto and Displace.draws(x) and u.can_afford(x)):
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
static func _keep_away(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	var foes: Array[Vector2i] = []
	for o: Unit in reads:
		if o.is_alive() and _foe(u, reads[o]):
			foes.append(reads[o].cell)
	if not foes.is_empty() and _away(b, u, foes, 0, reads):
		log.append("%s keeps away" % u.name)


# Walks to the tile it can reach (as it expects the walk to go) furthest from the nearest of `from` (_retreat()).
# False if there's nowhere better.
static func _away(b: Battle, u: Unit, from: Array[Vector2i], safe := 0, reads: Dictionary[Unit, Read] = {}) -> bool:
	var best := _retreat(b, u, from, safe, reads)
	return best != u.cell and not b.travel(u, best).is_empty()


# The tile u would back off to, by (in order): the least the foes it reads could drive it into (_shoved(), `reads`), the
# least their cc would likely take of its next turn there (_dread(), a tile out of their reach over one in it), the furthest from the nearest of `from` less what its way there costs beyond its steps (the price route() puts
# on it, as _approach() does: dread of ground it knows or suspects, marks), then room to back off again. `safe` > 0:
# any tile that far counts as far enough, and of those the one with the most room to back off again next round wins (_room(): a
# corner is a tile `from` need only close on); on a tie, one an ally still to back off wouldn't choose for itself (_claimed();
# `claim` is off for that ally's own reckoning). Where it stands if nowhere is better.
static func _retreat(b: Battle, u: Unit, from: Array[Vector2i], safe := 0, reads: Dictionary[Unit, Read] = {}, claim := true) -> Vector2i:
	var gap := func(c: Vector2i) -> int:
		return from.map(func(x: Vector2i): return Command.tiles(x, c)).min()
	var claimed: Array[Vector2i] = []
	if safe > 0 and claim:
		claimed = _claimed(b, u, from, safe, reads)
	var stunners := _stunners(b, u, reads)
	var strikers := _strikers(b, u, u.cell, ceili(u.move_left()) + 1, reads)
	var key := func(c: Vector2i, extra: float) -> Array:
		var g: int = gap.call(c)
		return [-roundi(_shoved(b, u, c, reads) + (_struck(b, u, c, strikers) if not strikers.is_empty() else 0.0)), -roundi(DREAD * _dread(stunners, c)), (g if safe <= 0 else mini(g, safe)) - snappedf(maxf(extra, 0.0), 0.01), 0 if safe <= 0 else _room(b, u, c, gap), 0 if c in claimed else 1]
	var best := u.cell
	var best_key: Array = key.call(best, 0.0)
	var state := b.rng.state  # pricing a line draws on the rng: planning mustn't use up the battle's
	var seen := {}
	var reach := ceili(u.move_left())
	for dx: int in range(-reach, reach + 1):
		for dy: int in range(-reach, reach + 1):
			var c := u.cell + Vector2i(dx, dy)
			if c == u.cell or not b.on_map(c):
				continue
			var walk := b.walk(u, c, true)
			var path: Array = walk.path
			if path.is_empty():
				continue
			if path[-1] in seen:
				continue  # several tiles' walks end on the same one
			seen[path[-1]] = true
			var price := {&"wary": true}
			b.route(u, path[-1], b.line(u.cell, path[-1], u.luck, u), price)
			var k: Array = key.call(path[-1], price.cost - walk.costs.reduce(func(a: float, x: float): return a + x, 0.0))
			if _later(k, best_key):
				best = path[-1]
				best_key = k
	b.rng.state = state
	return best


# The tiles u's allies that are yet to move this turn, and within `safe` of `from` too, would back off to (_retreat(), each
# on its own: the choice they would make if u weren't there to take one first). What coordinates a retreat: u leaves them theirs when it can.
static func _claimed(b: Battle, u: Unit, from: Array[Vector2i], safe: int, reads: Dictionary[Unit, Read]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for o: Unit in b.units.values():
		if o != u and o.is_alive() and not o.helpless() and Faction.friends(o.faction, u.faction) and o.move_left() >= o.stat(&"movement") and from.any(func(x: Vector2i): return Command.tiles(x, o.cell) < safe):
			var c := _retreat(b, o, from, safe, reads, false)
			if c != o.cell:
				out.append(c)
	return out


# Whether key a beats key b: the first place they differ, a's is greater.
static func _later(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != b[i]:
			return a[i] > b[i]
	return false


# What the foes u reads could do to it at c beyond their blow by driving it, with the blows it has read of theirs
# (Read.skills): the HP a slam would take off it, and the unit it would be driven into if that is its side's (what
# Battle.foresee() calls lo, hi and spill), by the worst blow of a foe that could walk up beside c, on the side it
# comes from (squarely: a diagonal's tile between them is the kick's ground). A forced move is read
# where it would end (Battle.course()): a tile against a wall or a unit is dearer than one in the open.
static func _shoved(b: Battle, u: Unit, c: Vector2i, reads: Dictionary[Unit, Read]) -> float:
	var worst := 0.0
	for o: Unit in reads:
		var r: Read = reads[o]
		if not o.is_alive() or o.helpless() or not _foe(u, r) or not r.located():
			continue
		var away := Vector2(o.cell - c)
		for s: Skill in r.skills:
			if not s.hostile or s.on_tile() or not (not s.behaviours.is_empty() or s.effects.any(func(e: Effect): return Battle.DRIVES.has(StringName(e.stat)))):
				continue
			var at := o.cell if away.length() < 1.5 and (away.x == 0.0 or away.y == 0.0) else c + (Vector2i(signi(roundi(away.x)), 0) if absf(away.x) >= absf(away.y) else Vector2i(0, signi(roundi(away.y))))  # square beside it, from the way it comes
			if at != o.cell and (not b.on_map(at) or b.unit_at(at) or Vector2(at).distance_to(Vector2(o.cell)) > ceili(o.stat(&"movement")) + 0.0001):
				continue  # it can't get to where it would shove from
			var more: Variant = b.standing(o, at, func(): return b.standing(u, c, func(): return b.foresee(o, s, u)))
			if more != null and not more.is_empty():
				worst = maxf(worst, (more.lo + more.hi) / 2.0 + maxf(more.spill, 0.0))
	return worst


# How many open tiles within u's walk of c lie further from `from` than c does (gap: tile -> its distance):
# where it could back off to next round. 0 at a corner or an edge, where whatever it keeps from would
# have it cornered. Straight lines and bare ground stand in for the walk, as in starve_worth().
static func _room(b: Battle, u: Unit, c: Vector2i, gap: Callable) -> int:
	var reach := ceili(u.stat(&"movement"))
	var here: int = gap.call(c)
	var n := 0
	for dx: int in range(-reach, reach + 1):
		for dy: int in range(-reach, reach + 1):
			var o := c + Vector2i(dx, dy)
			if o != c and b.on_map(o) and (b.unit_at(o) == null or b.unit_at(o) == u) and gap.call(o) > here:
				n += 1
	return n


# A recovering unit (a Starmote): off the star lattice, it heads for the nearest free lattice tile;
# on it, it holds. Only cornered - a foe beside it, and nowhere further from its foes to go - does it
# fight (its energy missiles).
static func _recover(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
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
	if near and (b.on_lattice(u.cell) or not _away(b, u, foes, 0, reads)):
		while _strike(b, u, reads, log):
			pass


# A channeled skill (Metea): holding one, it strikes the tile it can that takes in the most foes it can
# place (less its allies); not yet, it begins where foes gather within its reach - where a blast
# would take in the most of them, a tile further out to allow for their moving.
static func _channel(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> void:
	for s: Skill in u.actives.filter(func(x: Skill): return x.channel):
		var radius := s.blast * u.mods(s).rank(u.rank(s), &"rank_range")  # as Battle._detonate() reads it

		var striking := u.channel != null and u.channel.skill == s
		if not striking and (u.channel != null or not u.can_afford(s)):
			continue
		var cells: Array = b.strike_tiles(u) if striking else b.cells_near(u.cell, b.area_reach(u, s)).filter(
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
			for o: Unit in reads:
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
static func _best_target(u: Unit, reads: Dictionary[Unit, Read]) -> Unit:
	Unit.begin_read()  # weighing only (see _steady())
	var out := _targeting(u, reads)
	Unit.end_read()
	return out


static func _targeting(u: Unit, reads: Dictionary[Unit, Read]) -> Unit:
	var best: Unit = null
	var best_score := -INF
	for t: Unit in reads:
		if not _foe(u, reads[t]) or not t.is_alive():
			continue
		var guess: Variant = _level(u, reads[t])
		var lv: float = guess if guess != null else 0.0
		var v: float = -Vector2(u.cell).distance_to(Vector2(reads[t].cell)) - _hate(reads[t]) + _hunted(u, t, reads[t]) \
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


# Where to head for a target: a cell beside it (side-on first: diagonals can be near misses) that is the
# cheapest to reach - the price of the route the walk would take there (Battle.route(): movement, the
# units in the way, and the dread of ground it knows or suspects is bad, less what helpful marks draw it) -
# then the nearest, away from units it takes for aggressive. Never where it already stands. Planning
# mustn't use up the battle's rng, so it's restored.
static func _approach(b: Battle, u: Unit, t: Unit, reads: Dictionary[Unit, Read]) -> Vector2i:
	var r: Read = reads[t]
	var best: Vector2i = r.cell
	if Command.tiles(u.cell, r.cell) > u.move_left() + APPROACH_FAR:  # out of its walk's reach: only the heading counts (the flanking, dread and blows of a tile it won't end on aren't weighed)
		return _beside(b, u, r.cell)
	var state := b.rng.state
	var best_cost := INF
	var stunners := _stunners(b, u, reads)  # the foes whose cc is likely to land on it where it ends
	Unit.begin_read()  # planning only (route() asks the same of every neighbour): each unit's effects are found once
	var strikers := _strikers(b, u, t.cell, 2, reads)
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			var c: Vector2i = r.cell + Vector2i(dx, dy)
			if c == r.cell or c == u.cell or not b.on_map(c) or b.unit_at(c):
				continue
			var price := {&"wary": true}  # it weighs what it only suspects, too
			b.route(u, c, b.line(u.cell, c, u.luck, u), price)
			var away := Vector2(u.cell).distance_to(Vector2(c))
			var v: float = price.cost + (away - maxf(absf(c.x - u.cell.x), absf(c.y - u.cell.y))) + (0.5 if dx and dy else 0.0) - FLANKING * _opening(t, c) + DREAD * _dread(stunners, c) + (STRUCK * _struck(b, u, c, strikers) if not strikers.is_empty() else 0.0)
			for o: Unit in reads:
				var ro: Read = reads[o]
				if ro.attitude(u) == &"avoid" and ro.located() and Command.tiles(ro.cell, c) <= 1 and u.temper() not in BOLD:
					v += WARY
			if v < best_cost:
				best = c
				best_cost = v
	Unit.end_read()
	b.rng.state = state
	return best


# The free tile beside `at` nearest u (`at` itself with none): a heading, unpriced (_approach() far off, _herd()).
static func _beside(b: Battle, u: Unit, at: Vector2i) -> Vector2i:
	var best := at
	var nearest := INF
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			var c: Vector2i = at + Vector2i(dx, dy)
			if c != at and c != u.cell and b.on_map(c) and not b.unit_at(c) and Vector2(u.cell).distance_squared_to(Vector2(c)) < nearest:
				best = c
				nearest = Vector2(u.cell).distance_squared_to(Vector2(c))
	return best


# The foes within `within` tiles of `at` (a walk's ground: the tiles beside the target, or all u could reach), with a reaction of theirs it
# makes out (Read.skills, Read.kit) that strikes a walker ending beside them (Behaviour.strikes(): Opportunist), and can pay for the
# skill it would strike with (Unit.funding(): the blow is a free action, so Energy is all it needs): [holder, behaviour, rank, slot skill].
# Usually none. What _approach(), _line_up() and _retreat() price a walk's end with (_struck()).
static func _strikers(b: Battle, u: Unit, at: Vector2i, within: int, reads: Dictionary[Unit, Read]) -> Array:
	var out := []
	for o: Unit in reads:
		var r: Read = reads[o]
		if o == u or Command.tiles(o.cell, at) > within or not o.is_alive() or not o.reacts() or not _foe(u, r) or not r.located():
			continue
		for x in Battle.reactions_of(o, Battle.REACTION):
			if x.skill in r.skills or x.skill in r.kit:
				for bh in x.skill.behaviours:
					out.append([o, bh, x.rank, x.skill])
	return out


# The HP the strikers' blows would take off u on ending its walk at c (a tile beside them), as it reads them: the expected blow
# of each skill Behaviour.strikes() names (damage x hit chance), never more than u has left.
static func _struck(b: Battle, u: Unit, c: Vector2i, strikers: Array) -> float:
	var hp := 0.0
	var spent := {}  # [holder, pool] -> what the blows counted so far take from it: a pool is shared by a holder's skills
	for f in strikers:
		if c == u.cell or not Battle.next_to(f[0].cell, c):
			continue
		var r := Behaviour.Reaction.new()
		r.battle = b
		r.trigger = &"beside"
		r.subject = u
		r.by = u
		r.skill = f[3]
		var worth: Variant = b.standing(u, c, func():
			var s: Skill = f[1].strikes(r, f[0], f[2])
			if s == null or not s.attacks():
				return 0.0
			var cut := b.price_cut(f[0], s, [u] as Array[Unit])
			var fund: Variant = f[0].funding(s, cut)
			if fund == null:
				return 0.0
			var key := [f[0], fund]  # the Energy (or reserve) its earlier blows beside this tile took is gone
			var cost: int = f[0].cost_from(s, fund, cut)
			if (f[0].store(fund) if fund is Reserve else f[0].energy) - spent.get(key, 0) < cost:
				return 0.0
			spent[key] = spent.get(key, 0) + cost
			return float(Battle.damage_range(f[0], s, u, b).get("avg", 0.0)) * Battle.hit_chance(f[0], s, u, b))
		hp += worth if worth != null else 0.0
	return minf(hp, float(u.hp))


# The foes whose cc is likely to land on u, as it reads them (Read.skills: the ones it makes out), for _dread(): [foe, the
# furthest it could cast from (walking up: its movement and the skill's reach), the odds it lands: the cast's own (hit_chance())
# x the share of u's turn it takes if it does - what the skill's behaviours foresee (Battle.foresee() `afflicts`: Stun's save, a
# grip), else CC for one that only carries the cc tag] - the best of each foe's skills, and none for a foe that is helpless, or that
# u can't read the skills of. A unit already bearing a cc (Unit.afflicted()) fears one more less: the odds over 1 + what it bears.
static func _stunners(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> Array:
	var out := []
	if u.stopped():
		return out
	var borne := 1.0 + u.afflicted(&"cc").size()
	for o: Unit in reads:
		var r: Read = reads[o]
		if not o.is_alive() or o.stopped() or not _foe(u, r):
			continue
		var best := [0.0, 0.0]
		for s: Skill in r.skills:
			if not s.hostile or s.on_tile():
				continue
			var share: float = b.foresee(o, s, u).get("afflicts", 0.0)
			if share <= 0.0 and &"cc" in o.skill_tags(s):
				share = CC
			if share <= 0.0:
				continue
			var odds := Battle.hit_chance(o, s, u, b) * share / borne
			if odds > best[0]:
				best = [odds, ceili(o.stat(&"movement")) + b.skill_range(o, s, u)]
		if best[0] > 0.0:
			out.append([o, best[1], best[0]])
	return out


# The share of its next turn the foes _stunners() lists would likely take from u standing at c: each that could get to it
# (within its walk and its skill's reach of where it stands now), as likely as it lands; one at least of them, as the chance
# that none does: 1 - the product of the odds that each doesn't.
static func _dread(foes: Array, c: Vector2i) -> float:
	var clear := 1.0
	for f in foes:
		if Vector2(f[0].cell).distance_to(Vector2(c)) <= f[1] + 0.0001:
			clear *= 1.0 - f[2]
	return 1.0 - clear


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
	for s: Skill in u.actives.filter(func(x: Skill): return not x.hostile and not x.for_foes() and u.can_afford(x)):
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
static func _switch(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	if u.channel or _could_strike(b, u, reads):
		return false
	var worth := u.actives.filter(func(x: Skill): return u.price(x) > 0 and (x.for_foes() or _mends(b, u, x)))
	if worth.any(func(x: Skill): return u.can_afford(x)):
		return false
	for x in u.slots:
		var to: Variant = &"energy" if x.on else Unit.replacer(x.skill)
		if Unit.replacer(x.skill) and x.skill not in u.disabled and u.equipped(x.skill) and worth.any(func(w: Skill): return _pays(u, to, w)) and u.toggle(x.skill):
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
static func _could_strike(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> bool:
	Unit.begin_read()  # weighing only (see _steady())
	var out := _striking(b, u, reads)
	Unit.end_read()
	return out


static func _striking(b: Battle, u: Unit, reads: Dictionary[Unit, Read]) -> bool:
	for s: Skill in u.foe_actives():
		for t: Unit in reads:
			if t.is_alive() and _foe(u, reads[t]) and b.in_reach(u, s, t) and b.can_afford(u, s, t):
				return true
	return false


# Holding Focus (Reserve.aims, which builds only on a turn it rests) short of full, with a ranged attack it
# would pay for from it: it rests rather than walk up, building it for the shot (a ranged attack that
# empties it gets + rank to hit). When nothing is in reach to strike. Or when what is in reach is not worth
# it now - only ranged attacks, none likelier than SHOT to hit - and a rest would give Focus enough to pay
# for one it can't pay for from Focus now (and a Focus stat to add). Bounded: a rest or two fills it.
# True if it rested.
static func _steady(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	Unit.begin_read()  # weighing only: each unit's effects are found once (Unit._effects())
	var out := _steadying(b, u, reads, log)
	Unit.end_read()
	return out


static func _steadying(b: Battle, u: Unit, reads: Dictionary[Unit, Read], log: Array[String]) -> bool:
	if not u.idle():
		return false
	var weak := false
	for s: Skill in u.foe_actives():
		for t: Unit in reads:
			if t.is_alive() and _foe(u, reads[t]) and b.in_reach(u, s, t) and b.can_afford(u, s, t):
				if not u.ranged(s) or _chance(u, s, reads[t], b, t) >= SHOT:
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
	for s: Skill in u.actives.filter(func(x: Skill): return x.behaviours.any(func(bh: Behaviour): return bh.marks(b, u)) and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s uses %s" % [u.name, s.name])
			return true
	return false


# About to walk on t, which no blow of its reaches this turn on foot: it casts a skill that gives it tiles
# (Behaviour.strides(): Move, doubled paid with Stamina - as funding() would pay it now) when they close the
# gap with AP to spare for the blow, the cheapest AP of those that do. Straight-line tiles stand in for the
# walk, as in starve_worth(). True if it did.
static func _stretch(b: Battle, u: Unit, t: Unit, log: Array[String]) -> bool:
	var stretches := u.actives.filter(func(x: Skill): return not x.hostile and x.self_only and u.can_afford(x))  # (asked first: most units have none, and the blows are a read apiece)
	if stretches.is_empty():
		return false
	var blows := u.foe_actives(true).filter(func(x: Skill): return x.behaviours.all(func(bh: Behaviour): return bh.fits(b, u, t)))
	if blows.is_empty() or _rooted(b, u):
		return false
	var gaps: Array[int] = []  # the tiles to walk to bring each blow in reach
	var costs: Array[float] = []
	for x: Skill in blows:
		gaps.append(maxi(ceili(Vector2(u.cell).distance_to(Vector2(t.cell)) - b.skill_range(u, x, t) - 0.0001), 0))
		costs.append(u.ap_cost(x, u.funding(x)))
	if gaps.any(func(g: int): return g <= u.move_left()):
		return false  # it can walk into one's reach as it is
	var best: Skill = null
	var best_ap := INF
	for s: Skill in stretches:
		var c := b.cast_of(u, s, u, u.rank(s), false)
		var n := 0
		for bh in s.behaviours:
			n += bh.strides(c)
		var ap := u.ap_cost(s, u.funding(s))
		if n > 0 and ap < best_ap:
			for i in blows.size():
				if gaps[i] <= u.move_left() + n and u.ap_left() - ap + n - gaps[i] >= costs[i] - 0.0001:
					best = s
					best_ap = ap
	if best and b.cast(u, best, u):
		log.append("%s uses %s" % [u.name, best.name])
		return true
	return false


# With no foe in sight, no clue to search and nowhere its side last saw one to hunt, it casts a skill that
# senses unseen foes (Clairvoyance: Behaviour.senses()), unless it holds a channel already.
static func _scry(b: Battle, u: Unit, log: Array[String]) -> bool:
	if u.channel or (u.faction and not b.last_seen(u.faction).is_empty()):
		return false
	for s: Skill in u.actives.filter(func(x: Skill): return x.behaviours.any(func(bh: Behaviour): return bh.senses()) and u.can_afford(x)):
		if b.cast(u, s, u):
			log.append("%s uses %s" % [u.name, s.name])
			return true
	return false
