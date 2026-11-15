extends Behaviour

# Interject: when an ally beside it is hit, a dex check against the attacker; passing, it takes the hit
# in the ally's place (Battle.react(), &"hit"). It takes 25% less a rank of any hit not aimed at it, with
# no cap but the whole hit. From rank V, taking a hit for an ally, its Defense counts 25% more a rank
# against the roll that hit the ally. Snapped (Snapping Turtle: its holder attacks), the same check
# against its target: passing, the attack can't be turned aside by the target's side's reactions.

const CUT := 0.25  # of a hit not aimed at it, a rank
const GUARD_FROM := 5  # the rank from which...
const GUARD := 0.25  # ...its Defense counts this much more a rank, taking a hit for an ally


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	match r.trigger:
		&"hit":
			if not _beside(r, holder):
				return false
			if not r.contest(holder, &"dexterity", r.by) or not r.retarget(holder):
				return false
			var n := holder_rank(holder, rank)
			if n >= GUARD_FROM:
				r.guard += roundi(holder.defense(r.cast.tags) * GUARD * n)
			return true
		&"snap":
			if r.by == null or r.cast == null or r.locked or not r.contest(holder, &"dexterity", r.by):
				return false
			r.locked = true
			return true
	return false


# An ally beside it is hit by a cast under way that isn't its own and can still be turned.
func _beside(r: Reaction, holder: Unit) -> bool:
	return r.subject != holder and r.by != null and r.by != holder and r.cast != null and not r.locked \
			and Faction.friends(holder.faction, r.subject.faction) and Battle.next_to(holder.cell, r.subject.cell)


# The chance it takes the hit.
func foils(r: Reaction, holder: Unit, _rank: int) -> float:
	return r.odds(holder, &"dexterity", r.by) if r.trigger == &"hit" and _beside(r, holder) else 0.0


# A hit not aimed at it (the cast under way was meant for another: it took it in that one's place).
func hurt(b: Battle, holder: Unit, rank: int, d: int) -> int:
	var c := b.resolving()
	if d <= 0 or c == null or c.target != holder or c.meant == null or c.meant == holder:
		return d
	return roundi(d * maxf(1.0 - CUT * holder_rank(holder, rank), 0.0))


# Its terms: rank cuts the hits it takes for others, and from V raises its Defense (impact); a check.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "cut, Defense")
	t.check = true
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	var out := "{k:reaction|Reaction}: when an ally beside it is hit, a dex {k:check|check} against the attacker; passing, it takes the hit instead. It takes {r:%d%%} less of a hit not aimed at it." \
			% mini(roundi(CUT * rank * 100), 100)
	if rank >= GUARD_FROM:
		out += " Taking one for an ally, its Defense counts {r:%d%%} more." % roundi(GUARD * rank * 100)
	return out
