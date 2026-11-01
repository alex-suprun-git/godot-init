# Image Prompts: First Week

## Northern wheat field (2026-11-01)

- Built-in ImageGen map edit `art/source_images/wheat_field/direction-v1.png` was approved by the user. Derived production source: `ground-wheat-v1.png`; exact generation prompts are adjacent to both images. The separately optimized surface is integrated as `init/assets/textures/ground_wheat.png`. Implementation, preparation record and Godot verification: `art/source_images/wheat_field/README.md`. The user accepted the in-game result on 2026-11-01.

## Railway track texture refresh (2026-11-01)

- Built-in ImageGen edit of the existing G7 track texture, using bridge ballast as a material reference and a current Godot frame as map context. Preserved source: `art/source_images/railway/ground-rail-v2.png`; exact prompt: `art/source_images/railway/ground-rail-v2.prompt.md`.
- The user requested refreshed 2D artwork within the maintained-city direction: intact timber, clearer steel running surfaces, reduced rust and vegetation, neutral grey-brown ballast. The old G7 wording below is historical provenance and is superseded for the current texture. Optimized copy replaces `init/assets/textures/ground_rail.png`; final appearance review is pending. Actual game frames, limitations and preparation record: `art/railway/README.md`.

## Public transport 3D shape pass (2026-11-01)

Original procedural LiAZ-5256 and PAZ-3205 shape models now exist under
`art/models/public_transport/shape_v1/`. Generated turnarounds in that asset's
`references/` guide their appearance; no new raster art was generated or integrated.
Build scripts, measured exports, inspection results and remaining review points
are recorded in `art/models/public_transport/README.md`. The detailed `finish_v1`
exports are now integrated into ambient traffic and ATP; Godot screenshots compare
both buses with both current trucks and Volga. Visual inspection was performed in
both map axes. The user approved the in-game result after a uniform 20% bus
size reduction and requested the PR on 2026-11-01.

## Compact station market concept (2026-11-01)

- Current integrated revision: `art/source_images/market_hub/market_hub_v7.png` → `init/assets/sprites/market_hub_v7.png`. Exact revision prompts: `art/market_hub/REVISIONS.md`; current calibration and in-game review: `art/market_hub/README.md`. Implements user corrections to fencing, planting, relative sizes, station gap and the straight railway-side boundary; both tracks remain free.

- Combined 2D game asset from approved v3: `art/source_images/market_hub/market_hub_v1.png`; exact preparation prompt: `art/market_hub/asset-v1.prompt.md`; the superseded game copy is excluded from this PR. User explicitly requested this interim single-lot implementation; separate 3D models are deferred.
- Latest user-directed v3: `art/concepts/market-direction-v3.png`; full prompt and visual-review notes: `art/concepts/market-direction-v3.prompt.md`. Removes wagon, moves station to rails/platform, enlarges market, relocates bus bays to a straight row on the road side, shows former market as grass. User approved v3 as the visual and spatial direction on 2026-11-01; no game integration.
- Map-based v2 proposal: `art/concepts/market-direction-v2.png`; exact prompt and review: `art/concepts/market-direction-v2.prompt.md`; actual Godot reference: `art/concepts/market-direction-v2.map-reference.png`. Preserves the bus station and railway building; placement awaits user review.
- Untouched concept: `art/concepts/market-direction-v1.png`.
- Full generation prompt, input references and review limitations: `art/concepts/market-direction-v1.prompt.md`.
- Built-in image_gen; proposed direction awaiting user review, not integrated into Godot.

Prompts for the art needed by the first playable week (the heating-season opening, see `README.md`). Written for an image generator; each prompt is self-contained.

## Far-bank city concept (2026-10-31)

- Output: `art/concepts/far-bank-city-direction-v1.png`.
- Full prompt: `art/concepts/far-bank-city-v1.prompt.md`.
- Generator: built-in ImageGen; edit target/style/geography reference: `art/concepts/border-direction-v1.png`.
- Purpose: explore a distinct inhabited town across the river in the brotherly republic, with an older pitched-roof urban fabric, market square and residential waterfront. This replaces the sparse far bank of the earlier concept while retaining the near-bank district, river and two crossings.
- Status: exploratory, awaiting user feedback. Source concept only; no optimization, game integration or visual approval is implied. Gameplay intent and open questions are in README's Far-Bank City section.

## City park concept (2026-11-01)

- Output: `art/concepts/city-park-v1.png` (untouched generated original).
- Full prompt: `art/concepts/city-park-v1.prompt.md`.
- Generator: built-in ImageGen, with the user's map screenshot as camera/style reference.
- Status: first concept for `city_park`, selected by the user for integration on 2026-11-01. Optimized copy: `init/assets/sprites/city_park_v1.png`; report: `art/optimization_reports/city_park_v1.png.json`. The source has real alpha (0–254); the grounded-strip material uses alpha scissor to exclude the transparent exterior. Integration and review notes: `art/city_park/README.md`.

## Soviet new-district park comparison (2026-11-01)

- Output: `art/concepts/city-park-1980s-v1.png` (untouched original).
- Full prompt: `art/concepts/city-park-1980s-v1.prompt.md`.
- Generator: built-in ImageGen, no image references.
- Status: hypothetical visual comparison requested by the user, not a new approved game direction or a historical reconstruction; not optimized or integrated.

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

- Gusev (`gusev.png`): man in his late thirties, swept-back wavy dark hair, confident asymmetric grin, burgundy double-breasted jacket, cream shirt, patterned tie and gold chain.
- Father Georgiy: about fifty, narrow long face, receding brown hair, grey-streaked brown beard, black cassock and a plain wooden cross.
- Boiler-house watchman: lean man about sixty, drooping grey moustache, navy cap and faded olive work jacket; same face in the contractor and coal-theft scenes.
- Storekeeper: wiry man about fifty-five, thin greying hair, small grey moustache, watchful hooded eyes; stained brown padded vest over a pale blue shirt with rolled sleeves; closed worn ledger.
- Market woman trader: broad woman about fifty, round determined face, auburn hair in a bun, patterned teal blouse and plain dark apron.
- District militiaman: man about forty-five, long clean-shaven face, short sandy hair, grey 1990s uniform, cap pushed back, small notebook; no identifiable real-world national insignia.
- Contractor foreman: stocky man about fifty, bulldog-like face, cropped greying hair, navy work jacket over a pale shirt.

