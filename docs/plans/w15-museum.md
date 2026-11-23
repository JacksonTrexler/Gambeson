# w15-museum: rest of museum cost (card 2, conditional)
Result: not worth it, no code change.
- Existing safe cache = the read stretch (begin_read/_epoch; lends/_fx memo). Tried wrapping _fill_bar in begin_read/end_read: suite fails (command_test.test_default_bar, test_bar_place, hud_markers/hud_test toggles). In a stretch stat() skips the _touch_bar fast path and gathers effects, so the bar auto-equip order (the w14 quirk: _sync_new from inside stat) changes.
- Any other memo (lv/stat(level)/lends outside a stretch) needs invalidation on slots/timed/items/footing/hp/ground plus the _sync_new side effect; not simple. Max gain ~10 ms x 1033 tests ~ <=10 s, uncertain.
- Battle._enter 7.5 ms is gameplay (opening looks); left.
- Lead: fix the bar-order quirk (make auto-equip explicit, not a stat() side effect) first; then a stretch around _fill_bar becomes safe.
