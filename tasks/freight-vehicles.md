---
id: freight-vehicles
status: review
worker: lead
---

# Freight vehicle reference variants

## Authorized scope

Produce generated multi-view modeling references, using the same process as the UAZ and RAF sheets. The user requested:

1. A ZIL food delivery truck.
2. A ZIL coal truck based on the existing 2D coal sprite.
3. A KamAZ carrying consumer goods in a container-like cargo body.

No model replacement, Blender build, integration, commit or push is part of this reference-production step.

## Current interpretation

- Food ZIL: classic ZIL-130-family cab with an off-white insulated food box; no refrigeration machinery is assumed.
- Coal ZIL: same cab family, wooden drop-side bed, olive canvas partly pulled back over visible coal, retaining the existing `init/assets/sprites/truck_zil_plain.png` identity. Improve upkeep to current project standards rather than preserving pervasive rust.
- KamAZ: classic KamAZ-5410-family tractor with a skeletal semi-trailer carrying one closed standard-height 40-foot ISO dry container. This is a visual proposal for the user's uncertain "container" wording, not a settled gameplay or logistics rule. A normal box semi-trailer remains an alternative for review.

Exact subvariants, dimensions and mechanically consistent construction must be resolved before modeling. Generated sheets are not historical evidence or calibrated blueprints.

## Outputs

- `art/models/traffic/references/<id>-turnaround-v1.png` (untouched generated originals).
- Adjacent `.prompt.md` files with complete built-in ImageGen prompts.
- `art/models/traffic/references/README.md` with inspection and next action.

## Acceptance

- [x] Three sheets exist and are visually inspected.
- [x] Every sheet contains both sides, front, rear, top and three-quarter view.
- [x] Coal sheet uses the actual existing sprite as an image reference.
- [x] Existing game assets remain unchanged; generated inconsistencies and review state are recorded.

## Report

Completed reference generation and visual inspection on 2026-11-01. Three original PNGs and exact prompts are saved under `art/models/traffic/references/`; its README records inspection inconsistencies and scope. User visual review, including ISO container versus box-trailer choice, is pending. No game assets changed; no Blender build, Godot run or automated tests were performed.
