class_name Reserve
extends Resource

# An energy type beyond the default Energy (mana, stamina, sweet nothings...). One dedicated to tags
# (only) is spent before Energy on the skills it can pay for (Unit.funding()).
@export var name := ""
@export var color := Color.WHITE
@export var only: Array[StringName] = []  # skill tags and kinds it can pay for (Skill.tagged(): mana magical; stamina martial, specialist, general, physical); empty: any
@export var whole := 0  # pays a skill's whole cost, whatever it is, with this many points (Sweet Nothings: 1); 0: point for point
@export var on_kill := 0  # points back each time its holder slays a foe (Sweet Nothings: 1)
@export var patron := false  # comes back as its holder satisfies its patron (Analysis Dialysis; Unit.gain())
@export var base := 0  # given by a passive: points a rank beyond the holder's mod in its reserve_mod (Stamina: con mod + 2 a rank; Unit.pools())
@export var with_energy := false  # comes back as Energy does (Unit.recover(): its rate by activity), plus the rank of the passive giving it on a resting turn (Stamina)
@export var empty := false  # starts each battle empty rather than full (Focus)
@export var builds := 0.0  # share of its max back (rounded up) on each turn its holder rests - only resting, so not holding a channel (Focus: 0.5)
@export var aims := false  # pays first for a ranged attack (Unit.ranged()), and for anything else only once Energy can't (Unit.funding()); spending the last of it on one adds the holder's focus stat to the roll (Focus)
