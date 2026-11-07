# Map rework request: data-driven outskirts district

For Codex. This is an implementation brief. The design is decided; do not redesign. If something here conflicts with the code or turns out impossible, stop and report instead of improvising.

## Read first

1. `AGENTS.md`: workflow, Godot path, autoplay, no tests unless asked, no commits.
2. `docs/MAP_AND_DISTRICT.md`, sections "City Map" and "Starting District Layout".
3. `docs/adr/0001-data-driven-district-layout.md`: why the layout moves into data.
4. `art/concepts/district_layout_v3.svg`: the target layout. Its coordinates are map meters, and its lot ids are the data keys below.
5. `init/scripts/map/city_map.gd`, `init/scripts/data/week1.gd`, `init/scripts/sim/week_sim.gd`, `init/scripts/ui/hud.gd`.

## Goal

1. Replace the hand-placed layout in `city_map.gd` with a layout described as data and built by one generic builder.
2. Build the new district from `district_layout_v3.svg`, using existing art and plain placeholder boxes where art is missing.

The new art from `art/DISTRICT_ART_REQUEST.md` is produced in parallel. Do not wait for it and do not generate images. Every building must render with a placeholder now, and swapping in a texture later must be a one-line catalog change.

## Units and axes

- 1 map unit = 1 metre. Calibrated assets already assume this, for example the chimney is 34 m and a Lada is 4.3 m.
- x points east, z points south, y is up. The origin is the map center. The river is at negative z.
- Retire the SVG transform (`SVG_SCALE`, `SVG_ORIGIN`, `_svg_point`, `_svg_ground`, `_svg_box`, `_svg_building`). The new data is in metres directly. Keep helpers that are not SVG-specific (`_box`, `_ground_quad`, `_sprite`, `_prop`, `_grounded_prop`, `_facades`, `_roof`, `_panel_block`, `_windows`, `_tree`, `_occupy`), renaming or adapting them where they take SVG coordinates.

## Step 1: layout data

Create `init/scripts/data/district_layout.gd` (`extends RefCounted`, constants only, like the other data scripts):

- `LOTS`: id → `{"type": "W"|"K"|"G"|"X"|"D"|"R", "rect": Rect2(x0, z0, w, h), "content": String, "condition": "kept"|"worked"|"fading"|"abandoned", "facing": "n"|"s"|"e"|"w"}`.
  - `facing` is the side the main entrance or street front faces.
  - A W lot's long axis follows its rect: wider than deep runs east–west.
- `ROADS`: list of `{"rect": Rect2, "kind": "asphalt"|"yard"|"dirt"}`. Village dirt roads may be several rects in an L-pattern.
- `RAILS`: list of polylines (arrays of `Vector2`) for the passenger tracks, the freight tracks, and the port siding.
- `WATER`, `FOREIGN_BANK`, `BRIDGES` (road and rail; each rect plus a deck height).
- `AREAS`: ground areas that are not lots. For now only `village`: `Rect2(155, -75, 240, 370)`, ground `grass_dry`, condition `fading`. The church lot and the D plots lie inside it.
- Static helpers: `lot_center(id) -> Vector2` and `lot_rect(id) -> Rect2`.

Copy the coordinates from `district_layout_v3.svg`. Each lot `<rect>` there is a lot, and its small id label is the key. For reference, the main ones are below as x0, z0, x1, z1 (convert to `Rect2(x0, z0, x1 - x0, z1 - z0)`):

| Id | Type | x0, z0, x1, z1 | Content | Condition |
|---|---|---|---|---|
| `atp` | X | -430, -320, -290, -200 | `atp` | worked |
| `truck_stop` | X | -280, -320, -140, -200 | `truck_stop` | worked |
| `checkpoint` | X | -130, -320, 120, -200 | `checkpoint` | kept |
| `port` | X | 130, -320, 290, -200 | `port` | worked |
| `fuel_depot` | X | 300, -320, 395, -200 | `fuel_depot` | worked |
| `boiler` | X | -430, -170, -330, -95 | `boiler_house` | worked |
| `garages` | G | -320, -170, -30, -95 | `garages` | worked |
| `reserve` | R | 15, -170, 395, -95 | `wasteland` | abandoned |
| superblocks `a1`, `b1`, `a2`, `b2` | W ×4, K ×1 each | see below | `panel_5` / `panel_9`; K: `yard` | kept |
| `police` | G | 20, -75, 135, -30 | `police` | kept |
| `polyclinic` | G | 20, -20, 135, 40 | `polyclinic` | kept |
| `ispolkom` | G | 20, 50, 135, 135 | `ispolkom` | kept |
| `g_axis_1`, `g_axis_2` | G | 20, 145, 135, 200 / 20, 210, 135, 265 | `empty_lot` | kept |
| `church` | X | 245, 80, 305, 130 | `church` | fading |
| `g_south` | G | -430, 315, -230, 385 | `empty_lot` | worked |
| `market` | X | -215, 315, -30, 385 | `market` | worked |
| `station` | X | 15, 315, 230, 385 | `station` | worked |

