extends RefCounted

# The Restless Dead ?? (Unit.restless(): undead and Disturbed, by any source of either), kept by the battle
# (Battle.restless: each restless unit -> the allies that have noticed it). settle() runs as the outermost cast
# is over and as a side's turn ends (after its statuses tick):
# - a unit newly restless joins the list; one on it that has lost Disturbed (dispelled, expired) while still
#   undead is laid to rest: an instant death (Unit.slay());
# - a restless unit that just acted (a cast, or a walk: Battle.travel()) is seen doing it: each awake ally of its side that makes it out (located,
#   in sight) and hasn't yet noticed makes a wisdom check (tagged inquire, as Battle.doubt()) against
#   NOTICE ("medium easy"); passing, it takes the unit for a foe from then on (Read.restless, through Battle._read()).
# Its AI is AI._restless(); a side acts with its Disturbed last (Command.cognizant_first()).

const NOTICE := &"approachable"  # the user's "medium easy": between easy and standard (Difficulty), flat


static func settle(b: Battle, caster: Unit = null) -> void:
	for u: Unit in b.units.values():
		if u.is_alive() and u not in b.restless and u.restless():
			b.restless[u] = {}
	for u: Unit in b.restless.keys():
		if not is_instance_valid(u) or not u.is_alive():
			b.restless.erase(u)
		elif not u.disturbed():
			b.restless.erase(u)
			if u.has_tag(&"undead"):
				u.slay()  # laid to rest
	if caster and is_instance_valid(caster) and caster in b.restless and caster.is_alive():
		witness(b, caster)


# Each ally of r's side that sees r act, and hasn't noticed yet, checks once.
static func witness(b: Battle, r: Unit) -> void:
	var seen_by: Dictionary = b.restless[r]
	for o: Unit in b.units.values():
		if o == r or o in seen_by or not o.is_alive() or o.asleep() or o.restless() or not Faction.friends(o.faction, r.faction):
			continue
		var rd := b.read(o, r)
		if not rd.located() or not rd.seen:
			continue
		if b.check(o, &"wisdom", null, Difficulty.dc(NOTICE), {tags = [&"inquire"]}).won:
			seen_by[o] = true
