# w18-fog-frozen
Goal: explored out-of-sight tiles keep the look last seen.
Calls: Overlay.memory = TileMapLayer (same tile_set) between Map and Overlay; fog_of_war copies the map cell onto it when a tile leaves sight (`_freeze`), erases it on re-entry; rebuild on rect change. Cost: only transition cells (~tens of set_cell per move), no per-refresh loop; fog key skip unchanged (fog redraw base 0.88 ms Meadows; added work is the same cell set, est <0.1 ms, not separately profiled).
Limit: terrain only; Overlay-drawn ground effects (layers, marks) stay live (memory sits under Overlay). Unseen tiles stay live.
Test: sight_test.test_fog (+2 checks: changed out of sight keeps old look; seen again drops it). Visual shot not taken.
