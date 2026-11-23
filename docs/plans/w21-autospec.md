# w21-autospec: units spend skill points by their bio
Goal (user): AI picks skills by bio (tags/types; exploratory / training / remedial), else class tree. Player units never
auto-spec except a long-press "Spec Automatically" on the skill screen; under enforced auto (Disturbed) points are spent,
refunded as control returns ("level down"). "Hard" settings toggle: units spec automatically.

## Reading
- Spend code before: Unit.take_path() (w18-monster-ai: Monster traits, cheapest raise first); take_flex() (w18-flex-ai)
  only picks trees, spends nothing. No w19-monster-ai / w19-flex-ai plans exist. Non-Monster NPCs never spent points.
- NPC = bio or path_auto (w18). Player units have no bio (bio isn't saved); none marked as the player's.
- "Level down": Unit.unranked() undoes `purchases` newest first while a level curse lasts. No refund of points exists.
- Enforced auto: Unit.disturbed() (HUD.autopilot() reads it for the starter), Unit.uncontrolled.
- No scene sets skill_points: NPC spending only shows at level_up (and Monsters' owed points at ready).

## Calls
(see "as built")
