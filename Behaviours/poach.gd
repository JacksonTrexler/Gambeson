extends Behaviour

# Poach: a quick blow at easy pickings. On a bloodied foe (Unit.bloodied(): half its HP or less) it has
# never used a skill on this battle (Battle.aimed()), it's made at advantage and half its AP and cost
# come back (Unit.refund()). Its blow neutralizing the foe (Battle.neutralize(): downed, Downed, killed)
# gives back 5% x rank of its max Energy, and 10% x rank of its Focus and Stamina, each a recovery
# (Burnout: RE).

const FOCUS: Reserve = preload("res://Reserves/focus.tres")
const STAMINA: Reserve = preload("res://Reserves/stamina.tres")
const ENERGY_SHARE := 0.05
const RESERVE_SHARE := 0.1  # "double for focus and stamina"


# A bloodied foe it hasn't used a skill on before this one.
static func easy(c: Cast) -> bool:
	return c.foe and c.target.bloodied() and c.battle.aimed(c.caster, c.target) == 0


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
	u.grant_energy(u.rounded(ENERGY_SHARE * c.rank * u.max_energy))
	var pools := u.pools()
	for r: Reserve in [FOCUS, STAMINA]:
		if r in pools:
			var n := mini(u.rounded(RESERVE_SHARE * c.rank * pools[r]), pools[r] - u.store(r))
			if n > 0:
				u.set_store(r, u.store(r) + n)
				u.note_recovery(r, n)


func describe(rank: int) -> String:
	return "\n".join([
		"On a bloodied foe (half its HP or less) it hasn't used a skill on this battle: at advantage, and half its AP and cost come back",
		"Its blow neutralizing the foe (downed, Downed or killed): {r:%d}%% of its max Energy back, and {r:%d}%% of its Focus and Stamina (each a recovery: %s)" % [
				5 * rank, 10 * rank, Glossary.term(&"burnout")],
	])
