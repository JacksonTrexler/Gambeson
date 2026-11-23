# w14-museum: a cheaper fresh museum (pure perf)

Goal: cut the per-test museum add_child (~43 ms: Battle/Unit _ready) without changing behaviour.
Tool: `Tests/museum_prof.gd` (not a test: `godot --headless --path . -s Tests/museum_prof.gd`) times instantiate / add_child / frame / free over 60 museums. Deeper: wrap every Unit func with #PERF timers (scratch instr.py), run, restore.

## Readings
- add_child 43 ms of 43.7 (instantiate 0.4, free 0.2). Inside: Unit._ready x7 ~34 ms (_fill_bar 18, _show_bars 9.5, refit 5, hp 3.6), Battle._enter 9.
- Root cost: stat() outside a read stretch gathers every effect (_on_passives: equipped/lapsed/unranked per slot) for each call; lv()/slot_count()/_slot_keys() ask stat(level) and _grants() asks on_passives, hundreds of times while a bar fills.

## Calls
- stat() and _grants() outside a stretch: if lends(s) is false (nothing carried has an effect on s; a superset check) return the base at once.
- Quirk kept: gathering effects ran equipped(), whose _sync_new() auto-equips; a unit setting up gets its bar order from that (Icor: strike, hex, mana, arcanist). The fast path calls _touch_bar() to set it off exactly when the old path would (a passive on with slot cost, sig changed). Without it Icor's bar comes out strike, mana, hex (command_test.test_default_bar fails).
- Unit._ready: _show_bars connected after HP/Energy/reserves are filled, drawn once (was ~4 times a unit); pools() once.

## Done
1. stat/_grants fast path + _touch_bar, _show_bars once: museum add 43 -> 28.7 ms; suite 109 -> 84 s, 11012 checks, 0 failed.

## Next
- Battle._enter (9 ms), pools()/picks() in _show_bars, refit.
