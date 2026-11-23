# w21-sprites: Util/sprites.py

Goal (user): .py to cut sprites from sheets (diagonals attached, by opacity), PNG per sprite into Assets/sorted, named by average colour hex + `-<colour>`; test on sortme sheets.

## Calls
1. Output folder per sheet: `Assets/sorted/<sheet-stem>/` (spec). Not flat, so sheets stay traceable.
2. "Copy sheet": decoded to RGBA in memory; no copy on disk. sortme untouched.
3. Alpha > 0 = in a sprite (spec); stray alpha-7..11 specks therefore become sprites. Default `--min-size 1` keeps all (non-lossy; 1-px sparkles may be real effects). Committed output uses the default: 718 files (275 / 147 / 296), 48 of them 1-px.
4. Average = alpha-weighted over alpha>0 pixels, rounded; lowercase hex.
5. Colour word: nearest of 12 typical RGBs by redmean distance. Light grays (~190) read as pink/white; palette is small by spec.
6. Clash: `-2`, `-3` in reading order of each sprite's first pixel (top to bottom, left to right) -> deterministic. Re-run overwrites by name, never deletes stale files.
7. Pillow if importable (any mode), else plain zlib decoder (8-bit non-interlaced only; says "needs Pillow" otherwise). Output always zlib-encoded (no Pillow needed).
8. `check` = synthetic 12x6 sheet through both decoders (diagonal pair, unequal-alpha average, clash -2, speck cut) + every Assets/sorted PNG named `<hex>-<colour>[-n].png` and imported. Wired by adding "sprites" to `Tests/tooling_test.gd` test_checks (no new test file).
9. `.godot` import files: committed `.png.import` beside each PNG (718).

## Tests
Mutation: dropped the diagonal neighbours in `find` -> `check` fails (synthetic cut wrong); reverted.
Starting suite: 11461 checks, 0 failed (1071 tests).
