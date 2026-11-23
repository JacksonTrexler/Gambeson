# w20-hud-foe-also (?313)
Calls: Read.also (Array[StringName]) set in Perception beside Read.temper (same gate: insightful observer, net>=2); no new reveal. HUD foe branch adds MUTED chip per also != r.temper (lead stays in "Seems X" note). Deceived reads unchanged (existing temper gate has no deceive check).
Test: hud_test.test_foe_tempers (wis 8: none; wis 18 + recon 2: Vindictive, Power Hungry, no Flippant chip). Mutation: ungated also -> unreading check fails; reverted.
Visual: skipped.
