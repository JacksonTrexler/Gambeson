extends Behaviour

# Gallantry: when a foe attacks an ally beside it, a cha check against the attacker; passing, it becomes
# the attack's target, and the target is locked: no later reaction turns it back to the ally or anywhere
# else (Battle.react(), &"attacked", before the roll).


func _beside(r: Reaction, holder: Unit) -> bool:
	return r.trigger == &"attacked" and r.subject != holder and r.by != null and r.by != holder and r.cast != null and not r.locked \
			and Faction.friends(holder.faction, r.subject.faction) and Battle.next_to(holder.cell, r.subject.cell)


# The chance it steps in.
func foils(r: Reaction, holder: Unit, _rank: int) -> float:
	return r.odds(holder, &"charisma", r.by) if _beside(r, holder) else 0.0


func react(r: Reaction, holder: Unit, _rank: int) -> bool:
	if not _beside(r, holder):
		return false
	if not r.contest(holder, &"charisma", r.by) or not r.retarget(holder):
		return false
	r.locked = true
	return true


# Its terms: a check; rank adds nothing yet (a fixed check).
func terms(t: SkillTerms) -> void:
	t.check = true
	t.impact = &"impactful"


func describe(_rank: int) -> String:
	return "{k:reaction|Reaction}: when an ally beside it is attacked, a cha {k:check|check} against the attacker; passing, it becomes the target, and the attack can't be turned aside again."
