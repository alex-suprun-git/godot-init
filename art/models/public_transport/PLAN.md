# Bus and commuter train checkpoint

Updated 2026-11-01. The ER2 head and motor cars are built and exported; source,
Volga-relative scaling, four-car assembly and Godot review: `er2/README.md`.
LiAZ-5256 and PAZ-3205 buses are built and integrated into traffic and ATP;
bus sources and review state: `README.md`. The bus update was migrated to
`art/bus-models` from main `f620893` and rechecked in Godot with upgraded trucks.

## Existing project material

- `init/assets/sprites/bus_liaz.png`: generated cream/red large bus sprite,
  used at the ATP. Its filename is not proof of a precise LiAZ variant.
- `init/assets/sprites/bus_local_1997.png`: generated cream/red generic local
  bus, used twice at the ATP and at the bus terminal. `art/PROMPTS.md` explicitly
  says it is not a certified PAZ model. Source concepts remain under `art/concepts/`.
- At the initial 2026-10-31 audit no bus or commuter-train GLB existed. ER2 head
  and motor GLBs and both bus GLBs now live under `init/assets/models/vehicles/`.
  Editable bus stages are in `shape_v1/` and `finish_v1/`.
- `art/DISTRICT_ART_REQUEST.md`, A11: ER-type suburban electric train, green
  with a yellow/red nose; three coupled cars, approximately 60 m long and
  3.5 m wide. This is an existing text brief, not a completed asset/reference.
- `train_commuter.png` is absent. `district_builder.gd::_build_train_stock()`
  currently places `train_wagons_v2.png` only on the port freight siding; the
  station tracks stay clear in normal gameplay. The reviewed ER2 four-car train
  is now permanently placed as static scenery beside the village on the outer
  eastern embankment track (x=420, centre z=15, rail surface y=6.04), as requested
  by the user. Current Godot evidence: `er2/previews/godot-embankment*.png`.
- README has a passenger station/track and explicitly excludes trams in this
  district. Do not substitute the existing tram sprite for a commuter train.

## Approved creative choices

- Model both LiAZ-5256 and PAZ-3205 buses, using versions suitable for 1997.
- Model the ER2 with the angular, square-front cab. The user's latest correction
  explicitly supersedes their earlier round-cab selection. Do not build the
  round-cab variant.
- The user chose the handbook's four-car formation on 2026-11-01, superseding
  both the old three-car illustration brief and the temporary two-car proposal:
  head–motor–motor–head, outward cabs. The existing green/cream reference guides
  the model, positively reviewed by the user before requesting map placement.

## Reference leads

- Moscow Transport Museum, LiAZ-677 exhibit:
  https://mtmuseum.ru/exhibits/avtobusliaz-677/
- Moscow Transport, museum director's LiAZ-677 feature:
  https://transport.mos.ru/mostrans/all_news/111572
- Russian Railway Museum archive, electric-train photographs including ER2-389:
  https://archive.rzd-museum.ru/search?fund=0&rubrics%5B%5D=106

These are visual/history leads. No external model has been acquired and no
licence for reusing third-party geometry/textures has been established.

## Model comparison benchmarks

User direction updated 2026-11-01: compare the new buses with the current truck and Volga for dimensions and visual quality. Follow the project's Blender skill benchmark rules. Calibrate each bus to its own verified dimensions and compare all three dimensions, wheels and grounding in the same Godot frame. The old Lada scale factor is not the bus scaling rule.

## Next action

Generated multi-view concept sheets now exist in `references/` for all three
selected vehicles, with prompts and inspection notes in `references/README.md`.
The user requested generated turnarounds as the primary modeling guide. Use
these for the intended appearance, then calibrate real dimensions and reconcile
inconsistent details across views. Their drawn grids are not measured blueprints.
The user approved the refreshed bus comparison with a 20% size reduction and
requested a PR. The road fleet is capped at five buses by separate commit
`469e5fc`. Reconcile exact PAZ variant dimensions
if required. For ER2, review of the requested static map placement remains the
recorded next step; movement is open. See each asset's own README.
