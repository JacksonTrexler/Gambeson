extends Behaviour

# Word to the Wise: its holder may command an ally by its wisdom mod in place of its charisma mod (reach,
# orders, hotbar slots: Command.cha_for()), but no higher than the lower of the two units' wis mods +
# rank - so min(holder's wis mod, the ally's wis mod + rank). A wise leader talks over a wise ally's head
# no better than the ally can follow.


func command_mod(_c: Command, holder: Unit, rank: int, u: Unit) -> int:
	var m := mods_on(holder)
	var wis := m.stat(holder.mod(&"wisdom"), &"stat_impact")  # its own wis mod, through its modifiers
	return mini(wis, mini(wis, u.mod(&"wisdom")) + m.irank(rank, &"rank_impact"))


# Its terms: its wis mod is what it commands by (stat impact), capped by the ally's + rank (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"stat_impact", "commands by")
	t.add(&"rank_impact", "cap over the ally's")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return ("When commanding, use your %s in place of your %s, up to the lower of your and the ally's %s + {r:%d}"
			% [Glossary.mod(&"wis"), Glossary.mod(&"cha"), Glossary.mod(&"wis"), rank])
