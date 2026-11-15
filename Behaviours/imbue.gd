class_name Imbue
extends Behaviour

# Elemental Strike: its user picks one of its elements (the HUD asks: HUD._pick_element(); else the
# first), and its next rank Strikes carry it (Unit.element, Unit.imbued), the first hit of each + its
# highest mental mod. The uses are rank impact.

@export var elements: Array[StringName] = []


# The first Imbue on s, or null.
static func of(s: Skill) -> Imbue:
	for b in s.behaviours:
		if b is Imbue:
			return b
	return null


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	if c.caster.element not in elements:
		c.caster.element = elements[0]
	c.caster.imbued = c.impact_rank()


# Only carries out its numbers: no unique effect.
func impact() -> StringName:
	return &""


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "elements")


func describe(rank: int) -> String:
	return "Pick an element (%s): %s deal%s it, the first hit + your highest mental mod" % [", ".join(elements.map(func(e): return "{x:%s}" % e)),
			"your next Strike" if rank == 1 else "your next {r:%d} Strikes" % rank, "s" if rank == 1 else ""]


func describe_as(c: Cast) -> String:
	return describe(c.impact_rank())