## Rules

- Required preparation workflow: `art/ASSET_PIPELINE.md`. Save generated originals outside `init/`; after the applicable visual approval, run `uv run tools/optimize_asset.py` before saving/integrating the game copy. The paths in prompts below are final optimized destinations, not generation-output paths.

- The game starts in late August 1997, and every prompt states its month. Late August: summer greenery with the first yellow leaves. September: early autumn, mostly yellow trees. October: heavy leaf fall, half-bare trees, first cold. Keep foliage and clothing consistent with the stated month.
- Do not render readable text, signs, or UI inside images. Generators garble Cyrillic; labels are added in Godot.
- This is a fictional post-Soviet republic: no Lenin portraits, recognizable Soviet leaders, or real-world national flags. Use landscapes or a pale patch where an old portrait was removed. When flags are needed, use an explicitly fictional design; the situation-banner draft uses a muted teal field, a narrow ochre diagonal stripe and a small ivory disc (an art proposal, not a finalized national identity).
- User review direction (2026-10-31): portray an inhabited, functioning city with modest age and ordinary maintenance. Avoid pervasive decay, flaking paint, rust, broken windows, wrecked vehicles, rubble and mud. Buildings and working equipment should be intact; new goods, especially the two proposed courtyard kiosks, must look new. Apply this to all future art prompts. Historical prompt transcripts below are provenance, not overrides of this direction.
- In daylight scenes, lamps are off and apartment/office windows have natural daylight or reflections, not artificial orange illumination. Summer office coat hooks have no heavy coats or warm hats. Check people and vehicles against one coherent perspective and scale before selecting an image.
- Color review direction (2026-10-31, in-game House 5 card): future window illustrations should have slightly reduced saturation, restrained brightness and softer contrast to sit naturally beside the map. Use subdued olive/sage greens, neutral concrete and modest warm accents; avoid vivid yellow-green foliage, pervasive orange/golden grading, glowing highlights and glossy color. Preserve readable faces and natural skin tones. Compare new art inside an actual card against the current map before selecting it. This is guidance for future art; the existing banner files were not recolored in this review.
- Existing event banners now receive a reversible display grade in `init/assets/shaders/event_banner_grade.gdshader`, applied by `HUD._card_banner()`: saturation 0.76, contrast 0.96, brightness 0.96, RGB balance (0.98, 1.0, 1.02). This gently subdues color and reduces the orange cast. Originals and optimized PNGs stay unchanged; source contact sheets show the ungraded art. Future art should already follow the muted palette above; revisit the shared grade when new art naturally matches the map.
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

> Painted illustration texture in the style of a detailed hand-painted 1990s provincial city in a fictional post-Soviet republic: intact concrete and masonry, painted metal, ordinary maintenance and modest everyday wear. An inhabited, functioning city, with no pervasive ruin, heavy rust, flaking paint, rubble or mud. New structures and goods look new. Muted realistic palette with warm accents. Rich surface detail without clutter; foliage and clothing match the stated season.

Window style block (portraits, scenes, events):

> Painterly oil illustration with visible brushwork and a subtly textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Subdued realistic colors matched to the in-game map: slightly reduced saturation, restrained brightness, soft contrast, muted olive/sage greens and neutral concrete, modest warm accents, natural skin tones and readable faces. Soft natural light, gentle highlights; no vivid yellow-green foliage, pervasive orange/golden grading or glossy oversaturation. Grounded, slightly melancholic, with quiet dark humor in small details. An inhabited, functioning, ordinarily maintained city: modest age and wear, intact buildings, glazing and equipment, serviceable vehicles. No pervasive rust, flaking paint, ruin, rubble or mud; new goods look new. No Lenin portraits, recognizable Soviet leaders or real-world national flags. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.

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

## Situation banners — 2026-10-31

Eleven banners: ten missing scenes plus the hot-water replacement. Built-in ImageGen was used for new images and edits, with existing portraits as identity/style references. The user authorized the established window-art direction and requested specific revisions in chat. Optimizer approval records this scoped batch direction, not a claim that the user approved every finished pixel. All untouched originals and superseded drafts remain under `art/source_images/situation_banners/`. Game copies use the `scene` optimizer profile and separate reports.

User review overrides the original envelope brief: use the existing empty summer office, with no visitor. Fictional republic art must not contain Lenin portraits or real national flags. The boss's flag revision is a proposed fictional teal/ochre/ivory motif, not a finalized national identity.

All original generation prompts below expand the existing window style block. Portrait references: Baba Nina for `hot_water` and `residents_meeting`; Gusev for `contractor`, the rejected envelope scenes and `wasteland_stalls`; boss and protagonist for `boss_report`.

### Situation banner: hot_water

Original generation: `art/source_images/situation_banners/hot_water_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Late August evening in the courtyard of a five-storey panel building. Residents carry kettles and saucepans of heated water across the yard from a ground-floor open window where a neighbor boils water on a hot plate; Baba Nina stands in the middle counting people with her open green notebook. A boy holds a basin nearby; a cold radiator pipe is visible through a low basement window. Tired, slightly absurd, everyday mutual aid. Nina must match reference portrait: woman in her seventies, floral cream headscarf, rectangular glasses on a black cord, brown knitted cardigan, floral dress, lined round face. Reference is character identity and oil-paint manner only; create a new wide outdoor scene, not a portrait.

### Situation banner: contractor

Original generation: `art/source_images/situation_banners/contractor_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> The yard of a red-brick boiler house with one tall cold smokeless chimney, coal heaps, rusty gate, broken windows. Gusev (match reference identity: late thirties, slick dark wavy hair, confident grin, burgundy double-breasted jacket, gold chain) and a bulldog-faced stocky foreman aged fifty, cropped greying hair, navy work jacket over pale shirt argue nose to nose, gesturing with hands. Next to them a new-looking dark boxy 1990s jeep and an old olive UAZ. Between them in the middle distance, a sleepy lean watchman aged sixty with drooping grey moustache, navy cap and faded olive jacket in a little booth turns up a small radio. All main faces and hands and the radio inside central horizontal crop band. Reference portrait supplies Gusev identity and oil brushwork only; create new wide scene.

