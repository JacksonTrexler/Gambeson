# Clairvoyance

An arcane and Cleric spell: the caster senses where unseen foes are, and nothing more. Built on branch
`r-clair` (see "As built" at the end); tests in `Tests/clairvoyance_test.gd`.

## The rules to build

- Channeled, cast on the caster. Range: the caster's wisdom score + rank, in tiles.
- On cast, every foe in range the caster's side can't currently see is pinged: its tile is marked and
  the unit shows there as a black silhouette. A ping gives location only: no name, side, HP or traits.
- Each ping adds a stack of suspicion of that tile for the caster (`Battle.suspect()`), so the usual
  rules for inspecting and striking at suspected tiles apply. It never tells more than a located,
  unidentified read would.
- At each of the caster's turn ends while the channel holds: pings move to where the foes are now,
  foes that came into range are added, those that left are dropped, and the spell's rank for this
  channel rises by 1 (so the range grows a tile a turn).
- Ending the channel (moving on, being interrupted, `Battle.end_channel()`) drops the silhouettes; the
  suspicion stays and fades as suspicion does.
- Exhaustion: one use for the whole channel.

## Where it goes

- `Skills/clairvoyance.tres`, on the Wizard's and Mage's arcane tree and a Cleric tab (which god's is
  a call to make: Luun, as the god of the hidden, is the first guess).
- A behaviour script if the skill tooling's seam is in by then; otherwise one flag (`pings`) beside
  `observes`, to be lifted later.
- Silhouettes come from the look built in `docs/plans/silhouettes-glow.md`; the HUD draws a pinged
  unit at its pinged tile even though the side can't see it.
- Tests: `Tests/clairvoyance_test.gd`: range by wisdom and rank, location only, the update and the rank
  gained each turn, the channel ending, a foe already in sight not pinged.

## Open (?89)

- Does a ping see through walls? (Assumed yes: it is not sight.)
- Does the rank gained each turn have a cap? (Assumed: none while the channel is paid for.)
- AP and cost per turn held. (Assumed: the cast's cost once, like Metea's channel.)
- Do allies share the pings? (Assumed yes, as sight is shared across a side.)

## As built

- `Skills/clairvoyance.tres`: magical, wis; 3 AP, 3 cost; self only, no roll; one flag, `pings`, beside
  `observes` (no behaviour-script seam yet). Open on the Wizard's Arcane root, the Mage's Refinement
  root (the Mage has no Arcane tree; Refinement is its general one), and Luun's tree after Pray.
- `Battle.cast()`: cast, it ends any other channel, starts a `Unit.Channel` (at the caster's tile)
  with `rank` = its rank, and runs `Battle.clairvoy()`. Cast again while channeling: the channel stops,
  free. One payment for the whole channel (Exhaustion counts the one use).
- `clairvoy()`: drops the old pings, then pings every living foe within `clairvoyance_reach()` (wisdom
  score + the channel's rank, `Command.tiles` from where the caster stands, walls ignored) that no unit
  of its side has located, pings set aside; each ping is `Channel.pings[foe] = tile` and one
  `suspect(caster, tile)`. In `end_turn()`, each of the side's channelers re-pings, then `rank += 1`
  (before the turn-end look, so it can inspect the suspected tiles).
- `Battle.pinged(faction)`: the side's pings, merged (shared across the side). `Perception.unit()`
  locates a pinged foe still on its pinged tile and nothing more (cell + concealed: a black shape).
  `HUD.view()` also places one that has moved off at the pinged tile; `_show_units` draws it there
  and marks the tile ("Something may be here: sensed"); `unit_seen()` now needs the view's cell to match.
- Glossary term "Pinged"; `Skill.markup()` line.

Calls made: moving doesn't end it (as with Metea; only `end_channel()` paths: recast, downed, dead,
another channel); suspicion stacks are added at the cast and at every update, so they build each turn;
range is measured from the caster's current tile; no cap on the rank gained.
