# Redraw request: true isometric sprites and more variety

For Codex. Read `art/PROMPTS.md` first (map style block, sprite rules, established looks), then this file.

## Why

The map camera is now orthographic and true isometric (see `art/concepts/iso_projection_reference.png`, attach it to every prompt). The first 45 sprites were drawn in a looser isometric that varies from sprite to sprite: the ground edge of most long props slopes 0.3 to 0.4, but the camera needs 0.577. Next to a street they lie flatter than the street and look crooked. This batch redraws the worst of them and adds a few things to break up the grey, repeating blocks.

## Hard rules (every image)

- Match the projection in `art/concepts/iso_projection_reference.png`: ground axes at exactly 30 degrees, the long axis rising to the right, orthographic, vertical edges vertical.
- The long side of the object runs along the rising axis. The long side facing the viewer is the lower-right one; the short end faces the lower left.
- The footprint is a clean rectangle in that projection. Its near corner touches the bottom of the picture with at most 3% margin.
- Everything else from the PROMPTS.md sprite rules: transparent background (or flat #FF00FF), one object, no ground, no cast shadow, flat even light, no readable text. Map style block, late August.
- Save as `init/assets/sprites/<name>_v2.png` next to the old file. Do not overwrite the old ones.

## Check before you say it is done

After saving a batch, run

```
/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot --headless --path init --script res://scripts/dev/measure_sprite_anchors.gd
```

and read the line for each new file. For a long object drawn with its long axis rising to the right, `slope` must print between -0.52 and -0.63. Compact objects (station, house) print values near 0 and are judged by eye against the reference: their main edges must be parallel to the red and blue axes. If a slope is outside the range, redraw it before reporting. Report the printed slope for every file.

## Attempt status (2026-10-30)

| Batch | Status |
|---|---|
| 1 | Partial: `garages_row_v2` and `train_wagons_v2` pass; station, bus, tram, and fence drafts failed projection QA. |
| 2 | Partial: `bus_stop_v2` passes; vehicle drafts failed projection QA. The house failed visual axis review. |
| 3 | Partial: `carpet_beater_v2` passes; pigeon loft and laundry line failed projection QA. Facade dimensions pass, but edge seams do not. |

Accepted sprite files remain in `init/assets/sprites/`. Rejected drafts are under `art/concepts/redraw_attempts/` and are not game assets. The batches are not done.

### Sprite measurement results

Slope values are from `scripts/dev/measure_sprite_anchors.gd`; the train was re-generated once, so its value below is the final measurement. “Foot” means the script classified the image as a compact footprint rather than fitting a long ground edge.

| File | Slope | Result |
|---|---:|---|
| `station_v2.png` | -0.34 after one retry | Rejected; visual axes also too shallow |
| `garages_row_v2.png` | -0.52 | Pass |
| `train_wagons_v2.png` | -0.53 | Pass after correction |
| `bus_liaz_v2.png` | -0.50 | Rejected |
| `tram_v2.png` | -0.46 | Rejected |
| `fence_chainlink_v2.png` | -0.49 | Rejected |
| `car_lada_v2.png` | -0.35 | Rejected |
| `car_volga_black_v2.png` | -0.37 | Rejected |
| `van_uaz_police_v2.png` | -0.34 | Rejected |
| `truck_zil_plain_v2.png` | -0.37 | Rejected |
| `crane_truck_v2.png` | -0.29 | Rejected |
| `bus_stop_v2.png` | -0.55 (foot) | Pass |
| `private_house_v2.png` | -0.05 (foot) | Rejected by visual axis review |
| `pigeon_loft_v2.png` | -0.35 (foot) | Rejected |
| `carpet_beater_v2.png` | -0.63 (foot) | Pass |
| `laundry_line_v2.png` | -0.51 (foot) | Rejected |

The facade drafts are each 1774×887. Exact opposite-edge pixel comparison still found mean RGB differences (normalized 0–1) of 0.077 for `facade_brick_5storey_v2.png`, 0.061 for `facade_panel_painted_5storey_v2.png`, and 0.050 for `facade_panel_9storey_v2.png`; they need another pass before use as repeating textures.

## Batch 1: redraw first (these look crooked on the map)

| File | Prompt |
|---|---|
| `station_v2` | [Map style block] [Sprite rules] A small provincial railway station: pale yellow plaster walls on a brick plinth, green metal roof, a central entrance with a columned portico and a clock under a gable, one-storey wings on both sides. Footprint about 3 to 1. The long facade with the portico runs along the rising axis and faces the lower right. The short end wall faces the lower left. All roof ridges run parallel or perpendicular to the axes. |
| `garages_row_v2` | [Map style block] [Sprite rules] A row of eight metal garages side by side, each a different faded color (blue, green, cream, rust red, grey), pitched roofs, rusted double doors, the doors on the long side facing the lower right. The row runs along the rising axis. The whole row must be exactly straight: all eight stand on one line. |
| `train_wagons_v2` | [Map style block] [Sprite rules] Three coupled rust-brown covered freight wagons with buffers and bogies, in a straight line along the rising axis, long side facing the lower right. The wagons stand on an invisible track, so the wheels are on a perfectly straight line. No rails in the picture. |
| `bus_liaz_v2` | [Map style block] [Sprite rules] A cream and red LiAZ city bus, worn, long side along the rising axis, door side facing the lower right. |
| `tram_v2` | [Map style block] [Sprite rules] A cream and red Soviet tram car with a roof pantograph, long side along the rising axis, door side facing the lower right. |
| `fence_chainlink_v2` | [Map style block] [Sprite rules] A straight 12 metre section of chain-link fence with concrete posts, rusty, with a few weeds at the foot, along the rising axis. |

## Batch 2: vehicles and props

All long axis rising to the right, long side to the lower right, scaled to real size: the game draws a Lada about 5 map units wide on screen (one unit is about a metre), so keep proportions true (a Lada is roughly 4.1 m long and 1.7 m wide).

| File | Prompt |
|---|---|
| `car_lada_v2` | A white Lada 2107 sedan, worn. |
| `car_volga_black_v2` | A black GAZ-24 Volga sedan, clean. |
| `van_uaz_police_v2` | A grey-blue police UAZ van with a roof light bar. |
| `truck_zil_plain_v2` | A ZIL truck with a green tarpaulin loaded with coal, no license plates. |
| `crane_truck_v2` | A repair crane truck with an orange cab and the boom folded along the body. |
| `bus_stop_v2` | A concrete bus stop shelter with a bench, shelter along the rising axis. |
| `private_house_v2` | A one-storey village house with a pitched slate roof, a wooden porch, a picket fence and a vegetable garden. Ridge parallel to the rising axis. |

## Batch 3: variety (breaks up the grey blocks)

Facades are 2 to 1 straight-on elevations, same technical rules as `facade_panel_5storey.png` in PROMPTS.md (orthographic, even light, no shadows, seamless horizontally, 1774 by 887).

| File | Prompt |
|---|---|
| `init/assets/textures/facade_brick_5storey_v2.png` | Straight-on elevation of one section of a 1950s five-storey red-brown brick apartment building: pitched wooden window frames, small balconies, brick cornice, an entrance with a concrete canopy at the bottom center. Tileable horizontally. |
| `init/assets/textures/facade_panel_painted_5storey_v2.png` | Same panel building as `facade_panel_5storey.png` but painted: pale ochre lower floors, faded blue upper band, flaking paint, visible panel seams. Tileable horizontally. |
| `init/assets/textures/facade_panel_9storey_v2.png` | Straight-on elevation of one section of a nine-storey 1970s panel tower: nine rows of windows, narrow loggias, a mosaic panel under the roofline, entrance at the bottom center. Same 2 to 1 canvas. |
| `init/assets/sprites/pigeon_loft_v2.png` | A rickety wooden pigeon loft on stilts with a mesh run and a few pigeons, along the rising axis. |
| `init/assets/sprites/carpet_beater_v2.png` | A metal frame for beating carpets, with a rolled carpet over the bar, along the rising axis. |
| `init/assets/sprites/laundry_line_v2.png` | A laundry line between two posts with sheets and shirts, along the rising axis. |

## When you are done

List every saved file with its printed slope. Do not touch `README.md` or any code. Update the status table in `art/PROMPTS.md` and mark batches done.
