extends Behaviour

# Scrap Plating: its holder wears one armor more, in a slot of its own (Behaviour.armor_slot()), that confers no more
# than rank Defense. Its AP drag is the armor's own, in full, on top of the armor proper's (Unit.armor_drag()).


func armor_slot() -> bool:
	return true


# Its cap is rank impact, through its holder's modifiers.
func slot_defense(holder: Unit, rank: int, defense: int) -> int:
	return mini(defense, holder_rank(holder, rank))


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "defense cap")


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "An armor slot more: the armor in it confers at most {r:%d} Defense, and drags in full" % c.impact_rank()
