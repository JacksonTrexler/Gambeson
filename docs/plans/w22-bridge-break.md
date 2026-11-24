# w22-bridge-break: a unit on a bridge tile that breaks over void falls
Goal: a unit on a star tile that breaks/lapses with void beneath must not stay standing on void.

## Readings
- No unit-falls-into-pit rule existed (w16-nexus: "no fall damage" for void; w22-astral1: "units on a broken bridge stay on void (no fall rule)"). Only seams: `footing(u, c)` (void needs floating/flight), `_drop` (glass: land on what's beneath, ground effects), `slay()` (falls as at 0 HP: Downed/death/Final Act reactions).
- Also, the void never showed: a startile laid over void is `Layer.passes = false` (a floor on its own) and kept that through cracked startile -> Stardust, so a broken bridge was still solid dust. Nothing to fall onto.

## Calls
1. Fall = `u.slay()` (as at 0 HP; goes through `falling`, reactions, Downed/death). Reading of "falls (damage/removal as existing pits do)": no existing pit rule, so the strongest existing seam; flyers/floaters (footing()) stay up. ?? open: fall damage instead of a kill.
2. One generic hook in `Battle._restack(c)` (every layer lay/break/lift/mend ends there): the unit on c with no `footing()` falls. Not star-specific.
3. Void shows when a bridge goes to Stardust: `break_layer` sets `l.passes = true` for a `regrows` result (dust bears nothing). Cracked startile (glass) still bears (it teeters). `_repaired` re-bridges: `l.passes = _overlays(c, into)` (new helper, also used by `lay_star`: overlay unless void beneath).
4. Not touched: `_teeter` rolls its dex check after break_layer, so a cracked bridge over void kills before "catches itself" is read (the dead unit may log "catches itself"). Open.

## As built
- Battle.gd: `_restack` fall, `_overlays`, `break_layer` dust passes, `_repaired` re-bridge.
- Tests/starbuilding_test.gd `test_bridge_breaks` (+5 checks): lapse -> cracked bears; blow -> dust over void: walker falls; floater stays; ground beneath stays; mended re-bridges.
- Mutations (each fails it): fall hook off (1), hook falls all but floaters (9 incl. others), dust keeps bridging (1).
- Suite: start 11805 checks (1097 tests) -> 11810, 0 failed (1098 tests).
