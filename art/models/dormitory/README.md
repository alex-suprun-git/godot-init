# Protagonist dormitory

The user authorized modeling and replacement on 2026-11-06 after reviewing `../../source_images/district_visual_pack/dormitory-v1.png`. The model follows its four-storey L-shaped roof plan, not the inconsistent generated side elevations: 30 × 11 m main bar plus an 11 × 12 m western return. Storeys are 3 m; roof/parapet and vents reach about 13.6 m. Blender -Y faces the courtyard, exported as Godot +Z. No interior is modeled.

`dormitory.blend` is the editable source; `build_asset.py` rebuilds it. The game copy is `init/assets/models/dormitory/dormitory.glb`, one mesh with 10 material surfaces and about 17k triangles. Physical frames, sills, stair glazing, entrance canopy/steps, Cyrillic sign and roof vents supply map-visible detail. Window recesses are layered facade geometry, not modeled rooms. After the user accepted the overall appearance and requested a more compact position, the whole compound moved 19.25 m west and 25 m south toward west street. Its parcel is now 38 × 45 m, with about 3.6 m from the outer coping to the roadside sidewalk; surrounding reserve bounds were adjusted. The southern approach and doorstep move with the compound. The finished court links the entrance to west-street sidewalk and the housing footway, with connected bench pads, a bin, low facade planting and a worn washing-line patch; the simulation entrance aligns with the main path. `init/scripts/map/dormitory.gd` places the model, existing furniture/vegetation and clotheslines.

## Rebuild

Run from the repository root, replacing `Blender` with the installed binary:

```text
Blender --background --factory-startup --python art/models/dormitory/build_asset.py -- textures
uv run tools/optimize_asset.py art/source_images/dormitory/silicate-brick-v1.png --profile surface --output init/assets/models/dormitory/silicate_brick.png --approved
Blender --background --factory-startup --python art/models/dormitory/build_asset.py -- blockout
Blender --background --factory-startup --python art/models/dormitory/build_asset.py -- build
Godot --headless --path init --import
```

The original seamless brick albedo is analytically authored in Blender and separately optimizer-prepared; no new ImageGen art was made. The approved concept direction authorizes this material preparation. Existing prepared civic-centre felt is reused for the roof. For an intentional texture rebuild, pass the optimizer's explicit `--overwrite`. Godot extracts embedded GLB texture copies alongside the model during import.

Two opposite blockout angles were inspected before detailing. Export diagnostics and review renders stay in ignored `.local/dormitory/`. Graphical inspection uses `.local/dormitory/capture.gd` and the default game camera/zoom with a noon light override. Import and summer map appearance were checked; the user accepted the overall model appearance and requested the roadward relocation; final placement review is pending. No automated tests were run.
