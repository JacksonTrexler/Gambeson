# w9-party
Goal: Party button on a solo roster; static Battle.from_role shared with PartyPanel.outfit(); a defeated unit's pack as loot.
Files: Scripts/Entry.gd, PartyPanel.gd, Battle.gd, Tests/save_test.gd, plating_test.gd.

## Calls
- Pack loot shape (proposed, built): Battle._drops(u) = one roll of u.loot + every item in u.pack, each its own spoil + `dropped` emit; pack cleared (spills whole, never twice). Reuses the loot path (spoils/winnings/HUD "drops" log); no new field, flag or tag - the pack is already data on the unit, any unit with one (scene or later skill) joins. Alternative not taken: roll the pack through a Loot table (one item, chance) - rejected: a unit's whole kit lying where it fell is the point of carrying it.
- Party button: visible whenever the roster is non-empty (was > 1); solo text stays "Party: solo".
- from_role static; PartyPanel.outfit() calls Battle.from_role(faction or null, role, name) - same stats/reserves path, so no drift. Tests call Battle.from_role.

## Done
All three; tests: plating_test.test_packs (+ drop), save_test.test_party_size (+ solo button). Not mutation-checked beyond the obvious (button condition, pack spill are one-liners).
