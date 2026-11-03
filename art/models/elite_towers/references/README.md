# Civic facade assets and reference sheets

Issues #4 and #5 share branch `art/civic-facade-textures` by user request. Built-in ImageGen produced the sources; exact prompts are in `art/PROMPTS.md`. The user approved both tower looks on 2026-11-02 and positively reviewed the live facade/roof preview.

## Sources and preparation

Selected sheets: `e1-turnaround-v2.png` (tan brick, loggias, pilaster crown), `e2-e3-turnaround-v2.png` (ivory brick, balconies). Front/rear are the long faces, facing the avenue. V1 sheets remain preserved. Generated end widths, roof proportions and details are inconsistent; E2/E3 overcounts storeys. They are appearance references, not blueprints. Integration uses 24 x 20 m footprints, 3 m storeys and 42/36 m wall heights.

Original tower textures are under `art/source_images/elite_towers/`, named `<piece>_<variant>_v<n>.png`:

| Piece | E1 version | E2/E3 version |
|---|---|---|
| long | 2 | 3 |
| end | 2 | 1 |
| shop | 2 | 2 |
| entrance | 2 | 2 |
| crown | 3 | 2 |
| roof | 1 | 2 |

Game copies: `init/assets/textures/facade_tower_<piece>_<variant>.png`. Walls represent 12 x 6 m; entrance, shop and crown pieces 6 x 3 m. Two crown pieces cover a 12 m strip, resolving the brief's 12 x 3 m / 2:1 contradiction. Rejected whole-building compositions remain outside the game.

The six civic originals are under `art/source_images/d4_buildings/`: centre v1 and wing v2 for each building. Wings were derived from the centres to match horizontal bands. Existing footprints remain; outer wing fragments are clipped with UVs, not stretched.

`art/source_images/residential_lived/panel_5_v1.png` and `panel_9_v1.png` add varied curtains, occasional plants and glazing differences, connected as `facade_panel_late_<n>storey_lived.png`. The five-storey edit retains its existing near-2:1 canvas; all eighteen brief textures are exactly 2:1.

Each selected image was prepared separately with `uv run tools/optimize_asset.py <source> --profile facade --output <game copy> --approved`; wing corrections used explicit `--overwrite`. All twenty reports were reviewed: dimensions and pixels preserved, no crop or quantization. Reports and screenshots stay ignored.

## Integration and review

`civic_facades.gd` separates long/end walls, entrances, shops and top-storey modules. E1 is fourteen storeys; E2/E3 twelve. Doorstep offsets follow the entrance bay. Towers receive the same ground-wear ring as ordinary panel housing.

The facade shader keeps nighttime emission and adds opt-in glass roughness, approximate texture-derived shallow relief and 2% boundary blending on repeated tower walls. This is not authored normal-map or parallax data. `roof_felt.gdshader` adds metre-scale felt seams, tonal variation, roughness and shallow normal relief, following the town-asphalt approach. New civic buildings and ordinary panel housing use it.

After the roof request, `civic_roofs.gd` adds parapets, access huts, vents, tower antennas, E1 pilaster caps and larger store ventilation boxes. Box details share an instanced mesh; instance colours are converted to linear. These are procedural roof fittings on the existing simple volumes, not a separate Blender building model.

Both tile axes and centre/wing boundaries were checked. Selected civic edge RGB differences fell to roughly 3-8/255 after correction. Tower source boundaries remain imperfect and use the shader blend. Final overview and north/police views were inspected at the normal orthographic camera; no obvious join failure was seen. Extremely close seams, night/winter presentation and performance profiling remain unverified.

Import and graphical capture completed with exit 0 and no script/render warnings on installed Godot 4.7.2. No automated tests or full-week autoplay were run. Focused capture: `Godot --path init --script <repo>/art/models/elite_towers/capture_map.gd -- --no-log`. It saves overview, north and matched material-baseline frames under ignored `.local/civic-facades/`; selected frames are `map-detail.png` and `map-north.png`. `--facade-baseline` disables material additions in a normal launch.

## Floor-pitch correction (2026-11-02)

The lived-in nine-storey panel image contains eight window rows, with its bottom row clipped. `facade_floors.gd` now samples the seven complete source rows onto nine physical 3 m storeys, cycling two rows rather than stretching eight across 27 m. The narrow image-top decorative band and incomplete bottom row are excluded. E2/E3 long/end art also has different window positions and surplus masonry; calibrated UV bands now place each residential floor separately at 3 m, including the rear/side ground floor. Shop/entrance and crown modules retain their existing art. E1's already regular two-floor repetition remains unchanged. Building heights remain 27/36/42 m.

This is a mesh-UV correction: no raster image was edited, generated or reprocessed. Each wall still uses one mesh surface/material, with six vertices per floor. Existing nighttime shading and window materials remain connected. `CityMap._facade/_facades` accept optional floor-band data; all other callers retain their previous mapping.

Ran the real-map capture `art/models/civic_center/capture_integrated.gd` with Godot 4.7.2 and inspected the default-camera overview beside the administration and ordinary panel housing. Capture completed with exit 0 and no script errors; the local Windows certificate-store startup warning remains. Current image/log: ignored `.local/civic-center-review/integrated-overview.png` and `floor-pitch.log`. No automated tests were added or run. Night/winter and extreme close-up seams were not visually reviewed; user review of this correction remains pending.

Context reference reused: `.local/flows-final-shots/0_north.png` (actual Godot screenshot, ignored). Later 1997-specific signage, notices, kiosks and contextual props were discussed, not implemented in this update.
