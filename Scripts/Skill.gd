class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
@export var toggle := false  # passive: its holder switches it on and off (from the hotbar)
@export var inherent := false  # part of what its holder is (Starkind): it can't be disabled or removed, and takes no slot
@export var min_tier := 0  # its tier is at least this (Synergy: 2), wherever it's offered (Unit.tier())
@export var hybrid := false  # passive with an active part: using it costs its AP (Personify: adjusting its persona; Battle.personify())
@export var tags: Array[StringName] = []  # e.g. physical, dark, magical, str, wis; martial, magical, specialist: its category
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target
@export var max_rank := 0  # the highest rank it can be raised to; 0: no cap
@export var glyph := ""  # up to 2 characters standing for it on skill trees; empty: its initials
@export var rank_cost := 0  # skill points for rank II, times rank_growth for each rank after (Clever Disguise: 4, 8, 16...); 0: the usual 1 + r^2
@export var rank_growth := 2.0

@export_group("Active")
@export var ap := 0.0
@export var cost := 0  # paid in Energy, or a reserve that can pay for this skill's tags
@export var cost_per_rank := false  # cost x rank (starter spells)
@export var ap_with: Dictionary[Reserve, float] = {}  # AP factor when fully paid with a reserve (Hex: mana 0.5)
@export var needs: Reserve  # it can only be paid with this reserve (a Warlock's higher-tier skills: a Sweet Nothing)
@export var cost_with: Dictionary[Reserve, float] = {}  # cost factor paid with a reserve, once the caster has opened it up to this skill's tier (starter spells: mana 0.5, opened by Mana)
@export var radius := 0.0  # range before reach and size
@export var radius_stat := &""  # plus the caster's score in this stat itself, not its mod (Gasp: charisma)
@export var radius_mod := &""  # plus the caster's mod in this stat, reaching an adjacent unit at least (starter spells: intelligence)
@export var hostile := true  # targets enemies (false: allies)
@export var dual := false  # usable on allies and foes alike: allies get its effects, foes its damage (starter spells)
@export var either := false  # usable on allies and foes alike, its effects on both (wauaw)
@export var rolls := true  # used on a foe: rolls d20 + attack mod against its Defense first (Battle.cast())
@export var advantage := false  # that roll is the better of two d20s (Gasp)
@export var roll_per_rank := 0  # ...plus this x rank (Gasp: rank)
@export var pull := 0  # used on a foe: draws it this many tiles x rank toward the caster (Sing; Battle.pull())
@export var drags_to := &""  # used on a foe: a contest in its stat in place of the attack roll; won, it drags the foe to the nearest ground with this tag the caster could walk to, and both into it (Drown: water; Battle.drag_spot())
@export var grip := Vector2i.ZERO  # its effects hold the foe (grappled) until it breaks free by moving away: each turn it ends held, these dice + the caster's mod in its stat (Drown: 1d12; Battle._break_free(), Battle._grip())
@export var links := false  # on itself: links it with its teammates within its cha mod in tiles (at least 1) and its leader, to pool what they make out (Coordinate; Battle._link())
@export var prays := false  # prays to the caster's god, an effect by god (Pray; Battle.pray())
@export var observes := false  # cast on a tile: the caster inspects every tile around it as if it had rested rank turns (Observe; Battle.observe())
@export var auto := false  # used at once, landing on the nearest units in range - allies and foes alike - no more than its rank (Sing; Battle.auto_targets())
@export var save := &""  # used on a foe: in place of the attack roll, it saves - d20 + its mod in this beating d20 + the caster's mod in the skill's stat + rank; failing, it takes the effects, and that roll is what seeing through them must beat (Haluca: wisdom)
@export var disables := false  # a curse: with its save, the caster's luck-rounded sqrt(rank) of the foe's skill slots are switched off, right to left, for its turns; the foe adds the ranks of the skills in them to its save (Brainfog; Unit.disable_order())
@export var resisted := &""  # it pulls only foes enraptured by the caster (fooled, with no suspicion of it); on a suspicious one, d20 + the caster's mod in the skill's stat against d20 + its mod in this takes a stack of suspicion off (Sing: wisdom; Battle._lured())
@export var tiers: Array[Tier] = []  # damage by rank; none: no damage (tagged energy: it drains Energy first - Unit.drain())
@export var weapon_tag := false  # its damage takes its wielder's weapon's damage tag, or blunt bare-handed (Strike; Item.damage_tag, Battle.hit_tags())
@export var levels_down := false  # rank rolls of d20 + the caster's mod in its stat, each beating the higher of the foe's average stat mod + level and its last stand; each that does takes a level off it for rank - misses turns (Level Down; Battle._level_down())
@export var humbles := false  # caps the unit's max HP at its HP now less 1% of its max, for longer the less that cuts (Humble; Battle._humble())
@export var boost_pool := &""  # on an ally: AP it gains at once, for this use (skill, move)...
@export var boost_mod := &""  # ...the caster's mod in this + rank (Igna: skill AP; Aetha: movement)
@export var aura := false  # used on itself, its effects go on every ally within rank tiles too (Flamecharm, Flamedance; Battle._aura())
@export var splits := false  # ...from rank V, on only the nearest rank of them, its strength split among them (Flamecharm)
@export var opening := false  # only as its holder's turn opens: before it moves or spends AP (Flamedance)
@export var retrieves: Item  # used on itself: takes this unique item from wherever it is and puts it on, at the skill's rank (Burning Bag; Battle._retrieve())
@export var cinders := false  # used on a foe: rank of its rightmost hotbar slots burn for its turns (Cindering; Unit.burning_slots())
@export var renames := ""  # learned, Strike goes by this name (Decisive Strike; Unit.skill_name())
@export var exclusive := &""  # only one skill of this group can be learned (the low-tier Strike upgrades: strike_form)
@export var waives := &""  # opens a general tree's skills up to its rank in tier without their usual needs - general (Generalist), martial (Martialist), magical (Thaumaturgist); a tree its class doesn't have, it shows, one tier lower (Unit.missing())
@export var kills := false  # the foe's last stand, cut by how hurt it is (execute), against d20 + the caster's mod in its stat: failing, it takes 1 true damage and dies (Death; Battle._death())
@export var god_tag := false  # its damage takes the tag of its caster's god as well (Smite; Unit.GOD_TAGS): Urlo's energy drains Energy first
@export var carry := 0.0  # energy damage: this x (rank - 1) of what's left once the target's Energy is gone goes on to HP (Smite: 0.2)
@export var hits_per_rank := false  # Strike III hits three times
@export var chain := false  # each hit rolls on its own: a miss ends it, and each hit in a row is -1 to hit and damage (Strike; Battle._chain())
@export var elements: Array[StringName] = []  # used, its user picks one of these: its Strikes deal it for rank uses (Elemental Strike; Battle.imbue())
@export var grants: Skill  # also puts this skill's effects on the target (Stonegift: Stoneskin)
@export var turns := 0  # how many of the target's turns put-on effects last (zones: the caster's)
@export var turns_per_rank := 0  # ...plus this many per rank (Sola: rank turns)
@export var turns_mod := &""  # ...plus the caster's mod in this (Haluca: charisma)
@export var fades := false  # ...after which they lose a rank a turn, rather than ending (Clever Disguise)
@export var until_move := false  # they last until the target moves rather than standing still - with no turns set, with no limit (Hide)
@export var self_only := false  # used on its user alone (Hide)
@export var investigated := false  # the target rolls once (d20 + stat mod + rank), and enemies that can see it investigate against that; those who meet it aren't fooled by it (Battle.investigate())

