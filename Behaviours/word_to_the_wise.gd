extends Behaviour

# Word to the Wise: its holder may command an ally by its wisdom mod in place of its charisma mod (reach,
# orders, hotbar slots: Command.cha_for()), but no higher than the lower of the two units' wis mods +
# rank - so min(holder's wis mod, the ally's wis mod + rank). A wise leader talks over a wise ally's head
# no better than the ally can follow.


func command_mod(_c: Command, holder: Unit, rank: int, u: Unit) -> int:
	return mini(holder.mod(&"wisdom"), mini(holder.mod(&"wisdom"), u.mod(&"wisdom")) + rank)


func describe(rank: int) -> String:
	return ("When commanding, use your %s in place of your %s, up to the lower of your and the ally's %s + {r:%d}"
			% [Glossary.mod(&"wis"), Glossary.mod(&"cha"), Glossary.mod(&"wis"), rank])
