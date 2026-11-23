extends Test

# The star lattice (Battle.panes, Battle.starpower: Power back faster on it, by how full its source is;
# a bludgeoning blow with no target breaks a pane), Starmen (Starsap, a grudge on astral foes,
# falling back into Starmotes) and Starmotes (Starkind: wasting away off the lattice, reforming on
# it at full Power), and neutral sides (Faction.neutral).

var starman: PackedScene = load("res://Scenes/starman.tscn")
var starmote: PackedScene = load("res://Scenes/starmote.tscn")
var starmen: Faction = load("res://Factions/starmen.tres")
var stellar: Faction = load("res://Factions/astral.tres")
var staff: Item = load("res://Items/staff.tres")


func spawn(scene: PackedScene, f: Faction, at: Vector2i) -> Unit:
	return b.summon(scene, f, at)


# A line of panes from (1, 1) to (5, 1), its source - a startile - at (1, 1), `full` of the way: laid as
# layers (tile stacks).
func lattice(full: float) -> void:
	b.panes.clear()
	b.starpower.clear()
	b.charge.clear()
	for c in b.layers.keys():
		b.layers[c].clear()
		b._restack(c)
	for x in range(2, 6):
		b.lay_layer(Vector2i(x, 1), Battle.STARPANE)
	b.lay_layer(Vector2i(1, 1), Battle.STARTILE)
	b.starpower[Vector2i(1, 1)] = full
	b.charge[Vector2i(1, 1)] = roundi(full * Battle.STAR_CAPACITY)


func test_lattice() -> void:
	lattice(0.0)
	ok(b.star_source(Vector2i(5, 1)) == Vector2i(1, 1) and is_equal_approx(b.star_rate(Vector2i(5, 1)), 1.0), "a pane linked to an empty source: nothing")
	b.charge[Vector2i(1, 1)] = 1
	ok(b.star_rate(Vector2i(5, 1)) > 2.0 and b.star_rate(Vector2i(5, 1)) < 2.2, "a little Power in it: about x2")
	b.charge[Vector2i(1, 1)] = Battle.STAR_CAPACITY
	ok(is_equal_approx(b.star_rate(Vector2i(4, 1)), 5.0) and is_equal_approx(b.star_rate(Vector2i(7, 7)), 1.0), "full: x5; off the lattice: x1")
	b.panes.erase(Vector2i(3, 1))
	ok(b.star_source(Vector2i(5, 1)) == null and b.star_source(Vector2i(2, 1)) == Vector2i(1, 1), "a broken pane cuts the link")


func test_starlight() -> void:
	lattice(1.0)
	stage(lancin, {v(1): Vector2i(4, 1)})
	var p := spawn(load("res://Scenes/astral_princess.tscn"), stellar, Vector2i(2, 1))
	p.energy = 0
	b._starlight(p)
	var k := maxi(p.rounded((p.mod(&"constitution") + p.mod(&"wisdom")) / 2.0), 1)
	ok(p.energy == p.rounded(k * 5.0), "Power on a full source's lattice: x5 its resting rate (%d)" % p.energy)
	v(1).energy = 0
	v(1).wisdom = 14
	v(1).constitution = 14
	b._starlight(v(1))
	ok(v(1).energy == v(1).rounded(2 * 4.0 * Battle.STAR_ENERGY), "plain Energy: a fifth of the boost (%d)" % v(1).energy)


# Power Siphon: a live source with at_end (a starpower generator) puts it on whoever ends a turn anywhere
# on its circuit (Battle.circuit_ends()); power_siphon takes its share of max HP and gives that share of max Power.
func test_siphon() -> void:
	lattice(0.0)
	var gen: Terrain = load("res://Terrain/starpower_generator.tres")
	b.lay_layer(Vector2i(6, 1), gen)
	b.charge[Vector2i(6, 1)] = Battle.STAR_CAPACITY
	stage(lancin, {v(1): Vector2i(3, 1), v(2): Vector2i(3, 3), v(3): Vector2i(8, 4)})
	var hp := v(1).hp
	b.end_turn()
	ok(v(1).stat(&"power_siphon") == 0.05 and v(1).hp == hp - 1 and v(2).stat(&"power_siphon") == 0.0 and v(2).hp == v(2).max_hp, "on the generator's wires: siphoned; off them: not")
	b.panes.erase(Vector2i(5, 1))
	b.end_turn()
	b.end_turn()
	ok(v(1).stat(&"power_siphon") == 0.0 and v(1).hp == hp - 1, "a broken pane cuts it off: no more")
	v(2).max_energy = 40
	v(2).energy = 0
	v(2).afflict(gen.at_end[0], 2)
	b._siphon(v(2))
	ok(v(2).energy == 2 and v(2).hp == v(2).max_hp - 1, "5%% of max HP gone, 5%% of max Power gained (%d)" % v(2).energy)


