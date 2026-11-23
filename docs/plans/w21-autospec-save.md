# w21-autospec-save: mid-fight save keeps Disturbed auto-spent skills (todo 356)
Call: Unit.to_dict() writes the unit as refund_auto() would leave it (last auto_spent purchases dropped from purchases,
raises lowered, unlocks removed from learned and bar) on plain data; live unit untouched, nothing restored after. Least
invasive: no Game/Save change; skill_points already recomputed on load from level - purchases. Shared _lowered() with unspend().
Row points now written as points_in() (was raw, -1 allowed); same on load.
Test: autospec_test.test_refund (to_dict -> from_dict while Disturbed; live unchanged). Mutation: ignore auto_spent -> fails.
