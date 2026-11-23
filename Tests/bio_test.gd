extends Test

# A unit's bio (Scripts/Bio.gd): its behaviour drives its AI, its appearance and adjectives are how it
# looks to whoever can't make out its class (and what the AI guesses from), its properties are always
# on it, and its clout with a side lends its persona and its lies weight there.

var rotting: Property = load("res://Properties/rotting.tres")
var renew: Skill = load("res://Skills/renew.tres")


func bio(behaviour := &"", appearance := "", adjectives: Array[String] = []) -> Bio:
	var x := Bio.new()
	x.behaviour = behaviour
	x.appearance = appearance
	x.adjectives = adjectives
	return x


func test_properties() -> void:
	var u: Unit = load("res://Scenes/villager.tscn").instantiate()
	u.bio = bio()
	u.bio.properties = [rotting]
	b.get_node("Units").add_child(u)
	stage(lancin, {v(1): Vector2i(1, 2)})
	b.move(u, Vector2i(3, 2))
	ok(&"rotting" in u.tags, "a property's tags are the unit's: it counts as rotting")
	ok(is_equal_approx(u.mitigation([&"fire"]), -0.5) and is_equal_approx(u.mitigation([&"dark"]), 0.25),
			"Rotting: fire takes half again (%s), darkness a quarter less (%s)" % [u.mitigation([&"fire"]), u.mitigation([&"dark"])])
	soak(u, 100)
	ok(u.hit(10, [&"fire"] as Array[StringName]) >= 15, "a fire hit of 10 lands 15")
	v(1).afflict(effect("recon", 3), 9)
	ok(b.read(v(1), u).properties == [rotting], "whoever makes out its identity reads what it's made of")


func test_looks() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(4, 2)})
	v(3).bio = bio(&"", "Soldier", ["Injured"] as Array[String])
	var r := b.read(v(1), v(3))
	ok(r.role == null and r.looks == "Injured Soldier", "its class lost on it, it goes by how it looks: %s" % r.looks)
	ok(AI._level(v(1), r) == v(1).lv() + 0, "a Soldier, but Injured: guessed at its own level (%s)" % AI._level(v(1), r))
	v(3).bio.adjectives = ["Horrific"] as Array[String]
	r = b.read(v(1), v(3))
	ok(AI._level(v(1), r) == v(1).lv() + 2 and AI._hate(r) == AI.HATE * -1,
			"Horrific: guessed stronger, and hated like an ominous aura (%s, %s)" % [AI._level(v(1), r), AI._hate(r)])
	v(3).bio = bio(&"", "Knight")
	ok(Perception.kind_noun(v(3)) == "Knight", "its appearance is its kind's noun, where its class's would be")
	ok(Bio.hurt("Injured Knight") and not Bio.hurt("Beautiful Knight"), "Injured looks hurt")


func test_temper() -> void:
	ok(v(1).temper() == &"", "no bio: no temper")
	v(1).behaviour = &"craven"
	ok(v(1).temper() == &"timid", "a craven unit is timid")
	v(1).bio = bio(&"brave")
	ok(v(1).temper() == &"brave" and AI._leaning(v(1)) == 1, "brave: goes for the strongest")
	v(1).bio = bio(&"aggressive")
	ok(AI._leaning(v(1)) == -1, "aggressive: the weakest")
	v(1).strategy = [&"strongest"] as Array[StringName]
	ok(AI._leaning(v(1)) == 1, "a strategy outranks its temper")


func test_stoic_holds() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(3).bio = bio(&"stoic")
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "stoic: no foe in reach, it holds")
	v(3).bio = null
	v(3).refresh()
	AI.act(b, v(3))
	ok(v(3).cell != Vector2i(8, 2), "without a temper it closes in")


func test_helpful_tends() -> void:
	v(3).learned.append(slot(renew, 1)); v(3).sync_bar()
	v(3).refresh()
	stage(nemes, {v(1): Vector2i(1, 6), v(3): Vector2i(8, 2), v(4): Vector2i(8, 7)})
	v(4).hp = 2
	v(3).bio = bio(&"helpful")
	var log := AI.act(b, v(3))
	ok(log.size() > 0 and log[0].begins_with("Villager3 goes to Villager4") and v(4).hp > 2, "helpful: it goes to the wounded and heals them (%s)" % ", ".join(log))