# The AI prices the siphon as it does other turn-end ground: where a walk ends on the live circuit it owes the HP share;
# route()'s price for ending there is higher than for ending off it, and a broken circuit owes nothing.
func test_siphon_priced() -> void:
	lattice(0.0)
	b.lay_layer(Vector2i(6, 1), load("res://Terrain/starpower_generator.tres"))
	b.charge[Vector2i(6, 1)] = Battle.STAR_CAPACITY
	stage(lancin, {v(1): Vector2i(3, 2), v(2): Vector2i(3, 3), v(3): Vector2i(8, 4)})
	var on := Vector2i(4, 1)
	var off := Vector2i(4, 2)
	var hp: float = b.hazard(v(1), on, b.read(v(1), on), 1, true).get(&"hp", 0.0)
	ok(hp >= 1.0 and b.hazard(v(1), on, b.read(v(1), on), 1, false).is_empty() and b.hazard(v(1), off, b.read(v(1), off), 1, true).is_empty(), "ending on the circuit owes HP; passing over or ending off it owes none (%s)" % hp)
	var p_on := {&"wary": true}
	var p_off := {&"wary": true}
	b.route(v(1), on, [on], p_on)
	b.route(v(1), off, [off], p_off)
	ok(p_on.cost > p_off.cost, "route() prices the circuit end above bare ground (%s vs %s)" % [p_on.cost, p_off.cost])
	b.panes.erase(Vector2i(5, 1))
	ok(b.hazard(v(1), on, b.read(v(1), on), 1, true).is_empty(), "a cut circuit owes nothing")


func test_shatter() -> void:
	lattice(0.5)
	stage(lancin, {v(1): Vector2i(3, 2)})
	v(1).weapon = null
	ok(&"blunt" in Battle.hit_tags(v(1), strike), "Strike bare-handed: a blunt blow")
	ok(b.attempt(v(1), strike, Vector2i(3, 1)) == &"shattered" and Vector2i(3, 1) not in b.panes, "on a pane with no one there: it breaks")
	v(1).refresh()
	v(1).weapon = load("res://Items/broadsword.tres")
	ok(&"slash" in Battle.hit_tags(v(1), strike) and b.attempt(v(1), strike, Vector2i(4, 1)) == &"miss" and Vector2i(4, 1) in b.panes, "a sword's slash doesn't")
	v(1).refresh()
	v(1).weapon = staff
	b.move(v(1), Vector2i(4, 2))
	ok(b.attempt(v(1), strike, Vector2i(4, 1)) == &"shattered", "a staff's blunt blow does")
	v(1).weapon = null


# Waterstrike's tag was `bludgeon`, which nothing read: it's a blunt blow like any other.
func test_waterstrike_shatters() -> void:
	lattice(0.5)
	stage(lancin, {v(1): Vector2i(3, 2)})
	var water: Skill = load("res://Skills/waterstrike.tres")
	v(1).learned.append(slot(water)); v(1).sync_bar()
	ok(&"blunt" in Battle.hit_tags(v(1), water) and &"bludgeon" not in water.tags, "a blunt blow")
	ok(b.attempt(v(1), water, Vector2i(3, 1)) == &"shattered" and Vector2i(3, 1) not in b.panes, "on a pane with no one there: it breaks")


func test_sap() -> void:
	lattice(0.0)
	stage(lancin, {v(1): Vector2i(5, 5), v(2): Vector2i(7, 6), v(3): Vector2i(7, 5)})
	var s := spawn(starman, starmen, Vector2i(6, 5))
	ok(s.powered() and &"dangerous" in s.tags and &"beast" in s.tags and s.tempered(&"vindictive") and "astral" in s.bio.grudges, "a Starman: Power, dangerous, astral, a beast; a standing grudge on astral foes (the Stellar Order's)")
	s.energy = s.max_energy
	v(1).energy = 1
	var hp := v(1).hp
	var e3 := v(3).energy
	b._sap(s)
	ok(v(1).energy == 0 and v(1).hp == hp - 1, "2 drained: its last Energy, then 1 HP")
	ok(v(3).energy == e3 - 2, "and from the other side's unit beside it")
	ok(v(2).energy == v(2).max_energy, "not diagonally: two Medium units")
	ok(b.charge[Vector2i(1, 1)] == 4, "it's full: what it drained fills the source (%d)" % b.charge[Vector2i(1, 1)])
	b.charge[Vector2i(1, 1)] = Battle.STAR_CAPACITY
	var e1 := v(3).energy
	b._sap(s)
	ok(v(3).energy == e1, "every source full: it saps no more")
	ok(is_equal_approx(b.sap_reach(s, v(2)), 1.0), "Medium on Medium: a tile side-on")


func test_hunts() -> void:
	stage(lancin, {v(1): Vector2i(6, 4)})
	var s := spawn(starman, starmen, Vector2i(5, 4))
	var p := spawn(load("res://Scenes/astral_princess.tscn"), stellar, Vector2i(5, 7))
	v(1).energy = 0
	p.energy = 0  # neither worth draining (Power Hungry): the grudges alone
	var reads := AI.reads_from({v(1): b.read(s, v(1)), p: b.read(s, p)})
	ok(AI._best_target(s, reads) == p, "Vindictive: the Princess (astral) first, though a villager is nearer")
	v(1).wrongs[starmen] = 3  # the villager has struck it thrice: it is otherwise aggressed
	ok(AI._best_target(s, reads) == v(1), "struck often enough, it turns on its attacker")
	v(1).wrongs.clear()


