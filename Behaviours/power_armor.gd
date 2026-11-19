extends Behaviour

# Power Armor: its holder wears one armor more, in a slot of its own (Behaviour.armor_slot()). The slot works while
# its holder has at least 100% - 10% x rank of its Power (Unit.power_share(): its Energy, or the reserve it runs on);
# an attack it blocks (it would have hit without that armor) takes its damage / rank off that Power.
const SHARE := 0.1  # of its Power each rank lets the slot go without


func armor_slot() -> bool:
	return true


# Its rank (the share it lets go, the cut of each blow) is rank impact, through its holder's modifiers.
func slot_works(holder: Unit, rank: int) -> bool:
	return holder.power_share() >= 1.0 - SHARE * holder_rank(holder, rank) - 0.0001


func slot_blocked(_b: Battle, holder: Unit, rank: int, power: int) -> void:
	holder.sap_power(ceili(power / float(maxi(holder_rank(holder, rank), 1))))


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "power share and blow cut")


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "An armor slot more, while it has at least %d%% of its Power; blows it blocks take their damage / {r:%d} off Power" % [maxi(roundi((1.0 - SHARE * rank) * 100.0), 0), rank]
