extends Behaviour

# Final Act: once a battle, reaching 0 HP, it holds on and interrupts the turn under way to take one free
# action (Battle.grant_interrupt()); the interrupted turn then resumes. It falls once the action is done,
# as it would have (a heart, Downed, or death), unless the action got it back above 0 HP.


func react(r: Reaction, holder: Unit, _rank: int) -> bool:
	if r.trigger != &"fallen" or r.subject != holder or r.battle.times_reacted(holder, r.skill) > 0:
		return false
	r.stay = true
	r.battle.grant_interrupt(holder, 1)
	return true


func terms(t: SkillTerms) -> void:
	t.impact = &"impactful"


func describe(_rank: int) -> String:
	return "{k:reaction|Reaction}, once a battle: reaching 0 HP, it holds on to take one free action out of turn, then falls as it would have, unless that got it back up."
