# contract-spatial-oracle

Lean 4 proofs for the fabric's space-filling curve and its predictive bounding-volume hierarchy, and the code generator that emits their C header.

## What it is for

It holds two libraries in one package.

`Shared` is the vocabulary: the geometric and spatial-partition types the fabric's cores have in common, with no dependency beyond the Lean core library. The 30-bit Morton code is here, `morton3D` and `morton3DInverse`, with the proofs that it round-trips, that it is a bijection, and that a prefix of a code is an octree cell.

`PredictiveBvh` proves ghost-expansion and surface-area-heuristic bounds for moving entities on top of `Shared`, then generates `predictive_bvh.h` from the proven formulas for the zone guest and the engine module.

## Where it came from

This repository joins two that were separate, with the history of both: `entities-lean-shared` (the package `lean-shared-core`) and `interactor-spatial-oracle` (the package `lean-spatial-oracle`). `Shared` was a Lake dependency fetched from git and is now a library of this package, so the curve and the generator that emits it cannot be at different revisions.

## Build

```sh
lake exe cache get
lake build
lake exe bvh-codegen
```

`lake build Shared` builds the vocabulary alone and needs no cache.

`sh tools/morton_check.sh` holds the generated C to Lean on `testdata/morton_golden.tsv`; see `docs/morton.md`.

## Licence

MIT; see `LICENSE`.
