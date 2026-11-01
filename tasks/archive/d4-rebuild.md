---
id: d4-rebuild
status: done   # draft | ready | in-progress | review | blocked | done
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

- [x] `Godot --headless --path init --quit` prints no script errors and `DistrictLayout.validate_districts()` returns an empty array (show the output).
- [x] The route table from `init/scripts/dev/route_table.gd` still gives a route for every pair it lists, and none got more than 20 % longer than before the change (show before and after).
- [x] Autoplay screenshots (overview and the civic area) show the new centre: police at the corner by the cross street, the square with the executive committee, three tower placeholders, the department store, the park, the two slabs, the polyclinic at the avenue's west side. Attach the file names; read the images yourself and describe any defect.
- [x] No building overlaps a road or another building. Separately verify pedestrian access from the office to every new or relocated building entrance (police, polyclinic, executive committee, all three towers, department store and both slabs), plus the park access point. The existing route table does not cover these destinations. Report each destination, whether a connected route reaches its entrance, and how the final approach was checked for building or prop obstructions. Use a temporary check outside the tracked project files; do not modify `route_table.gd` or add automated tests.
- [x] Worker implementation changes stay inside *Outputs*. The lead additionally updated README and added PR screenshots during the approved PR preparation.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a lot does not fit its rect with the existing catalog entry and the fix needs a script change;
- a route gets worse than the limit and no road tweak inside D4 repairs it;
- the work would require editing files outside *Outputs*.

## Report

- **Status summary:** Implemented and visually reviewed with placeholders. Changes were developed in `/private/tmp/godot-d4-rebuild` on `task/d4-rebuild`, then copied into the main checkout by the lead. The user approved the implementation and visual changes; prepared for a dedicated PR.
- **Files created or changed:** `init/scripts/data/district_layout.gd`, `init/scripts/data/building_catalog.gd`, this brief. The existing UI edits in the main checkout were preserved. The lead also updated README and added PR screenshots during the approved PR preparation. No assets, scenes, builder code, route-table code or automated tests were added or modified.
- **Measurements / previews:** Godot 4.7.1; district validation output: `validate_districts(): []`. Headless startup has no script errors. Graphical autoplay reached `6_summary`, `7_week2` and `7_boiler_repairing`. Runs used `--no-log` and explicit engine log files, so no playtest JSONL was created. The process reports four ObjectDB instances and two resources still in use on shutdown; this was not investigated within this data-only task. Initial sandbox runs also reported denied editor-settings writes/system certificate access; the approved graphical run had no such errors.

  Route table, metres as printed by the existing tool (rounded):

  | Office → target | Foot before | Foot after | Car before | Car after |
  |---|---:|---:|---:|---:|
  | block5 | 162 | 173 | 162 | 173 |
  | boiler | 588 | 576 | 588 | 576 |
  | market | 365 | 386 | 365 | 386 |
  | church | 408 | 425 | 642 | 572 |
  | depot | 670 | 658 | 670 | 658 |
  | wasteland | 437 | 448 | 624 | 646 |
  | forest | 539 | 550 | 539 | 550 |
  | pond | 560 | 548 | 560 | 548 |

  All eight destinations remain reachable in both modes. Largest increase is approximately 7%, below 20%. This table uses the original tool's lot-boundary start, without renderer-registered doorsteps, in both versions.

  Separate entrance inspection instantiated the real scene, copied the renderer's actual doorsteps to a graph containing every lot, and measured the routes. Every segment was checked against road-clear building footprints and catalog dressing (0.35 m margin; walkable park paving excluded). The executive committee was approached from the police doorstep rather than from itself. No building/road or building/building intersections were found for the D4 buildings, including a 0.3 m roof allowance. This verifies authored building/prop geometry, not collision avoidance against every randomly spawned pedestrian or decorative object.

  | Destination | Origin | Foot metres | Building/prop blockers |
  |---|---|---:|---|
  | police | office doorstep | 264.5 | none |
  | polyclinic | office doorstep | 206.5 | none |
  | ispolkom | police doorstep | 264.5 | none |
  | tower_e1 | office doorstep | 265.6 | none |
  | tower_e2 | office doorstep | 260.8 | none |
  | tower_e3 | office doorstep | 286.5 | none |
  | department_store | office doorstep | 236.7 | none |
  | slab_1 | office doorstep | 335.0 | none |
  | slab_2 | office doorstep | 348.0 | none |
  | city_park access | office doorstep | 484.5 | none |

  Evidence directory: `/Users/oleksiisuprun/.codex/visualizations/2026/10/31/01a193b8-e55b-73b3-a27c-1822fffd7582/d4/`.
  Images read: `0_overview.png`, `0_administration.png`, `d4_complete.png`, `d4_north.png`, `6_summary.png`. `d4_complete.png` and `d4_north.png` were also captured and reviewed in the main checkout with its current UI. `7_week2.png` is retained as completion evidence. Route outputs: `d4-routes-before.txt`, `d4-routes-after.txt`; entrance details: `d4-main-inspect.txt`; autoplay output: `d4-autoplay.txt`.

  Visual findings: all three tower placeholders, the east-end executive committee and its monument, two southern slabs, the smaller west-side police and polyclinic, the department store and park are present. No visibly floating or overlapping D4 buildings were found. The park paths and benches are deliberately simple box placeholders; its four authored young trees reuse summer birch sprites and do not switch seasons. Legacy institutional textures are reused at the new dimensions; in particular, the old polyclinic front still paints five window rows on a 9 m high, three-storey placeholder. Replacement art remains a separate task. The long slabs use 108 x 11 m buildings inside the specified 110 x 14 m lots, with entrances on the long sides toward the new lane and their ends toward the avenue.
- **Open questions:** No blocking design questions. The user approved the placeholder layout; replacement art remains pending; no new raster art was generated.
- **Requests for the integrator:** Implemented data has already been copied into the main checkout. Keep the temporary worktree until review is accepted. README now records the implemented placeholder layout and the agreed 24 x 14 m polyclinic. Seasonal park trees and a properly three-storey painted clinic facade remain follow-up art/builder work outside this brief. Shutdown resource warnings are recorded above and are not a D4 script failure.

## Review notes

_Filled in by the lead after each review round._

- User confirmed the reduced polyclinic footprint of about 24 x 14 m (three storeys); README updated to supersede the earlier 40 x 28 m proposal.
- Entrance accessibility must be checked separately from the existing office route table, with results for every destination listed in the acceptance criteria.

- User approved the D4 changes and requested a pull request. The lead updated the campaign documentation and prepared the implementation on `task/d4-rebuild`; unrelated UI changes are excluded.
