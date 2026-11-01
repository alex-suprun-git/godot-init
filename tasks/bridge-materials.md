---
id: bridge-materials
status: review
worker: lead
---

# Bridge material integration

## Goal

Replace the plain bridge placeholders with the user-approved maintained-concrete, railway-ballast and painted-steel material family. This is lead-owned rendering integration, not a parallel asset-worker task.

## Inputs / outputs

- User's three actual game screenshots of the overpasses and railway river bridge.
- Sources/prompts: `art/source_images/bridges/`.
- Game copies/import files: `init/assets/textures/bridge_*.png`.
- Provenance: `art/optimization_reports/bridge_*.png.json`.
- Renderer: `init/scripts/map/district_builder.gd` (bridge/underpass recipes only).
- Inspection/reproduction helpers and actual game captures: `art/bridges/`.
- Campaign and prompt registries: `README.md`, `art/PROMPTS.md`.

## Acceptance

- [x] Three untouched generated originals and exact prompts preserved outside `init/`; selected copies separately optimized with reports.
- [x] Concrete on bridge structure, ballast between/beside rail strips, painted steel on the river truss.
- [x] Narrow concrete maintenance edges replace broad bare upper margins. Existing road/rail geometry, height and navigation remain.
- [x] Actual Godot before/after, close, alternate-camera and night frames inspected; repeated materials inspected for obvious seams and detail loss.
- [x] Import and graphical runs complete without new script/import errors. No automated tests or full-week playthrough run.
- [x] Sources, measurements, implementation and limitations recorded in `art/bridges/README.md`.
- [ ] Final user acceptance of in-game appearance.

## Report

Implemented and visually inspected 2026-11-01. Concrete 4 m repeat, ballast 3 m, steel 2 m, all world-aligned triplanar. All prepared images 1024px RGB. Existing mist is preserved and limits far-span inspection; near-bank truss is visible. Existing year-round railway material approach is retained, without new seasonal ballast art. No new railings, rivets, routes or bridge opening. No commit or push in this phase. Next: review `art/bridges/after/north_detail.png` and `rail_bridge.png`.

## Surface-continuity follow-up

2026-11-01: Full embankment crown now has continuous bridge ballast; quay paving and road-sidewalk surfaces extend into opaque haze. All six E-W road continuations now also carry phase-aligned road paint (separate geometry from asphalt texture). Actual Godot captures: `art/bridges/continuous/`, `edges/`; implementation notes in the asset README. No navigation, gateway or traffic changes.
