# The Morton code and its one definition

Every zone assignment, tree sort key and authority lookup of the fabric goes through one function:
three 10-bit cell coordinates in, one 30-bit code out. This page says where that function is
defined, how the C comes to be, and how a wrong copy is caught.

## What the code is

`Shared.morton3D x y z` interleaves the bits of the three coordinates, with `x` in the top bit of
each triple. `Shared.morton3DInverse` takes the code apart again. Three theorems in
`Shared/Types.lean` gate it: `morton_roundtrips`, `morton_is_a_bijection`, and
`morton_prefix_is_the_octree_cell`, which says that the top `3 * d` bits of a code name the octree
cell of side `2^(10 - d)` that holds the point. The last one is the property the zone partitioning
uses: a span of codes with one prefix is one cube.

## Why it is not a Hilbert curve

It was one until 2026-08-12. The encoder was written wrong twice, once in Lean and once by hand in
C, with the same two mistakes, and both copies were bijections that round-tripped, so every check
they had passed. Measured, 87.5% of consecutive codes were not neighbouring cells, which is worse
than the Morton order it had been chosen over, at five times the cost. The comment above
`part1by2` in `Shared/Types.lean` has the account. Morton order is a permutation of bits, so the
prefix property is its definition and there is no state to get backwards.

The proofs that compare the two curves live in `PredictiveBvh/compare/`: `CurveDuality.lean`
measures Morton against a true Hilbert curve, and `SkillingRoundtrip.lean` holds that curve's
stages. Nothing that is generated uses them. Outside that directory and this page no file names
the old curve: the modules that compute Morton codes are `MortonBroadphase` and `MortonCell`, and
`sh tools/name_lint.sh` holds it so, after it has found a planted name.

## One definition in C

Until this change the generated header only declared the curve's four C functions, and their
bodies were written by hand in two adapters. That is how a wrong body stayed in what shipped after
the Lean had been corrected. Now `lake exe bvh-codegen` writes the bodies into `predictive_bvh.h`:

| Function | What it does |
| --- | --- |
| `morton3d(x, y, z)` | the 30-bit code of three 10-bit cells |
| `morton3d_inverse(m, &x, &y, &z)` | the three cells of a code |
| `morton_of_aabb(&box, &scene)` | the code of the cell that holds the centre of a box, on a grid of 1,024 cells an axis over the scene |
| `morton_cell_of(code, depth, &scene)` | the box of the octree cell named by the top `3 * depth` bits |

A consumer includes the header and defines none of these. The header no longer declares
`hilbert3d`, `hilbert3d_inverse`, `hilbert_of_aabb` or `hilbert_cell_of`, and the deprecated Lean
name `hilbert3D` is gone, so a caller that still uses an old name does not build. The tree's leaf
field `hilbert` is now `code`, and `old_hilbert` is `old_code`.

Every stored or transmitted code made by the old encoder is void: the same cell has another code.

## The golden vectors

The generator also writes `testdata/morton_golden.tsv`: 512 rows of `x`, `y`, `z` and the code
Lean computes for them, tab separated. Twelve rows are corners and fixed cases and 500 come from a
fixed linear congruential sequence, so the file is the same on every run. A consumer in any
language checks its own encoder against this file.

## The check

```sh
sh tools/morton_check.sh
```

It compiles `tests/morton_check.cpp` against the generated header and runs it on the golden file.
For every row the C code must equal Lean's, the inverse must give the cells back, the code of a
box in that cell must be the same code, and at each depth from 0 to 10 the cell of the code must
be the octree cell of the point and must be the same box for the code with its low bits cleared.
The script fails at once if the header contains the old curve's name.

Before the real run the script must see three planted defects fail:

| Control | What is planted | Where it must fail |
| --- | --- | --- |
| `swapped` | a header whose `morton3d` puts `z` in the top bit, the old encoder's order | row 1, the code differs from Lean |
| `skewed` | a header whose `morton_cell_of` makes a cell twice as wide | row 0, a prefix is not its octree cell |
| altered row | row 200 of the golden file has its code raised by one | row 199, the code differs from Lean |

CI also regenerates the header and the golden file and fails when either differs from what is
committed.