@export_group("Channel")  # cast on a tile, it channels; cast again for strike_ap and strike_cost to strike (Metea; Battle._detonate())
@export var channel := false
@export var strike_ap := 0.0
@export var strike_cost := 0
@export var blast := 0.0  # the explosion's radius, per rank
@export var dice_per_rank := false  # its tier's dice rolled once per rank (Metea II: 2d12)

@export_group("Heal")  # used on an ally (Battle.mend())
@export var heal_mods: Array[StringName] = []  # heals the caster's mods in these, added up (First Aid: dexterity, wisdom; Renew: wisdom)...
@export var heal_split := 1  # ...divided by this (First Aid: 2; luck rounds)...
@export var heal_bonus := 0  # ...plus this (First Aid: 1), at least 1 HP
@export var squared := false  # clears wounds up to rank x rank, not its rank (Renew)
@export var restores := 0.0  # the recipient gets this x rank AP back (Renew)
@export var per_wound := 0  # this x rank more HP for each wound it clears (First Aid: 1)

@export_group("Area")  # cast on a cell rather than a unit (Darkstone)
@export var flamewall := false  # sets the tile on fire, and rank tiles to either side of it across the caster's line to it (Flamewall; Battle._flamewall())
@export var cone := 0.0  # a cone of this many degrees toward the tile, + 15 a rank past I, radius long, hitting everyone in it - its caster too (Solar; Battle._solar())
@export var zone := &""  # concealment kind laid on tiles: rank - distance from the centre levels
@export var radius_per_rank := 0.0  # range grows with rank (Darkstone: 1 + rank; Embellish, cast on a unit: rank - 1)

