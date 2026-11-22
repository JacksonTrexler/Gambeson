extends Behaviour

# Gank: a heavy blow on a foe an ally is already near - one within rank tiles of it (fits()). Unless it
# ambushes (Battle.ambushes(): the foe can't see or place the ganker as it strikes), it's made at
# disadvantage.


# Whether an ally of caster's (not caster itself), on its feet, stands within r tiles of target.
static func backed(b: Battle, caster: Unit, target: Unit, r: int) -> bool:
	for o: Unit in b.units.values():
		if o != caster and o != target and o.hp > 0 and Faction.friends(o.faction, caster.faction) \
				and Vector2(o.cell).distance_to(Vector2(target.cell)) <= r + 0.0001:
			return true
	return false


# Its rank as caster holds it, for checks that aren't handed one (fits()).
func _rank(caster: Unit) -> int:
	for s in caster.actives:
		if self in s.behaviours:
			return caster.rank(s)
	return 1


func fits(b: Battle, caster: Unit, target: Unit) -> bool:
	return backed(b, caster, target, _rank(caster))


func edge(c: Cast) -> int:
	return 0 if not c.foe or &"ambush" in c.tags else -1


# Its terms (SkillTerms; docs/plans/slayer.md's cost vocabulary): at disadvantage unless it ambushes - a
# major penalty. Its "ally within rank tiles" gates whether it can be used at all (fits()), not a payoff.
func terms(t: SkillTerms) -> void:
	t.penalty = &"major"
	t.contingencies.append(["an ally within rank tiles of the foe", 1.0 / 12.0, false])


func describe(rank: int) -> String:
	return "Only on a foe with an ally within {r:%d} tile%s of it. At disadvantage unless it's an %s: the foe can't see or place the attacker as it strikes" % [
			rank, "" if rank == 1 else "s", Glossary.term(&"ambush")]