func test_aggressive_heals_last() -> void:
	v(1).learned.append(slot(renew, 1)); v(1).sync_bar()
	v(1).strength = 40
	v(1).refresh()
	stage(lancin, {v(1): Vector2i(4, 4), v(2): Vector2i(4, 5), v(3): Vector2i(5, 4)})
	v(2).hp = 2
	soak(v(3), 300)
	v(1).bio = bio(&"aggressive")
	var log := AI.act(b, v(1))
	var hit := log.find_custom(func(x: String): return x.contains("uses Strike"))
	var healed := log.find_custom(func(x: String): return x.contains("heals"))
	ok(hit != -1 and (healed == -1 or healed > hit), "aggressive: it strikes first, heals with what's left (%s)" % ", ".join(log))


func test_clout() -> void:
	var bl: Unit = b.summon(load("res://Scenes/blinthe.tscn"), load("res://Factions/unaligned.tres"), Vector2i(5, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	b.move(bl, Vector2i(5, 3))
	var with_lancin := Perception.trickery(bl, Read.new(), v(1), b)
	var with_nemes := Perception.trickery(bl, Read.new(), v(3), b)
	ok(is_equal_approx(with_lancin - with_nemes, 1.0), "clout 3 with Lancin, 2 with Nemes: its lies go a rank further with Lancin (%s, %s)" % [with_lancin, with_nemes])
	bl.bio = bl.bio.duplicate(true)  # the scene's bio is shared: don't touch it
	bl.bio.clout.clear()
	ok(is_equal_approx(Perception.trickery(bl, Read.new(), v(1), b), with_lancin - 3.0), "no clout: 3 less")


func test_sheet_line() -> void:
	ok(Guide.text(&"character").contains("(%s)" % Bio.TEMPERS[Bio.BEHAVIOURS[0]]) and Bio.TEMPERS.size() == Bio.BEHAVIOURS.size(), "the Guide names every temper")
	var s: Unit = b.get_node("Units/Siren")
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(3, 2)})
	v(1).bio = bio(&"brave", "Knight", ["Injured"] as Array[String])
	v(1).bio.properties = [rotting]
	ok(Glossary.plain(Bio.line(v(1))) == "Brave · Injured Knight · Rotting", "its own bio, whole: %s" % Glossary.plain(Bio.line(v(1))))
	var sheet := CharacterSheet.new()
	sheet.open(v(1), false)
	ok(sheet.find_child("Bio", true, false) != null, "the sheet shows the line")
	sheet.free()
	s.bio = bio(&"aggressive", "Beast", ["Horrific"] as Array[String])
	s.bio.properties = [rotting]
	v(1).afflict(effect("recon", 1), 9)
	var r := b.read(v(1), s)
	var line := Glossary.plain(Bio.line(s, r))
	ok(r.deceived and "Aggressive" not in line and "Rotting" not in line and "Horrific" not in line and s.alias_noun in line,
			"a disguised foe shows its persona's bio, not its own: %s" % line)
	v(1).afflict(effect("recon", -20), 9)
	ok(Bio.line(s, b.read(v(1), s)) == "", "a foe it can't make out shows nothing")


# The HUD's look-over (middle-click / the look_over key) opens the read-only sheet with the player's Read.
func test_look_over() -> void:
	var s: Unit = b.get_node("Units/Siren")
	stage(lancin, {v(1): Vector2i(1, 2), s: Vector2i(3, 2)})
	v(1).bio = bio(&"brave", "Knight", ["Injured"] as Array[String])
	s.bio = bio(&"aggressive", "Beast", ["Horrific"] as Array[String])
	s.bio.properties = [rotting]
	var h := await hud(v(1))
	var line := func() -> String:
		var l := h.sheet.find_child("Bio", true, false) as RichTextLabel
		return l.get_parsed_text() if h.sheet.visible and l else ""
	h.look_over(v(1).cell)
	ok(h.sheet.visible and h.sheet.unit == v(1) and line.call() == "Brave · Injured Knight", "its own unit reads whole: %s" % line.call())
	h.sheet.hide()
	v(1).afflict(effect("recon", 1), 9)
	h.look_over(s.cell)
	ok(h.sheet.visible and h.sheet.unit == s and "Aggressive" not in line.call() and "Rotting" not in line.call() and "Horrific" not in line.call(), "a disguised foe shows its persona: %s" % line.call())
	var all := h.sheet.find_children("*", "Label", true, false).map(func(l: Label): return l.text)
	ok(not " ".join(all).contains("Siren") and not " ".join(all).contains("XP") and not " ".join(all).contains("Weapon"), "and none of its real name, XP or kit: %s" % [all])
	h.sheet.hide()
	v(1).afflict(effect("recon", -20), 9)
	h.look_over(s.cell)
	ok(line.call() == "" and h.view(s).name == "", "a foe it can't make out shows nothing: %s" % line.call())
	h.sheet.hide()
	h.look_over(Vector2i(6, 6))
	ok(not h.sheet.visible, "an empty tile opens nothing")
	h.free()


