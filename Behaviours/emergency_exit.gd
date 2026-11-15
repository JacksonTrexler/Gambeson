extends Behaviour

# Emergency Exit: a forming escape portal (the Meadows) opens rank turns sooner; with none forming, the
# caster and its allies within rank tiles warp to a pocket of stone for rank turns. Its turns are rank
# impact, the allies it takes within rank range (its caster's modifiers).


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	open(c.battle, c.caster, c.skill, c.impact_rank(), c.range_rank())


# by opens it (skill s) at rank impact r, reaching rr tiles.
static func open(b: Battle, by: Unit, s: Skill, r: int, rr: int) -> void:
	var meadows := b.get_node_or_null("Meadows")
	if meadows and meadows.portal != null and not meadows.opened:
		meadows.hasten(r)
		return
	var p := b._new_pocket(&"refuge", by, s, by.cell)
	p.turns = r
	for m in p.marks:
		m.turns = r
	var from := by.cell
	for u: Unit in b.members(by.faction):
		if Vector2(u.cell).distance_to(Vector2(from)) <= rr + 0.0001 and not b._in_pocket(u.cell):
			b.move(u, b.free_near_in(p, p.centre))


func impact() -> StringName:
	return &"impactful"


func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "exits")
	t.add(&"rank_impact", "exits")


func describe(rank: int) -> String:
	return _say(rank, rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank(), c.range_rank())


func _say(ri: int, rr: int) -> String:
	return "An escape portal forming opens {r:%d} turns sooner. With none forming: warps the caster and allies within {r:%d} tiles to a pocket of stone, a door back and forth, for {t:%d turns}; then it returns them in a clump" % [ri, rr, ri]
