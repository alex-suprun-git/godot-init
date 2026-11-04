# Department store — 1997 commercial rework

## Current integrated pass — 2026-11-03

The user requested a strong 1990s overhaul within the previously selected central-building commercial-layer direction. The same24x30m Soviet two-storey body stays at(24.5,15.5), with the avenue entrance and shared garden walks retained. `init/scripts/map/department_store.gd` replaces the generic textured box with the original Blender export: physical concrete piers/recessed glazing, repaired plinth, different rented sections/doors/canopies, separate clothing/commission/household signs, outdoor display tables and a clothes rail on the garden apron, service cartons/ventilation and large imported-electronics advertising. Public paths remain clear. The old red roof letters were enlarged/thickened for map readability and, following the user's latest correction, face SOUTH toward the administration; this supersedes the earlier general player-facing orientation. Retail names are backdrop, not implemented shop gameplay.

`build_store.py` imports the existing civic-venue helpers without running their exporter; that script now guards its CLI build with `__main__`. Source checkpoint: `department_store_1997.blend`; selected game export under `exports/`, copied to `init/assets/models/department_store/`. Front is Blender-Y/Godot+Z, map yaw-90degrees. The body is 7.2 m high (two 3.6 m storeys; increased from 6 m after the user's scale review), retaining 2.35 m shop doors and the 24 x 30 m plan, with taller physical roof lettering; final bounds/triangle/material counts are recorded in `export_report.json`. The current structural materials use the civic PBR v2 albedo/normal/roughness maps, including UV-mapped felt roofing and cool glazing; the previous near-flat bitumen source is superseded. Existing printed tenant graphics and geometry are retained; no older unrelated art was bulk-processed.

Built-in ImageGen sources, exact prompts and input roles: `art/source_images/department_store/in-context-1997-v1.*` and `retail-atlas-v1.*`. The first uses the actual current precinct screenshot as its map reference. The generated3x2 retail atlas was inspected and separately optimizer-prepared before use, within the user-authorized 1997 texture batch. In-game lettering for the main roof sign/electronics headline is authored geometry for readability rather than a compressed full-square print. The current render still awaits user live review.

```powershell
uv run tools/optimize_asset.py art/source_images/department_store/retail-atlas-v1.png --profile facade --output art/models/department_store/textures/retail-atlas-v1.png --approved
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/department_store/build_store.py
Copy-Item art/models/department_store/exports/department_store_1997.glb init/assets/models/department_store/
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe' --headless --path init --import
```

Godot4.7.2 graphical captures checked the store together with the current restaurant, at the ordinary map angle and a closer zoom. This caught thin roof lettering and compressed electronics artwork; both were corrected before the final demo launch. Actual captures/logs remain ignored under `.local/civic-venues-review/` and `.local/department-store-*`; use the civic venues capture script with `--venue-closeup` to reproduce. Script/placement errors were checked in the capture log. No automated tests were added/run; night presentation, winter roof treatment and full-week gameplay remain outside this visual check.

For Windows visual QA, follow the waited import/capture sequence in ../civic_venues/README.md; earlier captures could race the asynchronous GUI import. The v2 material correction was inspected together with the restaurant after import completion.

Scale revision verified in Godot after a waited import: 7.2 m shell, 9.95 m including roof lettering/supports, unchanged 24 x 30 m body plan and 2.35 m shop doors. The standard map view was inspected beside the 14 m office bar, 18 m administration hall and 36 m tower bodies; captures remain local under `.local/proportion-review/`. Upper glazing, floor band, retail graphics, canopies and roof details were repositioned rather than stretching the full mesh.
