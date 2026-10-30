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
| Later window art (W3–W7) | After W2 |

## Established looks

Canonical appearance from the chosen portraits. Later variants of these characters (seasons, story changes) must keep these features.

- Protagonist (`protagonist.png`): man of about 26, short brown hair, clean-shaven, tired watchful eyes, grey suit, white shirt, narrow dark striped tie, cardboard folders; painted against a city view from a window.
- Mikhalych (`mikhalych.png`): heavy-set man around sixty, grey hair under a flat cap, large grey walrus moustache, ruddy face, grumpy sideways look, padded work jacket over a striped undershirt, rusty red pipe wrench on his shoulder.
- Tolik (`tolik.png`): lean, gaunt man in his forties, messy dark hair, light stubble, sly sideways glance, cigarette behind his ear, worn brown leather jacket over a checked shirt and knitted sweater, car keys in hand.
- Baba Nina (`baba_nina.png`): woman in her seventies, floral headscarf, glasses on a cord, brown knitted cardigan, floral dress, green notebook held to her chest.
- The boss (`boss.png`): heavy man in his early sixties, grey swept-back hair, heavy tired eyes, oversized grey suit, loosened burgundy striped tie.

## Rules

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

### Technical rules for sprites (map props)

- One object, centered, whole, nothing cropped.
- Viewed from above at about 45 degrees, matching the map camera. All sprites in the set use the same angle.
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

## Not generated here

- The 3D geometry of the map, lighting, smoke, fire, weather, and day and night: built in Godot.
- Request icons (plea, conflict, crisis, offer, promise) and UI panels: built in Godot or as SVG.
- Map tokens for people: cropped from the portraits in Godot.
