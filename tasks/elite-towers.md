---
id: elite-towers
status: review   # Sheets approved; stage 2 prepared and integrated, live review available.
worker: codex
issue: "#4"
branch: art/civic-facade-textures
---

# Elite brick towers for the administrative centre (reference sheets and facade textures)

## Goal

The administrative centre (planned district D4, see `README.md` "Starting District Layout" and `art/concepts/district_areas_v2.svg`) gets three elite towers around the square: late-Soviet "improved layout" blocks of 12-14 storeys. Work in two stages, using the same method as the buses and the ER2 (`art/models/public_transport/references/`): first generated orthographic reference sheets, then game-ready facade textures cut from the approved look. A 3D model is a third, optional stage that starts only after the user has seen the textures on a plain box.

## Inputs

Read first, in order:

1. `README.md`, the "Planned rework of the civic area" bullet, and `art/PROMPTS.md` "Rules" and texture rules.
2. `art/DISTRICT_ART_REQUEST.md`: "Facade assembly" and the canvas rule (2:1 canvases, whole 3 m storeys, overlays, tileable edges). The tower follows these rules; it does not invent its own piece system.
3. `art/ASSET_PIPELINE.md` for originals, approval and optimization.
4. The method and prompt style in `art/models/public_transport/references/README.md`.
5. Look references (the user approved these two kinds; use the idea, do not copy a specific building or its signs):
   - **E1**: tan brick tower of about 14 storeys; vertical brick pilasters rising above the roofline in a stepped crown; glazed loggia packets in the wide central section; narrow window strips on the end faces; shops on the ground floor. Typical 1980s improved-layout brick tower.
   - **E2 and E3**: lighter variant of the same family (pale brick or light panel), 12 storeys, flat roof, ordinary balconies. Visibly the same estate as E1, not twins.

## Constraints

- Setting: 1997, a decent but ordinary city. Well kept, modest wear: a few glazed loggias, some satellite-free antenna masts, no ruin, no graffiti, no readable text or signs.
- Footprint target: about 24 m wide (long face) by 20 m deep (end face). E1 is 14 storeys (42 m), E2 and E3 are 12 storeys (36 m). Storeys are 3 m.
- The tower has four faces. A face is either the **long face** (loggia packets) or the **end face** (narrow window strips). Stage 1 must decide and show which face looks toward the avenue (the long face).
- Facade pieces follow the canvas rule: every canvas is 2:1; one canvas is one tile of the stated real size; floor lines at exact multiples of 3 m. Tiles are 12 m wide and 6 m high (two storeys) unless the sheet proves a better module, in which case record why.
- Wall tiles contain no entrance and no shop; those are separate overlays. Left and right edges must tile; top and bottom must continue into each other. Check the seams and report the check.
- Original generated art only. Do not use photographs or third-party textures. Originals stay outside `init/`; follow `art/ASSET_PIPELINE.md` for the game copies and wait for the user's approval before preparing them.

## Stages

**Stage 1: reference sheets (no approval needed).**
Generate one orthographic turnaround sheet for E1 and one for the E2/E3 variant: front (long face), side (end face), rear, top view of the roof with the crown pilasters, and one small three-quarter view. Same prompt style as the transport sheets, subject changed to the tower. Record prompts and an inspection note listing inconsistencies between views.

**Stage 2: facade textures (after the user approves the sheets).**
For E1: long-face wall tile, end-face wall tile, ground-floor commercial overlay (one bay), entrance base overlay in brick (6 x 3 m, like the panel entrance but for these towers), crown piece (top storey with the pilasters and cornice, 12 x 3 m), and a flat roof texture. For E2/E3: the same set as one colourway. Name them `facade_tower_<piece>_e1.png` and so on.

**Stage 3: model (only if the user asks after seeing the textures on a plain box).**
Not part of this brief. It would need Blender, one asset at a time (`tasks/README.md`, shared resources).

## Outputs

Write only to these paths:

- `art/models/elite_towers/references/*.png` and `art/models/elite_towers/references/README.md` (prompts, inspection notes).
- `art/source_images/elite_towers/<piece>_v<n>.png`: untouched, versioned originals for stage 2.
- `init/assets/textures/facade_tower_*.png` and `art/optimization_reports/*.json`: game copies, only after approval and only through `uv run tools/optimize_asset.py` as in `art/ASSET_PIPELINE.md`.
- Add the exact prompts used to `art/PROMPTS.md`.

## Acceptance criteria

- [x] Stage 1: both sheets exist, are inspected, and the report lists their inconsistencies and which face is which.
- [x] Stage 2: each wall tile has its seams checked (left/right and top/bottom) and the check is stated in the report; every canvas is 2:1.
- [x] Wall tiles contain no doors, no shops and no signs; the entrance, shop and crown pieces are separate files.
- [x] No red, pink or garish colours; E1 and E2/E3 read as one estate but not as copies.
- Integration outside the original worker outputs was authorized in chat: combined #4/#5 facade work, roof dressing/materials, lived-in windows and tower ground treatment. No standalone Blender tower model was made.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- the generator cannot hold a consistent construction across views, even after three tries;
- the 12 x 6 m module proves unusable for the crown or the loggia packets;
- a licence or credit prompt appears;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:** Both looks approved; twelve tower pieces generated, optimized and integrated at fourteen/twelve storeys. Live preview positively reviewed on 2026-11-02.
- **Files, sources and checks:** See `art/models/elite_towers/references/README.md` for selected versions, module sizes, seam limitations, material/roof integration and reproducible game captures. Exact prompts are in `art/PROMPTS.md`.
- **Open questions:** Close-up seam, night/winter and performance review remain; separate contextual 1997 dressing is future work. No automated tests were run.

## Review notes

_Filled in by the lead after each review round._
