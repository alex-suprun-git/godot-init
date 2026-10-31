# Image Prompts: First Week

Prompts for the art needed by the first playable week (the heating-season opening, see `README.md`). Written for an image generator; each prompt is self-contained.

## Direction

- The playable map is a 3D scene seen from above at an angle, built in Godot. The generator does not paint the map itself. It paints the **surfaces and props** that dress the 3D map: facade textures for simple building shapes and flat sprites for trees, cars, kiosks, and people.
- Everything shown in windows is 2D painted art: portraits, location scenes, and event illustrations.
- Mood reference for the city: `art/concepts/isometric-city-direction-v2.png`.
- Manner reference for window art: the finished portraits in `init/assets/portraits/` (painterly oil manner, warm textured background). New portraits, scenes, and events must match them.

## Status

| Item | Status |
|---|---|
| Portraits: Mikhalych, Baba Nina, Tolik, the boss | Done |
| Test batch for the 3D map (T1–T3) | Generated; awaiting review |
| W1 pipe burst (early October) | Done |
| W2 office | Next |
| Map kit (K1–K12) | Generated; awaiting review |
| Ground textures and road decals (G1–G8, D1–D2) | Generated; awaiting in-game visual review |
| Map sprites (M1–M29) | Generated; awaiting in-game visual review |
| Lada 3D pilot | V2 GLB integrated into street parking, the polyclinic and House 5 courtyard; replaces the Lada sprites. Source, previews and workflow: `art/models/lada/README.md`. |
| District building art batch (A1–A5, B5–B6, B19–B21) | Generated and connected; in-game review pending |
| Checkpoint booth sprite (B8) | Generated and connected |
| Seasonal tree variants and snow ground (S1–S4) | Generated; awaiting in-game visual review |
| True-isometric redraw request (R1–R3) | In progress: 4 sprites pass anchor checks; rejected drafts are in `art/concepts/redraw_attempts/` |
| Later window art (W3–W7) | After W2 |

## Established looks

Canonical appearance from the chosen portraits. Later variants of these characters (seasons, story changes) must keep these features.

- Protagonist (`protagonist.png`): man of about 26, short brown hair, clean-shaven, tired watchful eyes, grey suit, white shirt, narrow dark striped tie, cardboard folders; painted against a city view from a window.
- Mikhalych (`mikhalych.png`): heavy-set man around sixty, grey hair under a flat cap, large grey walrus moustache, ruddy face, grumpy sideways look, padded work jacket over a striped undershirt, rusty red pipe wrench on his shoulder.
- Tolik (`tolik.png`): lean, gaunt man in his forties, messy dark hair, light stubble, sly sideways glance, cigarette behind his ear, worn brown leather jacket over a checked shirt and knitted sweater, car keys in hand.
- Baba Nina (`baba_nina.png`): woman in her seventies, floral headscarf, glasses on a cord, brown knitted cardigan, floral dress, green notebook held to her chest.
- The boss (`boss.png`): heavy man in his early sixties, grey swept-back hair, heavy tired eyes, oversized grey suit, loosened burgundy striped tie.

## Rules

- Required preparation workflow: `art/ASSET_PIPELINE.md`. Save generated originals outside `init/`; after the applicable visual approval, run `uv run tools/optimize_asset.py` before saving/integrating the game copy. The paths in prompts below are final optimized destinations, not generation-output paths.

- The game starts in late August 1997, and every prompt states its month. Late August: summer greenery with the first yellow leaves. September: early autumn, mostly yellow trees. October: heavy leaf fall, half-bare trees, first cold. Keep foliage and clothing consistent with the stated month.
- Do not render readable text, signs, or UI inside images. Generators garble Cyrillic; labels are added in Godot.
- Save game-ready images to the exact path in each prompt, under `init/assets/` (Godot only sees `init/`). Save explorations and rejected variants to `art/concepts/`.
- If a result breaks a technical rule below, report it and retry; do not save it as a game asset.
- After each batch, list the saved files and note any that drifted from the style.

### Technical rules for textures (map surfaces)

- Strictly orthographic, viewed straight on, like an architectural elevation. No perspective, no vanishing points, no visible sides or roof.
- Flat, even, shadowless lighting. No cast shadows, no sun direction, no lit windows. The engine adds light, shadows, and night.
- The image is the surface only, edge to edge: no sky, no ground, no surroundings, no frame.
- When marked tileable, the left edge must continue seamlessly into the right edge.
- Square or 2:1 canvas as noted.

### Roof surfaces

Map buildings need visible material on every roof plane; do not leave broad top faces as a single flat color. Existing reusable surfaces are `init/assets/textures/roof_tar.png` for flat tarred roofs and `roof_rusty_metal.png` for corrugated metal roofs. New roof textures should be top-down, orthographic, tileable, and detailed at the scale of a building roof: seams, worn patches, drains, and a few vents are useful, while large standalone rooftop props should remain separate geometry.

### Technical rules for sprites (map props)

- One object, centered, whole, nothing cropped.
- Exact projection (the map camera is orthographic and true isometric; sprites that deviate float or tilt against the streets):
  - Orthographic, no perspective: parallel lines stay parallel, size does not depend on distance.
  - True isometric: the horizontal ground axes run at 30 degrees to the horizontal edge of the picture (a ground line rises or falls 0.577 pixels for every pixel of width). Vertical edges stay vertical.
  - The long side of a vehicle or building runs along one of those two axes, never straight across the picture. Draw it with the long axis rising to the right ("/"); the game mirrors it when a street runs the other way.
  - The footprint is a clean rhombus whose near corner touches the bottom of the picture; nothing but a thin margin below it.
  - Reference for the angle: `art/concepts/iso_projection_reference.png` (added with the next batch); until then match `train_wagons.png`, the closest existing sprite.
