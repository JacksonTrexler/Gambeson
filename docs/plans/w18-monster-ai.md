# w18-monster-ai: NPC / summoned Monsters pick a path and spend points
Calls:
1. Home = Unit.take_path() (beside take_flex), on _ready and level_up. No AI.gd change.
2. Who: NPC (bio) or summoned (`path_auto`, set by Unit.monster()). A player's Monster (no bio) picks/spends itself.
3. Pick: `Unit.fewest_path(side, rng)` lifted from Theseus.path (which now calls it); at ready the side = same-faction siblings in the parent (no Battle ref), ties first.
4. Spend: owed = max(skill_points, level-1-purchases); raise the path's traits (openers), cheapest raise_cost first (ties tree order) until none affordable/capped. Leftover stays.
5. Theseus Monsters now spend their points (was left unspent, ?303).
Changed test: monster_test.test_paths sets path_auto=false (it checks the unspent helper output).
Tests: monster_test.test_ai (table: pre-picked Starmen/Sirens/Skeletons, unpicked L1 and L5; fewest; player's left alone; summoned L5).
