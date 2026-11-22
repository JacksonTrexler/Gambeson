extends Behaviour

# Armor: the Defense its armor sets, lent with the armor as an equipment skill (Unit.armor_defense() asks every
# one its worn armor lends). The armor's own fields say how (Item.WEIGHTS and the Armor group: a floor or its
# wearer's level, + dex mod, full_dex, no_dex); this is where they are read, so what the armor does is one skill a
# status can take away and another armor skill can sit beside (Power Armor, Scrap Plating). Armor that sets
# none (Heart Up-Link) leaves Defense unarmored: dex mod + con mod. It owns its enchantment: an enchanted
# armor gives +1 Defense (it is not ranked up).


func armor(holder: Unit, _rank: int, item: Item) -> int:
	var plus := 1 if item.enchanted() else 0
	if not item.sets_defense():
		return holder.mod(&"dexterity") + holder.mod(&"constitution") + plus
	var w := item.weight_class()
	if w:
		var base: Array = Item.WEIGHTS[w]
		var share: float = 0.0 if item.no_dex else (1.0 if item.full_dex else base[2])
		var m := holder.mod(&"dexterity")
		var dex := floori(m * share) if m < 0 else holder.rounded(m * share)  # a negative share rounds down: a penalty always bites
		return maxi(base[0], holder.rounded(holder.lv() * base[1])) + dex + plus
	var floor_or_level := maxi(item.defense, holder.rounded(holder.lv() * item.per_level))
	return floor_or_level + (holder.mod(&"dexterity") if item.plus_dex else 0) \
			+ (holder.rounded(holder.stat(&"dexterity") * item.dex_share) if item.dex_share > 0.0 else 0) + plus


func owns_enchant() -> bool:
	return true


func describe(_rank: int) -> String:
	return "Sets its holder's Defense by the armor lending it; enchanted, +1 Defense"
