class_name Terrain
extends Resource

# One per kind of ground, stored in the TileSet's "terrain" custom data. Tiles left blank count
# as plain ground: entering costs 1 unless a terrain says otherwise.
@export var name := ""
@export var enter := 1  # movement to step onto it
@export var exit := 0  # extra movement to step off it (sticky ground)
@export var tags: Array[StringName] = []  # beneficial / detrimental, rough, sticky, trap, water, wet...

@export_group("Concealment")  # traps: what it really is hides behind levels of concealment
@export var concealment := 0
@export var kind := &""  # concealment kind ("" plain sight, dark, light, sound)
@export var looks_like := &""  # what the unaware see it as (Grass)
@export var shape := ""  # the hint at concealment 2: "disturbed earth?"
@export var vibe := ""  # the hint at concealment 3: "a prickle of unease"

@export_group("Effects")
@export var effects: Array[Effect] = []  # on whoever stands here (Shrine: Heal, regen 0.1)
@export var afflicts: Array[Effect] = []  # put on whoever steps here, for `turns` of their turns
@export var at_end: Array[Effect] = []  # put on whoever ends its side's turn here, likewise (Magic Stew)
@export var turns := 0  # unless an effect sets its own; counted from the unit's next turn
@export var level := 1  # how strong what it does to whoever steps on it is (afflicts, its trap): a unit standing still at this Meander rank or above passes it by

@export_group("Trap")  # sprung when a unit steps on it
@export var dice := Vector2i.ZERO  # damage: the roll x `times`, + `bonus`
@export var times := 1
@export var bonus := 0
@export var bonus_stat := &""  # laid by a skill (Battle.lay()): `bonus` is the setter's mod in this (Snare: dexterity)
@export var damage_tags: Array[StringName] = []  # trap, pierce...
@export var blast := 0.0  # hits every unit within this radius, not just the one who stepped on it
@export var reveals := true  # sprung, it loses all its concealment (most traps)
@export var wounds: Array[Effect] = []  # put on whoever it hits, at its level (Snare: Bleeding)...
@export var wound_turns := 1  # ...for this many turns (laid by a skill: rank + the setter's mod in bonus_stat)


@export_group("Layer")  # laid over a tile's ground, in a stack (Battle.lay_layer(): leaves, glass, starpanes, startiles)
@export var passes := false  # whoever's on it deals with the layer beneath too (Leaves; an overlay starpane) - else only with it
@export var drag := 0.0  # movement it adds on top of what's beneath (Leaves: 0.1)
@export var obscures := false  # what's beneath can't be made out until a unit stands on it; stepping in blind, checks the ground beneath imposes are rolled at disadvantage (Leaves)
@export var cover := false  # advantage to concealment checks made on it (Leaves)
@export var brittle := false  # blunt damage - aimed at it, over an area, or at whoever's on it - breaks it (glass, starpanes, startiles)
@export var breaks_into: Terrain  # what's left when it breaks (a startile: a cracked startile); none - it's gone
@export var unstable := false  # ending a turn on it without resting, having moved more than its dex mod in tiles, a unit breaks it, and makes a dex check against dc or drops through (glass)
@export var dc := 12
@export var flammable := false  # fire on it burns it away and sets the tile alight (Leaves)
@export var windswept := false  # wind on it blows it away (Leaves)
@export var source := false  # a star power source on the lattice (a startile: Battle.starpower)
@export var pane := false  # a starpane: links the lattice side-on (Battle.panes)
@export_file("*.tres") var repairs_into := ""  # mends into this near a power source, a turn a tile of distance (a cracked startile: a startile; Battle._repair_tiles()) - a path: the two refer to each other


func is_trap() -> bool:
	return dice != Vector2i.ZERO


# +1 explicitly beneficial, -1 explicitly detrimental (by tag). Most ground is neutral, even with
# minor effects either way (bramble's sticky exit, a conveyor's push). Tie-breaks between equally
# near tiles use it, and it's what tiers of perception reveal as good or bad ground.
func worth() -> int:
	return int(&"beneficial" in tags) - int(&"detrimental" in tags)
