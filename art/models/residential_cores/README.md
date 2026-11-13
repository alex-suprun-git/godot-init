# Residential core assets

On 2026-11-13 the user accepted the [four-core paintovers](../../source_images/district_visual_pack/README.md) as sketch references and confirmed the objects for modeling. Final composition and parcel assignments are open. The school is a compact 1997 classroom block with a lower gym. The kindergarten has two classroom wings around a recessed entrance. The ZhEK building houses dispatch and a repair bay with pipe storage. Gusev's two kiosks are separate prefabs, and the shoe/key repair booth is a separate option for a later trading yard. The mini-football pitch includes markings, goals and a fence with an opening.

[`plans.json`](plans.json) defines the footprints, heights and openings used by both the dimensioned [orthographic sheets](projections/) and the editable [Blender source](residential_cores.blend). The first exports in [exports](exports/) are individual metre-scale GLBs, with the front facing Godot +Z. School and gym are one mesh. The pitch is a separate mesh. The buildings use draft solid-color materials and physical window frames, doors, canopies and roof fittings.

The preview script loads all seven GLBs in the actual district at the existing camera angle. `preview_yards.gd` adds the school forecourt and pitch access, the fenced kindergarten yard with a shelter and play equipment, the ZhEK service apron, and the pedestrian approach to the later kiosk yard. It reuses the district's seasonal grass, paving, asphalt and foliage. Only the preview replaces the old dressing within those footprints. The final yard positions, pedestrian routing and kiosk event states still need integration. The buildings' surface textures are a separate pass.

From the repository root:

```powershell
uv run python art/models/residential_cores/draw_projections.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python art/models/residential_cores/build_assets.py
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path init --script ../art/models/residential_cores/preview_map.gd -- --hour=11 --no-log
```

The daylight capture is saved to `.local/residential-cores/yards.png`.

## Panel housing details

On 2026-11-13 the user approved the daytime House 5 pilot (`.local/housing-block-details/0_house5_courtyard.png`) as the direction for #49. The live map uses per-building facade tints and one to three instanced roof aerials across the 24 five- and nine-storey panel blocks. Balcony dishes are sparse and the painted river mural stays on one House 5 gable. The mural is native SVG with the panel joints drawn through the artwork.