**Superblocks.** Origins `(x0, z0)`: a1 (-430, -75), b1 (-220, -75), a2 (-430, 115), b2 (-220, 115). Each block is 200 × 180 with `cx = x0 + 100` and `cz = z0 + 90`:

- `<b>_n`: (cx-45, z0+2, cx+45, z0+26)
- `<b>_s`: (cx-45, z0+154, cx+45, z0+178)
- `<b>_w`: (x0+2, cz-45, x0+26, cz+45)
- `<b>_e`: (x0+174, cz-45, x0+198, cz+45)
- `<b>_k`: (cx-50, cz-40, cx+50, cz+40)

Mix `panel_5` and `panel_9` across the 16 W lots in a fixed pattern, roughly two thirds `panel_5`. Exception: `a2_k` gets content `wasteland`, because the week's "wasteland" location lives there ("a school was supposed to stand here").

**Village plots.** Inside the `village` area, define about 12 D lots, each 25–35 m wide and 35–45 m deep, at irregular offsets, like the green plots in the SVG. Give each a content key: `house_kept`, `house_poor`, or `house_abandoned`, about half kept. Dirt roads connect them to the street at x 140–150.

**Roads and rails.** Take them from the SVG:

- Highway: z -195..-180.
- Inner road: z -90..-80.
- South road: z 300..310.
- Axis: x -20..10, from the bridge (z -330) to the station (z 312).
- Village street: x 140..150.
- Yard roads (kind `yard`): z 105..115, x -230..-220.
- Passenger tracks: z 395 and 405, from x -450 to 410/420, curving north into the freight line.
- Freight line: x 410 and 420, from the rail bridge at z -405 to z 405.
- Port siding: from (410, -230) to (150, -245).
- Road bridge: x -12..2, z -405..-325.
- Rail bridge: x 405..425, same z range.
- River: z -400..-330. Foreign bank: north of it.

## Step 2: building catalog

Create `init/scripts/data/building_catalog.gd`: content key → how to build it.

- Fields: `footprint` (metres, centered in the lot unless stated), `floors` or `height`, `facade` (texture path or `""`), `facade_side`, `roof`, `placeholder_color`, `label` (Russian, shown only in the dev label mode below), and `dressing` (a list of props in **lot-local** coordinates, for example a bench at (-20, 8)).
- Facades follow "Facade assembly" in `art/DISTRICT_ART_REQUEST.md`. Storeys are 3 m, and no piece is ever stretched.
- Panel blocks: optional `entrance_base` and `stair` overlays.
  - An entrance is one 6 m column: `entrance_base` on the ground storey, `stair` stacked on every storey above (4× on five storeys, 8× on nine).
  - Place one entrance every 24 m along the long side named by `facing`.
  - Optional `ground_floor` replaces the ground-storey overlay of one chosen bay (shop, pharmacy, police point).
  - Nine-storey blocks use the nine-storey tile, never a stacked five-storey tile.
  - All overlays stay empty until their files exist.
- Unique buildings with a main entrance (school, police, polyclinic, ispolkom): `facade_center`, `facade_wing`, and both piece widths. The front wall is `[wing × k] [center] [wing × k]`, and the side and rear walls are wing tiles only. Set footprint lengths to exactly `center + 2·k·wing` and adjust the footprints given in this brief to the nearest such length. Until the art exists, the placeholder box uses the same footprint.
- Every content key used in `LOTS` must exist. Missing art means an empty `facade` and a plain box in `placeholder_color` at the right height.
- Map current art where it fits:
  - Panel facades and `_panel_block` → `panel_5` / `panel_9`.
  - Brick facade, chimney, coal heap → `boiler_house`.
  - `garage_single_v3` model (`garage_model.gd`) → `garages`.
  - Church sprite → `church`.
  - Fuel tanks → `fuel_depot`.
  - Market tents and kiosks → `market`.
  - Station sprite → `station`.
  - Border post sprite and barge → `checkpoint` / `port`.
  - Private house sprite → `house_*`.
  - Warehouse facade → `port`.
  - `ispolkom` is a late-Soviet modernist block: about 60 × 25 m footprint, five storeys (15 m), facing the axis with a paved square and the monument in front. Until `facade_ispolkom_front.png` / `facade_ispolkom_side.png` exist, use `facade_admin_stalinist` as a temporary texture, with the new file names as commented-out values.
  - `polyclinic` is a mid-size polyclinic, not a hospital: one block about 50 × 18 m, five storeys, with a small parking area. Placeholder until `facade_polyclinic.png` exists.