### Situation banner: envelope

Original generation: `art/source_images/situation_banners/envelope_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Across the aide's worn desk in a cramped administration office, Gusev slides a thick unmarked buff envelope with TWO fingers toward the viewer, smiling; his eyes in shadow. Match reference identity: man late thirties, slick dark wavy hair, burgundy double-breasted jacket, gold chain, unbuttoned cream shirt, patterned dark tie. Black rotary phone, tea glass in metal holder and cardboard folders. Envelope, hand, smile, phone and tea all in middle horizontal band. Dusty late-August window light, green trees outside. View from aide's side, intimate uneasy encounter. Reference portrait for Gusev identity and painterly manner only, no mobile phone.

### Situation banner: church_heat

Original generation: `art/source_images/situation_banners/church_heat_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Inside a small whitewashed Orthodox church. Father Georgiy, about fifty, long narrow face with a grey-streaked brown beard, receding brown hair, black cassock, plain wooden cross stands beside a cold cast iron radiator under a window, resting one hand on its iron pipe as if apologizing for it. Behind him exactly four elderly women in headscarves and light coats despite August stand before a painted icon, one holding a thermos. Dusty sunlight through a high window, warm outside with green foliage. Heads, hand on pipe, radiator and thermos fit middle band; medium wide shot zoomed out. No lettering on icon, no inscriptions.

### Situation banner: coal_theft

Original generation: `art/source_images/situation_banners/coal_theft_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Mid-morning, bright and wrong. Open gate of a red-brick boiler house yard; a blue 1990s ZIL truck WITHOUT license plates, canvas tarpaulin drawn back, men with shovels loading coal from a heap. Lean sixty-year-old watchman with drooping grey moustache, navy cap and faded olive work jacket sleeps in his small booth, with unlabelled bottle on sill and small radio. Dead smokeless brick chimney behind, green trees. Medium distant eye level, urgent and darkly funny; heads, shovel action, truck loading bed and sleeping watchman all in central crop strip. Plain unlabelled vehicles, avoid any legible badge.

### Situation banner: wasteland_stalls

Original generation: `art/source_images/situation_banners/wasteland_stalls_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Wasteland between five-storey panel buildings: green birches with first few yellow leaves, glass bottles in grass, a rusty swing frame. Gusev, pleased, gestures at it as if showing a luxury showroom; a surveyor stake with ribbon; behind him a trailer stacked with welded metal kiosk frames. In background residents' windows, a few faces watching. Match Gusev reference identity: late thirties, swept-back dark wavy hair, smug grin, burgundy double-breasted jacket, gold chain, cream shirt and patterned tie. He is shown at medium distance so his whole head, gesturing hand and kiosk frames remain within y25%-75%. Reference is identity/style only, no mobile phone.

### Situation banner: market_cops

Original generation: `art/source_images/situation_banners/market_cops_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Market beside a provincial railway station: rows of faded tarp-covered stalls and folding tables, striped plastic shuttle traders' bags. Center: district militiaman aged forty-five with long clean-shaven face and sandy short hair, grey 1990s uniform, cap pushed back and small notebook, faces a broad woman trader aged fifty with round determined face, auburn hair in a bun, patterned teal blouse and plain dark apron over summer clothes. They stand on opposite sides of table piled with unbranded jeans, each pointing at something different. Other traders crowd behind her; station building in haze. Heads, hands, notebook and jeans all inside middle horizontal band, zoomed-out medium wide. No writing on uniform or stalls, plain patches and no logos.

### Situation banner: fuel_offer

Original generation: `art/source_images/situation_banners/fuel_offer_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Fuel depot with white cylindrical storage tanks and pipe manifolds, rusty barrels. A wiry male storekeeper about fifty-five with thin greying hair, small grey moustache, watchful hooded eyes and stained brown padded vest over rolled-sleeve pale blue work shirt holds a thick CLOSED unmarked ledger against his chest and looks past viewer. A railway tank wagon behind him, hose running to a period 1990s GAZ truck whose license plates are covered by a rag. Sunlight and rainbow oil sheen on ground, sly and calm. Medium distant composition with face, ledger and arms and visible hose-truck connection in central crop band. No modern tech, no writing or number labels on tanks.

### Situation banner: residents_meeting

Original generation: `art/source_images/situation_banners/residents_meeting_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Late-August evening courtyard of house 5, a five-storey panel apartment building. About fifteen residents stand and sit in rough half circle on benches and curb stones before entrance. Baba Nina stands in front, open green notebook held in her crossed arms, cream floral headscarf, rectangular glasses on black cord, brown knitted cardigan and floral dress, seventy-year-old round lined face matching reference. Men with cigarettes at back, woman holding baby, boy on bicycle at edge. One small EMPTY wooden stool in middle awaits an official. Green trees, summer clothing, warm tired light. Wide medium distant shot, faces and Nina's notebook and the empty stool all remain inside middle horizontal crop band. Reference for identity and painterly oil manner only.

### Situation banner: journalist

Original generation: `art/source_images/situation_banners/journalist_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Aide's cramped office seen from behind desk, ONLY hands visible, NO face. One male hand rests on receiver of a black rotary telephone, cord stretched across a folded local newspaper whose columns and headline are grey abstract brush shapes ONLY. Notepad with abstract illegible marks, tea glass in metal holder. Through window green late-August trees; pale rectangular patch on wall where portrait once hung. A feeling of being listened to, quiet uneasy sunlight. Desk arrangement low eye-level with phone, hand, newspaper and tea glass all within central horizontal crop band, spare room setting above and below. No letters, no digits on telephone dial, no readable text whatsoever.

