---
id: d4-rebuild
status: ready   # draft | ready | in-progress | review | blocked | done
worker: codex
issue: "#3"
branch: task/d4-rebuild
---

# Rebuild the administrative centre (D4) in the lot data

## Goal

Replace the old stack of police, polyclinic and executive committee on the east side of the civic axis with the layout agreed in `art/concepts/district_areas_v2.svg` and the README paragraph "Planned rework of the civic area". When this is done the map shows the new centre with placeholder buildings, every route still works, and the district data (`DISTRICTS`) matches the lots.

## Exception to the usual file ownership

Workers normally never edit `init/scripts/`. For this brief the user explicitly allows edits to the two data files listed under *Outputs* and nothing else in `init/scripts/`. Anything that needs another script file goes into *Report → Requests for the integrator*.

## Inputs

1. `README.md`: "Starting District Layout" (the civic-area bullets and the data-model bullet).
2. `art/concepts/district_areas_v2.svg`: the target plan, with roads drawn from the data.
3. `init/scripts/data/district_layout.gd`: `LOTS`, `ROADS`, `DISTRICTS`, `HOURS`, `validate_districts()`. `init/scripts/data/building_catalog.gd`: building and dressing definitions.
4. `docs/adr/0001-data-driven-district-layout.md` and `docs/MAP_LAYOUT_REQUEST.md` for the lot rules.
5. `init/scripts/dev/route_table.gd`, `init/scripts/dev/autoplay.gd` and the workflow notes in `AGENTS.md` (autoplay screenshots, headless import).

## The new layout (metres, x east, z south; the same numbers are in the SVG)

Keep the lot ids `police`, `polyclinic` and `ispolkom`: `week1.gd` refers to them. All other new lots get new ids.

| Lot | Rect (x, z, w, d) | What stands there |
|---|---|---|
| `police` | (-44, -75, 24, 32) | Small two-storey building about 18 x 10 m with a yard; west side of the axis, south of the cross street, facing the axis. Resize the `police` catalog entry; the old 36 x 14 one is too big. |
| `tower_e1` | (30, -60, 40, 38) | Elite tower placeholder: a nine-storey panel block (existing facades) for now; footprint about 24 x 20 m, entrance toward the avenue. |
| `department_store` | (30, -15, 45, 30) | Department store: a low flat-roofed shop building, placeholder box with the existing shop/ground-floor texture; new catalog entry `department_store`. |
| `city_park` | (82, -72, 54, 84) | Small city park: grass, paths, benches, young trees; no building. New catalog entry `city_park` (type N). |
| `ispolkom` | (25, 22, 115, 108) | The paved square with the executive committee at its back (east) end, façade toward the avenue; keep the monument; the paving fills the lot. The building keeps its current look and size. |
| `tower_e2` | (30, 140, 40, 38) | Elite tower placeholder, as `tower_e1` (a second look is not needed). |
| `tower_e3` | (82, 140, 40, 38) | Elite tower placeholder beside E2. |
| `slab_1` | (22, 190, 110, 14) | Simple five-storey panel slab, long side along x, end facing the avenue. |
| `slab_2` | (22, 232, 110, 14) | Same, a second slab. |
| `polyclinic` | (-45, 135, 28, 42) | Polyclinic about 24 x 14 m, three storeys, small ambulance yard; it replaces the south end house on the west side of the avenue: delete lot `b2_e` and use its place. |

Delete the lots `g_axis_1` and `g_axis_2`. Roads: keep the footpath that runs between the square and tower E2; add a short asphalt lane about 5 m wide from the axis edge east to the village street, between the two slabs; add two short footpaths from the axis, one at each of the two tower groups, so each tower entrance is reachable. Draw the exact road rectangles from the SVG; adjust where a lot would block them.

Update `DISTRICTS`: the `admin` rects and subzones must match the new lots (`admin_police`, `admin_polyclinic`, `admin_square`, `admin_park`, `admin_shops`, `admin_elite`; add subzones for the slabs if sensible). `validate_districts()` must return no problems.

## Constraints

- Placeholders only: reuse existing facade textures and the existing catalog patterns; no new art is part of this brief. New textures and models come from other briefs (`elite-towers`, `d4-building-art`).
- No static cars in the new dressing: they will come later as models. Do not leave floating or overlapping props.
- Do not move anything outside D4 except what the table says (`b2_e` removal). Do not touch `ROADS` entries outside D4 apart from the new lane and footpaths.
- Follow `AGENTS.md` rules: run `Godot --headless --path init --import` if assets change; check visuals with the autoplay screenshots, not by guessing.

## Outputs

Write only to these paths:

- `init/scripts/data/district_layout.gd`
- `init/scripts/data/building_catalog.gd`
- the Report section of this brief.

## Acceptance criteria

- [ ] `Godot --headless --path init --quit` prints no script errors and `DistrictLayout.validate_districts()` returns an empty array (show the output).
- [ ] The route table from `init/scripts/dev/route_table.gd` still gives a route for every pair it lists, and none got more than 20 % longer than before the change (show before and after).
- [ ] Autoplay screenshots (overview and the civic area) show the new centre: police at the corner by the cross street, the square with the executive committee, three tower placeholders, the department store, the park, the two slabs, the polyclinic at the avenue's west side. Attach the file names; read the images yourself and describe any defect.
- [ ] No building overlaps a road or another building; walkers can reach each new entrance (state how you checked).
- [ ] Nothing outside *Outputs* is changed.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a lot does not fit its rect with the existing catalog entry and the fix needs a script change;
- a route gets worse than the limit and no road tweak inside D4 repairs it;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:**

## Review notes

_Filled in by the lead after each review round._
