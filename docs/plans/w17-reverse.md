# w17-reverse: `reverse` run crashed meadows_test.test_camera / test_tower_difficulty

## Cause
`Test.hud()` (Tests/test.gd) added the HUD to `tree.root`, not the test's scene, so run.gd's `scene.free()` left it alive.
Two tests leaked one: `ai_tactics_test.test_kick_in_the_forecast`, `prep_test.test_hud_uses`. A leaked HUD stays in group `hud`
with `selected` pointing at a freed Unit. In `reverse` those run before meadows_test; BattleCamera._process / home() take the
(last) group member, so `hud.selected` assigned a freed instance. Forward order ran them after, so it never showed. Game code is fine
(a HUD outliving its battle only exists in tests).

## Fix
1. Tests/test.gd `hud()`: parent = `b.get_parent()` (the museum scene; root if none), so the run frees it with the scene.
2. Tests/run.gd: guard: snapshot root's children before each test, free any new ones after `scene.free()`; prints "freed N nodes tests left on the root" if any (silent when 0). Catches the same leak from any other helper/test.

## Calls
- ?278 Fixed at the helper (root cause) AND a runner sweep (net): the helper fix alone cures it; the sweep makes any future root-leaking test harmless rather than order-dependent. Sweep frees silently-ish (a count line) rather than failing: a leak is not a rule failure, its cross-test effect is what hurt. Alternative: fail on a leak; refused (would break single-word runs of tests that free late).
- ?279 Game code (BattleCamera picking `hud` from the group's last member, no is_instance_valid on hud.selected) left alone: only reachable via leaked HUDs.

## Checks
- reverse: 11088 checks, 0 failed (1047 tests, reverse). full: 11088 checks, 0 failed (1047 tests). (start count equal; no tests added.)
- Mutation: helper reverted, sweep kept -> 0 failed, "freed 2 nodes"; both reverted -> 5 FAIL lines (the 2 meadows tests); both in -> 0 failed.
