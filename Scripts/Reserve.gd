class_name Reserve
extends Resource

# An energy type beyond the default Energy (mana, stamina, sweet nothings...).
@export var name := ""
@export var color := Color.WHITE
@export var only: Array[StringName] = []  # skill tags it can pay for (mana: magical); empty: any
@export var whole := 0  # pays a skill's whole cost, whatever it is, with this many points (Sweet Nothings: 1); 0: point for point
@export var on_kill := 0  # points back each time its holder slays a foe (Sweet Nothings: 1)
@export var patron := false  # comes back as its holder satisfies its patron (Analysis Dialysis; Unit.gain())