func test_revert_and_reform() -> void:
	lattice(1.0)
	stage(lancin, {v(1): Vector2i(7, 7)})
	var s := spawn(starman, starmen, Vector2i(3, 1))
	s.energy = 7
	var motes: Array[Unit] = []
	b.reverted.connect(func(_was: Unit, now: Unit): motes.append(now))
	s.hp = 0
	ok(motes.size() == 1 and b.unit_at(Vector2i(3, 1)) == motes[0], "a Starman falls back into a Starmote, where it fell")
	var sp := motes[0]
	ok(sp.starkind() == 3 and sp.max_hp == sp.max_energy and sp.energy == 7, "Starkind III: max HP its max Power (%d); the Power it had" % sp.max_hp)
	ok(sp.behaviour == &"recovering", "it recovers")
	b.move(sp, Vector2i(8, 8))
	var hp := sp.hp
	b._starkind(sp, true)
	ok(sp.hp == hp - ceili(0.4 * sp.max_hp), "off the lattice: 40% of its max HP a turn")
	sp.hp = sp.max_hp
	b.move(sp, Vector2i(3, 1))
	b._starkind(sp, true)
	ok(sp.hp == sp.max_hp and Battle.REFORMING not in sp.timed, "on it: no decay - and short of full Power, no stack")
	sp.energy = sp.max_energy
	var formed: Array[Unit] = []
	b.reformed.connect(func(_was: Unit, now: Unit): formed.append(now))
	b._starkind(sp, false)
	b._starkind(sp, true)
	ok(sp.timed[Battle.REFORMING].rank == 2, "full, on the lattice: a stack as its turn starts and one as it ends")
	sp.energy = 0
	b._starkind(sp, false)
	ok(sp.timed[Battle.REFORMING].rank == 1, "not full: it loses one")
	sp.energy = sp.max_energy
	b._starkind(sp, true)
	b._starkind(sp, false)
	ok(formed.size() == 1 and formed[0].name.begins_with("Starman") and b.unit_at(Vector2i(3, 1)) == formed[0], "stacks at its level (3): it reforms, a Starman again")


func test_recovering_ai() -> void:
	lattice(0.0)
	stage(starmen, {v(1): Vector2i(8, 8)})
	var sp := spawn(starmote, starmen, Vector2i(4, 4))
	sp.refresh()
	AI.act(b, sp)
	ok(b.on_lattice(sp.cell) or Command.tiles(sp.cell, Vector2i(4, 1)) < 3, "it heads for the lattice (%s)" % sp.cell)


func test_neutral() -> void:
	ok(starmen.neutral and not stellar.neutral, "Starmen are neutral")
	b.order.assign([lancin, starmen])
	ok(Array(b.fighting()) == [lancin], "only fighting sides count toward the end")
	b.order.assign([lancin, nemes])


# Flippant (AI._skirt()): unpunished, a Starman skirts off away from a foe rather than striking it; once it has lost
# Bio.FLIPPANT of its max HP this fight (Unit.harmed), it is aggressive and closes in.
func test_flippant() -> void:
	stage(starmen, {v(1): Vector2i(4, 4)})
	v(1).energy = 0  # nothing to drain (Power Hungry)
	var s := spawn(starman, starmen, Vector2i(7, 4))
	s.energy = 2  # a Hop's worth
	s.refresh()
	var hp := v(1).hp
	var was := Command.tiles(s.cell, v(1).cell)
	AI.act(b, s)
	ok(s.temper() == &"flippant" and v(1).hp == hp and Command.tiles(s.cell, v(1).cell) > was, "it skirts off, striking nothing (%s, %d tiles)" % [s.cell, Command.tiles(s.cell, v(1).cell)])
	s.damage(ceili(s.max_hp * Bio.FLIPPANT) - 1)
	ok(s.temper() == &"flippant", "a scratch doesn't punish it")
	s.damage(1)
	s.refresh()
	var far := Command.tiles(s.cell, v(1).cell)
	AI.act(b, s)
	ok(s.temper() == &"aggressive" and (Command.tiles(s.cell, v(1).cell) < far or v(1).hp < hp), "punished: it presses in")


# Power Hungry (AI._feed()): it steps beside whoever holds the most of its bar - a neutral as much as a foe - and drains it
# (Energy Transfer); one with less than AI.FEED of its bar is passed over.
func test_power_hungry() -> void:
	var others := Faction.new()
	others.neutral = true
	stage(starmen, {v(1): Vector2i(3, 2), v(2): Vector2i(3, 7)})
	v(1).energy = 1
	v(2).faction = others
	v(2).energy = v(2).max_energy
	var e2 := v(2).energy
	var s := spawn(starman, starmen, Vector2i(7, 5))
	s.energy = 10
	s.refresh()
	AI.act(b, s)
	ok(Command.tiles(s.cell, v(2).cell) <= 1 and v(2).energy < e2 and v(1).energy == 1, "beside the neutral with the full bar, draining it (%s, %d -> %d)" % [s.cell, e2, v(2).energy])
	v(2).faction = lancin
