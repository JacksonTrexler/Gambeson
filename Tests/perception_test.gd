extends Test

# Concealment, recon, trickery and Persona; traps, Darkstone, Darkvision, Tonefoolery, the Siren,
# and an AI that acts on what it perceives. Trap at (5,4); the Siren starts on a wet rock at (8,6).

const TRAP := Vector2i(5, 4)
var trap: Terrain = load("res://Terrain/trap.tres")
var darkstone: Skill = load("res://Skills/darkstone.tres")
var darkvision: Skill = load("res://Skills/darkvision.tres")
var glamour: Skill = load("res://Skills/glamour.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func icor() -> Unit:
	return b.get_node("Units/Icor")


func test_trap_reads() -> void:
	var r := b.read(v(1), TRAP)
	ok(r.net == -2 and r.name == "Grass" and r.hint == "disturbed earth?", "recon 0 vs concealment 2: looks like grass, 'disturbed earth?'")
	ok(r.cost == null and r.worth == null and r.aura == -1 and not r.known_bad(), "...with an ominous vibe but nothing known")
	ok(b.read(v(3), TRAP).net == -2, "Wary I gives 0.5 trap recon, rounded down at luck 0")
	v(3).learned[0].rank = 2
	ok(b.read(v(3), TRAP).net == -1 and b.read(v(3), TRAP).hint == "", "Wary II (recon 1): -1, no details")
	v(3).learned[0].rank = 4
	var r4 := b.read(v(3), TRAP)
	ok(r4.net == 0 and r4.name == "Spike Trap" and r4.cost == 1 and r4.known_bad(), "Wary IV (recon 2): its name, and that it's a trap")
	v(3).learned[0].rank = 6
	ok(b.read(v(3), TRAP).worth == -1, "Wary VI (recon 3): known bad ground")
	v(1).afflict(effect("recon", -1), 9)
	ok(b.read(v(1), TRAP).hint == "a prickle of unease", "-3: only a vibe")
	v(1).afflict(effect("recon", -2), 9)
	var r_4 := b.read(v(1), TRAP)
	ok(r_4.net <= -4 and r_4.name == "Grass" and r_4.aura == null and r_4.hint == "", "-4: just grass")
	var plain := b.read(v(2), Vector2i(0, 0))
	ok(plain.net == 0 and plain.name == "Grass" and plain.cost == 1 and plain.trap == false, "plain ground: no surprises")


func test_trap_springs() -> void:
	trap.dice = Vector2i(4, 1)  # always 4
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	ok(b.travel(v(1), Vector2i(7, 4)) == cells([TRAP]) and v(1).cell == TRAP, "the move stops on the trap")
	ok(v(1).hp == 7, "4 pierce: Favour 1% (pierce is physical), luck rounds 3.96 down -> 3")
	ok(b.revealed.has(TRAP) and b.read(v(2), TRAP).known_bad(), "sprung: revealed, and now everyone knows")
	stage(nemes, {v(3): Vector2i(4, 4), v(1): Vector2i(0, 0)})
	b.travel(v(3), Vector2i(7, 4))
	ok(v(3).hp == 7, "Wary I: 25% off trap damage, 4 -> 3")
	trap.dice = Vector2i(1, 6)


func test_wary_v() -> void:
	trap.dice = Vector2i(1, 1)
	trap.blast = 1.0
	stage(nemes, {v(3): Vector2i(4, 4), v(1): Vector2i(5, 3), v(4): Vector2i(5, 5)})
	v(3).learned[0].rank = 5
	b.travel(v(3), TRAP)
	ok(v(3).hp == 10, "Wary V: 125% trap mitigation, immune")
	ok(v(1).hp == 9, "an enemy in the blast takes 1 x 1.25 x 0.99 = 1.24 -> 1 (it would be 0 without Wary V)")
	ok(v(4).hp == 9, "an ally in the blast gets no boost: 1 x 0.75 (Wary I), rounded up at net luck 0 -> 1")
	trap.dice = Vector2i(1, 6)
	trap.blast = 0.0


func test_darkstone() -> void:
	icor().learned.append(slot(darkstone, 2))
	stage(nemes, {icor(): Vector2i(7, 3), v(1): Vector2i(5, 3), v(3): Vector2i(9, 3)})
	ok(not b.cast_at(icor(), darkstone, Vector2i(3, 3)), "rank 2: centre within 1 + 2 = 3")
	ok(b.cast_at(icor(), darkstone, Vector2i(5, 3)), "cast at (5,3)")
	var z: Battle.Zone = b.zones[0]
	ok(z.levels[Vector2i(5, 3)] == 2 and z.levels[Vector2i(4, 3)] == 1 and z.levels[Vector2i(6, 2)] == 1 and not z.levels.has(Vector2i(5, 5)), "rank - distance: 2 at the centre, 1 around, none at 2 away")
	ok(icor().store(load("res://Reserves/mana.tres")) == 9, "3 mana (it's magical)")
	var r := b.read(v(3), v(1))
	ok(r.net == -2 and r.hint == "a shape in the dark?" and r.located() and r.faction == null and not r.seen and r.heard, "a unit in darkness 2: a shape, located, unseen but heard")
	v(3).learned.append(slot(darkvision, 1))
	ok(b.read(v(3), v(1)).net == -1, "Darkvision I nullifies one level")
	v(3).learned[-1].rank = 2
	ok(b.read(v(3), v(1)).net == 0 and b.read(v(3), v(1)).faction == lancin, "Darkvision II sees through it")
	ok(b.read(v(4), Vector2i(4, 3)).net == -1 and b.read(v(4), Vector2i(4, 3)).name == "", "dark ground: no details")
	for i in 6:
		b.end_turn()
	ok(b.zones.is_empty(), "gone after 3 Nemes turns")


func test_siren() -> void:
	var s := siren()
	ok(s.faction == nemes and s.charisma == 18 and s.ground.has(&"wet"), "Nemes, cha 18, on a wet rock")
	ok(s.stat(&"strength") == 12 and s.stat(&"dexterity") == 12, "Oceanic: no penalty when wet")
	b.move(s, Vector2i(7, 4))
	ok(s.stat(&"strength") == 8 and s.stat(&"dexterity") == 8 and s.stat(&"constitution") == 8 and s.stat(&"intelligence") == 12, "on grass: physical stats -4")
	b.move(s, Vector2i(8, 6))
	ok(roundi(s.stat(&"persona")) == 3 and Perception.trickery(s, Read.new()) == 2.0, "Persona III, Tonefoolery II")


func test_siren_fools() -> void:
	var r := b.read(v(1), siren())
	ok(r.deceived and r.twist == 1.0, "trickery 2 vs recon 0: fooled, fully")
	ok(r.faction == lancin and r.vibe == "Harmless, Beautiful, Serene" and r.aura == 2 and r.tags == [&"holy"], "reads as a harmless, holy ally")
	ok(r.healthy == false and r.hp == 1, "unpresented fields are inverted (full health reads as nearly dead)")
	ok(r.name == "" and r.skills.is_empty(), "posing as something else, it hides its name and skills")
	var ally := b.read(v(3), siren())
	ok(not ally.deceived and ally.faction == nemes and ally.hp == 16, "its own side isn't fooled")
	v(1).afflict(effect("recon", 3), 9)
	var sharp := b.read(v(1), siren())
	ok(not sharp.deceived and sharp.faction == nemes and sharp.vibe == "Briny, hungry" and sharp.aura == -2, "recon 3 sees the truth")
	ok(sharp.tags.has(&"monster") and sharp.skills.size() == 4, "...what it is, and (net 3) its skills")


func test_tonefoolery_doubles() -> void:
	icor().learned.append(slot(darkstone, 2))
	stage(nemes, {icor(): Vector2i(7, 4), siren(): Vector2i(8, 6), v(1): Vector2i(0, 0)})
	b.cast_at(icor(), darkstone, Vector2i(8, 5))
	v(1).afflict(effect("recon", 3), 9)
	var r := b.read(v(1), siren())
	ok(not r.seen and r.heard and Perception.trickery(siren(), r) == 4.0, "heard but not seen: Tonefoolery doubles to 4")
	ok(r.deceived and is_equal_approx(r.twist, 4.0 / 6.0), "4 vs recon 3: fooled, twist 4 / (2 x 3)")


func test_glamour_doubles() -> void:
	v(3).learned.append(slot(glamour, 1))
	ok(Perception.trickery(v(3), b.read(v(1), v(3))) == 1.0, "Glamour I, heard: 1")
	v(3).afflict(effect("concealment", 1, [&"sound"]), 9)
	var r := b.read(v(1), v(3))
	ok(not r.heard and Perception.trickery(v(3), r) == 2.0, "unheard: doubles to 2")


func test_twist() -> void:
	v(3).afflict(effect("trickery", 1), 9)
	v(1).afflict(effect("recon", 1), 9)
	var half := b.read(v(1), v(3))
	ok(half.deceived and half.twist == 0.5, "trickery 1 vs recon 1: fooled, half twisted")
	v(3).afflict(effect("trickery", 2), 9)
	var full := b.read(v(1), v(3))
	ok(full.twist == 1.0 and full.faction == lancin and full.healthy == false and full.aura == 0, "trickery 2 vs recon 1: every field inverted (ally, bloodied)")
	ok(full.strengths[0] in [&"intelligence", &"charisma"], "strengths and weaknesses swap (shows a true weakness)")
	ok(b.read(v(1), v(3)).faction == full.faction, "reads don't flicker")


func test_ai_spares_beloved() -> void:
	stage(lancin, {v(1): Vector2i(7, 6), siren(): Vector2i(8, 6)})
	var log := AI.act(b, v(1))
	ok(siren().hp == 16 and not log.any(func(l): return "on Siren" in l), "fooled: it won't strike the 'harmless ally'")
	v(1).afflict(effect("recon", 3), 9)
	stage(lancin, {v(1): Vector2i(7, 6), siren(): Vector2i(8, 6)})
	AI.act(b, v(1))
	ok(siren().hp < 16, "with recon 3 it sees the threat and strikes")


func test_ai_avoids_known_traps() -> void:
	v(3).learned[0].rank = 6  # trap recon 3: knows (5,4) is a trap
	stage(nemes, {v(3): Vector2i(3, 4), v(1): Vector2i(7, 4)})
	AI.act(b, v(3))
	ok(not b.revealed.has(TRAP) and v(3).cell != TRAP, "walks around a trap it knows about")


func cells(a: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(a)
	return out


func test_ai_wont_hit_unknowns() -> void:
	icor().learned.append(slot(darkstone, 2))
	stage(nemes, {icor(): Vector2i(7, 1), v(3): Vector2i(5, 3), v(1): Vector2i(4, 3)})
	b.cast_at(icor(), darkstone, Vector2i(5, 3))  # v(3) in darkness 2: a shape, side unknown
	b.end_turn()
	ok(b.turn == lancin and b.read(v(1), v(3)).faction == null, "Lancin can't tell whose side the shape is on")
	AI.act(b, v(1))
	ok(v(3).hp == 10, "so it doesn't strike it")


func test_trap_under_darkness() -> void:
	icor().learned.append(slot(darkstone, 2))
	stage(nemes, {icor(): Vector2i(7, 4), v(1): Vector2i(0, 0)})
	b.cast_at(icor(), darkstone, TRAP)
	var r := b.read(v(1), TRAP)
	ok(r.net <= -4 and r.name == "" and b.read(v(1), Vector2i(4, 4)).name == "", "in darkness a trap reads like any dark ground, not 'Grass'")
