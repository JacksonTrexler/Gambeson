# w7-art: utumno placeholder art

Source: `/Users/jtrex/assets/utumno` (never modified). The user (2026-11-20): "use assets in /Users/jtrex/assets/utumno for placeholder icons where possible, there's one for siren as well".

## Calls
1. All 268 skill icons are 32x32 and so are the 32x32 utumno icons: copied as is, no resize. `icon.py check` verifies items only, so nothing in it constrains skill or unit art size ("any size").
2. Skill icons are meant to be white on clear (tinted by state). The utumno ones are coloured; the user asked for them, so they are copied unchanged and the skills screen's tint will multiply over the colour. Revisit if it reads badly.
3. Overwrote only drawn placeholders under `Icons/Skills/` (every one was written by `icon.py skill`). Skipped `Shade.png` and `Elmit.png` (older, odd sizes, not icon.py's 20x25: possibly real art) for the silhouette and the siren.
4. Siren: the Siren unit shared `Units/Elmit.png` with Undine, so `Units/Siren.png` is a new file and `Scenes/siren.tscn` now points at it (the one scene edit). Undine keeps Elmit.
5. Statuses: only Suspicion has an effect icon (`Icons/Effects/`, a 13x9 shape drawn in code, not a placeholder file to replace); nothing mapped. Skipped Sibling-owned ids (surveyor, evaluator, inquisitor).
6. One source per target, each source used once.

## Mapping (source in utumno/ to target, reason)
- utumno-music-note.png -> Icons/Skills/sing.png (a note for the singing skill)
- utumno-heal.png -> Icons/Skills/heal.png (the heal glyph)
- utumno-regen.png -> Icons/Skills/regeneration_pulse.png (regen cross)
- utumno-anti-bleed.png -> Icons/Skills/first_aid.png (stops bleeding)
- utumno-inspect.png -> Icons/Skills/observe.png (magnifier)
- utumno-magic-eye.png -> Icons/Skills/clairvoyance.png (eye)
- utumno-pentagram.png -> Icons/Skills/hex.png (curse sigil)
- utumno-skull.png -> Icons/Skills/death.png (skull)
- utumno-purple-skull.png -> Icons/Skills/deathlust.png (skull, purple for the lust)
- utumno-broken-skill-command.png -> Icons/Skills/rally.png (command banner)
- utumno-broken-skill-animal.png -> Icons/Skills/beastshape.png (animal head)
- utumno-broken-skil-enchant-armor.png -> Icons/Skills/mage_armor.png (enchanted armour figure)
- utumno-energy-bolt.png -> Icons/Skills/energy_missile.png (bolt)
- utumno-omnishield.png -> Icons/Skills/shields_up.png (shield)
- utumno-magic-shield.png -> Icons/Skills/ward.png (magic shield)
- utumno-bronze-shield-up.png -> Icons/Skills/bulwark.png (raised shield)
- utumno-frost.png -> Icons/Skills/hoarfrost.png (snowflake)
- utumno-potion.png -> Icons/Skills/mana.png (potion)
- utumno-tree.png -> Icons/Skills/barkskin.png (tree)
- utumno-shovel.png -> Icons/Skills/forage.png (digging for forage)
- utumno-ankh-undead.png -> Icons/Skills/resuscitate.png (ankh: revival)
- utumno-smoke.png -> Icons/Skills/vaporize.png (smoke)
- utumno-silhouette.png -> Icons/Skills/invisibility.png (silhouette)
- utumno-reflection.png -> Icons/Skills/mirror_image.png (reflection)
- utumno-uturn-arrow.png -> Icons/Skills/switcheroo.png (u-turn swap)
- utumno-confuse.png -> Icons/Skills/brainfog.png (confusion spiral)
- utumno-blood-droplet.png -> Icons/Skills/blood_magic.png (blood drop)
- utumno-bleeding-blade.png -> Icons/Skills/jugular.png (bleeding wound)
- utumno-penetration.png -> Icons/Skills/piercing_focus.png (piercing)
- utumno-blade.png -> Icons/Skills/strike.png (a blade)
- utumno-crossed-swords.png -> Icons/Skills/martialist.png (crossed swords)
- utumno-bless.png -> Icons/Skills/divinity.png (blessing cross)
- utumno-holy-buff.png -> Icons/Skills/pray.png (holy boost)
- utumno-empower-hourglass.png -> Icons/Skills/borrowed_time.png (hourglass)
- utumno-purple-cancel.png -> Icons/Skills/dispel.png (cancel)
- utumno-blocked.png -> Icons/Skills/obstruct.png (blocked X)
- utumno-chained-heart.png -> Icons/Skills/alluring.png (chained heart (love))
- utumno-compass.png -> Icons/Skills/meander.png (compass)
- utumno-siren.png -> Units/Siren.png (a mermaid for the Siren unit; scene re-pointed)

Counts: 38 skills, 1 unit, 0 statuses = 39.

## Unused sources
?-shield, ankh, antidragon, beastshield, body-plus, broken-astral-robes, broken-blue-robes, broken-doom-plate, broken-shield-magic, broken-skil-enchant-armor, broken-skill-magic-icebolt, bronze-lil-heart, brown-bolt, cursed-accessory, cursed-blade, cursed-helm, death-shield, dex, electric-shield, empower-physical, empower-protective-enhanced-gray-X, empower-protective-enhanced-inspect, empower-protective-shield, enchanted-helm, fear, fireshield, frost-shield, grave, increased-strength, int, lil-speed, ombnibuff, poison, poison-shield, purple-spiral, rare-blade, repeat, shadow-flame-spiral, shadowflame-sword, shield-poly, snake-debuff, tileset, tileset-doors, tileset-objects, tileset-sandtile, tileset-statues, uturn-omni-shield, uturn-rare-helm, water-shield

(the tileset sheets and the other shields/armour/items had no clearly matching skill; the three .aseprite files are skipped.)

## As built
Imported, icon.py check and skill.py check pass; suite result in the report.
