# Art request: the outskirts district

For Codex. Read these first, in order:

1. `README.md`, section "Starting District Layout": what the district is and why it looks the way it does.
2. `art/PROMPTS.md`: style blocks, texture rules, sprite rules, established looks.
3. `art/REDRAW_REQUEST.md`: the projection rules and the slope check. They apply to every sprite below.
4. `art/concepts/district_layout_v3.svg`: where each thing stands. Lot ids in this file match the ids in the layout.

## What changed and why

The map is being rebuilt as an outskirts district: border, port, transport hub, railway junction, late panel housing, and an emptying village. See README. This needs new buildings and props and retires some old ones.

The second change is condition. The map style block in `PROMPTS.md` currently tells every image to look worn: "worn concrete, rusted metal, peeling paint, water stains, autumn grime". That is wrong for most of this district. The housing was built in the late 1980s and is only 10–15 years old in 1997. Wear must come from the layer a building belongs to, not from a blanket rule.

## Condition blocks

From now on, use the map style block without its wear clause, then add exactly one condition: `kept`, `worked`, `fading`, or `abandoned`. Write the condition into the prompt. Do not rely on the generator to infer it.

Base block, replacing the map style block for this request:

> Painted illustration texture in the style of a detailed hand-painted 1990s post-Soviet provincial city. Muted realistic palette with warm accents. Rich surface detail without clutter.

| Condition | Use for | Text to add |
|---|---|---|
| `kept` | Late panel housing, school, kindergarten, polyclinic, executive committee, police | Built about ten years ago and reasonably kept: intact panels and paint, clean glazing, slight dust and a few weather streaks only, no rust stains, no broken windows, no peeling. |
| `worked` | ATP, truck stop, port, station, checkpoint, market, garages, boiler house | Heavily used rather than old: oil stains, scuffed and patched surfaces, dented metal, dirt from traffic, improvised repairs. Structure intact. |
| `fading` | Old village houses and sheds | Old wooden and brick village buildings, some tidy and painted, some sagging, faded, or overgrown. |
| `abandoned` | Unfinished construction, ruined village houses | Abandoned: bare concrete or charred or collapsed parts, weeds, no glass, nobody maintains it. |

Each entry below names its condition. The same four words are the `condition` field of the layout data in `docs/MAP_LAYOUT_REQUEST.md`.

## Global rules for this request

- Late August 1997 unless an entry says otherwise. No readable text or signs anywhere; symbols such as a red cross or a state emblem without text are fine.
- Buildings are 3D boxes built in Godot. For buildings you paint **facade textures**, not pictures of buildings. Follow the texture rules in `PROMPTS.md`: orthographic elevation, flat even light, edge to edge, tileable horizontally when marked. Canvas 2:1 at 1774×887 unless stated.
- **Canvas rule:** every facade canvas is 2:1 (1774×887), and one canvas is one tile of the stated real size, always twice as wide as high. Godot repeats tiles across the wall and stacks them vertically (`_facades` derives tile width from height × 2), so a different aspect stretches. Only entries marked as an overlay state their own canvas.
- Overlays (entrance bay, ground-floor shop) are laid by Godot over a tiled wall at given spots; they share the wall's materials and colours exactly.
- Unique buildings get one **front facade** (not tileable) and one **side or rear facade** (tileable).
- Props are **sprites**: all the sprite rules and the slope check from `REDRAW_REQUEST.md`, with the projection reference attached to every prompt. Each entry states its real dimensions.
- Save game assets under `init/assets/textures/` or `init/assets/sprites/` with the file name given. Never overwrite an existing file. Rejected drafts go to `art/concepts/redraw_attempts/`.
- After every batch, run the anchor script (`AGENTS.md` has the command) and report each sprite's printed slope.
- For tileable textures, compare the left and right edges before reporting. The facade drafts in `REDRAW_REQUEST.md` failed exactly there.

## Batch A: blocks the new layout cannot do without (do first)