- Flat, even, shadowless lighting; no ground shadow.
- Transparent background. If transparency is not possible, a flat pure magenta (#FF00FF) background with no gradient, so it can be keyed out.
- No ground, no other objects around it.

## Shared style blocks

Map style block (textures and sprites):

> Painted illustration texture in the style of a detailed hand-painted 1990s post-Soviet provincial city: worn concrete, rusted metal, peeling paint, water stains, autumn grime. Muted realistic palette with warm accents. Rich surface detail without clutter.

Window style block (portraits, scenes, events):

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.

## T: Test batch for the 3D map

This batch decides whether the textured-3D approach works. Generate these three first and stop for review.

### T1. Facade texture: five-storey panel building

Path: `init/assets/textures/facade_panel_5storey.png`

> [Map style block] [Texture rules] Straight-on elevation of one repeatable section of a Khrushchev-era five-storey panel apartment building: grey concrete panels with visible seams, five rows of windows with wooden frames and mismatched curtains, three of them with glazed-in balconies of different colors, laundry on one balcony, a satellite dish, rust streaks under the window sills. Do not include a unique entrance door in this repeating texture; add the entrance as separate geometry in Godot. Tileable horizontally. 2:1 canvas, wider than tall.

### T2. Facade texture: red-brick boiler house wall

Path: `init/assets/textures/facade_boiler_brick.png`

> [Map style block] [Texture rules] Straight-on elevation of a repeatable section of the long wall of a 1960s red-brick industrial boiler house: weathered brick with darker repaired patches, tall arched windows with some broken panes, soot stains above the windows, a pipe running along the wall. Do not include a unique gate in this repeating texture; add the gate as separate geometry in Godot. Tileable horizontally. 2:1 canvas, wider than tall.

### T3. Sprite: autumn birch tree

Path: `init/assets/sprites/tree_birch_august.png`

> [Map style block] [Sprite rules] A single birch tree in late August: white trunk with black marks, full green foliage with the first few yellow leaves. Square canvas.

Later seasonal variants of the same tree (September, October, winter) go next to it as `tree_birch_september.png` and so on.

## W: Window art

### W1. Event: pipe burst at Block 5 (crisis)

Path: `init/assets/events/pipe_burst.png`

Done. Kept as the early October crisis at the first trial run of the heating system.

> [Window style block] Early October, heavy leaf fall. Eye-level scene. The basement entrance of a five-storey panel building, steam pouring out of the door into the cold autumn air, hot water flooding the courtyard, residents in coats and slippers arguing, an elderly woman shouting into the steam, a boy with a school backpack just staring. Urgent but darkly funny. Landscape 16:9.

### W2. Location: the aide's office

Path: `init/assets/locations/office.png`

> [Window style block] Late August. Eye-level interior. A cramped office in a district administration building: a desk with a heavy rotary phone, piles of paper and folders, a typewriter, a tea glass in a metal holder, a 1997 wall calendar open at August, green trees outside the window, a pale rectangle on the wall where a portrait used to hang, a padded door to the boss's office slightly ajar. Morning light through dusty blinds. Landscape 16:9.

### W3. Portrait: Gusev, businessman

Path: `init/assets/portraits/gusev.png`

> [Window style block] Bust portrait, three-quarter view, matching the framing, background, and manner of the portraits in `init/assets/portraits/`. A man in his late thirties, a new 1990s businessman: burgundy double-breasted jacket, gold chain, a brick-sized mobile phone, confident grin, a cheap expensive look. Portrait 3:4.

### W4. Event: envelope on the desk (offer)

Path: `init/assets/events/envelope.png`

> [Window style block] Late August. Close scene at eye level. Across the aide's desk, a businessman in a burgundy double-breasted jacket with a gold chain slides a thick envelope forward with two fingers, smiling. Only his hands, jacket, and smile are clearly visible; his eyes are in shadow. Landscape 16:9.

### W5. Event: picket at Block 5 (broken promise)

Path: `init/assets/events/picket.png`

> [Window style block] Early October, cold and grey, leaves falling. Eye-level scene. Residents of a five-storey building in coats stand in the courtyard with hand-painted placards (shapes only, no readable text), an elderly woman in front with her arms crossed, a few curious kids, a bored policeman leaning on a UAZ van. Grim weather, grim faces, a little absurd. Landscape 16:9.

### W6. Event: the rival on local TV

Path: `init/assets/events/rival_tv.png`

> [Window style block] A late August evening. An old CRT television in a living room shows a local news studio: a confident older party apparatchik in a dark suit with medal ribbons speaking into a microphone. In front of the TV, a tea glass and a plate of sunflower seeds. Landscape 16:9.

### W7. Location: Boiler House No. 3 yard

Path: `init/assets/locations/boiler_house.png`

> [Window style block] Late August, green trees with the first yellow leaves. Eye-level scene. The yard of a red-brick boiler house with one tall brick chimney, cold and smokeless; coal heaps, a rusty gate, broken windows, a sleepy watchman in a booth with a radio, two contractors in leather jackets arguing next to their cars. Landscape 16:9.

### W8. Portrait: the protagonist (prototype)

Done, saved as `init/assets/portraits/protagonist.png` (chosen variant).

Path: `init/assets/portraits/protagonist.png`

> [Window style block] Bust portrait, three-quarter view, matching the framing, background, and manner of the portraits in `init/assets/portraits/`. A man of 26, newly hired aide to a district head in late August 1997: clean-shaven, short practical haircut, attentive intelligent eyes, a cheap grey suit slightly too big at the shoulders, a white shirt, a narrow dark tie that is clearly his only one, a cardboard folder of papers under his arm. Expression neutral and watchful, neither naive nor cynical yet: the player decides who he becomes. Ordinary, believable face, not a model or a hero. Portrait 3:4.

## K: Map kit (after the test batch passes)

Same rules as the test batch. Facades are tileable horizontally unless noted.

| Id | Path | Content |
|---|---|---|
| K1 | `init/assets/textures/facade_admin_stalinist.png` | Front of a three-storey Stalinist administration building: columns, tall windows, a round state emblem without text, steps at the bottom. Not tileable. 2:1. |
| K2 | `init/assets/textures/facade_warehouse.png` | Long brick warehouse wall with loading gates and a metal canopy. 2:1. |
| K3 | `init/assets/textures/facade_merchant_house.png` | Two-storey 19th-century merchant house, plastered, with ornate window frames and a shop on the ground floor. 2:1. |
| K4 | `init/assets/textures/roof_tar.png` | Flat tar roof seen straight from above: patches, puddles, vents, an antenna. Tileable both ways. Square. |
| K5 | `init/assets/textures/roof_rusty_metal.png` | Pitched rusty metal roof sheet seen straight on. Tileable both ways. Square. |
| K6 | `init/assets/sprites/kiosk.png` | A 1990s street kiosk with a small window, cigarette and drink displays, a cheap awning. |
| K7 | `init/assets/sprites/market_tent.png` | A market stall tent with hanging clothes and a folding table. |
| K8 | `init/assets/sprites/car_lada.png` | A white Lada 2107 sedan. |
| K9 | `init/assets/sprites/car_volga_black.png` | The administration's black GAZ-24 Volga. |
| K10 | `init/assets/sprites/van_uaz_police.png` | A police UAZ van in grey-blue with a light bar. |
| K11 | `init/assets/sprites/scaffolding.png` | A section of wooden construction scaffolding with planks and a tarp. |
| K12 | `init/assets/sprites/tree_poplar_august.png` | A tall poplar tree in late August, green with the first yellow leaves. |

## G: Ground textures (grass, asphalt and the rest of the flat surfaces)

The map is a 3D scene, but the ground itself needs no 3D: these are flat tiles laid on the ground planes, so grass, roads, and paving get painted detail instead of one flat color. Same style as the facades.

Ground rules (all G items):

- Seen straight from above, orthographic, no perspective, no horizon.
- Seamless in both directions: left edge continues into the right edge, top into bottom.
- Flat, even, shadowless light, no directional sun, no objects casting shadows. The engine adds light.
- Fine, evenly distributed detail; no single large feature (a puddle, a manhole) that would visibly repeat. Tiny details are fine.
- Square canvas, as high resolution as possible. Map style block applies, late August.

| Id | Path | Content |
|---|---|---|
| G1 | `init/assets/textures/ground_grass.png` | Late-August lawn and weeds: tired green grass with yellowing patches, dry stalks, clover, small bare earth spots, a few fallen leaves. |
| G2 | `init/assets/textures/ground_grass_dry.png` | The same grass but drier and patchier with more bare earth and gravel, for wasteland edges and under trees. |
| G3 | `init/assets/textures/ground_asphalt.png` | Worn 1990s asphalt: grey-black, a network of fine cracks, patched repairs of darker tar, a few potholes' edges, sand and dust at the margins. No road markings. |
| G4 | `init/assets/textures/ground_paving.png` | Concrete slab paving of a square or sidewalk: big grey slabs with seams, weeds growing in the joints, stains. |
| G5 | `init/assets/textures/ground_dirt.png` | Packed dirt and gravel with sparse weeds, tyre tracks: wasteland and courtyards. |
| G6 | `init/assets/textures/ground_water.png` | River water seen from above: dark grey-blue, slow ripples, faint reflections, no foam, no boats. |
| G7 | `init/assets/textures/ground_rail.png` | Railway bed, tileable along one axis only: ballast gravel, wooden sleepers, two steel rails, rusty and weedy. |
| G8 | `init/assets/textures/ground_courtyard.png` | A residential courtyard: patchy lawn mixed with trodden paths and dirt, a few cigarette-butt-sized details, no large objects. |

Road markings are separate transparent decals, standing sprites rules do not apply (seen from above, transparent background, one item per image):

| Id | Path | Content |
|---|---|---|
| D1 | `init/assets/sprites/decal_center_line.png` | A worn white dashed center line, 5 dashes, horizontal. |
| D2 | `init/assets/sprites/decal_crosswalk.png` | A worn zebra crossing, horizontal. |

## M: Missing map sprites

What the map still builds from plain boxes or leaves empty. Sprite rules apply; set each in late August unless the note says otherwise. Priority first.

### P1: visible in the first week right now

| Id | Path | Content |
|---|---|---|
| M1 | `init/assets/sprites/person_walk_man.png` | A man in a grey jacket walking with a bag. |
| M2 | `init/assets/sprites/person_walk_woman.png` | A woman in a coat with a shopping bag. |
| M3 | `init/assets/sprites/person_pensioner.png` | An elderly woman in a headscarf with a cane. |
| M4 | `init/assets/sprites/person_worker.png` | A worker in a padded jacket carrying a pipe. |
| M5 | `init/assets/sprites/person_kid.png` | A schoolchild with a backpack. |
| M6 | `init/assets/sprites/picket_group.png` | A group of eight residents in coats holding hand-painted placards (shapes only, no readable text), seen as one sprite. Used for the picket at Block 5. |
| M7 | `init/assets/sprites/truck_zil_plain.png` | A ZIL truck with a green tarpaulin, no license plates, loaded with coal. Used for the coal theft. |
| M8 | `init/assets/sprites/church.png` | The whole small church with a green dome and gilded cross, whitewashed, seen at the map camera angle. |
| M9 | `init/assets/sprites/fuel_tanks.png` | Three white cylindrical fuel tanks with a pipe manifold and ladders. |
| M10 | `init/assets/sprites/boiler_chimney.png` | A tall brick boiler chimney with a metal ladder, no smoke. |
| M11 | `init/assets/sprites/coal_heap.png` | A heap of black coal with a front loader's tracks. |
| M12 | `init/assets/sprites/crane_truck.png` | A repair crane truck with an orange cab. For the boiler house under repair. |

### P2: soon

| Id | Path | Content |
|---|---|---|
| M13 | `init/assets/sprites/private_house.png` | A private house with a pitched slate roof, a wooden fence and a vegetable garden. |
| M14 | `init/assets/sprites/garages_row.png` | A row of eight metal garages in different faded colors. |
| M15 | `init/assets/sprites/lamp_post.png` | A concrete street lamp with a cobra head. |
| M16 | `init/assets/sprites/power_pole.png` | A concrete power pole with crossbars and wires. |
| M17 | `init/assets/sprites/bench_playground.png` | A bench with a rusty playground (swing and slide) behind it. |
| M18 | `init/assets/sprites/bus_stop.png` | A concrete bus stop shelter with a bench. |
| M19 | `init/assets/sprites/bus_liaz.png` | A cream-and-red LiAZ city bus. |
| M20 | `init/assets/sprites/tram.png` | A cream-and-red tram car. |
| M21 | `init/assets/sprites/fence_chainlink.png` | A section of chain-link fence with concrete posts. |
| M22 | `init/assets/sprites/monument.png` | A statue of a figure on a stepped granite pedestal. |
| M23 | `init/assets/sprites/border_post.png` | A border checkpoint booth with a red-and-white barrier and a watchtower. |
| M24 | `init/assets/sprites/train_wagons.png` | Three freight wagons in rust brown on a siding. |
| M25 | `init/assets/sprites/station.png` | A small provincial railway station building in pale yellow with a clock. |
| M26 | `init/assets/sprites/barge.png` | A river barge with a crane, moored at a pier. |
| M27 | `init/assets/sprites/garbage_pile.png` | A pile of garbage and an overturned container. |
| M28 | `init/assets/sprites/bush.png` | A shrub in late August. |
| M29 | `init/assets/sprites/water_tower.png` | A brick water tower in the distance. |

### Seasonal variants (when the story reaches them)

| Id | Path | Content |
|---|---|---|
| S1 | `init/assets/sprites/tree_birch_september.png` and `tree_poplar_september.png` | The same trees in September: mostly yellow. |
| S2 | `init/assets/sprites/tree_birch_october.png` and `tree_poplar_october.png` | October: half bare, orange and brown leaves. |
| S3 | `init/assets/sprites/tree_birch_winter.png` and `tree_poplar_winter.png` | Winter: bare, snow on the branches. |
| S4 | `init/assets/textures/ground_snow_*.png` | Snow versions of the ground tiles G1 to G5. |

## R: Redraw list for the true isometric projection

The full request for Codex, with prompts per object and the slope check, is `art/REDRAW_REQUEST.md`. Projection reference: `art/concepts/iso_projection_reference.png`. Wagons and the barge were first judged close enough by their numbers, but wagons look crooked beside the rail in the map, so wagons are redrawn too.

Measured with `scripts/dev/measure_sprite_anchors.gd` (slope of the ground edge; the true isometric camera needs 0.577). The first group sits flatter than the camera and shows it next to a street; the second is close enough to keep for now.

| Redraw first (slope well below 0.577) | Slope |
|---|---|
| `garages_row`, `fence_chainlink` | 0.30 and 0.39 |
| `bus_liaz`, `tram`, `bus_stop` | 0.37, 0.36 and 0.28 |
| `car_lada`, `car_volga_black`, `van_uaz_police`, `truck_zil_plain`, `crane_truck` | 0.30 to 0.34 |
| `station`, `private_house`, `market_tent`, `bench_playground`, `kiosk` | 0.1 to 0.26 (nearly front-on) |

| Keep (close to the camera) | Slope |
|---|---|
| `train_wagons`, `barge` | 0.53 and 0.49 |
| trees, `church`, `fuel_tanks`, `boiler_chimney`, `water_tower`, `monument`, people | upright objects, no long axis |

### R redraw attempt log (2026-10-30)

The first generated batch did not meet the projection rules consistently. Only these new sprites are currently kept under `init/assets/sprites/`; slopes are from `measure_sprite_anchors.gd`:

| File | Slope | Check |
|---|---:|---|
| `garages_row_v2.png` | -0.52 | Pass |
| `train_wagons_v2.png` | -0.53 | Pass after one projection correction |
| `bus_stop_v2.png` | -0.55 | Pass; compact footprint reported as `foot` |
| `carpet_beater_v2.png` | -0.63 | Pass; compact footprint reported as `foot` |

These four sprites were connected to the playable map in the first integration pass. Both freight trains, the bus shelter and the courtyard carpet-beating frames still use these versions; the garage row has since been superseded by eight dimensioned 3D bays using `garage_single_v3.png` (see the proportion pass below).

Renderer correction (2026-10-31): a passing silhouette slope alone does not establish correct projection. Long props, the station, and market tents now use `scripts/map/grounded_props.gd`: both source ground axes are mapped to the orthographic camera axes, and a strip mesh maps the opaque bottom contour onto the ground. This avoids terrain cutting through the lower half of a billboard. Station and tent axes are calibrated from their structural edges; station and market rows follow the railway's X direction. PNG files remain unchanged. Graphical close-ups are required when changing this calibration; inspect wheels, both footprint axes, vertical edges, mirrored lighting, and intersections with neighboring buildings.

Other generated sprite drafts failed the requested slope or visual projection check and are kept in `art/concepts/redraw_attempts/`, not as game assets. The three facade drafts have the requested 1774×887 dimensions, but their left/right edge mismatch is still visible and they are not considered tileable. The three redraw batches remain incomplete pending corrected images.

## Not generated here

- The 3D geometry of the map, lighting, smoke, fire, weather, and day and night: built in Godot.
- Request icons (plea, conflict, crisis, offer, promise) and UI panels: built in Godot or as SVG.
- Map tokens for people: cropped from the portraits in Godot.

## Proportion pass V3 (2026-10-31)

Built-in image generation produced the following new assets. The garage image is mapped onto a dimensioned 3D bay, not displayed as a billboard. The two cars use source-axis calibration and a separate vertical factor in `scripts/data/prop_dimensions.gd`. Raw silhouette slopes are -0.33 (Lada), -0.32 (Volga), and +0.27 (single garage); these numbers are not accepted as proof of correct source projection. The final game geometry and the visual reference scene are the acceptance reference.

- `init/assets/sprites/garage_single_v3.png`: new single-bay material. Model dimensions are 3.2 × 6 m, eaves 2.5 m, ridge 2.9 m. Eight bays are assembled in Godot.
- `init/assets/sprites/car_lada_v3.png`: new white Lada; width and vertical correction are calibrated alongside a 1.8 m adult and garage door.
- `init/assets/sprites/car_volga_black_v3.png`: new black Volga, calibrated alongside the Lada.

Full generation prompts, with `art/concepts/iso_projection_reference.png` as projection reference and transparent output requested:

### Garage single V3

> Game asset, one isolated SINGLE Soviet metal car garage, hand-painted detailed muted late-August 1997 provincial post-Soviet city style. Realistic proportions based on an engineering box: footprint 3.2 metres across the front by 6 metres deep, vertical walls 2.5 metres high, shallow pitched roof ridge only 2.9 metres high. One rusty faded sage-green metal double door 2.5 metres wide and 2.2 metres high on the narrow FRONT face. Important: NOT a tall warehouse, NOT multiple garages. Strict orthographic true isometric parallel projection matching attached ground-axis reference; both ground axes exactly 30 degrees and verticals stay vertical. Door face faces lower right, long side wall faces lower left; the width across the doors rises right; all parallel edges stay parallel, no vanishing points. Transparent background, whole object uncropped, no ground or weeds, no cast shadow, no people, no text or watermark. Show enough fine rust and worn corrugation to match painted city props, flat even illumination.

### Lada V3

> One transparent game sprite of a worn white Lada 2107 sedan for a hand-painted 1997 post-Soviet provincial city. Exact orthographic true isometric camera, no perspective: both ground axes 30 degrees as reference, parallel edges stay parallel, verticals vertical. Car dimensions 4.1m long, 1.7m wide, 1.45m high, wheel diameter 0.57m. Long low sedan with small normal-size wheels, NOT a tall toy car. Long body axis rises right, front short end lower left, broad side faces lower right. Use an engineering axonometric car-body box before painting: equal-size front and rear wheels, parallel rocker panels and roof edges, no lens distortion or taper. Muted realistic hand-painted worn finish, soft even light, late August. One whole car uncropped on transparent background, no ground, cast shadow, props, labels, license plate text, watermark.

### Volga V3

> One isolated transparent sprite of a clean black GAZ-24 Volga sedan, for a detailed hand-painted 1997 post-Soviet city map. Engineering proportions: length4.7m width1.8m height1.5m, wheel diameter0.65m. Strict orthographic true isometric matching attached reference, both ground axes exactly30degrees, verticals vertical, parallel edges remain parallel, equal-size front/rear wheels. Long axis rises right, broad side faces lower right, short front end faces lower left. Long low dignified sedan; no photographic lens perspective, no exaggerated tall cabin or huge wheels. Muted realistic painted finish, subdued chrome, flat even lighting, late August. Whole car uncropped, transparent background, no ground, no cast shadow, no people, labels, readable plates, text or watermark.

Manual calibration scene: `init/scenes/dev/scale_reference.tscn` (F6). It places the actual game assets on a 1 m grid with a 1.8 m pole and a 2.2 m door reference. People, station, market stalls, bus shelter, bus and tram were recalibrated in this pass. The executive committee and historic centre were enlarged following the creative direction recorded in README.md; the church was enlarged by one third.

Road paint follow-up: the map no longer consumes `decal_center_line.png` or `decal_crosswalk.png` as stretched image patches. Individual dashes and zebra bars use world dimensions and `init/assets/shaders/road_paint.gdshader` for sparse wear; widths and placement are owned by `city_map.gd`. Existing generated decal images are retained as prior art.

## District building facade batch (2026-10-31)

Generated with the built-in ImageGen tool. These are flat facade textures for the existing dimensioned building meshes, not isometric billboards. All files are 2:1 architectural elevations; facades are wired in `scripts/data/building_catalog.gd`. The nine-storey facade's top ceramic strip was edited twice to remove pseudo-writing and replace it with plain geometry. In-game seam and close-range review is still required before treating the textures as final art.

| File | Size | Use |
|---|---:|---|
| `init/assets/textures/facade_panel_late_9storey.png` | 1774×887 | A1, 54×27 m, nine storeys |
| `init/assets/textures/facade_panel_late_5storey.png` | 1768×889 | A2, 30×15 m, five storeys |
| `init/assets/textures/facade_ispolkom_front.png` | 1774×887 | B19, 30×15 m principal facade |
| `init/assets/textures/facade_ispolkom_side.png` | 1774×887 | B20, 30×15 m side/rear tile |
| `init/assets/textures/facade_panel_entrance.png` | 1774×887 | A3, 6×3 m entrance bay overlay |
| `init/assets/textures/facade_panel_stair.png` | 1774×887 | A3b, 6×3 m repeatable stairwell overlay |
| `init/assets/textures/facade_police_front.png` | 1774×887 | B5, 12×6 m main police facade |
| `init/assets/textures/facade_police_side.png` | 1774×887 | B5, 12×6 m police side tile |
| `init/assets/textures/facade_polyclinic.png` | 1774×887 | B6, 30×15 m polyclinic wall tile |
| `init/assets/textures/facade_polyclinic_entrance.png` | 1774×887 | B21, 30×15 m polyclinic main facade |
| `init/assets/textures/facade_panel_groundfloor_shop.png` | 1774×887 | A4, 6×3 m shop bay overlay |
| `init/assets/textures/roof_panel_flat.png` | 1254×1254 | A5, 12×12 m panel roof tile |
| `init/assets/sprites/checkpoint_booth.png` | 1344×1344 | B8, 3×3 m lane-island booth sprite |

### A1 — nine-storey panel facade

> Create one repeatable, perfectly front-facing orthographic elevation section of a late-1980s nine-storey Soviet panel apartment block in a fictional provincial border city, August 1997. Wide 2:1 landscape. The facade fills the image edge to edge. Exactly nine equal storeys: tidy pale grey and warm cream precast concrete panels, regular slab seams, repeated modest apartment windows and narrow loggias. A few loggias have mismatched glazing or curtains added by residents. Simple ceramic tile band under roofline. Detailed hand-painted architectural texture, inhabited and maintained but lightly weathered, subtle water stains, restrained muted blue-green glazing. Flat diffuse lighting, no shadows. This is a seamless tileable surface: left and right edges must join exactly, with consistent window and seam rhythm. Intended to repeat horizontally on a 54m by 27m wall. Facade only: no sides, perspective, roof plane, ground, sky, surroundings, frame, entrance doors, stairwell window columns, signs, text, logos, watermark, lit windows, deep shadows, dramatic contrast, heavy rust, or deep balconies. Keep flat window rhythm on all floors including ground floor.

Refinement 1: remove every glyph, letter-like mark and pseudo-text from the top ceramic band, replacing it with plain muted teal and cream geometric tiles; preserve the rest and edge rhythm.

Refinement 2: replace plus/cross motifs in the band with abstract cream and muted teal rectangles and diamonds, with no symbol resembling a cross, emblem, letter or number; preserve the facade below and matching edge pattern.

### A2 — five-storey panel facade

> Create one repeatable, perfectly front-facing orthographic elevation section of a late-1980s five-storey Soviet panel apartment block in the same residential estate series as a nine-storey building: pale grey and warm cream precast concrete panels, tidy regular slab seams, repeated modest apartment windows and narrow loggias, a few resident-glazed loggias with muted blue-green glass, lightly weathered concrete, a narrow restrained teal-and-cream geometric ceramic tile band at the roofline. Exactly five equal storeys with windows on every floor, including ground floor. Detailed hand-painted architectural texture, inhabited and maintained but lightly weathered, matching the late-Soviet panel facade palette. Wide 2:1 landscape, fill image edge to edge, seamless tileable left-to-right with matching wall, window and slab rhythms at both edges. Intended repeat tile: 30m wide by 15m tall. Flat diffuse light, no cast shadows. Facade only: no sides, perspective, roof plane, ground, sky, surroundings, frame, entrance doors, stairwell window columns, signs, text, letters, numbers, logos, crosses, or watermark. Avoid dramatic contrast, excessive rust, deep balconies, and any roof or signage.

### B19 — executive committee front

> Create a perfectly straight-on, orthographic architectural elevation of the principal facade of a late-Soviet district executive committee (райисполком), built in a fictional provincial border city in 1987 and seen in August 1997. Wide 2:1 landscape canvas, representing a 30-metre-wide by 15-metre-high wall. A restrained four-to-five-storey modernist civic building, long horizontal bands of dark reflective windows separated by light concrete or pale limestone spandrels, evenly spaced structural piers, broad glazed ground-floor lobby centered beneath a projecting flat concrete canopy on slim columns, broad shallow entrance steps integrated at the base. Above the canopy, a small blank circular state medallion with abstract laurel relief but no writing or recognizable real-world insignia. Two simple metal flagpole brackets near the roofline, no flags. Late-1980s Soviet provincial public architecture: formal, functional, maintained, a little weathered at edges, not imperial or neoclassical. Detailed hand-painted architectural texture consistent with a muted realistic 1990s post-Soviet game world. Flat diffuse lighting with no cast shadows. Surface only fills the image: no visible side walls, perspective, roof plane, ground, sky, surroundings, frame, readable text, letters, numbers, emblems with writing, logos, watermark, people, cars, trees, or signs. Avoid columns across the upper floors, ornate classical capitals, baroque or Stalinist decoration, extreme decay, and dramatic contrast.

### B20 — executive committee side/rear tile

> Create a perfectly straight-on orthographic elevation of the side/rear wall of the same late-Soviet district executive committee building as its main facade: a 1987 provincial modernist civic building in a fictional border city, seen in August 1997. Wide 2:1 landscape texture, representing a 30-metre-wide by 15-metre-high repeated wall tile. Exactly five equal storeys, with long horizontal dark window bands separated by pale concrete or limestone spandrels, evenly spaced structural piers, matching the material, window frames and subdued tone of a polished but slightly weathered late-1980s municipal building. Main entrance is not visible on this side; no canopy, no steps, no medallion, no flag brackets. Flat diffuse shadowless lighting. Tileable seamlessly left-to-right with matching wall, pier, window and floor rhythm at both edges. Facade only fills canvas edge to edge: no perspective, sides, roof plane, ground, sky, surroundings, frame, text, letters, logos, emblems, watermark, people, cars, or signs. Avoid classical ornament, columns, dramatic contrast and heavy decay.

### A3 — apartment entrance base

> Paint a straight-on orthographic 6-metre-wide by 3-metre-high ground-floor entrance bay for a late-1980s Soviet panel apartment block, matching a worn but inhabited August 1997 provincial residential estate. Pale grey and warm cream precast concrete wall panels with slab seams. Center a modest dark metal apartment entrance door beneath a shallow concrete canopy; low concrete steps; one small side window and a simple wall-mounted entrance lamp. Ordinary and lightly weathered, muted concrete tones with a rusty handrail. Flat diffuse shadowless light. Exact 2:1 horizontal surface fills the canvas edge-to-edge, no perspective or visible sides, no people, ground, sky, other buildings, signs, readable text, numbers, logos or watermark. Entrance centered and recognizable at map scale.

### A3b — stairwell storey overlay

> Paint one 6-metre-wide by 3-metre-high storey of the stairwell column of the same late-1980s Soviet panel apartment block: pale grey and warm cream precast concrete wall panels, subtle seams matching the facade, one narrow stairwell landing window set slightly above the centre line, muted dark blue-grey glass with a faint interior landing silhouette, no glowing light. Worn but inhabited August 1997 provincial estate, restrained weathering and muted colors. Straight-on orthographic surface, flat even shadowless light, no perspective. This exact texture will be stacked vertically, so top and bottom edges continue seamlessly in panel color, seams and wall detail. Wide 2:1 horizontal canvas, fills image edge to edge. No door, canopy, steps, signs, text, logos, watermark, people, ground, sky or surrounding building. Keep the window readable at small map scale.

### B5 — district police department front

> Create a straight-on orthographic 2:1 architectural elevation texture for a small two-storey district police department in a fictional provincial town in August 1997. Exact nominal surface 12m wide by 6m tall. Late-Soviet utilitarian building, maintained but worn: reddish-brown brick or faded beige render, regular dark-framed windows, barred ground-floor windows, a heavy centered entrance door reached by a few concrete steps, small lamp over the door, a blank round state medallion without writing or recognizable insignia. Restrained, believable, slightly stern civic architecture; hand-painted detailed surface, muted realistic 1990s palette. Flat diffuse light, no shadows, no perspective. Facade fills the entire image. No visible side, roof, ground, sky, surroundings, people, vehicles, flags, readable text, letters, numbers, logos or watermark. Avoid grand columns, palace-like ornament, modern glass architecture and dramatic decay.

### B5 — district police department side tile

> Straight-on orthographic 2:1 surface, one 12m by 6m two-storey module of the same late-Soviet district police department. Restrained red-brown brick and faded beige render wall, matching dark metal window frames and concrete trim; two floors of ordinary rectangular windows, with bars on the ground-floor windows. No entrance, steps, medallion or lamp. Maintained but worn provincial municipal building in August 1997, hand-painted realistic texture. Left/right edges repeat seamlessly with matching brick courses and window spacing. Flat diffuse shadowless lighting. Surface fills edge-to-edge, no perspective, roof, ground, sky, surroundings, people, cars, text, logos or watermark.

### B6 — polyclinic wall tile

> Create a straight-on orthographic 30-metre-wide by 15-metre-high elevation of one repeatable section of a five-storey district polyclinic in a fictional provincial town in August 1997. Late-Soviet white and pale sage-grey panel construction, five regular storeys with evenly spaced rectangular windows, visible slab seams, a modest red medical cross on a small blank panel near one edge (symbol only, no text), clean and maintained but slightly weathered. Muted believable 1990s public healthcare building, not a modern glass hospital. Detailed hand-painted architectural surface, flat diffuse shadowless lighting. Wide 2:1 image fills canvas edge-to-edge and tiles left-to-right with matching panel and floor rhythm. No visible sides, roof, ground, sky, surroundings, entrance door, canopy, people, vehicles, readable text, letters, numbers, logos or watermark. Avoid modern glass curtain walls, bright colors, grand columns or excessive decay.

### B21 — polyclinic principal facade

> Create a straight-on orthographic 2:1 facade texture for the front of a five-storey late-Soviet district polyclinic, 30 metres wide by 15 metres high, in a fictional provincial town in August 1997. Same pale grey and light sage-grey panel system, regular window grid, visible slab seams, and muted frames as a practical 1980s public clinic. At the ground-floor center, a wide modest glazed entrance hall with double doors beneath a flat concrete canopy, a few low steps, and one small red medical cross symbol above the entrance (symbol only). Windows and materials continue in the same rhythm above. Maintained and clean but not pristine, hand-painted architectural surface, flat diffuse shadowless lighting. Image fills edge-to-edge, no perspective, visible side, roof plane, ground, sky, surroundings, people, cars, readable text, letters, numbers, logo or watermark. Avoid modern hospital glass curtain walls, bright colors, grand columns or excessive dirt.

### A4 — panel-building ground-floor shop overlay

> Create a straight-on orthographic 2:1 surface for one 6m-wide by 3m-high ground-floor bay of an occupied late-1980s Soviet panel apartment block, August 1997. Match pale grey and cream precast panels and worn seams of its residential facade. A small ordinary neighborhood shop or service office: modest metal door, two broad barred display windows, shallow faded muted teal awning, a couple of empty window shelves, no readable goods labels. Practical, slightly improvised and lived-in. Flat diffuse shadowless light. Image fills edge-to-edge, no perspective, visible side, full building, ground, sky, surroundings, people, cars, text, letters, numbers, logos or watermark. Keep useful at 6m by 3m scale and avoid vivid modern retail styling.

### A5 — panel-building flat roof

> Create a square top-down orthographic texture of a flat tarred roof on a late-Soviet apartment block, August 1997. Dark charcoal bitumen, roofing seams, a few small rectangular ventilation caps and a simple antenna base spread naturally, patches of lighter repair tar, subtle grit and faded water stains. Muted realistic hand-painted texture matching a 1990s provincial Soviet city. Entire image is just the roof surface, flat even lighting, no shadows, sky, horizon, surrounding buildings, large rooftop machinery, people, text, numbers, labels, logos or watermark. Tileable seamlessly in both horizontal and vertical directions, with no conspicuous object cut off at an edge. Intended repeat size 12 by 12 metres.

### B8 — checkpoint control booth

> One small 1990s Soviet border checkpoint control booth, exactly 3m by 3m footprint and 3m high. Compact square booth with cream-gray prefab walls, large dark wraparound inspection windows on all visible sides, faded green lower paneling, a flat shallow metal roof, one small red-and-white striped corner post. It stands between truck lanes in a fictional provincial border post in August 1997. Detailed hand-painted muted realistic provincial post-Soviet style, flat even light. Strict orthographic true isometric parallel projection: ground axes at exactly 30 degrees to horizontal, no perspective; vertical edges stay vertical. Show the booth's broad front side facing the lower right and its short side facing the lower left. Square rhombus footprint, nearest ground corner at the bottom center with minimal transparent margin. One object only, completely visible, centered. Transparent background, no ground plane, cast shadow, other objects, people, text, logos or watermark. Avoid skewed shallow angles, vanishing points, cropped roof, exaggerated tallness, or a base pedestal.

## Transport, port and village pass (2026-10-31)

Built-in ImageGen produced `facade_bus_garage.png`, `facade_roadside_cafe.png`, `facade_customs_office.png`, `facade_inspection_hangar.png`, `portal_crane.png`, `shipping_containers.png`, and `village_house_kept.png`, `village_house_poor.png`, `village_house_abandoned.png`. These are connected through `building_catalog.gd`. The station draft is retained as `art/concepts/station_candidate.png`: it has a background and is not game-ready.

Facade prompts: straight-on orthographic seamless horizontal facades in a detailed hand-painted, muted post-Soviet provincial style, August 1997, flat diffuse light, no perspective, sky, ground, people, signs, text or logos. Subjects: 16×8 m brick and corrugated-metal bus depot repair hangar with bus gates; 8×4 m faded rendered roadside cafe with curtained windows and metal canopy; 12×6 m two-storey pale rendered customs office with window blinds; 14×7 m grey corrugated-metal customs inspection hangar with truck gates.

Sprite prompts: single isolated sprite, transparent background, no ground, shadow, text or people; detailed hand-painted muted 1997 post-Soviet provincial style; strict orthographic isometric with ground axes at 30 degrees and vertical edges vertical. Subjects: steel portal crane with raised lattice boom; three stacked faded 6 m shipping containers; kept painted wooden village house with carved window frames and slate roof; poor brick-and-wood house with patched roof and lean-to; abandoned boarded house with collapsing roof; pale-yellow provincial station with green roof and central portico (concept only).

## Residential courtyard concept — October 31, 2026

- `art/concepts/residential-courtyard-direction-v1.png`: built-in image_gen paintover of the compacted House 5 courtyard. The old city reference is used for mood only; current district geometry and late-Soviet housing are the subject.
- Full prompt: `art/concepts/residential-courtyard-direction-v1.prompt.md`.
- Status: proposed visual direction, awaiting user feedback. This is concept art, not achieved engine quality; generated details and floor counts need checking during implementation.

Village details: built-in ImageGen produced `village_shed.png` and `village_well.png`, connected to house lots. Prompts requested isolated transparent sprites in muted hand-painted 1997 provincial style, strict orthographic isometric, no ground, shadow or text: a small wooden shed and outhouse with slate roofs; and an old wooden well with a pitched roof, bucket and crank. A 10 m worn picket fence draft and an edited station draft retained backgrounds and remain concepts rather than game assets.

## District concept series — October 31, 2026

The user strongly liked the residential courtyard concept and requested the same direction for other places. Five built-in image_gen concepts use current game screenshots for layout and `residential-courtyard-direction-v1.png` for style:

- `art/concepts/forest-direction-v1.png`
- `art/concepts/village-direction-v1.png`
- `art/concepts/boiler-direction-v1.png`
- `art/concepts/administration-direction-v1.png`
- `art/concepts/border-direction-v1.png`

Full prompts: `art/concepts/district-concept-series-v1.prompts.md`. Status: awaiting user feedback; not in-engine screenshots. Architectural details, floor counts, entrance orientation and traffic routes must be checked against the current layout during implementation.

Transport follow-up: built-in ImageGen produced `art/concepts/bus_paz_candidate_2.png` and `art/concepts/truck_kamaz_candidate_2.png`; both retained an opaque background and remain concepts. Prompts asked for isolated transparent sprites in muted hand-painted 1997 post-Soviet style, orthographic isometric with long axis rising right 30 degrees: a cream-and-red PAZ bus and an olive KamAZ tractor with covered semi-trailer. A subsequent background-removal attempt also retained the backgrounds. The station platform canopy is instead assembled as dimensioned 3D concrete geometry in `district_builder.gd`.

### Transport integration and alpha correction (2026-10-31)

The previous claims that the transport/station drafts had an opaque background were incorrect: they were judged from the preview without reading the alpha channel. The selected bus, truck and station PNGs contain real transparent pixels (sampled transparent fractions 0.429, 0.588 and 0.604). Their painted RGB preview background is not evidence that those pixels are opaque.

Selected built-in ImageGen outputs are now saved and connected:
- `init/assets/sprites/bus_local_1997.png` (from `bus_paz_candidate_2.png`): two ATP buses and the bus-terminal bus. The generated appearance is a generic local bus, not a certified PAZ model.
- `init/assets/sprites/truck_kamaz_semi.png` (from `truck_kamaz_candidate_2.png`): two truck-stop and two checkpoint semis.
- `init/assets/sprites/station_v3.png` (from `station_candidate.png`): station building, with its own source-axis calibration.

Vehicle dimensions and source-axis correction are in `prop_dimensions.gd`; the bus's positive source long-axis direction is handled explicitly by the existing sprite renderer. Original and concept files are preserved. The dimensioned 3D platform canopy remains in use. Anchor metadata was regenerated and a graphical scene inspection was performed.
