# RAF-22031 ambulance

## Current checkpoint — 2026-11-02

The separately proportioned RAF-22031 ambulance is built, exported and inspected beside the police UAZ, current Volga, PAZ and ZIL in Godot. The user positively reviewed the models and requested the recorded size adjustments. Catalog/placement integration remains separate.

- Source: `raf_ambulance.blend`, scene `RAF_Ambulance`; build/export entry points: `build_raf.py`, `export_raf.py`. They use the shared asset-owned helpers in `../uaz_service/`.
- Export: `init/assets/models/vehicles/raf_ambulance.glb`; measurements: `glb_inspection.json`.
- Real-scale Blender source length/body width/roof height: **5.070 / 1.940 / 1.985 m**; wheelbase **2.620 m**. The user requested both vans 15% smaller on 2026-11-02. Uniform **0.85** scale is embedded in the GLB: exported length **4.3095 m**, body width **1.649 m**, mirror width/beacon height **1.938 / 1.938 m**, wheelbase **2.227 m**. Ground-centred origin, Godot +Z forward. Do not apply the reduction twice at integration.
- **9,864 triangles**, five meshes (body and four wheels), seven primitives, three materials and one embedded **64 × 64** palette atlas. No animation, camera, lights or collision. Below the Lada triangle/texture budget; above the original approximate 8k target.
- Godot 4.7.2 / Compatibility frame: `../uaz_service/previews/service-comparison-v4.png` (ignored), including front/rear views and default-map-zoom readability with the requested 15% van reduction and subsequent 10% Volga reduction. Actual clinic placement and main-project rendering remain unverified.

- Untouched original: `references/raf-22031-turnaround-v1.png`.
- Exact prompt: `references/raf-22031-turnaround-v1.prompt.md`.
- Views: orthographic left, right, front, rear and top, plus front three-quarter.
- Modeling-only reference outside `init/`; no raster optimization/import was performed or needed.
- Vehicle choice: RAF-22031 medical variant of RAF-2203; standard-roof appearance is the current generated proposal, not a separately approved detailed specification.
- Historical identification source consulted during selection: https://t.mos.ru/mostrans/all_news/124000 (transport museum account of a RAF-22031-01 ambulance).

## Visual inspection

All six complete views are present. The sloping cab, rectangular headlights, long low van body, off-white/red medical livery and blue beacon are readable. Vehicle surfaces contain no lettering or readable plates; panel labels stay outside the vehicle. Appearance remains for user review.

Resolve before modeling:

- Right-side medical access appears as a broad door area with multiple handles/seams; the exact door mechanism/layout must be resolved against actual RAF references, not inferred from generated marks.
- Side window divisions, frost boundaries and apparent spacing vary slightly in the three-quarter view. Choose one shared landmark layout.
- Roof vent shape/detail differs between side and top panels; rear view does not clearly show the beacon. Resolve consistent fittings and placement.
- Grid spacing, apparent dimensions and projections are uncalibrated. Establish real body bounds, wheelbase and variant details independently before tracing geometry.
- Rendering is more detailed than the intended game mesh. Retain silhouette; simplify seams/fittings and use established opaque cab glazing without a detailed interior.

## Rebuild and next action

Run `build_raf.py` in Blender with its real `__file__`, then `export_raf.py` as a separate stage. It builds RAF-specific shell sections, axle spacing, sloping cab, glazing and medical livery, sharing only technical helpers with UAZ. No paint bake is required; the editable vertex palette becomes an embedded atlas to avoid the observed Godot vertex-albedo issue on fittings. See the UAZ README for preview preparation/run commands. Next action: clinic/catalog integration in a separate update.

The [factory operating manual](https://ru.djvu.online/file/77k1BXZpJa2XE), pp. 189–191, specifies one hinged side salon door, an upward-opening rear hatch and curved windscreen. The model uses one continuous front screen with two wipers and one right-side salon door; duplicated/generated handles were discarded. This is a simplified exterior with opaque/frosted glazing, no detailed interior or antenna. The dimensions table's 2.280 m height is stated with the antenna lowered; the simplified beacon reaches that envelope without claiming an exact equipment reconstruction.

## User review — 2026-11-01

The user approved both the police UAZ and RAF ambulance reference appearances ("both are excellent"). This approves the visual direction of v1, not generated projection accuracy. Resolve the inspection inconsistencies technically before modeling; do not request the same visual-direction approval again. No models exist yet.

## Scale comparison — 2026-11-02

User direction: research real dimensions and visually compare proportions beside the current Volga and PAZ. The [1989 RAF factory operating manual](https://ru.djvu.online/file/77k1BXZpJa2XE) lists RAF-22031-01 at 5.070 m long, 1.940 m wide without mirrors, 2.280 m overall height and 2.620 m wheelbase. Resolve the height footnote/roof equipment from the scanned page before setting roof geometry. Relative to real vehicles, RAF is about 14% longer than the 4.440 m UAZ and 7% longer than the 4.735 m Volga, with the same nominal body width as UAZ. It must retain its own longer, lower-looking body proportions.

The shared Godot comparison uses current Volga and PAZ exports at their game presentation scales; see the UAZ asset README for factors. PAZ has an approved 20% reduction. The user subsequently requested 15% reduction for both new vans; v3 uses that factor embedded in the GLBs, without extra preview scaling. The real vehicle dimensions remain the modeling reference.