@export_group("Trap")  # cast on a cell, lays a trap there (Snare; Battle.lay())
@export var lays: Terrain  # the trap: its concealment and dice multiplier are per rank

@export_group("Stand-in")  # passive: one stat stands in for others on skills sharing a tag with it
@export var stand_in := &""  # Arcanist Perspective: intelligence
@export var replaces: Array[StringName] = []  # wisdom, charisma

@export_group("Energy")  # passive: what its holder's Energy counts as
@export var energy_as: Array[StringName] = []  # Energy paid for skills with these tags gets the bonuses their own resources give (Working Knowledge: magical - Hex at half AP, as with Mana)
@export var reserve: Reserve  # passive: gives its holder this reserve, its max the holder's mod in reserve_mod (at least 0) x rank (Sweet Nothings)
@export var reserve_mod := &""
@export var opens: Reserve  # skills up to its rank in tier get their cost_with savings for this reserve (Mana: mana)

@export_group("Look")  # a persona it puts forward on whoever has it (Alluring; Unit._take_looks()), cutting their dissonance penalty by its rank
@export var stance := ""
@export var shows_vibe: Array[String] = []
@export var shows_tags: Array[StringName] = []
@export var shows_adjectives: Array[String] = []
@export var shows_nouns: Dictionary[String, String] = {}
@export_multiline var lore := ""  # a story behind it, shown after what it does (the Bracing passives: Jimhe Deyn's gangs)
@export_group("Stub")  # a skill that isn't built yet: shown on skill trees, but it can't be learned
@export var stub := ""  # the open question(s) in todo.md it waits on: "?3", "?2 ?11"
@export_multiline var plan := ""  # what it's meant to do, until it's built

const STAT_TAGS := {&"str": &"strength", &"dex": &"dexterity", &"con": &"constitution",
		&"int": &"intelligence", &"wis": &"wisdom", &"cha": &"charisma"}
const CATEGORIES := {&"magical": "Magic", &"martial": "Martial", &"specialist": "Specialist"}


func tier(rank: int) -> Tier:
	var best: Tier = null
	for t in tiers:
		if t.rank <= rank and (best == null or t.rank > best.rank):
			best = t
	return best


# Has a part its holder works by hand - it's cast, or switched on and off - so it goes on the hotbar.
func fits_bar() -> bool:
	return not passive or toggle


# Its holder's build stands on it (Powerful): it's the easiest to disable, and one going takes every
# pillar skill with it (Unit.disable()).
func pillar() -> bool:
	return &"pillar" in Tags.expand(tags)


# A Pillar that sits rank / 2 slots in from the right for disabling (Generalist): harder to reach.
func foundation() -> bool:
	return &"foundation" in tags


# Aimed at a tile rather than a unit: area skills and trap skills.
func on_tile() -> bool:
	return zone != &"" or lays != null or observes or channel or flamewall or cone > 0.0


# Whether it can serve a posture when a unit reaches for its default move (HUD default orders, and the
# context tags in docs/plan-composability.md): &"offensive" an attack on a foe, &"supportive" help for
# an ally, &"defensive" protecting oneself. A skill can serve more than one (a dual spell attacks and
# supports); a passive serves none - it's not a move to order.
func serves(posture: StringName) -> bool:
	if passive:
		return false
	match posture:
		&"offensive":
			return for_foes() and (attacks() or contests() or not tiers.is_empty() or pull != 0 or disables)
		&"supportive":
			return for_allies() and not self_only and (heals() or grants != null or boost_pool != &"" or aura or not effects.is_empty())
		&"defensive":
			return self_only
	return false


