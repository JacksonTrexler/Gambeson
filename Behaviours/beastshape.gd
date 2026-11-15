extends Behaviour

# Beastshape: its caster becomes the beast its ground suits (Battle.form_for(): one of the biomes it
# picked) at rank, for rank + 1 of its turns, body and mind - only Strike, beast skills and this until
# then (Unit.shaped_allows()). Used shaped, it turns back. Its rank and turns are rank impact.


# Only shaped (to turn back), or where some beast thrives.
func fits(b: Battle, caster: Unit, _target: Unit) -> bool:
	return caster.form != &"" or not b.form_for(caster).is_empty()


func unfit() -> String:
	return "No beast thrives here"


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	var u := c.caster
	if u.form:
		u.unshape()
		c.battle.shaped.emit(u, &"", &"")
		return
	var f := c.battle.form_for(u)
	var r := c.impact_rank()
	u.shape(f[0], f[1], r, r + 1)
	c.battle.shaped.emit(u, f[0], f[1])


func impact() -> StringName:
	return &"impactful"


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "shapes")


func describe(rank: int) -> String:
	return "Takes the shape of the beast its ground suits (one of the biomes it picked), at rank {r:%d}, for {t:%d turns}: only Strike, beast skills and this until then. Used shaped, it turns back" % [rank, rank + 1]


func describe_as(c: Cast) -> String:
	return describe(c.impact_rank())