### Situation banner: boss_report

Original generation: `art/source_images/situation_banners/boss_report_v1.png`.

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Wide single painted scene, canvas approximately 2.4:1. Composition must survive a center crop to 3.5:1: place ALL faces, hands, key storytelling objects within y=25%-75% of image height. Zoom out to fit this. Upper and lower fifth are expendable setting only. Late August 25-29, 1997, green trees with only first yellow leaves, warm weather and summer clothes with occasional light jacket. No readable text, lettering, logos, signatures or watermarks anywhere. Not a collage, no borders.
> Boss's office seen from padded doorway over shoulder of protagonist, only his grey suit sleeve and shoulder at edge. Pyotr Petrovich sits beyond at a vast desk with cardboard folders spread in fan. Match boss reference: heavy man early sixties, grey swept-back hair, heavy tired eyes and broad lined face, oversized grey suit and loosened burgundy striped tie. He looks up with exhausted patience of man who has done this many times. Plain muted flag in corner without any symbols or letters, window onto provincial town hall square with green late-August trees. Head, shoulders, hands and desk folders all within middle horizontal crop strip, medium distant view. Reference portraits for character identities and oil painting manner only; no floating portraits in scene.

### Envelope review history

`envelope_v1.png` was rejected for a visible visitor, a Lenin portrait and unsuitable crop. `envelope_v2.png` explored a wider crop and removed the portrait; it is also superseded because the user requested no person. The selected `envelope_v3.png` is a byte-for-byte source copy of the existing `init/assets/locations/summer_day_office_v3.png`, per the user's explicit instruction. It is reused rather than regenerated, then separately optimized to `init/assets/events/envelope.png`.

Envelope v2 edit prompt (superseded):

> Painterly oil illustration with visible brushwork and a warm textured background, 1990s post-Soviet provincial city in a fictional Slavic border republic, in the season stated by the prompt. Muted realistic palette with warm accents, soft natural light. Grounded, slightly melancholic, with quiet dark humor in small details. No fantasy, no modern 2020s cars or phones; cars are Ladas, Volgas, UAZ vans, ZIL and GAZ trucks.
> Edit the supplied envelope illustration ONLY to fix its panoramic composition. Preserve Gusev's face identity, burgundy jacket, oil-painted manner, late-August office and the action of sliding a thick unmarked envelope with two fingers. Zoom OUT and recompose: the entire top of Gusev's hair must be BELOW y=23% of total canvas height, his eyes at y=38%, chin at y=49%, fingers and the complete envelope between y=52% and y=71%. Make him smaller, viewed from slightly farther back. Put extra expendable wall above and desk foreground below. Rotary phone and tea glass on either side must also fit y=30%-73%. Darken his eyes into subtle shadow but retain small smile. Wide 2.4:1 canvas. The FULL scene action must survive a center crop to 3.5:1. Remove the framed portrait from wall, leave a pale rectangle instead. No text, lettering, logos or watermarks. Do not add people.

### First review revisions (superseded by later passes)

First-pass sources (superseded below): `hot_water_v2.png`, `contractor_v2.png`, `envelope_v3.png`, `boss_report_v2.png`, `fuel_offer_v2.png`, `wasteland_stalls_v2.png`; all other scenes use v1. Version 1 drafts are preserved and excluded from the final contact sheet. `hot_water` removes duplicate residents, an unclear background figure, malformed cars and the confused pot interaction; `contractor` redraws the jeep; `boss_report` replaces the real-looking flag and political statue; `fuel_offer` fixes the head crop; `wasteland_stalls` removes a generated signature-like mark.

#### hot_water v2 edit prompt

> Painterly oil illustration, preserve established style.
> Edit this existing wide oil painting, preserving Baba Nina's face, headscarf, glasses, green notebook, the boy with blue basin, building, warm August light and wide framing. Correct these exact defects: (1) keep the foreground woman at far LEFT in her floral dress, but REMOVE the near-identical curly-haired woman immediately behind the boy at x68% and REMOVE the near-identical woman at far RIGHT x96%. Replace their spaces naturally with yard/bench/grass. Keep the two distinct men at x75% and x82%, give them natural separate arms and believable kettle/pot handles. (2) REMOVE the tiny confusing partly hidden person directly behind the boy at x57%, y36%; replace with open quiet courtyard. (3) REMOVE ALL distant cars and trucks, especially the mangled car at far right edge, replace with simple empty yard. (4) Fix water distribution at x21%, y36%: the woman IN the window stands clearly behind a stable electric hotplate with one large saucepan; no floating utensils or fire. The man outside stands beside window holding a DIFFERENT saucepan by two well-defined handles with both hands, no merged bodies/hands/pots, no impossible interaction. Distinct faces, clothing and hair for all remaining adults. No additional people. No text or signatures. Keep whole Nina face and notebook, boy face and basin in central band y23%-77%.

#### contractor v2 edit prompt

> Painterly oil illustration, preserve established style.
> Edit ONLY the malformed dark jeep at the LEFT side of the existing painting. Replace it with an anatomically/mechanically coherent boxy 1990s dark charcoal off-road jeep, parked in same location facing lower-left. Correct bonnet, grille, headlights, windshield, side windows, doors, bumpers and round wheels with consistent single perspective and axle alignment. No squeezed or melted panels or doubled wheels; rear may be naturally occluded behind Gusev. Preserve EXACTLY the two arguing men, faces, gestures and clothes, sleepy watchman and booth, old UAZ on right, brick boiler house, greenery, oil paint style, canvas ratio, lighting and scene composition. No text, readable badges or logos, no signature.

#### boss_report v2 edit prompt

