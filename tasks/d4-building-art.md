---
id: d4-building-art
status: ready   # draft | ready | in-progress | review | blocked | done
worker: codex
branch: task/d4-building-art
---

# Facade textures for the new administrative-centre buildings

## Goal

The rebuilt administrative centre (`tasks/d4-rebuild.md`) needs its own looks instead of placeholders: a small district police station, a three-storey polyclinic, and a department store. Paint their facade textures, in the same manner as the existing ones, so the integrator can swap them into the catalog.

## Inputs

1. `art/DISTRICT_ART_REQUEST.md`: "Facade assembly" and the 2:1 canvas rule. Existing examples to match: `init/assets/textures/facade_police_front.png`, `facade_police_side.png`, `facade_polyclinic_entrance.png`, `facade_polyclinic.png`, `facade_ispolkom_front.png`.
2. `art/PROMPTS.md`: "Rules" and the texture rules; add the new prompts to it.
3. `art/ASSET_PIPELINE.md`: originals outside `init/`, approval, optimization.
4. `README.md`, "Planned rework of the civic area", for the story and mood of the buildings.

## Constraints

- 1997, a decent ordinary district: tidy, modest wear, no ruin, no graffiti, no readable text or signs.
- Police station: a modest two-storey late-Soviet building, plain, institutional; one front facade with the entrance (centre piece) and one tileable wing/side facade.
- Polyclinic: three storeys, mid-size, light cladding, a canopy and a ramp at the entrance; front (centre) and side (wing). It must not look like a hospital complex.
- Department store ("универмаг"): a low late-Soviet shop building, mostly glazed ground floor with a solid upper band, flat roof; front and side. Shop signs only as blank panels.
- Follow the centre/wing assembly rules from the art request exactly: the centre piece is the only one with the main entrance; the wing tile continues seamlessly into it and tiles horizontally. Verify the seams and report the check.
- Original generated art only. Originals outside `init/`; game copies only after approval and only via `uv run tools/optimize_asset.py` as in `art/ASSET_PIPELINE.md`.

## Outputs

Write only to these paths:

- `art/source_images/d4_buildings/<piece>_v<n>.png`: untouched, versioned originals.
- `init/assets/textures/facade_police_new_*.png`, `facade_polyclinic_new_*.png`, `facade_department_store_*.png` and `art/optimization_reports/*.json`: game copies, after approval.
- the new prompts appended to `art/PROMPTS.md`.

## Acceptance criteria

- [ ] Six pieces exist (three buildings x centre and wing), all 2:1 canvases; each wing's left and right edges tile and join the centre; the seam check is stated.
- [ ] Each building reads as the right type at a glance in a contact sheet, and the three look like one district.
- [ ] No red, pink or garish colours; no readable lettering.
- [ ] Nothing outside *Outputs* is edited.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- the generator cannot produce a wing tile that tiles after three tries;
- a licence or credit prompt appears;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:** (catalog entries and facade sizes the integrator needs)

## Review notes

_Filled in by the lead after each review round._