- Each new texture from `art/DISTRICT_ART_REQUEST.md` must slot in by filling one `facade` / `roof` field. Use the file names from that document as commented-out values so the swap is obvious.
- `condition` from the lot drives small, data-only differences:
  - `kept`: clean tint, no garbage piles.
  - `worked`: oil-stain ground patch if available, parked vehicles.
  - `fading` / `abandoned`: dry grass, garbage pile allowed.
  - Panel blocks must look **kept**: drop the rusty roof variant for them.

## Step 3: builder

- Create `init/scripts/map/district_builder.gd`, or a clearly separated section in `city_map.gd` if splitting costs too much. It reads `DistrictLayout` and `BuildingCatalog` and builds ground, roads, rails, water, bridges, lots, and dressing.
- `city_map.gd` keeps environment, weather, camera, tokens, overlays, pedestrians, traffic, and lot states. Delete the old hand-placed `_build_microdistrict`, `_build_boiler` placement, `_build_center`, `_build_old_center`, `_build_depot`, and `_build_south`. Port their useful details into catalog entries or dressing; do not keep two layouts.
- **Lot states** keep working. `boiler` keeps its `repairing` / `working` children: scaffolding, fence, and crane truck for `repairing`, chimney smoke for `working`. Build them relative to the boiler lot, not at fixed coordinates.
- **Overlays** (`block5:picket`, `boiler:truck`) are placed relative to their lot.
- Trees, bushes, lamps, and pedestrians: keep the existing random placement with a fixed seed, but generate candidates from lot and road geometry. For example, place trees inside K lots and along road edges, and keep them off `_occupied`.
- **Roads and rails are never covered by lot geometry.** Where they cross a lot, the lot's buildings and dressing keep clear of them:
  - The `checkpoint` lot straddles the axis road. Build it as lanes: booths and barriers between lanes, the customs office and inspection hangar beside the road, the truck holding area on the east side.
  - The port siding runs through `port` and `fuel_depot` along the quay.
  - Building footprints stay out of road and rail rects, and so do dressing props, except vehicles on roads.
- Remove the tram entirely. Keep buses, cars, and freight wagons, and put at least one commuter train standing at the station on the passenger track. Use `train_wagons_v2` until `train_commuter.png` exists.
- Add a dev toggle (key `F9`, off by default) that shows `label` and lot id above every lot as `Label3D`, so layout can be reviewed by eye.

## Step 4: game locations follow the layout

- In `week1.gd`, replace each `"pos"` with `"layout": "<lot id>"`:

  | Location | Lot |
  |---|---|
  | office | `ispolkom` |
  | block5 | `b1_s` |
  | boiler | `boiler` |
  | depot | `fuel_depot` |
  | church | `church` |
  | market | `market` |
  | wasteland | `a2_k` |

- Add one function that returns a location's map position from its layout lot, and use it everywhere `Week1.LOTS[...]["pos"]` is read today:
  - `city_map.gd`: `lot_screen_position`, `focus_on`, overlays, `_is_occupied`.
  - `week_sim.gd`: lines around 49, 157, 295.
- **Validation at startup:** every location's `layout` id exists in `DistrictLayout.LOTS`, and every lot's `content` exists in `BuildingCatalog`. Report failures with `push_error` naming the bad id.
- Do not change requests, events, texts, or balance in `week1.gd` beyond this reference change.

## Step 5: camera and travel time

- Update `BOUNDS`, `ZOOM_MAX`, and the default camera target so the whole district can be seen and the default view opens on the executive committee and the nearest superblock.
- Do **not** change actor speeds. The user wants the game slower, and a larger map does that through distance.
- Measure travel instead. Print a before/after table of straight-line game hours on foot (`me`) and by car (`tolik`) for office → block5, office → boiler, office → market, office → church, office → depot, and office → wasteland. "Before" uses the current `pos` values. Include it in your report.

## Check before reporting

1. Run `Godot --headless --path init --import` if any asset was added, then run the dev autoplay with screenshots (`AGENTS.md` has the command). Read the PNGs.
2. Confirm in the screenshots:
   - The river and both bridges.
   - The checkpoint on the axis.
   - Four superblocks with K lots in their centers.
   - Police nearest the highway and the executive committee two lots further south.
   - The village with dirt roads and the church.
   - Market and station side by side in the south.
   - Two passenger tracks and the freight line on the east edge.
   - No tram.
   - The picket overlay at block5 and the boiler states still appear when the autoplay reaches them.
3. Read the newest `_autoplay.jsonl` playtest log and confirm the week completes. Note the week summary's waiting time and contact utilization next to the previous autoplay log's numbers.
4. Report:
   - Files changed.
   - The travel table.
   - Screenshot paths.
   - Every place where you deviated from this brief, and why.

## Do not

- Commit, push, or edit `README.md`, `art/PROMPTS.md`, or `art/DISTRICT_ART_REQUEST.md`.
- Generate images or change events and balance.
- Add automated tests.
- Leave the old hand-placed layout code alongside the new one.