| Id | File | Kind | Cond. | Real size | Content |
|---|---|---|---|---|---|
| A1 | `textures/facade_panel_late_9storey.png` | facade, tileable | kept | tile = 54 m wide, 27 m high (two entrances, nine floors) | Late-1980s nine-storey panel block: light grey and cream panels with tidy seams, regular windows, uniform loggias with a few glazed in by residents, a simple ceramic tile band under the roof. Ground floor plain. |
| A2 | `textures/facade_panel_late_5storey.png` | facade, tileable | kept | tile = 30 m wide, 15 m high | Late-1980s five-storey panel block of the same series as A1: same panels and colours, five floors, loggias. Visibly the same estate as A1. |
| A3 | `textures/facade_panel_entrance.png` | overlay, canvas 887×1774 (1:2 portrait) | kept | 7.5 m wide, 15 m high | The entrance bay of the A2 block: concrete canopy over a metal entrance door, a bench, the stairwell's vertical window strip. Placed by Godot over A1/A2 at each entrance. |
| A4 | `textures/facade_panel_groundfloor_shop.png` | overlay, not tileable | kept | 6 m wide, 3 m high (one bay) | Ground floor of the A1/A2 block converted to a small shop or office: a separate entrance with steps, a metal door, barred windows, an awning. No signs. Laid over the bottom floor of one section. Reused for pharmacy, police point, savings bank; Godot adds the label. |
| A5 | `textures/roof_panel_flat.png` | roof, tileable both ways | kept | 12×12 m | Flat bitumen roof of a recent panel block: even dark surface, neat seams, vents, a few TV aerials, no puddles or patches. |
| A6 | `textures/ground_dirt_road.png` | ground, tileable along one axis | fading | 6 m wide strip | Village dirt road from above: two packed wheel ruts, grass in the middle, puddle edges, gravel at the margins. Tileable lengthwise only, like `ground_rail.png`. |
| A7 | `textures/ground_parking_oil.png` | ground, tileable both ways | worked | 12×12 m | Worn asphalt of a truck yard: oil stains, tyre marks, patched potholes, sand. Base for ATP, truck stop, checkpoint holding area. |
| A8 | `textures/ground_quay.png` | ground, tileable both ways | worked | 12×12 m | Port quay: large reinforced concrete slabs, a crane rail embedded flush, rust stains, spilled coal and sand. |
| A9 | `sprites/truck_kamaz_semi.png` | sprite | worked | 16 m long, 2.5 m wide, 3.8 m high | A KamAZ tractor with a covered semi-trailer, long axis rising to the right. No plates, no text. |
| A10 | `sprites/truck_western_semi.png` | sprite | worked | 16.5 m long, 2.5 m wide, 4 m high | A generic Western European long-haul truck of the mid-1990s with a tarpaulin semi-trailer, cab-over, no brand, no text. The truck from the other side of the border. |
| A11 | `sprites/train_commuter.png` | sprite | worked | three cars, 60 m long, 3.5 m wide | A Soviet suburban electric train (ER-type), green with a yellow-red nose, three cars coupled straight. |
| A12 | `sprites/train_passenger_coaches.png` | sprite | worked | three coaches, 72 m long | Three dark green long-distance passenger coaches with a diesel locomotive at the front. |

## Batch B: the landmarks and game locations

