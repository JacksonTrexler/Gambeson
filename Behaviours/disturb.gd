extends Behaviour

# Disturbance: the target makes a wisdom check at a difficulty set by what it is - unfair (very difficult)
# for anyone, easy for a leader (Battle.leads(): the player, or a unit with a party). Failing, it is
# Disturbed (Effects/disturbed.tres, Unit.disturbed()) for its rank (impact) in turns: it can't be
# commanded or give commands, and acts alone by its own behaviour. No attack roll. Its rank is rank impact.

const DISTURBED: Effect = preload("res://Effects/disturbed.tres")
const HARD := &"unfair"
const EASY := &"easy"


func whole(_c: Cast) -> bool:
	return true


func fits(_b: Battle, caster: Unit, target: Unit) -> bool:
	return target != caster and not target.disturbed()


func unfit() -> String:
	return "already Disturbed"


# Its check's difficulty on t at a rank (as its caster's modifiers read it: m).
static func dc(b: Battle, t: Unit, rank: int, m := Modifiers.NONE) -> int:
	return Difficulty.dc(EASY if b.leads(t) else HARD, m.irank(rank, &"rank_impact")) + m.check


func apply(c: Cast) -> void:
	var b := c.battle
	var t := c.target
	if not t.is_alive():
		return
	var bar := dc(b, t, c.rank, c.mods if c.mods else Modifiers.NONE)
	var roll := b.check(t, &"wisdom", null, bar, {role = &"defensive"})
	b.contested.emit(c.caster, t, bar, roll.mine.total + 1)  # the caster wins on the target's missing it: a tie is a pass
	if roll.won:
		return
	c.put(DISTURBED, c.impact_rank())


func impact() -> StringName:
	return &"impactful"


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "DC, turns")


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var r := c.impact_rank()
	return "The target makes a {k:check|Check} of its {d:wis mod}: against {r:%d} (%s), or {r:%d} for a leader (%s). Failing, it is %s for {t:%d turns}: it can't be commanded or give commands, and acts alone by its own behaviour, on whichever side it is" % [
			Difficulty.dc(HARD, r), Glossary.term(Difficulty.word(HARD)), Difficulty.dc(EASY, r), Glossary.term(Difficulty.word(EASY)),
			Glossary.term(&"disturbed", "Disturbed"), r]