> Painterly oil illustration, preserve established style.
> Edit the existing boss office illustration only as follows. Replace the real-world-looking tricolor at x39% with an ORIGINAL fictional republic flag: dark muted teal cloth field, one narrow warm ochre DIAGONAL stripe running from upper hoist to lower fly and one small ivory disc in upper fly corner. NOT horizontal tricolor, no recognizable real national flag, no letters, no emblems. Flag should be physically coherent folded cloth on same pole. Outside window replace the human political statue with a modest abstract stone civic monument with simple geometric arch, no identifiable real historical person. Preserve boss face/clothes, aide's shoulder, desk, documents, setting, oil brushwork, warm August daylight, composition. No Lenin, Soviet leader portrait, hammer and sickle, real-world political symbols, lettering, signature or watermark anywhere.

#### fuel_offer v2 edit prompt

> Painterly oil illustration, preserve established style.
> Preserve this fuel depot oil painting's storekeeper identity, clothing, closed ledger, tank wagon, tanks, hose, oil sheen and rag covering truck plates. Fix composition by zooming out mildly and moving the storekeeper lower: entire top of his hair must be at y25% of canvas, eyes at y36%, closed ledger and both hands within y50%-73%. Full head must survive center crop to 3.5:1. Keep wide 2.4:1 aspect. Preserve plausible proportions and consistent truck construction. No text, insignia, signatures or watermark.

#### wasteland_stalls v2 edit prompt

> Painterly oil illustration, preserve established style.
> Edit only the tiny signature-like scribble at bottom RIGHT: remove it completely and replace with naturally continuous painted grass/dirt. Preserve everything else exactly, including Gusev, his face, clothes and gestures, kiosk frames, truck, birch trees, swing and bottles, wide composition and oil-paint style. No text, lettering, signature, logo or watermark.


### Maintenance review pass (supersedes earlier selections)

The user requested a functioning, inhabited city with less general decay across all images. The following edits preserve scene content while removing excessive rust, peeling surfaces, broken glazing and mud. In `wasteland_stalls`, replace the many rusty frames with exactly two new compact kiosks. This count is the banner composition agreed in review.

#### hot_water v3 maintenance edit

Input: `hot_water_v2.png`; untouched output: `hot_water_v3.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Keep exactly the same seven distinct people from this corrected version, no extra people and no cars. Baba Nina, boy, pots and window interaction unchanged. Repair panel facade to intact light-grey concrete with subtle seams and only minor stains; repaint basement window surround and bench to serviceable finish, little paint loss. Tidy yard with dry paths and healthy grass. Kettles and basin clean but used. Preserve the removed clones and removed background figure as absent.

#### contractor v3 maintenance edit

Input: `contractor_v2.png`; untouched output: `contractor_v3.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Repair brick boiler-house facade: intact glazed windows, no shattered panes, sound masonry. Left metal fence/gate uniformly painted muted blue-grey with a few small scuffs, no spreading orange rust. Watchman's booth has intact pale painted siding, sound roof and clear glass. Yard compact dry gravel/asphalt, remove muddy pools and debris. Dark jeep must look like relatively new well-kept 1990s vehicle with clean intact dark paint and correct geometry, round aligned wheels. Old UAZ remains older but clean/serviceable olive paint, only subtle wear and no rust perforation. Preserve both men's identity/gestures and watchman with radio, all three characters unchanged.

#### coal_theft v2 maintenance edit

Input: `coal_theft_v1.png`; untouched output: `coal_theft_v2.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Preserve coal theft: sleeping watchman, bottle/radio, men actively shoveling coal, ZIL without license plate, covered truck bed. Make watchman's booth sound and neatly painted pale grey-blue, intact wood and glazing, remove severe peeling/rust. Brick gate piers and boiler house maintained; gates painted dark grey with modest scuffs. Working blue ZIL has serviceable intact blue paint and coherent body/wheels, no wrecked rusted appearance. Keep coal heap and some realistic coal dust, but yard mostly dry hardstanding, no swampy mud/rubble.

#### wasteland_stalls v3 maintenance edit

Input: `wasteland_stalls_v2.png`; untouched output: `wasteland_stalls_v3.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Replace the entire huge truckload of many rusty kiosk frames with EXACTLY TWO small compact NEW prefabricated kiosks, each roughly 2m wide and 2m deep, on ONE modest 1990s flatbed truck/trailer. This is a tiny residential courtyard proposal, not a market complex. The two kiosks should be individually clear, simple finished units with clean muted blue-grey painted sheet steel, straight clean frames, a single closed serving hatch, no rust anywhere, no lettering. No additional stacked frames or loose panels; remove all extra kiosk skeletons and reduce truck bulk to match just two small units. Keep Gusev and gesture, birches, stake and ribbon. Surrounding apartment facades intact and lived-in with modest age, swing frame freshly maintained with only small wear. A few bottles in grass remain as story detail, no rubbish dump.

#### fuel_offer v3 maintenance edit

Input: `fuel_offer_v2.png`; untouched output: `fuel_offer_v3.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Keep the fuel transaction, storekeeper with closed ledger, workers, hose, tank wagon and rag hiding truck plate. Make truck a working cared-for light blue-grey period tanker with intact paint and coherent construction, minor grime but no flaking wreck. White storage tanks kept painted white, minor stains at pipe fittings only. Railway tank wagon uniform dark brown paint with light wear instead of heavy orange rust. Barrels have intact muted paint. Ground is dry service yard with ONE small restrained oil-sheen patch near hose, not flooded oil swamp; remove all pervasive mud and spilled rainbow pools. Keep full storekeeper head safely inside crop.

#### residents_meeting v2 maintenance edit

Input: `residents_meeting_v1.png`; untouched output: `residents_meeting_v2.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Preserve residents meeting, Nina, mother/baby, boy/bike and empty stool, same people/count and no clones. Repair entrance facade to intact pale painted render/concrete with only minor age and faint stains, sound entrance canopy and painted handrails, working ordinary entrance lamp. Benches well-kept painted wood, clean dry paving and maintained grass. Serviceable parked older cars, no wrecks. Keep warm inhabited courtyard and everyday clothes. Nina's notebook can remain held as pictured.

#### journalist v2 maintenance edit

Input: `journalist_v1.png`; untouched output: `journalist_v2.png`.