# Can be used on foes: hostile skills, and dual ones.
func for_foes() -> bool:
	return hostile or dual or either


# Can be used on allies: support skills, and dual ones.
func for_allies() -> bool:
	return not hostile or dual or either


# Rolls to hit a foe before it does anything to it.
func attacks() -> bool:
	return for_foes() and rolls and not on_tile() and not contests()


# Heals (or restores AP): mends allies it's used on.
func heals() -> bool:
	return not heal_mods.is_empty() or heal_bonus > 0 or restores > 0.0


# Carries a look its holder puts forward (Alluring).
func has_look() -> bool:
	return stance != "" or not (shows_vibe.is_empty() and shows_tags.is_empty() and shows_adjectives.is_empty() and shows_nouns.is_empty())


# The highest rank of wound it clears at a rank: its rank, or rank x rank (Renew).
func clears(rank: int) -> int:
	return rank * rank if squared else rank


# HP it heals, cast by u (at least 1).
func healing(u: Unit) -> int:
	var sum := 0
	for s in heal_mods:
		sum += u.mod(s, tags)
	return maxi(u.rounded(sum / float(heal_split)) + heal_bonus, 1)


# Its cost at a rank (starter spells: cost x rank).
func price(rank: int) -> int:
	return cost * (maxi(rank, 1) if cost_per_rank else 1)


# How many of the target's turns the effects it puts on last, at a rank.
func lasts(rank: int, u: Unit = null) -> int:
	return turns + turns_per_rank * rank + (maxi(u.mod(turns_mod), 0) if u and turns_mod else 0)


# Contests a foe in place of an attack roll: a save, a drag, Level Down, Death.
func contests() -> bool:
	return save != &"" or drags_to != &"" or levels_down or kills


# Used on its user alone: self_only, except a prayer to Drael (Pray), which is on a unit within rank tiles.
func on_self(u: Unit) -> bool:
	return self_only and not (prays and u and u.deity() == &"drael")


# Its range for a caster, before reach and size: radius (+ radius_per_rank x rank: Embellish), plus
# its mod in radius_mod - at least 1, so it reaches an adjacent unit - plus what its range effects add
# (a Staff, a Broadsword: Unit.skill_stat()).
func span(u: Unit) -> float:
	var r := radius + radius_per_rank * u.rank(self) + (u.stat(radius_stat) if radius_stat else 0.0)
	if radius_mod:
		r = maxf(r + u.mod(radius_mod, tags), 1.0)
	return r + (u.skill_stat(&"range", self) if not self_only else 0.0)


# The tags it's asked about by for its attributes (Unit.skill_stat()): its own, plus damage for a skill
# that deals any.
func query() -> Array[StringName]:
	var out: Array[StringName] = tags.duplicate()
	if not tiers.is_empty():
		out.append(&"damage")
	return out


# Up to 2 characters for it on skill trees: a stub's question ("?3"), its glyph, or its initials.
func mark() -> String:
	if stub:
		return stub.split(" ")[0]
	if glyph:
		return glyph
	var words := name.split(" ", false)
	if words.size() > 1:
		return words[0].left(1) + words[1].left(1)
	return name.left(2)


# "Waits on open question 3", "...questions 2 and 11".
func waits() -> String:
	var ids := Array(stub.replace("?", "").split(" ", false))
	if ids.size() == 1:
		return "Waits on open question %s (todo.md)" % ids[0]
	return "Waits on open questions %s and %s (todo.md)" % [", ".join(ids.slice(0, -1)), ids[-1]]


# The stat it's used with, for its attack roll: the one its tags name (str, wis...), else the one its
# damage scales on, else strength.
func stat() -> StringName:
	for t in tags:
		if t in STAT_TAGS:
			return STAT_TAGS[t]
	for t in tiers:
		if t.stat:
			return t.stat
	return &"strength"


