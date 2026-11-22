extends Behaviour

# Gallantry: when a foe attacks an ally beside it, a cha check against the attacker; passing, it becomes
# the attack's target, and the target is locked: no later reaction turns it back to the ally or anywhere
# else (Battle.react(), &"attacked", before the roll). Rank adds to the check: CHECK_PER_RANK a rank past I,
# through its holder's modifiers (rank impact), so rank I is the plain check.

const CHECK_PER_RANK := 1  # + to its cha check a rank past I


func _beside(r: Reaction, holder: Unit) -> bool:
	return r.trigger == &"attacked" and r.subject != holder and r.by != null and r.by != holder and r.cast != null and not r.locked \
			and Faction.friends(holder.faction, r.subject.faction) and Battle.next_to(holder.cell, r.subject.cell)


# The chance it steps in.
func foils(r: Reaction, holder: Unit, rank: int) -> float:
	return r.odds(holder, &"charisma", r.by, check_bonus(holder, rank)) if _beside(r, holder) else 0.0


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	if not _beside(r, holder):
		return false
	if not r.contest(holder, &"charisma", r.by, check_bonus(holder, rank)) or not r.retarget(holder):
		return false
	r.locked = true
	return true


# Its check's bonus: CHECK_PER_RANK a rank past I, at the rank its holder's modifiers give it, and their check shift (Density).
func check_bonus(holder: Unit, rank: int) -> int:
	return CHECK_PER_RANK * (holder_rank(holder, rank) - 1) + mods_on(holder).check


func _bonus_at(rank: int) -> int:
	return CHECK_PER_RANK * (rank - 1)


# Its terms: a check, which rank adds to.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "check")
	t.check = true
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var n := _bonus_at(c.impact_rank())
	return "{k:reaction|Reaction}: when an ally beside it is attacked, a cha {k:check|check}%s against the attacker; passing, it becomes the target, and the attack can't be turned aside again." % ((" at +{r:%d}" % n) if n > 0 else "")
