# w24-group: group AI (card 6a)

Goal: like units of a side share one target a side turn and act back to back; a seam for the Assault skill (6b).

## Readings
- Herds (AI._kind(): faction, role, race; _herd_plan(), HERD 3) already share a goal, but only far from foes (_herded()); in a fight each member took a full turn and its own target.
- _hunted() is the one want-bonus both _strike() (blow choice) and _targeting() (walk choice) add: hunts, grudge, hunger, orders. The group's pull joins it there.
- HUD._act_alone: units act in list order; `together` (default) = a frame per unit; not together = `pace` wait between units.

## Calls
- Group = _kind() (the herd's notion, cheapest), GROUP = 2 alive "in step" members. In step: no behaviour (Siren, skittish...), not Restless, Downed or posing, temper not timid / flippant (those act alone). A brave/aggressive/compliant/etc member stays in the group (it still weighs its own temper on top).
- Target decided once per group per side turn by its first member to take a full turn: _targeting() (existing scoring) from that member's reads, with distance the mean over the members' cells (the group's want, not one unit's). Re-decided once if it falls. Not the herd plan's pick (lowest Defense near the centre): tried, dropped - for 3+ it would always win and the walk-scoring path would only serve pairs; one notion.
- Pull, not force: GROUPED 4.0 (as ORDERED) added in _hunted() to the group target, so a likely kill (KILL 5) or a foe only in reach still wins: "when possible".
- Only self-directed full turns (_full(), posture ""): drill, herd, prowl, ordered postures unchanged; the meta is cleared at each act() so it never lingers.
- Quick sequence: HUD orders a side's units so kin act back to back (AI.in_groups(), stable, before cognizant_first) and skips the `pace` wait between kin (not-together mode); sign holds kept (they show something).
- Seam for Assault: AI.assault(b, units, targets, per := 1).