| Id | File | Kind | Cond. | Real size | Content |
|---|---|---|---|---|---|
| B1 | `textures/facade_school_front.png` | facade, not tileable | kept | 26 m wide, 13 m high (the central entrance part; the rest of the front uses B2) | A typical late Soviet three-storey school: white sand-lime brick or light panels, long ribbon windows, a central entrance with a canopy, a mosaic panel with children and a sun (no text) on the stair tower. |
| B2 | `textures/facade_school_side.png` | facade, tileable | kept | tile = 26 m wide, 13 m high | Side wall of B1, same materials, ribbon windows. |
| B3 | `textures/facade_school_gym.png` | facade, tileable | kept | tile = 16 m wide, 8 m high | The gym wing: tall wall with high strip windows. |
| B4 | `textures/ground_sports.png` | ground, tileable both ways | kept | 12×12 m | School yard and sports ground from above: asphalt with faded painted court lines, a strip of running track. |
| B5 | `textures/facade_police_front.png` | facade, not tileable | kept | 14 m wide, 7 m high (entrance part; the rest uses the same walls without the door, save as `facade_police_side.png`, tileable) | A two-storey district police department: brick or rendered walls, barred ground-floor windows, a heavy door with steps, a lamp over the entrance, a state emblem without text. |
| B6 | `textures/facade_polyclinic.png` | facade, tileable | kept | tile = 30 m wide, 15 m high | A mid-size district polyclinic, not a hospital complex: a five-storey white panel polyclinic: large regular windows, a red cross symbol on one section, clean. |
| B7 | `textures/facade_customs_office.png` | facade, tileable | kept | tile = 14 m wide, 7 m high | Two-storey customs office building at the checkpoint: new-ish late Soviet build, light render, blinds in windows, a flagpole bracket. Serious, kept. |
| B8 | `sprites/checkpoint_booth.png` | sprite | kept | 3×3 m, 3 m high | A checkpoint control booth with windows on all sides, between traffic lanes. |
| B9 | `sprites/checkpoint_barrier.png` | sprite | kept | 8 m long | A red and white lifting barrier with its post, long axis rising to the right. |
| B10 | `sprites/border_watchtower.png` | sprite | worked | 3×3 m, 10 m high | A border guard watchtower of steel with a cabin on top. |
| B11 | `textures/facade_inspection_hangar.png` | facade, tileable | worked | tile = 14 m wide, 7 m high | Customs inspection hangar: corrugated metal wall with one large truck gate per section. |
| B12 | `sprites/portal_crane.png` | sprite | worked | 10 m wide base, 25 m high | A port portal crane on rails with its boom raised. Base along the rising axis. |
| B13 | `sprites/shipping_containers.png` | sprite | worked | a stack of three 6 m containers | Faded containers in different colours, stacked two high. |
| B14 | `textures/facade_bus_garage.png` | facade, tileable | worked | tile = 16 m wide, 8 m high | ATP repair hangar: brick and corrugated metal, one tall bus gate per section, oil-streaked apron edge. |
| B15 | `sprites/bus_paz.png` | sprite | worked | 7 m long, 2.5 m wide | A small PAZ bus, cream with a stripe, door side to the lower right. |
| B16 | `textures/facade_roadside_cafe.png` | facade, tileable | worked | tile = 8 m wide, 4 m high | One-storey roadside cafe and motel for truckers: rendered walls, big windows with curtains, a metal canopy. |
| B17 | `sprites/station_v3.png` | sprite | worked | 40 m long, 12 m deep | Replaces `station.png`. A small provincial station: pale yellow render on a brick plinth, green metal roof, central portico with a clock. Must pass the slope check (previous attempts failed). |
| B18 | `sprites/platform_canopy.png` | sprite | worked | 30 m long | A concrete platform canopy on columns for the bus station. |

| B19 | `textures/facade_ispolkom_front.png` | facade, not tileable | kept | 30 m wide, 15 m high (central entrance part) | A late-Soviet modernist district executive committee built in the 1980s: four to five storeys, long horizontal bands of windows between light concrete or white stone spandrels, a wide glazed ground-floor lobby under a projecting concrete canopy on slim pillars, broad steps, a state emblem without text above the canopy, flagpole brackets. Formal and kept. |
| B20 | `textures/facade_ispolkom_side.png` | facade, tileable | kept | tile = 30 m wide, 15 m high | The same building's side and rear walls: the same window bands and spandrels, no entrance. |

The executive committee is late-Soviet modernist (decided, see README). `facade_admin_stalinist.png` is no longer its target look; the map keeps it only as a placeholder until B19 and B20 exist.

## Batch C: the market and its people