> Edit this existing oil-painted illustration to match a functioning, normally maintained provincial city in August 1997. Modest ordinary wear only. Remove excessive rust, crumbling/peeling surfaces, ruin, rubble and mud. The setting is inhabited and serviceable. Maintain the same oil brushwork, warm light, palette, people, faces, poses, clothes, story action, and wide canvas composition. Keep ALL main faces, hands and key story props inside y20%-78% for a 3.5:1 center crop. Preserve 1990s technology, green late-August foliage, and grounded quiet humor. No text, letters, logos, signature, watermark, Lenin, identifiable political leaders or real national flags. This is NOT a glossy modern renovation: ordinary cared-for older buildings.
> Preserve ONLY male hand on receiver, rotary phone and stretched cord, tea glass, newspaper made of grey abstract shapes, desk and green view. Repaint office wall intact warm off-white above clean muted sage wainscot, modest surface age only, no cracked flaking plaster. Sound painted window frames, intact clean door and filing cabinet, tidy but paper-filled lived-in desk. Preserve pale empty rectangle from removed wall portrait, no replacement leader portrait. Retain uneasy atmosphere through composition/light, not dilapidation.


### Daylight, seasonal props and perspective review

Daytime lamps and glowing windows were removed; the journalist office has bare coat hooks without heavy clothing. Fuel transfer versions v1–v4 were rejected for incoherent spatial scale. Per the user's final direction, the selected fuel-depot scene keeps the storekeeper and replaces the entire background with stationary tanks, a depot office and barrels; no pumping process, truck, railway wagon, hoses or other workers. v5 established the new background; v6 removes an accidentally generated door lamp.

#### journalist v3 edit

Input: `journalist_v2.png`; output: `journalist_v3.png`.

> Edit ONLY these details in this existing wide oil painting. REMOVE the green desk lamp at the far RIGHT entirely; replace that area naturally with the existing office/desk background, no new lamp or light fixture. REMOVE the heavy coat and dark hat hanging in upper LEFT; leave a few bare simple coat hooks on the otherwise intact wall. It is warm August daytime: only natural window daylight, no illuminated lamps or artificial light anywhere. Preserve EXACTLY the hand on rotary phone, desk, tea glass, newspaper, window, summer greenery, sound walls, soft oil-paint style, color palette and wide composition. No new people, text, signature or logos.

#### residents_meeting v3 edit

Input: `residents_meeting_v2.png`; output: `residents_meeting_v3.png`.

> Edit ONLY artificial lighting in this oil painting of a summer residents meeting. Turn OFF the round lamp under entrance canopy: an unlit dull cream/glass bulb, no yellow halo and no light spill. All apartment windows including the three marked areas behind seated residents and at top edge must show neutral shaded interiors or natural daylight reflections, absolutely no orange/yellow luminous interior illumination. Doorway interior dim in ordinary natural shade, no glowing yellow lamps. Keep warm low SUNLIGHT on people, trees and facade. Preserve EXACTLY all people/faces/clothes, Nina, baby, bicycle, empty stool, maintained building, cars and full wide composition. No new text, signatures or emblems.

#### hot_water v4 edit

Input: `hot_water_v3.png`; output: `hot_water_v4.png`.

> Edit ONLY illumination inside ALL apartment windows in this wide oil painting. The open kitchen window with the woman cooking at upper LEFT must have an ordinary neutral daylight interior with pale walls and dim natural shade, NO golden/orange glowing room, no artificial lights. Keep woman, saucepan and electric HOTPLATE (needed to boil water); hotplate is cooking equipment, do not remove it. The distant windows at RIGHT also show natural grey/blue daylight reflections or dim neutral rooms, no luminous orange squares. All other windows neutral daylight, ALL lamps off. Preserve warm late afternoon SUNLIGHT outside, every person, Nina face/notebook, boy/basin, all pots, flower beds, improved facade, removed duplicate people and absent cars. Keep framing and oil paint style, no text or signatures.

#### contractor v4 edit

Input: `contractor_v3.png`; output: `contractor_v4.png`.

> Edit ONLY lighting inside the watchman's booth. The small hanging lamp directly above the watchman must be OFF: no luminous yellow bulb, no glow, no artificial light spill. Booth interior naturally shaded in daylight with neutral pale walls. Preserve EXACTLY everything else: arguing men faces, clothes and gestures, watchman and radio, clean dark jeep, olive UAZ, maintained brick boiler house, painted gate, dry courtyard, green foliage and wide oil-painted composition. No new text or logos, no signatures.

#### fuel_offer v4 edit

Input: `fuel_offer_v3.png`; output: `fuel_offer_v4.png` (superseded).

> Correct the inconsistent spatial scale and perspective in this fuel depot oil painting. Recompose the railway tank wagon on LEFT and tanker truck on RIGHT as two coherent full-size vehicles in the SAME midground depth, behind the foreground storekeeper. Show the railway wagon farther back than currently so its complete tank and undercarriage fit comfortably in frame; no gigantic near-camera cropped cylinder. Wagon and truck should have approximately SIMILAR APPARENT overall height, railway tank only modestly larger than road tanker, never twice its height. Both workers are ordinary adult men with approximately the SAME apparent body height at this depth; match workers to vehicle door/handrail sizes and wheel diameters. Single consistent eye-level horizon and ground plane, visible rails at left converge correctly, truck wheels sit firmly on same yard plane. Keep the truck closer than wagon, both clearly readable with mechanically coherent wheels, axles, cab and cylindrical tanks. Keep storekeeper identity, whole face below y24%, ledger and hands in middle band, maintained white storage tanks, clean dry yard, one small oil sheen, hose running clearly between wagon and road tanker, rag hiding truck plate. Ordinary maintained 1997 depot, moderate wear, no massive rust or ruin. All outdoor lights OFF in daylight. Preserve oil-painted style, warm sunlight and panoramic 2.4:1 framing; all key faces/hands within central crop band. No readable text, letters, badges, signatures or watermark.

#### fuel_offer v5 edit