# Vindictive (AI._grudge()): of two foes alike, it goes after the one that landed a blow on its side this fight (Unit.wrongs),
# or the one its grudges name (Bio.grudges); it signs "Grudge" the first time only (Battle.first_time()).
func test_vindictive_grudge() -> void:
	stage(nemes, {v(1): Vector2i(5, 2), v(2): Vector2i(5, 6), v(3): Vector2i(3, 4), v(4): Vector2i(8, 8)})
	for u in [v(1), v(2), v(3), v(4)]:
		u.wrongs.clear()
	b._firsts.clear()
	v(3).bio = bio(&"vindictive")
	var plain := AI._best_target(v(3), AI._reads(b, v(3)))
	var other := v(2) if plain == v(1) else v(1)
	soak(v(4))
	v(4).hit(3, [] as Array[StringName], other)
	ok(AI._best_target(v(3), AI._reads(b, v(3))) == other, "it goes after %s, who struck its ally" % other.name)
	v(3).bio.behaviour = &""
	ok(AI._best_target(v(3), AI._reads(b, v(3))) == plain, "no temper, no grudge")
	other.wrongs.clear()
	v(3).bio = bio(&"vindictive")
	v(3).bio.grudges = [other.name] as Array[String]
	ok(AI._best_target(v(3), AI._reads(b, v(3))) == other, "its grudges name %s" % other.name)
	var signs := []
	var count := func(u: Unit, _s: Skill, _n: int, stat: StringName, _r: int): if stat == &"grudge": signs.append(u)
	b.passive_fired.connect(count)
	AI.act(b, v(3))
	v(3).refresh()
	AI.act(b, v(3))
	b.passive_fired.disconnect(count)
	ok(signs == [v(3)], "Grudge signed once over two turns (%s)" % [signs])
	v(3).bio = null
	soak(v(4), 10)


# Flirty (AI._fancies()): its support goes to the ally it fancies (Bio.fancies, else high charisma) first, signed "Smitten".
func test_flirty_supports_fancied() -> void:
	var buff: Skill = load("res://Skills/intervention.tres").duplicate()
	buff.effects = [effect("mitigate", 0.2)] as Array[Effect]
	v(3).learned.append(slot(buff)); v(3).sync_bar()
	v(3).refresh()
	v(2).faction = nemes
	stage(nemes, {v(1): Vector2i(1, 8), v(2): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(6, 3)})
	b._firsts.clear()
	var given := func() -> Unit:
		for o in [v(2), v(4)]:
			o.timed.erase(buff.effects[0])
		var log: Array[String] = []
		AI._support(b, v(3), AI.reads_from({v(2): b.read(v(3), v(2)), v(4): b.read(v(3), v(4))}), log)
		return v(2) if buff.effects[0] in v(2).timed else (v(4) if buff.effects[0] in v(4).timed else null)
	var plain: Unit = given.call()
	var other := v(4) if plain == v(2) else v(2)
	v(3).bio = bio(&"flirty")
	v(3).bio.fancies = [other.name] as Array[String]
	var signs := []
	var count := func(u: Unit, _s: Skill, _n: int, stat: StringName, _r: int): if stat == &"smitten": signs.append(u)
	b.passive_fired.connect(count)
	ok(plain != null and given.call() == other, "flirty: it gives to %s, whom it fancies, first" % other.name)
	b.passive_fired.disconnect(count)
	ok(signs == [v(3)], "signed Smitten (%s)" % [signs])
	v(3).bio.fancies = [] as Array[String]
	other.charisma = 16
	var recon := effect("recon", 3)
	v(3).afflict(recon, 9)  # to read its stats
	ok(given.call() == other, "fancying no one by name: high charisma (%s)" % b.read(v(3), other).stats.get(&"charisma"))
	other.charisma = 10
	v(3).timed.erase(recon)
	v(3).bio = null
	v(2).faction = lancin
	v(3).learned.pop_back(); v(3).sync_bar()
	v(3).refresh()
