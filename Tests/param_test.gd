extends Test

# Skills parameterized for modifiers (docs/plans/param.md): each declares its terms (a behaviour's
# terms(), or SkillTerms' reading of its reserve, opens, downed rule or per-stat effect) and reads its
# rank and stats through its holder's modifiers, so at least one modifier fits it and acts on it.

# Every skill parameterized here: eligible for at least one modifier.
const PARAMETERIZED := ["acceptance", "bargaining", "quarry", "survivalist", "wildcaller", "bandwagon", "illusionist",
		"molothrus", "telepathy", "word_to_the_wise", "energize", "heal", "megaheal", "move", "resuscitate", "clairvoyance",
		"manifest", "sweet_nothings", "mana", "grudge", "tenacity"]


func emblem(word: StringName, scope: StringName, rank := 1) -> Item:
	var it := Item.new()
	it.name = "Test %s %s" % [word, scope]
	it.slot = "trinket"
	it.emblem = word
	it.scope = scope
	it.rank = rank
	return it


func test_eligible() -> void:
	for id in PARAMETERIZED:
		var s: Skill = load("res://Skills/%s.tres" % id)
		var fits := Modifiers.words().filter(func(w: StringName): return Modifiers.eligible(w, s))
		ok(not fits.is_empty() and SkillTerms.of(s).scales(), "%s: eligible for %s" % [id, ", ".join(fits.slice(0, 4))])


# An active's behaviour: Move's tiles are rank impact.
func test_move() -> void:
	var move: Skill = load("res://Skills/move.tres")
	v(1).learned.append(slot(move, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)  # x1.5: rank II reads as 3
	var before := v(1).move_left()
	ok(b.cast(v(1), move, v(1)) and is_equal_approx(v(1).move_left() - before, 3.0), "Density: Move II gains 3 tiles (%s)" % (v(1).move_left() - before))
	ok(not Modifiers.eligible(&"rho_down", move), "Diluted doesn't fit it: no rank range to boost, so an emblem never only takes away")


# Heal's caster mod is stat impact.
func test_heal() -> void:
	var heal: Skill = load("res://Skills/heal.tres")
	v(1).learned.append(slot(heal, 1))
	v(1).wisdom = 16  # +3
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	var plain: int = heal.behaviours[0].restores(b.cast_of(v(1), heal, v(2), 1, false))[&"hp"]
	v(1).trinket = emblem(&"sigma_down", &"insignia", 1)  # stat impact x1.5
	var more: int = heal.behaviours[0].restores(b.cast_of(v(1), heal, v(2), 1, false))[&"hp"]
	ok(more - plain == 2, "Concentrated: its wis mod 3 x1.5 -> 5 (%d -> %d)" % [plain, more])


# Clairvoyance's reach: wisdom score and channel rank, both range.
func test_clairvoyance() -> void:
	var cv: Skill = load("res://Skills/clairvoyance.tres")
	v(1).learned.append(slot(cv, 1))
	v(1).wisdom = 4
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 6)})
	v(1).trinket = emblem(&"sigma_up", &"insignia", 1)  # stat range x1.5
	ok(b.cast(v(1), cv, v(1)) and cv.behaviours[0].reach(v(1)) == roundi(4 * 1.5 + 1), "Dispersed: wisdom x1.5 + rank (%d)" % cv.behaviours[0].reach(v(1)))
	v(1).trinket = emblem(&"rho_up", &"insignia", 1)
	ok(not Modifiers.eligible(&"rho_up", cv) and cv.behaviours[0].reach(v(1)) == 5, "Density doesn't fit it (no rank impact): wisdom + rank, unmodified")
	v(1).trinket = emblem(&"rho_down", &"insignia", 1)  # rank range x1.5
	ok(cv.behaviours[0].reach(v(1)) == roundi(4 + 1.5), "Diluted: wisdom + rank x1.5 (%d)" % cv.behaviours[0].reach(v(1)))


# A passive's hook (Word to the Wise: its wis mod is stat impact) and Unit-side reads (a reserve, Mana's tiers).
func test_passives() -> void:
	var wise: Skill = load("res://Skills/word_to_the_wise.tres")
	var sweet: Skill = load("res://Skills/sweet_nothings.tres")
	var mana: Skill = load("res://Skills/mana.tres")
	v(1).learned.append(slot(wise, 1))
	v(1).learned.append(slot(sweet, 1))
	v(1).wisdom = 16  # +3
	v(2).wisdom = 16
	v(1).charisma = 14  # +2
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	var bh: Behaviour = wise.behaviours[0]
	ok(bh.command_mod(null, v(1), 1, v(2)) == 3 and v(1).pools()[sweet.reserve] == 2, "unmodified: commands by wis mod 3; Sweet Nothings cha mod 2 x I")
	v(1).trinket = emblem(&"sigma_down", &"badge", 1)  # stat impact x(1 + 2/3)
	ok(bh.command_mod(null, v(1), 1, v(2)) == 4 and v(1).pools()[sweet.reserve] == 3, "Concentrated Badge: wis 3 -> min(5, 3 + 1) = 4; Sweet Nothings 2 -> 3 (%d, %d)" % [bh.command_mod(null, v(1), 1, v(2)), v(1).pools()[sweet.reserve]])
	v(1).learned.append(slot(mana, 1))
	v(1).refresh()
	v(1).trinket = emblem(&"rho_up", &"badge", 1)
	ok(v(1).opened(mana.opens) == 2, "Density Badge: Mana I opens up to tier 2 (%d)" % v(1).opened(mana.opens))
