# w24-fog
Card: "give the fog ranks. fog divides sight range for units inside by 1 + rank."
Calls:
- Battle.fog_rank (@export int 0..5, 0 none); &"fog" in conditions kept = rank 1 (no scene migrated; none used it).
- Fog zones (Undine's Waltz of Vapors, kind &"fog", levels by cell) already exist: their level is the rank, so a unit standing in one has sight / (1 + level). Undine fog (level 1) now also halves sight inside. Strongest of area/zone at observer's cell.
- Observer's own tile only (not target's). All callers already use perception_range; Battle.fog_at(c) is the one lookup.
- Test: meadows_test fog case extended (rank 2, zone rank 3). No new files.
