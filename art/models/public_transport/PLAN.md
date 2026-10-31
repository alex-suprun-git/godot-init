# Bus and commuter train checkpoint

Checked 2026-10-31. User requested a bus and commuter train after the vehicle
modelling work. Vehicle variants are approved; modelling has not started.

## Existing project material

- `init/assets/sprites/bus_liaz.png`: generated cream/red large bus sprite,
  used at the ATP. Its filename is not proof of a precise LiAZ variant.
- `init/assets/sprites/bus_local_1997.png`: generated cream/red generic local
  bus, used twice at the ATP and at the bus terminal. `art/PROMPTS.md` explicitly
  says it is not a certified PAZ model. Source concepts remain under `art/concepts/`.
- No bus GLB or commuter-train GLB was found in the project model directories.
- `art/DISTRICT_ART_REQUEST.md`, A11: ER-type suburban electric train, green
  with a yellow/red nose; three coupled cars, approximately 60 m long and
  3.5 m wide. This is an existing text brief, not a completed asset/reference.
- `train_commuter.png` is absent. `district_builder.gd::_build_train_stock()`
  currently places `train_wagons_v2.png` on both the passenger track and freight
  siding. `docs/MAP_LAYOUT_REQUEST.md` explicitly describes that placeholder.
- README has a passenger station/track and explicitly excludes trams in this
  district. Do not substitute the existing tram sprite for a commuter train.

## Approved creative choices

- Model both LiAZ-5256 and PAZ-3205 buses, using versions suitable for 1997.
- Model the ER2 with the angular, square-front cab. The user's latest correction
  explicitly supersedes their earlier round-cab selection. Do not build the
  round-cab variant.
- The old three-car brief remains a map representation, not an assertion about
  an actual operational ER2 formation. Exact livery and budgets remain to be
  established against references.

## Reference leads

- Moscow Transport Museum, LiAZ-677 exhibit:
  https://mtmuseum.ru/exhibits/avtobusliaz-677/
- Moscow Transport, museum director's LiAZ-677 feature:
  https://transport.mos.ru/mostrans/all_news/111572
- Russian Railway Museum archive, electric-train photographs including ER2-389:
  https://archive.rzd-museum.ru/search?fund=0&rubrics%5B%5D=106

These are visual/history leads. No external model has been acquired and no
licence for reusing third-party geometry/textures has been established.

## Next action

Generated multi-view concept sheets now exist in `references/` for all three
selected vehicles, with prompts and inspection notes in `references/README.md`.
The user requested generated turnarounds as the primary modeling guide. Use
these for the intended appearance, then calibrate real dimensions and reconcile
inconsistent details across views. Their drawn grids are not measured blueprints.
No 3D models have been built yet.

Collect consistent front/side/rear/three-quarter references for LiAZ-5256,
PAZ-3205 and the square-cab ER2, and choose
geometry/material budgets for their actual map scale. Then use the project's
Blender skill and `references/vehicle-modeling.md`: establish silhouette and
proportions before detail/baking, keep body/glazing coordinated, export only
the asset, inspect actual GLBs and show a Godot frame. A three-car train in the
old art brief is a proposed map representation, not an assertion about a real
ER2 operational consist. No models or gameplay files were changed in this pass.
