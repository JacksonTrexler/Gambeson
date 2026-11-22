extends Behaviour

# Switcheroo: the caster and the unit it's used on trade places in a blink - an ally willingly, a foe
# failing its dex save (Skill.save) - each landing where the other stood. Ground there works on each
# as on any unit put down on it (Battle.place(): a trap springs).


func apply(c: Cast) -> void:
	var b := c.battle
	var mine := c.caster.cell
	var theirs := c.target.cell
	if mine == theirs:
		return
	b.units.erase(theirs)  # the target lifted out, the caster can land in its place
	b.move(c.caster, theirs)
	b.move(c.target, mine)
	for u: Unit in [c.caster, c.target]:
		if u.is_alive() and b.terrain(u.cell).is_trap():
			b.spring(u.cell, u)


func describe(_rank: int) -> String:
	return "The caster and the unit trade places, each landing where the other stood (a foe resists with a dex save)"
