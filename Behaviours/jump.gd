extends Behaviour

# Jump (Hop): its jumper leaps to a free tile in range, over whatever lies between - void, units, walls - no
# movement spent, nothing brushed past (Battle.place(): a trap where it lands still springs). It must land where
# it can stand (Battle.footing(): not void, unless it floats or flies). Its range is the skill's, which jump
# range effects stretch (Floaty: x(rank + 1)).


func tile_target() -> StringName:
	return &"tile"


func fits_at(b: Battle, caster: Unit, cell: Vector2i) -> bool:
	return cell != caster.cell and not b.unit_at(cell) and b.footing(caster, cell)


func apply_at(c: Cast, cell: Vector2i) -> void:
	c.battle.place(c.caster, cell)


func describe(_rank: int) -> String:
	return "Leaps to a free tile in range, over whatever lies between, spending no movement; it can't land on %s unless it floats or flies" % Glossary.term(&"void", "void")
