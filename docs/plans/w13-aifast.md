# AI fast turns (w13-aifast, 2026-11-23)
Goal (the user: "raise the budget provided players dont actually spend time waiting for large factions"; 20/80 shortcuts OK; AI decisions may change):
follower fast path; overlap planning with animation; cheap far-from-foe routine if measured; measure player-perceived wait 15 / 30-unit side turns (M3 x4) before/after;
busy_fight digest pin -> outcome checks; raise budget only as far as measured.
Base = origin/main daf5c1d.

## Readings
- HUD `_act_alone`: `together` (default true) runs AI.act for EVERY unit in ONE frame (no await between units), then waits out walks. So a side's whole AI time is one frozen frame: the player-perceived wait. pace > 0 only when watched; tests use pace 0 (sync).
- Leaders: `Unit.follows` (Command.join: player's party; Battle 637). AI factions have none today; busy_fight has none.
- Skill to command: `Command.cha_of(l)` (cha mod + command_mod); at +0 or below "it can only be told to move".

## Calls
## Done
## Next
