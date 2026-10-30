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
| Test batch for the 3D map (T1–T3) | Next |
| W1 pipe burst (early October) | Done |
| W2 office | Next |
| Map kit (K1–K12) | After the test batch passes |
| Later window art (W3–W7) | After W2 |

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

> [Map style block] [Texture rules] Straight-on elevation of one section of a Khrushchev-era five-storey panel apartment building: grey concrete panels with visible seams, five rows of windows with wooden frames and mismatched curtains, three of them with glazed-in balconies of different colors, laundry on one balcony, a satellite dish, rust streaks under the window sills, the ground-floor entrance door with a small concrete canopy at the bottom center. Tileable horizontally. 2:1 canvas, wider than tall.

### T2. Facade texture: red-brick boiler house wall

Path: `init/assets/textures/facade_boiler_brick.png`

> [Map style block] [Texture rules] Straight-on elevation of the long wall of a 1960s red-brick industrial boiler house: weathered brick with darker repaired patches, tall arched windows with some broken panes, a large metal gate with peeling green paint, soot stains above the windows, a pipe running along the wall. Tileable horizontally. 2:1 canvas, wider than tall.

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

## Not generated here

- The 3D geometry of the map, lighting, smoke, fire, weather, and day and night: built in Godot.
- Request icons (plea, conflict, crisis, offer, promise) and UI panels: built in Godot or as SVG.
- Map tokens for people: cropped from the portraits in Godot.
