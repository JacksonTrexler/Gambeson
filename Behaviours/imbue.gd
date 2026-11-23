extends Behaviour

# Elemental Strike: its user picks one of its elements (the HUD asks with its shared picker, Behaviour.choices();
# else, as the AI, its own element if it is one of these, else the first), and its next rank Strikes carry it (Unit.element, Unit.imbued), the first hit of each + its
# highest mental mod. The uses are rank impact.

@export var elements: Array[StringName] = []


func whole(_c: Cast) -> bool:
	return true


func choices(_c: Cast) -> Array[String]:
	var out: Array[String] = []
	out.assign(elements.map(func(e): return String(e).capitalize()))
	return out


func apply(c: Cast) -> void:
	if StringName(c.chose.to_lower()) in elements:
		c.caster.element = StringName(c.chose.to_lower())
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
