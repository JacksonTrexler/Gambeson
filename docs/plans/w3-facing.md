# Facing, forced moves, shove and cc (branch w3-facing, 2026-11-18)

The user (answers-2026-11-18b, items 1 and 7): "intentional unit actions only: pushes / warps etc don't count"; "`shove` should only apply to skills that apply the force to a unit itself. fear would technically be the unit itself deciding to act a certain way: it *would* face the direction it is moving, and it should probably spend movement AP accordingly. tag it `cc` if needed for utility purposes though, any skill or effect that infers penalties on a unit's ability to act needs to be tagged as such."

## Readings
- ?188 (w2-facing call 3) turned a unit along any `Battle.displace()`. Revert: push, pull, send (teleport) and every other move by another's force leave facing alone. Interject's stand-in (call 4) already doesn't turn; `move()`/`place()`/`drag()`/Switcheroo never did.
- Fear is the unit moving itself. Entrance (Sing's draw, the `entrance` effect) is the same shape (it walks to its source), so it is treated alike.
- `cc` is the user's own tag (no ??). `Effect.tags` filters what a stat counts on (a tagged status with `cc` there would stop counting), so a status bears `cc` in a new field, not there.

## Calls
1. **Self-driven moves** are named by tag: `Battle.SELF_DRIVEN = [fear, entrance]`. `displace()` with such a tag turns the unit along the move, and charges the tiles (the ground's real step cost, `stride()`) to movement and move AP (`Unit.walked(.., compelled)`). Not a new flag: the tag on the move decides, so a later effect that carries the tag joins.
2. **Compelled pays what it has and goes anyway**: fear applied on a foe's turn, or with less AP than the walk costs, still flees; it pays `min(cost, AP left)` and `moved` goes up by the full cost. At its own turn start (`_frighten()`, after `refresh()`) that comes off the fresh pool. The alternative (a unit out of AP ignores fear) made fear useless against units that already spent their turn.
3. **Entrance counts as self-driven**, including Sing's `Displace(toward)`: the enraptured walks to the singer, faces it, and pays move AP. Only fear was named; entrance was the sibling.
4. **Slam unchanged**: a flee or draw stopped short still slams (code did already, `Effect.describe` said only shove hurts). Left for the user; not touched.
5. **`shove` on skills**: Kick (push) and Send Off (teleport away). Kick's pushes now carry the `shove` move tag and credit the kicker (`by`), so a slam rides the tag like Displace's. Not tagged: Sing (a draw: entrance, cc), Switcheroo (a trade of places, no force of its own on the pair: stayed untagged, caster moves itself), Drown/Hitch/Coalescing (grapples: held, not driven; Hitch's tow is the holder's own move).
6. **`cc`** is declared by `mechanic.py tag cc --human` (term "CC", kind condition, colour `#a5a1c9`), kind `condition` so an emblem of it fits skills that put effects on a target. New `mechanic.py carry <tag> --skills --effects --inline skill:stat` tags what exists (the tool reuses `tres.py`; `bears` joined `NAME_LISTS`). New `Effect.bears` and `Unit.afflicted(tag)` (statuses on it bearing a tag): no rule reads cc yet.

## The cc audit (255 skills, 15 reusable statuses, inline statuses)
Tagged `cc`: skills Stun (helpless), Jam, Slam Jam (jammed: no reactions), Hitch (a grip), Drown, Coalescing (grappled), Brainfog (disables skills), Interdict (AP off), Bludgeon (Winded: AP lost), Sing (entrance), Mindless Fury (the user is helpless: a self-inflicted cost, tagged all the same; say if not). Statuses in `Effects/`: Stunned, Jammed, Winded, Traits Suppressed, Hitched. Inline: Grappled (Drown, Coalescing), Interdicted's base AP, Mindless.
Considered, not tagged: Level Down (stat loss, though it seals slots), Haluca (scrambled reading), Humble (max HP cap), Hex, Showstopper, Phantasm, Breathtaking (HP/luck/recon), Soaked and Blinded (a movement or check penalty, not a stop), Judgement and its Shackles (the item does nothing but replace a trinket), the Stew tile's sleep (a tile, not a skill or status), and the fear, shove and entrance effect stats (no skill or reusable status carries them yet; one that does should bear `cc` for fear and entrance).

## As built
`Battle.displace()` (`SELF_DRIVEN`, `own`), `Unit.walked(.., compelled)`, `Unit.afflicted()`, `Effect.bears`, Glossary text for shove, fear and entrance, `Behaviours/kick.gd` (tags and `by`), Skills (20 `cc`, 2 `shove` files) and Effects, `Util/mechanic.py carry`, `Util/tres.py`.

## Tests
Changed to the new rule: `facing_test.test_latest_wins` (a push, pull and send turn nobody; fear turns), `displace_test.test_any_skill_knocks_back` (the foe keeps its facing), `displace_test.test_draw_in` (the drawn walks: faces and pays move AP), `forced_test.test_the_three_effects` (fear faces and pays 2 tiles of AP; the repeat at turn start). New: `forced_test.test_cc_and_shove_are_tagged`, one table check over every skill and status (any that stuns, sleeps, grapples, jams, disables, draws or forces joins by what it does) plus `Unit.afflicted()`. Mutations: turning on every displace fails the facing and displace tests; stripping cc from Stun fails the table; both reverted.