> Edit the supplied panoramic oil-painted illustration. KEEP THE FOREGROUND STOREKEEPER EXACTLY: same man, face identity, grey hair and moustache, position near the center, gaze, body, hands holding closed ledger, stained brown vest, pale rolled-sleeve work shirt, same size and full head inside central banner band. Completely replace ALL background and side scenery. Create a simple quiet functioning provincial fuel depot in August 1997: three modest WHITE fixed cylindrical storage tanks in the middle distance behind a low maintained perimeter fence, a small single-storey pale brick depot office/storehouse to one side, several neatly arranged clean painted barrels, dry flat service yard, green late-summer trees and a small distant town skyline. Coherent restrained eye-level perspective, one ground plane, ordinary scale. NO railway wagon, NO rails, NO truck, NO road tanker, NO workers, NO hoses, NO pumping or unloading process, NO active machinery anywhere. Only this one man in the scene. The background tells 'fuel depot' through stationary storage tanks alone. No excessive rust, peeling surfaces, decay or mud. All lights off in daylight, natural warm afternoon sun. Preserve painterly oil brushwork and muted realistic warm palette of reference, not photorealism. Wide 2.4:1 frame, man and ledger entirely within middle 60% of height for 3.5:1 center crop. No readable text, numbers, lettering, logos, political symbols, signatures or watermark.

#### fuel_offer v6 edit

> Make exactly ONE tiny correction to this supplied oil-painted fuel depot image: REMOVE the small glowing yellow wall lamp mounted above the office door on the far LEFT, around x13%, y38%. Remove the lamp fixture AND all yellow glow, filling its spot with plain naturally shaded brick wall under the existing canopy. No replacement light fixture. Everything else must stay EXACTLY unchanged: the storekeeper with ledger, face, clothing, pose and scale, three stationary white tanks, fence, barrel groups, office architecture, yard, trees, skyline, sunlight, oil-painted style and panorama. No trucks, wagons, hoses, workers or pumping process. No artificial lamps or glowing windows, no readable text, no signatures. Preserve 2.4:1 canvas.

### Current selected sources

This table supersedes the earlier selection notes. All game files are separately prepared with `tools/optimize_asset.py --profile scene --approved`, with reports at `art/optimization_reports/<id>.json`. Creative review of the finished series remains with the user; batch authorization and requested corrections are recorded above.

| Event | Selected original | Game copy |
|---|---|---|
| `hot_water` | `art/source_images/situation_banners/hot_water_v4.png` | `init/assets/events/hot_water.png` |
| `contractor` | `art/source_images/situation_banners/contractor_v4.png` | `init/assets/events/contractor.png` |
| `envelope` | `art/source_images/situation_banners/envelope_v3.png` | `init/assets/events/envelope.png` |
| `church_heat` | `art/source_images/situation_banners/church_heat_v1.png` | `init/assets/events/church_heat.png` |
| `coal_theft` | `art/source_images/situation_banners/coal_theft_v2.png` | `init/assets/events/coal_theft.png` |
| `wasteland_stalls` | `art/source_images/situation_banners/wasteland_stalls_v3.png` | `init/assets/events/wasteland_stalls.png` |
| `market_cops` | `art/source_images/situation_banners/market_cops_v1.png` | `init/assets/events/market_cops.png` |
| `fuel_offer` | `art/source_images/situation_banners/fuel_offer_v6.png` | `init/assets/events/fuel_offer.png` |
| `residents_meeting` | `art/source_images/situation_banners/residents_meeting_v3.png` | `init/assets/events/residents_meeting.png` |
| `journalist` | `art/source_images/situation_banners/journalist_v3.png` | `init/assets/events/journalist.png` |
| `boss_report` | `art/source_images/situation_banners/boss_report_v2.png` | `init/assets/events/boss_report.png` |

## Traffic light — 1970s–1980s turnaround v1

- Concept: `art/concepts/traffic-light-1970s-1980s-turnaround-v1.png`.
- Full prompt and review status: `art/concepts/traffic-light-1970s-1980s-turnaround-v1.prompt.md`.
- Built-in ImageGen; front, left, rear, three-quarter and enlarged head detail. Period-inspired modeling reference; not a verified historical blueprint. The original Blender model and its static game integration now live under `art/models/traffic_lights/`; the reference image itself remains a concept, not a game texture. See the asset README for geometry, independently controllable lenses and inspected Godot views.

## Freight truck turnaround references (2026-11-01)

Built-in ImageGen, conceptual modeling aids only; no raster game integration. Originals, full prompts and inspection notes are under `art/models/traffic/references/`.

- Food ZIL: `zil-food-turnaround-v1.png`; exact prompt `zil-food-turnaround-v1.prompt.md`.
- Coal ZIL: `zil-coal-turnaround-v1.png`; exact prompt `zil-coal-turnaround-v1.prompt.md`. Direct image reference: `init/assets/sprites/truck_zil_plain.png`.
- Container KamAZ: `kamaz-container-turnaround-v1.png`; exact prompt `kamaz-container-turnaround-v1.prompt.md`. Closed 40-foot ISO container is a proposal for the user's tentative container request.

All three are visually inspected and awaiting user review. Generated projection/detail inconsistencies must be resolved before modeling; existing game models are unchanged.

## Sidewalk surface textures (2026-11-01)

Built-in ImageGen created three square top-down material sources under `art/source_images/sidewalks/`: `sidewalk-slabs-clean-v1.png`, `sidewalk-slabs-aged-v1.png`, `sidewalk-asphalt-v1.png`. Complete exact prompts are stored in the adjacent `.prompt.md` files; inspection and next action are in that folder's README. Proposed use: maintained square grey concrete slabs on the central civic avenue, gently aged slabs on secondary footways, lighter fine-grained asphalt on ordinary sidewalks. The user authorized integration on 2026-11-01: clean v1 slabs and asphalt are separately optimized and bound to the civic axis/ordinary sidewalks. Exact output/provenance and measured shader sampling are documented in the source README; actual Godot frames are in `art/sidewalks/`. A built-in ImageGen edge-correction attempt `sidewalk-slabs-clean-v2.png` (exact prompt adjacent) was preserved but not selected. Instead the material samples a measured interior region of optimized v1 to avoid partial perimeter slabs. Repetition and day/night/winter rendering were visually inspected. Aged slabs remain an unused candidate; final in-game user review is pending.

