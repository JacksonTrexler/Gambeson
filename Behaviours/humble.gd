extends Behaviour

# Humble: the target's max HP is capped at its HP now less 1% of its max (Effect humble: the cut), for
# rank x 4 x (1 - the share cut) turns, at least 1 - the less it loses, the longer it lasts. No roll: it
# lands as it's used. Its rank is rank impact.


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	var b := c.battle
	var t := c.target
	var r := c.impact_rank()
	var cap := maxi(t.hp - maxi(ceili(0.01 * t.max_hp), 1), 1)
	var cut := t.max_hp - cap
	if cut <= 0:
		return
	var e := Effect.new()
	e.stat = "humble"
	e.name = "Humbled"
	e.amount = cut
	var n := maxi(ceili(r * 4.0 * (1.0 - float(cut) / t.max_hp)), 1)
	var a := t.afflict(e, n + (1 if t.faction == b.turn else 0), r)
	a.skill = c.skill
	a.by = c.caster
	a.since = b.turns_begun
	t.refit()
	if not Faction.friends(t.faction, c.caster.faction) and c.caster.stat(&"breathless") > 0.0:
		b._choke(c.caster, t)


func impact() -> StringName:
	return &"impactful"


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "humbles")


func describe(_rank: int) -> String:
	return "Caps its max HP at its HP now less 1%, for rank x 4 x (1 - the share cut) turns: the less it cuts, the longer"
