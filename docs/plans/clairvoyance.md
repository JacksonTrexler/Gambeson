# Clairvoyance

An arcane and Cleric spell: the caster senses where unseen foes are, and nothing more. Starts once
Silhouettes and glow is merged, since it shows its findings as silhouettes.

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
