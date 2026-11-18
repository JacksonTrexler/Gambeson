extends Behaviour

# Final Act: once a battle, reaching 0 HP, it holds on and interrupts the turn under way to take one free
# action (Battle.grant_interrupt()); the interrupted turn then resumes. It falls once the action is done,
# as it would have (a heart, Downed, or death), unless the action got it back above 0 HP. Its free actions
# are its rank, through its holder's modifiers (rank impact): one at rank I.


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	if r.trigger != &"fallen" or r.subject != holder or r.battle.times_reacted(holder, r.skill) > 0:
		return false
	r.stay = true
	r.battle.grant_interrupt(holder, holder_rank(holder, rank))
	return true


# Its free action, as the AI weighs a killing blow on it (reprisal()): the best strike it could make at the
# blow's author, chance to hit x average damage - HP, the unit the AI already counts a blow's worth in.
func reprisal(r: Reaction, holder: Unit, rank: int) -> float:
	if r.trigger != &"fallen" or r.subject != holder or r.battle.times_reacted(holder, r.skill) > 0 or r.by == null:
		return 0.0
	var best := 0.0
	for s in holder.foe_actives():
		var d := Battle.damage_range(holder, s, r.by, r.battle)
		best = maxf(best, Battle.hit_chance(holder, s, r.by, r.battle) * float(d.get("avg", 0.0)))
	return best * holder_rank(holder, rank)


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "free actions")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var n := c.impact_rank()
	return "{k:reaction|Reaction}, once a battle: reaching 0 HP, it holds on to take {r:%d} free action%s out of turn, then falls as it would have, unless that got it back up." % [n, "" if n == 1 else "s"]