## Bridge material textures (2026-11-01)

Built-in ImageGen created `art/source_images/bridges/bridge-concrete-v1.png`, `bridge-ballast-v1.png` and `bridge-steel-v1.png`; exact prompts are in the adjacent `.prompt.md` files. All are opaque top-down materials, not complete bridge paintings. The user approved this direction and requested integration. Separately optimized surface-profile copies are `init/assets/textures/bridge_{concrete,ballast,steel}.png`; matching reports are under `art/optimization_reports/`. Actual world scale, material repeat inspection, game screenshots and remaining appearance review are recorded in `art/bridges/README.md`. No original source was altered.

## Freight truck 3D upgrade (2026-11-01)

Original procedural Blender geometry follows the three existing freight turnarounds above: shared rounded ZIL cab with food/coal bodies and KamAZ with a distinct blue container. The user positively reviewed the shown visual direction. No new image generation or raster integration was performed. Current source, Volga/ER2 scale calibration, measured exports and Godot review workflow: `art/models/traffic/README.md`.

Retired freight sprites: the unused KamAZ sprite was removed from `init/`; the former coal ZIL sprite is preserved as `art/models/traffic/references/zil-coal-original-sprite.png`. The coal-event overlay now uses the same 3D ZIL as traffic. Historical prompt paths above describe the original generation, not current runtime dependencies.

## Terrain texture candidates (2026-11-01, issue #39)

Built-in ImageGen generated unapproved originals under `art/source_images/terrain/`. Current-main shader comparison, 3 × 3 repeat previews, limitations and next action are recorded in that folder's README. T1–T3 were previewed at runtime only; T4 is not a verified seamless grayscale map and the current shader uses procedural macro noise. T1–T3 were subsequently approved (summer positive, autumn accepted) and optimized to new 1024px game copies; permanent bindings remain for integration.

### grass v1

Use case: stylized-concept. Asset type: seamless square terrain albedo texture for a Godot isometric city map. Reference: current game has muted painterly buildings, olive trees and grey roads in a functioning 1990s Slavic provincial city. Create SURFACE ONLY, straight-down orthographic, perfectly flat diffuse shadowless illumination, no ambient occlusion, no perspective, no objects, text, borders or watermark. Seamlessly periodic on BOTH axes. Fine natural irregular texture distributed evenly; avoid distinctive blobs, stripes, grids, directional strokes or large recognisable patches. Subtle material detail must survive mipmapping at distant map camera. Square 1024x1024 opaque RGB. Subject: short mixed meadow/lawn grass, modest maintenance, subdued sage and olive green with a few muted straw blades and tiny soil gaps. Overall middle-light neutral green suitable for multiplication by seasonal tints; low saturation, restrained contrast, no yellow-green or lush emerald, no flowers, no isolated tufts or paths. Entire image is one continuous flat grass surface. Small blades rather than large clumps. Do not bake large-scale macro variation into this detail tile.

### grass dry v1

Use case: stylized-concept. Asset type: seamless square terrain albedo texture for a Godot isometric city map. Reference: current game has muted painterly buildings, olive trees and grey roads in a functioning 1990s Slavic provincial city. Create SURFACE ONLY, straight-down orthographic, perfectly flat diffuse shadowless illumination, no ambient occlusion, no perspective, no objects, text, borders or watermark. Seamlessly periodic on BOTH axes. Fine natural irregular texture distributed evenly; avoid distinctive blobs, stripes, grids, directional strokes or large recognisable patches. Subtle material detail must survive mipmapping at distant map camera. Square 1024x1024 opaque RGB. Subject: dry late-summer short grass, muted straw beige and grey-olive blades over small neutral taupe soil gaps, a small amount of living sage-green grass. Same fine density and scale as a short mixed meadow. Not orange, not golden, not hay, no large bare patches or isolated bunches, no flowers or leaves. Middle-light neutral albedo, subtle contrast. Do not bake large-scale macro variation into the detail tile.

### dirt v1

Use case: stylized-concept. Asset type: seamless square terrain albedo texture for a Godot isometric city map. Reference: current game has muted painterly buildings, olive trees and grey roads in a functioning 1990s Slavic provincial city. Create SURFACE ONLY, straight-down orthographic, perfectly flat diffuse shadowless illumination, no ambient occlusion, no perspective, no objects, text, borders or watermark. Seamlessly periodic on BOTH axes. Fine natural irregular texture distributed evenly; avoid distinctive blobs, stripes, grids, directional strokes or large recognisable patches. Subtle material detail must survive mipmapping at distant map camera. Square 1024x1024 opaque RGB. Subject: compacted dry earth, neutral grey-brown taupe soil with fine crumbly mineral grains and occasional tiny embedded pebbles, subtle painterly detail. Modest everyday foot traffic, functioning city, dry firm ground. Medium neutral albedo, very low contrast broad tones. No grass, no vegetation, no cracks, footprints, tyre tracks, mud, litter or large stones, no reddish or orange grading. No large-scale tonal patches; the engine supplies separate macro variation.

### macro v1

Use case: stylized-concept. Asset type: grayscale shader data texture, NOT an illustration of terrain. Generate one square 1024x1024 seamless tileable on both axes low-frequency noise map for large-scale ground tint variation in a Godot city map. Pure neutral grayscale, smooth organic amorphous cloud-shaped regions, roughly 6 to 10 broad softly interleaved irregular regions across width. Continuous soft gradients spanning medium dark grey to medium light grey, mean near 50 percent grey; no solid black or white. Entire texture edge to edge, no lighting, no central subject, no vignette, no fine grain or tiny detail, no cracks, contour lines, sharp edges, grids, directional stripes, borders, text or watermark. Both opposing edges must match smoothly. This is smooth technical noise data, not realistic clouds or smoke.
