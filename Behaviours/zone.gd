extends Behaviour

# Darkstone, cast on a tile: lays concealment of its `kind` on the tiles around it, rank - distance from
# the centre levels (Battle.zone_levels()), for the skill's turns. Its rank is rank impact.

@export var kind := &""  # the concealment it lays (dark: Perception reads it)


func apply_at(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	b.zones.append(Battle.Zone.new(kind, b.zone_levels(c.impact_rank(), cell), c.skill.turns, c.caster.faction))


func tile_target() -> StringName:
	return &"area"


# Its levels are rank impact; laying concealment is a rider (tame).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "zone")
	if t.impact == &"":
		t.impact = &"tame"


func describe(_rank: int) -> String:
	return "Lays %s %s around a tile" % [kind, Glossary.term(&"concealment", "concealment")]


func describe_as(c: Cast) -> String:
	var turns: int = c.skill.turns if c.skill else 0
	return "Lays %s %s around a tile, {r:%d} deep at its centre and one less a tile out, for {t:%d turn%s}" % [
			kind, Glossary.term(&"concealment", "concealment"), c.impact_rank(), turns, "" if turns == 1 else "s"]
