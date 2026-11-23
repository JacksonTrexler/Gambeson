---
name: sprites
description: Cut a sprite sheet into one PNG per sprite, named by average colour (hex plus colour word) so a folder sorts by hue - Util/sprites.py, output in Assets/sorted/<sheet>/. Use when art arrives as a sheet (sortme/sheet-*.png) and must be split into individual sprites.
---

# Cutting sprite sheets

```
python3 Util/sprites.py cut sortme/sheet-*.png [--min-size 4] [--dry-run] [--out Assets/sorted]
python3 Util/sprites.py check
```
- A sprite is an 8-connected island (diagonals attach) of alpha > 0 pixels, clipped to its bounding box.
- File: `<hex>-<colour>.png` in `Assets/sorted/<sheet-stem>/`; hex is the alpha-weighted average RGB, colour the nearest of
  red orange yellow green cyan blue purple pink brown gray black white. A clash adds `-2`, `-3` (reading order).
- The sheet is read only (decoded to RGBA in memory). Pillow decodes if present; else 8-bit PNGs only.
- `--min-size N` skips islands under N pixels (default keeps all, 1-pixel sparkles included). Re-runs overwrite by name; stale files stay.
- Then `godot --headless --path . --import` and commit the PNGs with their `.png.import`. `check` (run by `Tests/tooling_test.gd`) cuts a
  synthetic sheet through both decoders and fails a name in Assets/sorted that is not `<hex>-<colour>.png` or lacks its import.
