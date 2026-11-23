extends Behaviour

# Summon, cast on a tile: `per_rank` x rank units of `scene` rise on the caster's side, each on the free
# tile nearest the one aimed at (Battle.summon(); fewer if the map has no room). They are ordinary units
# of the caster's side - its allies to command or leave to the AI, hurt and killed like any other - and
# arrive with their turn's AP spent but for a few they keep (keeps()): rank + the cast's stat mod + what the
# summoner's passives add (Behaviour.summon_ap(): Wake and Rake), at most what they had. Permanent: nothing ends
# them but a death. Skeleton is its first user; any later summon sets another `scene` and `per_rank`.
# Its rank is rank impact (the count), so a modifier that raises it raises the host.
# Soft cap (cap()): rank + the cast's stat mod of its summoner's own (Unit.raised_by) it holds in hand. Past that,
# the furthest from the summoner become Disturbed for good (a trait) until no more than the cap are left in
# hand: an undead one is Restless Dead ?? (Unit.restless()), and turns on the living nearest it.

const DISTURBED: Effect = preload("res://Effects/disturbed.tres")

@export var scene: PackedScene
@export var per_rank := 2


# How many it raises: per_rank x its rank impact.
func count(c: Cast) -> int:
	return per_rank * c.impact_rank()


# The bodies its cast adds that stay in hand (the AI prices these): none past the soft cap.
func bodies(c: Cast) -> int:
	return clampi(cap(c) - in_hand(c.battle, c.caster).size(), 0, count(c)) if c.battle else count(c)


# How many of its summoner's own it holds in hand: its impact rank + the cast's stat mod.
func cap(c: Cast) -> int:
	return c.impact_rank() + c.stat_mod(c.caster.mod(c.skill.stat(), c.caster.skill_tags(c.skill)))


# What `by` raised that is alive and not Disturbed.
static func in_hand(b: Battle, by: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u: Unit in b.units.values():
		if u.raised_by == by and u.is_alive() and not u.disturbed():
			out.append(u)
	return out


# Past the cap: the furthest from the summoner go Disturbed for good, one by one, till the cap holds.
func overflow(c: Cast) -> void:
	var held := in_hand(c.battle, c.caster)
	var from := Vector2(c.caster.cell)
	held.sort_custom(func(x: Unit, y: Unit): return from.distance_squared_to(Vector2(x.cell)) > from.distance_squared_to(Vector2(y.cell)))
	for i in maxi(held.size() - cap(c), 0):
		held[i].afflict(DISTURBED, 0).lasting = true


func apply_at(c: Cast, cell: Vector2i) -> void:
	for i in count(c):
		var u := make(c, cell)
		if u == null:
			break  # no room anywhere: the rest don't come
		u.raised_by = c.caster
		var keep := float(keeps(c, u))
		for p in u.ap:  # risen this turn: all spent but what they keep, the first pools first
			var held := minf(p.amount, keep)
			keep -= held
			p.amount = held
	overflow(c)


# One unit it raises, on the caster's side on the free tile nearest cell (null: no room). A later summon that
# builds its own unit overrides this (Behaviours/theseus.gd: a Monster); the rules around it hold.
func make(c: Cast, cell: Vector2i) -> Unit:
	return c.battle.summon(scene, c.caster.faction, cell)


# The AP a summoned unit keeps: its cast's rank + stat mod, plus each passive its summoner has that adds
# (Behaviour.summon_ap(): any, by the unit's tags, not by name), never below 0.
func keeps(c: Cast, who: Unit) -> int:
	var n := c.impact_rank() + c.stat_mod(c.caster.mod(c.skill.stat(), c.caster.skill_tags(c.skill)))
	for x in c.caster.slots:
		if x.rank > 0 and x.skill.passive and c.caster.equipped(x.skill):
			for h in x.skill.behaviours:
				n += h.summon_ap(c.caster, x.rank, who)
	return maxi(n, 0)


func tile_target() -> StringName:
	return &"tile"


# Its count is rank impact; raising units is a thing of its own (impactful).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "summon")
	if t.impact == &"":
		t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var n := count(c)
	var who: String = scene.get_state().get_node_name(0) if scene else "unit"
	var r_mod := "{r:%d} + %s" % [c.impact_rank(), c.mod_text(c.skill.stat() if c.skill else &"intelligence")]
	return "Raises {r:%d} %s%s on the free tiles nearest a tile, on the caster's side: ordinary units that keep %s AP on arriving and act in full from next turn. It holds %s of what it raised in hand; past that, the furthest become %s for good" % [n, who, "" if n == 1 else "s", r_mod, r_mod, Glossary.term(&"disturbed", "Disturbed")]
