extends Behaviour

# Peel (passive): coming to an engaged ally's aid. With an ally within rank + wis mod tiles of where it
# steps from, and a foe it can place within rank tiles of that ally, each step bringing it closer to
# that foe costs half the tiles it closes less - at most half the step - for rank steps a turn
# (Unit.tally). Battle.walk() asks it of each step, so the HUD's reach and costs show it.


func step_cost(b: Battle, holder: Unit, rank: int, from: Vector2i, to: Vector2i, cost: float, bag: Dictionary) -> float:
	if cost <= 0.0 or bag.get(&"peel", 0) + holder.tally.get(&"peel", 0) >= rank:
		return cost
	var m := Modifiers.NONE
	for s in holder.passives:  # its modifiers: rank and wis mod are both reach
		if self in s.behaviours:
			m = holder.mods(s)
	var near := m.rank(rank, &"rank_range") + m.stat(holder.mod(&"wisdom"), &"stat_range")
	var best := 0.0
	for a: Unit in b.units.values():
		if a == holder or a.hp <= 0 or not Faction.friends(a.faction, holder.faction) or Vector2(from).distance_to(Vector2(a.cell)) > near + 0.0001:
			continue
		for e: Unit in b.units.values():
			if e.is_alive() and not Faction.friends(e.faction, holder.faction) and Vector2(a.cell).distance_to(Vector2(e.cell)) <= rank + 0.0001:
				var closer := Vector2(from).distance_to(Vector2(e.cell)) - Vector2(to).distance_to(Vector2(e.cell))
				if closer / 2.0 > best and b.read(holder, e).located():
					best = closer / 2.0
	if best <= 0.0:
		return cost
	bag[&"peel"] = bag.get(&"peel", 0) + 1
	return cost - minf(best, cost / 2.0)


# Its terms: reach by rank and wis mod (both through modifiers), a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "ally reach")
	t.add(&"stat_range", "ally reach")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return "With an ally within {r:%d} + {o:wis mod} tiles, and a foe within {r:%d} tiles of that ally: each step toward that foe costs half the tiles it closes less, at most half the step, for {r:%d} step%s a turn" % [
			rank, rank, rank, "" if rank == 1 else "s"]
