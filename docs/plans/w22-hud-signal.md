# w22-hud-signal: signal readout, Stardust arc, locked marker
## Calls
1. Tile pane line "Signal: N" (HUD._tile_effects) when signal_at > 0, or >= 0 on a star-tagged layer (not just startile: tag-based). Not shown at -1.
2. Stardust arc: Overlay._stack, t.regrows and repair_goal > 0, same arc as cracked startile's (_glass).
3. Locked marker lives in Unit._lock_mark (the map bars are Unit.gd's, no Overlay bars): bar meta `lock` = locked/raw_max, drawn dim + hatched at the bar's right end via bar.draw (bound callable, dup-safe). Bar max stays raw (negative call).
4. Info row (leader card only): "LK  locked N" red, one per sealed pool (energy + held reserves). Not on others' cards (their seals unread).
## Tests
hud_test.test_signal_and_lock (5 checks). Mutations (drop star-tile gate, drop LK row) fail it. Suite 11635+ -> 11821 checks, 0 failed (1099 tests).
## Visual
S/shot_w22-hud-signal/m00000119.png: Signal line, Repairing 3/5, LK row, arcs on Stardust. Bar hatch unseen (map bars off-screen); meta tested.
