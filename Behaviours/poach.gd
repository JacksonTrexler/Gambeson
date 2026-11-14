extends Behaviour

# Poach: a quick blow at easy pickings. On a bloodied foe (Unit.bloodied(): half its HP or less) it has
# never used a skill on this battle (Battle.aimed()), it's made at advantage and half its AP and cost
# come back (Unit.refund()). Its blow neutralizing the foe (Battle.neutralize(): downed, Downed, killed)
# gives back 5% x rank of its max Energy, and 10% x rank of its Focus and Stamina, each a recovery
# (Burnout: RE).

const FOCUS: Reserve = preload("res://Reserves/focus.tres")
const STAMINA: Reserve = preload("res://Reserves/stamina.tres")
const ENERGY_SHARE := 0.05
const BLOODIED := 0.5  # Unit.bloodied(): half its HP or less - the share lambda tightens or loosens
const RESERVE_SHARE := 0.1  # "double for focus and stamina"


# A bloodied foe it hasn't used a skill on before this one.
static func easy(c: Cast) -> bool:
	var hurt := c.target.execute_share() <= (c.mods.share(BLOODIED) if c.mods else BLOODIED)  # bloodied, through lambda
	return c.foe and hurt and c.battle.aimed(c.caster, c.target) == 0


func aim(c: Cast) -> void:
	c.bag[&"poach"] = easy(c)  # asked before this use is remembered
	if c.bag[&"poach"]:
		c.caster.refund(c.skill, 0.5)


func edge(c: Cast) -> int:
	return 1 if c.bag.get(&"poach", easy(c)) else 0


func felled(c: Cast, _how: StringName) -> void:
	if c.bag.get(&"regained", false) or not c.caster.is_alive():
		return
	c.bag[&"regained"] = true
	var u := c.caster
	u.grant_energy(u.rounded(ENERGY_SHARE * c.impact_rank() * u.max_energy))
	var pools := u.pools()
	for r: Reserve in [FOCUS, STAMINA]:
		if r in pools:
			var n := mini(u.rounded(RESERVE_SHARE * c.impact_rank() * pools[r]), pools[r] - u.store(r))
			if n > 0:
				u.set_store(r, u.store(r) + n)
				u.note_recovery(r, n)


# Its terms: a bloodied foe (share 0.5, through lambda: easy()) it hasn't aimed at gives advantage and half
# its price back - an impactful effect behind a contingency; the regain grows with rank.
func terms(t: SkillTerms) -> void:
	t.impact = &"impactful"
	t.contingencies.append(["a bloodied foe it hasn't aimed at", BLOODIED, true])
	t.add(&"rank_impact", "regain")


func describe(rank: int) -> String:
	return "\n".join([
		"On a bloodied foe (half its HP or less) it hasn't used a skill on this battle: at advantage, and half its AP and cost come back",
		"Its blow neutralizing the foe (downed, Downed or killed): {r:%d}%% of its max Energy back, and {r:%d}%% of its Focus and Stamina (each a recovery: %s)" % [
				5 * rank, 10 * rank, Glossary.term(&"burnout")],
	])
