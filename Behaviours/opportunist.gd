extends Behaviour

# Opportunist: an enemy that ends its walk beside it (the reaction trigger &"beside", from Battle.travel())
# draws its first active, used on it at once (Battle.grant_interrupt()'s `aim`: a free action, no one picks;
# Energy and other costs still paid). The skill must be hostile and reach the walker. No limit but what
# it can pay: every such walk is a use. A walk ended beside it by being pushed, pulled or lured is no one's
# doing but the one who did it, so it does not count (only travel() fires it).


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	var s := strikes(r, holder, rank)
	if s == null:
		return false
	r.battle.grant_interrupt(holder, 1, {s: holder.rank(s)}, {}, r.subject)
	return true


# The skill it would use on r's walker, or null: the walker is an enemy beside it, and its first active is
# hostile and reaches it. (Whom it happens to is a foe for the holder, whatever either reads the other as.)
func strikes(r: Reaction, holder: Unit, _rank: int) -> Skill:
	if r.trigger != &"beside" or r.subject == holder or not r.subject.is_alive() or holder.actives.is_empty():
		return null
	if Faction.friends(holder.faction, r.subject.faction) or not Battle.next_to(holder.cell, r.subject.cell):
		return null
	var s := holder.actives[0]
	return s if s.hostile and r.battle.in_reach(holder, s, r.subject) else null


func describe(_rank: int) -> String:
	return "{k:reaction|Reaction}: an enemy that ends its move beside it is struck by its first active skill, out of turn, at once."
