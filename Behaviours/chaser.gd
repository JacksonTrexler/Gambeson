extends Behaviour

# Chaser: rolling a critical hit (the reaction trigger &"crit", from Battle.roll_attack()), its holder gets an
# interrupt of one action (Battle.grant_interrupt(), as Final Act's) in which it may use only one of its
# rightmost rank actives on its hotbar (the leftmost are harder to reach with many slotted), each at no more
# than Chaser's rank (Unit.allowed). The player picks it in the HUD, the AI as any interrupt (AI.interrupt()).
# Once per skill use (Battle.use_of(): a Strike's many crits chase once), and a use made in an interrupt (its
# own, Final Act's) sets off no chase. The chase is a use of its own: Heavy Strike pools it apart.

const CHASED := &"chased"  # in the use's bag: it has chased already


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	if r.trigger != &"crit" or r.by != holder or r.battle.interrupter == holder:
		return false
	var v := r.battle.use_of(holder)
	if v == null or v.bag.has(CHASED):
		return false
	var n := holder_rank(holder, rank)
	var only := {}
	for s in reach(holder, n):
		only[s] = n
	if only.is_empty():
		return false
	v.bag[CHASED] = true
	r.battle.grant_interrupt(holder, 1, only)
	return true


# The actives a chase may use: the holder's usable actives on its hotbar, the rightmost n of them.
static func reach(holder: Unit, n: int) -> Array[Skill]:
	var row: Array[Skill] = []
	var have := holder.actives
	for s in holder.hotbar:
		if s and s in have:
			row.append(s)
	return row.slice(maxi(row.size() - n, 0))


# Its terms: rank reaches further left along the hotbar and lifts the cap on the chase's rank (impact).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "actives in reach, and their highest rank")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var n := c.impact_rank()
	return "{k:reaction|Reaction}: rolling a {k:critical} hit, it may use one of the rightmost {r:%d} active skill%s on its hotbar out of turn, at no more than rank {r:%d}; once a skill use." % [n, "" if n == 1 else "s", n]