| Id | File | Kind | Cond. | Real size | Content |
|---|---|---|---|---|---|
| C1 | `sprites/market_stall_row.png` | sprite | worked | 12 m long | A row of three metal-frame stalls under tarps, clothes and goods hanging, folding tables. Long axis rising to the right. |
| C2 | `sprites/container_kiosk.png` | sprite | worked | 6 m container | A shipping container turned into a shop: a cut-out window with a shutter, goods on hooks. |
| C3 | `sprites/car_trunk_trade.png` | sprite | worked | Lada, 4.1 m | A Lada with its trunk open, goods spread on the trunk and a table beside it. Match `car_lada_v3.png`. |
| C4 | `sprites/goods_pile.png` | sprite | worked | 2 m across | Cardboard boxes and big checked plastic shuttle bags piled up. |
| C5 | `sprites/person_shuttle_trader.png` | sprite | n/a | adult, 1.75 m | A woman in a cheap tracksuit dragging two huge checked shuttle bags. |
| C6 | `sprites/person_customs_officer.png` | sprite | n/a | adult | A customs officer in uniform and cap with a clipboard. |
| C7 | `sprites/person_militiaman.png` | sprite | n/a | adult | A militiaman in grey uniform and cap. |
| C8 | `sprites/person_trucker.png` | sprite | n/a | adult | A heavy trucker in a vest and flip-flops with a thermos. |

People follow the scale notes in `scripts/data/prop_dimensions.gd`.

## Batch D: the village

| Id | File | Kind | Cond. | Real size | Content |
|---|---|---|---|---|---|
| D1 | `sprites/village_house_kept.png` | sprite | fading, tidy | 8×6 m, ridge 5 m | A painted wooden village house with carved window frames, a slate roof, flowers. Ridge along the rising axis. |
| D2 | `sprites/village_house_poor.png` | sprite | fading, sagging | 7×6 m | A small brick-and-wood house, faded, a patched roof, a lean-to. |
| D3 | `sprites/village_house_abandoned.png` | sprite | abandoned | 7×6 m | An abandoned house: boarded windows, a collapsing roof, overgrown. |
| D4 | `sprites/village_house_burned.png` | sprite | abandoned | 7×6 m | The charred remains of a house: chimney standing, black beams. |
| D5 | `sprites/fence_picket_village.png` | sprite | fading | 10 m segment | A wooden picket fence with a gate, some boards missing. |
| D6 | `sprites/village_shed.png` | sprite | fading | 3×3 m | A wooden shed and an outhouse side by side. |
| D7 | `sprites/village_well.png` | sprite | fading | 1.5 m | A wooden well with a roof and crank. |
| D8 | `textures/ground_garden_beds.png` | ground, tileable both ways | fading | 12×12 m | Vegetable garden beds from above: rows of potatoes and cabbages, paths between them. |

## Batch E: the unfinished and the reserve

| Id | File | Kind | Cond. | Real size | Content |
|---|---|---|---|---|---|
| E1 | `textures/facade_unfinished_panel.png` | facade, tileable | abandoned | tile = 30 m wide, 15 m high | A five-storey panel block abandoned mid-construction: bare panels, no windows, floor slabs visible, rebar sticking out. |
| E2 | `sprites/tower_crane_abandoned.png` | sprite | abandoned | 4 m base, 40 m high | A rusting tower crane left on site, jib along the rising axis. |
| E3 | `sprites/construction_fence.png` | sprite | abandoned | 12 m segment | A concrete slab fence, leaning, with gaps. |

## Retire or downgrade

Do not delete files. They are noted here so nobody spends effort on them:

- `tram.png`: no tram in this district.
- `facade_merchant_house.png`: no merchant houses in this district.
- `facade_panel_5storey.png` (old, rusty): keep only for the odd older block. A1/A2 replace it as the default.
- `monument.png`: keep for the executive committee square.
- The tram item and the failed `station_v2` from `REDRAW_REQUEST.md` are superseded by B17.

## Report

After each batch, report:

- Every saved file with its printed slope (sprites) or its edge comparison (tileable textures).
- Any file that drifted from its condition block.

Add the batches to the status table in `art/PROMPTS.md`, with the full prompts used, as the earlier passes did. Do not change code or `README.md`.
