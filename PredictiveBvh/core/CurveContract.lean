-- SPDX-License-Identifier: MIT
-- Copyright (c) 2026-present K. S. Ernest (iFire) Lee

import Shared.Types

-- ============================================================================
-- WHAT THE PREDICTIVE BVH REQUIRES OF THE CURVE
--
-- `Shared` gates `morton3D` beside its definition. This file asserts the same contract from the
-- side that uses it, so a change to the curve fails here too, by name, in the library whose
-- spans assume it. It dates from when `Shared` was a pinned git dependency and a stale pin
-- could change the curve with no diff in this tree; `Shared` is now a library of this package.
--
-- Kept deliberately cheap: a tripwire that costs a second is one nobody deletes.
-- ============================================================================

namespace CurveContract

/-- Every cell of an `n`-cube. -/
def cells (n : Nat) : List (Nat × Nat × Nat) :=
  (List.range n).flatMap fun x => (List.range n).flatMap fun y => (List.range n).map fun z => (x, y, z)

/-- Codes whose `3*d`-bit prefix does not name their own octree cell at depth `d`.
    This is the property a zone span IS, so it is the one worth pinning. -/
def prefixDefects (n d : Nat) : Nat :=
  let shift := if d ≤ 10 then 10 - d else 0
  ((cells n).filter (fun c =>
    let code := morton3D c.1 c.2.1 c.2.2
    let origin := morton3D ((c.1 >>> shift) <<< shift) ((c.2.1 >>> shift) <<< shift)
      ((c.2.2 >>> shift) <<< shift)
    ¬ (code >>> (3 * shift) = origin >>> (3 * shift)))).length

/-- THE TRIPWIRE. Not "is the dependency's test green" -- that test is not run by this
    build -- but "does the curve we are compiled against still partition the way this
    repository's spans assume". -/
theorem pinned_curve_prefix_is_the_octree_cell :
    prefixDefects 8 6 = 0 ∧ prefixDefects 8 8 = 0 ∧ prefixDefects 8 10 = 0 := by native_decide

/-- Round-trip, which is necessary and by itself proves nothing -- kept deliberately, since
    a passing round-trip is exactly what let a broken curve through here twice. -/
theorem pinned_curve_roundtrips :
    ((cells 8).filter (fun c =>
      ¬ (morton3DInverse (morton3D c.1 c.2.1 c.2.2) = (c.1, c.2.1, c.2.2)))).length = 0 := by
  native_decide

/-- A canary on exact values, because the properties above hold for more than one curve.
    Any change to the encoder -- orientation, bit order, order parameter -- moves these, and
    moving them silently is the failure mode.

    These are Morton values. The encoder changed twice before them, and each time the change
    was invisible from here until this theorem started failing, which is the reason it exists. -/
theorem pinned_curve_values :
    morton3D 0 0 0 = 0 ∧
    morton3D 512 0 0 = 536870912 ∧
    morton3D 1023 1023 1023 = 1073741823 := by native_decide

end CurveContract