static func roman(n: int) -> String:
	var out := ""
	for pair in [[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= pair[0]:
			out += pair[1]
			n -= pair[0]
	return out


# What it's used on (a Glossary target term): self, nearest, area, tile, ally_or_foe, foe or ally.
func target() -> StringName:
	if self_only:
		return &"self"
	if auto:
		return &"nearest"
	if zone or cone > 0.0 or channel:
		return &"area"
	if on_tile():
		return &"tile"
	if dual or either:
		return &"ally_or_foe"
	return &"foe" if hostile else &"ally"


# Its range as it scales, in Glossary markup: the set part first, then what grows with rank (gold),
# then its user's stat (orange): "2 + {o:int mod}", "{r:rank} + {o:cha mod}", "{r:rank} - 1".
func reach_markup() -> String:
	var parts: PackedStringArray = []
	if radius_per_rank:
		parts.append("{r:rank}" if radius_per_rank == 1 else "{r:%s x rank}" % num(radius_per_rank))
	if radius_stat:
		parts.append("{o:%s score}" % String(radius_stat).left(3))
	if radius_mod:
		parts.append(Glossary.mod(radius_mod))
	var grows := " + ".join(parts)
	if not grows:
		return num(radius)
	if radius > 0.0:
		return "%s + %s" % [num(radius), grows]
	if radius < 0.0:
		return "%s - %s" % [grows, num(-radius)]
	return grows


# What using it takes, in the same order on every skill: [label, Glossary markup] - its target, its
# range (none on itself), AP, cost. A passive: just how it runs.
func spec() -> Array:
	if stub:
		return [["", "Not built yet"]]
	if passive:
		return [["", "Passive"], ["", "Toggle" if toggle else ("Inherent" if inherent else "Always on")]]
	var out := [["", Glossary.term(target())]]
	if not self_only:
		out.append(["range", reach_markup()])
	out.append(["AP", num(ap)])
	if cost:
		out.append(["cost", "{r:%d x rank}" % cost if cost_per_rank else str(cost)])
	return out


# Its spec as one line of markup: "{k:foe} · range 2 + {o:int mod} · 3 AP · 2 cost".
func spec_line() -> String:
	return " · ".join(spec().map(spec_part))


# A part of its spec, read: "{k:foe}", "range 2 + {o:int mod}", "3 AP", "2 cost".
static func spec_part(p: Array) -> String:
	return p[1] if not p[0] else ("range " + p[1] if p[0] == "range" else "%s %s" % [p[1], p[0]])


# One line for lists: its spec, plain.
func summary() -> String:
	return Glossary.plain(spec_line())


# Everything it does at this rank, as plain text.
func describe(rank := 1) -> String:
	return Glossary.plain(markup(rank))


# The same in Glossary markup, for the skills screen and rich tooltips; with_spec: leading with its
# spec line (the skills screen shows that apart).
func markup(rank := 1, with_spec := true) -> String:
	var lines: PackedStringArray = []
	if stub:
		lines.append("Not built yet. " + waits())
		if plan:
			lines.append(plan)
		return "\n".join(lines)
	var foe := "On a foe: " if dual else ""
	var ally := "On an ally: " if dual else ""
	var me := Glossary.mod(stat())
	var me_short := String(stat()).left(3)
	if with_spec:
		lines.append(spec_line() if not passive or not inherent else "Inherent: can't be removed or disabled, and takes no slot")
	if not passive:
		for r: Reserve in ap_with:
			lines.append("%s AP paid with %s" % [share(ap_with[r]), r.name])
		for r: Reserve in cost_with:  # the skill opening a reserve goes by its name (Mana)
			lines.append("%s cost paid with %s, once the caster's %s rank reaches its tier" % [share(cost_with[r]), r.name, r.name])
		if attacks():
			lines.append("%s%s (%s%s)" % [foe, Glossary.term(&"attack") + (" with " + Glossary.term(&"advantage") if advantage else ""),
					me, " + {r:%d}" % (roll_per_rank * rank) if roll_per_rank else ""])
		if zone:
			lines.append("Lays %s %s around a tile for {t:%d turn%s}" % [zone, Glossary.term(&"concealment", "concealment"), turns, "" if turns == 1 else "s"])
		if observes:
			lines.append("Inspects around a tile as if it had rested {t:%d turn%s}: every tile within %s (at least 1) + {r:%d} tiles of it, at +{r:%d}, -1 a tile from it"
					% [rank, "" if rank == 1 else "s", Glossary.mod(&"wis"), rank, rank])
		if prays:
			var n := rank
			var s := "" if n == 1 else "s"
			lines.append("Prays to the caster's god:")
			lines.append("Ramut: its side waits {r:%d} turn%s less for Ramut's Ire" % [n, s])
			lines.append("Eros: up to {r:%d} unit%s within {r:%d} tile%s that can see it lose a stack of %s of it" % [n, s, n, s, Glossary.term(&"suspicion", "suspicion")])
			lines.append("Sol: darkness within {r:%d} tile%s is gone" % [n, s])
			lines.append("Urlo: enchants {r:%d} unenchanted item%s of allies within {r:%d} tile%s, weapons first (+1)" % [n, s, n, s])
			lines.append("Luun: the ground within {r:%d} tile%s falls into %s for {t:%d turn%s}, concealing its side a level" % [n, s, Glossary.term(&"darkness", "darkness"), n, s])
			lines.append("Drael: takes {r:%d} rank%s of debuffs off an ally within {r:%d} tile%s, the highest first" % [n, s, n, s])
			lines.append("Vetruvis: the ground within {r:%d} tile%s becomes %s for {t:%d turn%s}, costing its enemies 50%% more to enter" % [n, s, Glossary.term(&"disturbed_earth", "disturbed earth"), n, s])
		if save:
			lines.append("%s (%s%s) vs %s + {r:%d}" % [Glossary.term(&"save"), Glossary.mod(save, true),
					" + the ranks of the skills it would lose" if disables else "", me, rank])
		if levels_down:
			lines.append("{r:%d} %s (%s), each against the higher of the foe's {d:average stat mod} + level and its %s. Each that wins takes a level off it, for {t:%d turn%s} less one a miss"
					% [rank, Glossary.term(&"check", "check" if rank == 1 else "checks"), me, Glossary.term(&"last_stand"), rank, "" if rank == 1 else "s"])
		if kills:
			lines.append("Its %s x (its HP left / {r:%d}) vs a %s (%s): failing, it takes 1 %s damage and dies"
					% [Glossary.term(&"last_stand"), rank, Glossary.term(&"check", "check"), me, Glossary.term(&"true", "true")])
		if disables:
			var n := floori(sqrt(rank))
			var up := ceili(sqrt(rank))
			lines.append("Failing, {r:%s} of its skill slots are %s, from the right%s; its pillar skills go first, all as one slot"
					% [str(n) if n == up else "%d (%d while lucky)" % [n, up], Glossary.term(&"disabled", "disabled"), _lasting(rank)])
		if lays:
			var bonus := " + %s" % Glossary.mod(lays.bonus_stat) if lays.bonus_stat else ""
			lines.append("Sets a %s: %s {r:%d}, %dd%d x {r:%d}%s %s" % [Glossary.term(&"trap", lays.name.to_lower()), Glossary.term(&"concealment", "concealment"), lays.concealment * rank,
					lays.dice.x, lays.dice.y, lays.times * rank, bonus, " ".join(lays.damage_tags.filter(func(t): return t != &"trap").map(func(t): return "{x:%s}" % t))])
			if &"trap" in tags:
				lines.append("Allies within its %s in tiles learn where it is" % Glossary.mod(&"cha"))
		var t := tier(rank)
		if channel:
			lines.append("Channels on a tile. Cast again for %s AP and %d cost to strike: a tile within (its side's turns since) tiles of it explodes, hitting everyone within {r:%s} tiles but the caster"
					% [num(strike_ap), strike_cost, num(blast * rank)])
		if god_tag:
			var n := rank
			lines.append("Its damage takes its caster's god's tag, and on a hit its god adds:")
			lines.append("Eros ({x:love}): used on an ally, it heals what it would deal, overhealing at {r:%d%%}" % (20 * n))
			lines.append("Luun ({x:dark}): a foe left at {r:%d%%} of its max HP or less dies" % (5 * n))
			lines.append("Sol ({x:fire}): it burns again for {r:%d%%} of the damage, pure fire, as its turn ends" % (20 * n))
			lines.append("Urlo ({x:energy}): %s Energy (or Power) first%s; takes {r:%d} enchantment%s off, enchanting the caster's items with the rest"
					% [Glossary.term(&"drain", "drains"), ", then {r:%d%%} of the rest goes on to HP" % roundi(carry * (n - 1) * 100) if carry * (n - 1) > 0 else "", n, "" if n == 1 else "s"])
			lines.append("Drael ({x:water}): takes {r:%d} rank%s of its buffs off" % [n, "" if n == 1 else "s"])
			lines.append("Vetruvis ({x:earth}): radiates to everyone within {r:%d} tile%s, the damage / (tiles away + 1)" % [n, "" if n == 1 else "s"])
			lines.append("Ramut ({x:physical}): nothing more")
		if t:
			var dmg := _damage(t)
			if dice_per_rank and rank > 1:
				dmg = dmg.replace("%dd%d" % [t.dice.x, t.dice.y], "{r:%dd%d}" % [t.dice.x * rank, t.dice.y])
			if hits_per_rank and rank > 1:
				dmg = "{r:%d} hits of %s" % [rank, dmg]
			lines.append(foe + ("deals " if dual else "Deals ") + dmg)
			if &"energy" in tags:
				lines.append("%s: Energy (or Power) first%s" % [Glossary.term(&"drain"), ", then {r:%d%%} of the rest goes on to HP" % roundi(carry * (rank - 1) * 100) if carry * (rank - 1) > 0 else ""])
		if grants:
			lines.append("Gives %s for {t:%d turn%s}" % [grants.name, lasts(rank), "" if lasts(rank) == 1 else "s"])
		if chain:
			lines.append("Attacks cease on a miss. -1 to hit and damage for each hit in a row")
		if not elements.is_empty():
			lines.append("Pick an element (%s): %s deal%s it, the first hit + your highest mental mod" % [", ".join(elements.map(func(e): return "{x:%s}" % e)),
					"your next Strike" if rank == 1 else "your next {r:%d} Strikes" % rank, "s" if rank == 1 else ""])
		if boost_pool:
			lines.append("%sit gains %s + {r:%d} %s AP at once" % [ally if ally else "On an ally: ", Glossary.mod(boost_mod), rank, boost_pool])
		if humbles:
			lines.append("Caps its max HP at its HP now less 1%, for rank x 4 x (1 - the share cut) turns: the less it cuts, the longer")
		if aura:
			lines.append("%s: also on every ally within {r:%d} tile%s%s" % [Glossary.term(&"aura"), rank, "" if rank == 1 else "s", " - from rank V only the nearest {r:%d}, its strength split among them" % rank if splits else ""])
		if opening:
			lines.append("Only as its turn opens, before it moves or spends AP")
		if retrieves:
			lines.append("Takes the %s from wherever it is and puts it on, at rank {r:%d}" % [retrieves.name, rank])
		if flamewall:
			lines.append("Sets the tile and {r:%d} to either side of it, across the caster's line, %s for {t:%d turns}: 1d8 + %s {x:fire} to whoever enters or ends a turn there. One standing there makes a %s (%s) to get clear"
					% [rank, Glossary.term(&"burning", "burning"), rank, Glossary.mod(&"wis"), Glossary.term(&"check", "check"), Glossary.mod(&"dex", true)])
		if cone > 0.0:
			lines.append("A {r:%d} degree cone, its range long: 1d20 + {o:wis score} {x:fire} to everyone in it, the caster too" % roundi(cone + 15.0 * (rank - 1)))
		if heals():
			var mods := " + ".join(heal_mods.map(func(x): return Glossary.mod(x)))
			if heal_split > 1:
				mods = "(%s) / %d" % [mods, heal_split]
			lines.append("Heals %s%s HP, at least 1" % [mods, (" + %d" % heal_bonus if mods else str(heal_bonus)) if heal_bonus else ""])
			lines.append("Clears %s up to rank {r:%d}%s" % [Glossary.term(&"wound", "wounds"), clears(rank), " (rank x rank)" if squared else ""])
			if per_wound:
				lines.append("+{r:%d} HP for each wound it clears" % (per_wound * rank))
			if restores > 0.0:
				lines.append("Gives back {r:%s} AP" % num(restores * rank))
		if drags_to:
			lines.append("%s (%s vs %s) in place of an attack, -1 a tile it must drag the foe%s. Won: drags it to the nearest %s the caster could walk to, and both go in"
					% [Glossary.term(&"contest"), me, Glossary.mod(stat(), true), " (less {r:%d})" % (rank - 1) if rank > 1 else "", drags_to])
		if grip != Vector2i.ZERO:
			lines.append("%s it: moving away first takes 1 + %s tiles of movement and a %s. Each turn it ends held, it takes %dd%d + %s"
					% [Glossary.term(&"held", "Holds"), me, Glossary.term(&"contest", "contest"), grip.x, grip.y, me])
		if pull:
			lines.append("%s%s it up to {r:%d} tile%s toward the caster" % [foe, "draws" if dual else "Draws", pull * rank, "" if pull * rank == 1 else "s"])
		if resisted:
			lines.append("%s%s comes. On a suspicious one, a %s (%s vs %s) takes a stack of %s off"
					% [foe, ("only one " if dual else "Only one ") + Glossary.term(&"enraptured", "enraptured"), Glossary.term(&"contest", "contest"),
					me, Glossary.mod(resisted, true), Glossary.term(&"suspicion", "suspicion")])
		if auto:
			lines.append("Used at once: lands on the nearest {r:%d} unit%s in range, allies and foes alike" % [rank, "" if rank == 1 else "s"])
	for e in effects:
		lines.append(ally + e.markup(rank) + ("" if passive else _lasting(rank)))
	if has_look():
		var look := ([stance] if stance else []) + [", ".join(shows_vibe)] + [", ".join(shows_tags)]
		lines.append("Puts forward a look: %s. Its holder's dissonance counts {r:%d} less against its own checks"
				% ["; ".join(look.filter(func(x: String): return x != "")), rank])
	if investigated:
		lines.append("A %s as it's used (%s + {r:%d}): enemies that can see it %s against that at once, with %s within their %s - {r:%d} tiles. Those who meet it aren't fooled by it"
				% [Glossary.term(&"check", "check"), me, rank, Glossary.term(&"investigate", "investigate"), Glossary.term(&"advantage", "advantage"), Glossary.mod(&"wis", true), rank])
	if not energy_as.is_empty():
		lines.append("Energy paid for %s skills counts as their own resources, with the bonuses those give" %
				" or ".join(energy_as.map(func(t): return CATEGORIES.get(t, String(t)).to_lower())))
	if waives:
		lines.append("Opens the %s tree's skills up to {r:T%d} without their usual needs (one tier lower where your class doesn't have the tree, which it then shows). Skills learned that way stop working without it"
				% ["General" if waives == &"general" else ("Caster" if waives == &"magical" else String(waives).capitalize()), rank])
	if exclusive:
		lines.append("Only one %s can be learned" % ("Strike upgrade" if exclusive == &"strike_form" else String(exclusive)))
	if renames:
		lines.append("Strike becomes %s" % renames)
	if opens:
		lines.append("Cheaper casting with %s: skills up to {r:T%d} get the savings they list for it" % [opens.name, rank])
	if stand_in:
		lines.append("%s stands in for %s on %s skills" % [stand_in.capitalize(),
				", ".join(replaces.map(func(x): return String(x).capitalize())), ", ".join(tags)])
	if rank_cost:
		lines.append("Ranks cost more: II takes %d points, then x%s each rank" % [rank_cost, num(rank_growth)])
	if not tags.is_empty() and not stand_in:
		lines.append("Tags: " + ", ".join(tags.map(func(t): return "{x:%s}" % t)))
	if lore:
		lines.append(lore.replace("{", "(").replace("}", ")"))
	return "\n".join(lines)


# How long its put-on effects last at a rank: " for 2 turns", " until it moves", " for 2 turns,
# then a level less each turn".
func _lasting(rank: int) -> String:
	var n := lasts(rank)
	var text := " for {t:%d turn%s}" % [n, "" if n == 1 else "s"] if n else ""
	if turns_mod:
		text = " for %s + {t:%d turns}" % [Glossary.mod(turns_mod), n]
	if until_move:
		text += (", or" if n else "") + " until it moves"
	if fades and n:
		text += ", then a level less each turn"
	return text


func _damage(t: Tier) -> String:
	var parts: PackedStringArray = []
	if t.power:
		parts.append(str(t.power))
	if t.dice != Vector2i.ZERO:
		parts.append("%dd%d" % [t.dice.x, t.dice.y])
	if t.stat:
		parts.append(Glossary.mod(t.stat))
	return " + ".join(parts) + (", " + Glossary.term(&"unblockable", "unblockable") if t.direct else "")


# "Half", "A quarter", "x0.75": a cost or AP factor.
static func share(f: float) -> String:
	if is_equal_approx(f, 0.5):
		return "Half"
	if is_equal_approx(f, 0.25):
		return "A quarter"
	return "x" + num(f)


static func num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else String.num(x, 2)
