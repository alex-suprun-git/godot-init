# Police station (РОВД) and polyclinic, 1997

Replaces the generic textured boxes on the `police` and `polyclinic` lots. They read as housing from the default camera and had no identity next to the department store.

## Approval

- 2026-11-13: user approved the massing direction in chat ("Ja, detaillieren") from `previews/police_iso.png` and `previews/clinic_iso.png`. Scope: direction only. The in-game appearance of the textured models is **not yet approved**.

## Design (real-life references, not copied from a source image)

- **Police:** two-storey pale-brick district station, 28.8 x 10.5 x 7.2 m. Projecting entrance block with a concrete canopy and a blue "МИЛИЦИЯ" board, wall flagpole, 16 m lattice radio mast on the roof, rear garage wing for the duty vehicles. Front and rear carry `facade_police_new_wing.png` (two tiles of 14.4 m, windows included).
- **Polyclinic:** three-storey tiled block with green bands, 36 x 12 x 10.8 m. Central glazed stair tower that rises above the roofline (13.2 m), canopy over the entrance, red-cross plate, ambulance porch at the south end. Front and rear carry `facade_polyclinic_new_wing.png` (two tiles of 18 m, slightly narrower than the source aspect).
- Window bays of the facade textures line up with the entrance blocks: block widths (5.0 m and 7.0 m) were chosen so no window is cut.

## Build

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/civic_service_buildings/build_blockout.py   # massing previews only
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/civic_service_buildings/build_buildings.py  # textured export
Copy-Item art/models/civic_service_buildings/exports/*.glb init/assets/models/civic_services/
```

Blender -Y is the front, which exports as Godot +Z. Origin: centre of the main body at ground level. Bounds, triangles and materials are in `export_report.json` (police 2440 triangles, clinic 3782).

## Integration

`init/scripts/map/civic_services.gd` places the GLB on the lot (east-facing only): rear 1 m from the lot's back edge, yaw +90 degrees. `building_catalog.gd` gives each entry `rear_extent`, `front_extent` and `width_extent` (from the export bounds) and the parked service van as dressing. The earlier flat forecourt/sign placeholders were removed. Each lot is also a fenced territory drawn as one MultiMesh (`_fence`, `_path`): a precast concrete panel fence with a pedestrian gate and a vehicle gate at the police; a metal bar fence on brick pillars with a pedestrian gate, a vehicle gate, an entrance path, an ambulance drive and a lawn ground at the polyclinic (user request 2026-11-13: fenced territory outlined on the map). The lots were enlarged for this in `district_layout.gd`: police 36 x 34 m (x -56..-20, z -77..-43; limited by the north street and the housing block to the south), polyclinic 33 x 52 m (x -53..-20, z 130..182; the east edge stays clear of the axis pavement). Building offsets inside them are `rear_gap` in the catalog entries. The polyclinic yard is furnished by `init/scripts/map/clinic_yard.gd`: entrance plaza with benches, bins, lanterns and planters, a patient car park behind its own gate (two Ladas), hedges and trees along the fence, poplar screen at the rear, a bin enclosure and a utility shed. The police yard is furnished by `init/scripts/map/police_yard.gd`: asphalt vehicle yard behind the gate with bay lines for the van and the chief's black Volga, a gate booth, an entrance walk with two lanterns, a notice stand and a bench, hedges and trees along the side fence, and a rear yard with parking in front of the three garage doors (moved to the wing's rear face so they open into the yard, not into the fence), poplars and a bin enclosure. Trees in front of the entrance were kept few on purpose: the default camera looks from the south-east and they hid the stair tower.

The polyclinic name "ПОЛИКЛИНИКА" is authored geometry on the entrance canopy fascia (capitals, red on cream), not a free-standing sign.

## Open

- Gable walls use generic brick/plaster; no roof detail beyond huts and the mast.
- Night frame, winter roof and full-week play were not checked.
- The existing street lamp stands in front of the police entrance (map-wide lamp rhythm, not part of this asset).
