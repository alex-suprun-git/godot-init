# Market, bus station and railway station — combined 2D site

**Historical interim implementation:** the combined painting is now replaced in the game by the first 3D station/market/forecourt assembly. Current sources, dimensions, limitations and graphical verification: `../models/station_hub/README.md`. The v7 source and calibration below remain preserved for provenance.

## Current state

The user approved the map-based concept v3 and explicitly requested one combined 2D painting in the moved market slot as an interim implementation. Separate 3D stalls are deferred. The current integrated source is **asset v7**, incorporating the user's subsequent corrections; the final in-game result awaits user review.

- Source: `art/source_images/market_hub/market_hub_v7.png` (untouched generated original, 1605 x 980 RGBA).
- Game copy: `init/assets/sprites/market_hub_v7.png`.
- Provenance: `art/optimization_reports/market_hub_v7.png.json`.
- Initial prompt: `asset-v1.prompt.md`; exact revision prompts: `REVISIONS.md`.
- Map basis: `art/concepts/market-direction-v2.map-reference.png`; approved composition: `art/concepts/market-direction-v3.png`.

## User-directed corrections

- The freight wagon is removed from the passenger railway; both parallel through tracks remain clear and unchanged.
- The station is on the railway side, the bus bays form one straight row on the road side, and the dense colourful market adjoins the station.
- The market-side railway boundary has a plain metal mesh fence. No platform furniture, lamps or decorative plants sit along that boundary. Planting on the back/street side remains in the painting.
- Only the station-front part is a passenger platform. The ambiguous dark structure formerly in front of the building is removed.
- The user requested a 10% larger station, 10% smaller stalls and about five metres clear between stalls/fence and station. These are depicted generative targets, not surveyed measurements of individual painted objects.
- The station stays fixed while its platform widens to create one straight railway-facing boundary, continuous with the market concrete edge. Yellow paint occurs only at the station platform and immediately adjoins the transparent exterior; no extra foreground paving strip covers the railway.

## Integration and calibration

- Step-zero relocation (2026-11-03) first translated the whole painting 260 m west. The subsequent scale/layout trial reduces its rendered size to 60%, using `market = Rect2(-182, 344, 150, 46.8)` while retaining the railway-facing anchor. `g_south` ends at x=-290; `former_market` marks grass east of the avenue, `Rect2(15, 315, 215, 78)`. The resulting roughly 30 m setback from south street is available for a future forecourt/access layout. **Everything depicted in the painting is intended to become separate 3D geometry**, including the station, market, bus bays and surroundings. The 60% scale is a temporary composition trial, not a requirement to give every future asset one common factor: painted people and vehicles have inconsistent relative sizes.
- The `market` event location ID is preserved. South-hub subzones follow the new market and station areas, with reduced activity on the former market field.
- `building_catalog.gd` uses `painted_lot`, the v7 sprite and grass beneath it, avoiding the old duplicate paving slab. The picture reserves the site against additional random dressing.
- Grounded strips now use canvas width 133.26 map units, footprint 146.4 x 42 m, anchor `(0.7913, 0.9867)`, source axes `(+0.583, -0.600)` and local offset `(0.8, 2.3)`. Only renderer placement/scale changes; the approved source and optimized PNG are untouched. The affine vertical correction remains about 0.976.
- The anchor remains at world `(-33, 390.7)` (originally `(227, 390.7)`). The smaller painting's ground envelope ends around z=392.0. Track centres remain z=395 and 405. The image contains no rails of its own.
- The static passenger-line wagon is no longer created. Port-siding wagons are unchanged.
- Optimizer: sprite profile, explicit 2048px limit for the whole site. Size remains 1605 x 980; PNG drops from 1,254,991 to 1,212,233 bytes; alpha extrema remain 0–255. No cropping or palette quantization.
- Godot import and the required sprite-anchor refresh were run. This painted lot uses its explicit calibrated corner instead of the automatic average edge anchor.

## Visual verification

- Inspected actual Godot frames `in-game-v7.png` (whole site) and `platform-v7.png` (station, straight boundary and both clear tracks). No duplicate station, old market stalls, old paving slab or passenger wagon is present. No script errors occurred during the focused captures.
- Earlier v1 autoplay produced overview and hub frames, then ended after the day-card frame; a completed first-week playthrough is **not** claimed. It reported the already recorded shutdown warnings about four ObjectDB instances/two resources still in use. The final v7 was checked with focused graphical captures rather than automated tests.
- `autoplay.gd` now includes `0_market_hub` for repeatable visual review.
- This is one static late-summer painting for the fixed isometric camera. Painted shoppers, buses and stalls do not independently animate or simulate internal aisle movement; separate seasonal/event art and 3D models are future work.

## Next action

The new `station_platform.gd` supplies a separate 180 x 6.5 m 3D platform, x=-100..80, z=386.25..392.75, passing under the avenue and extending east. Its paving surface is y=1.28, near the ER2's modeled upper step (about y=1.29 on these tracks). The conservative full-width ER2 envelope leaves 0.245 m horizontally to the platform edge. Bridge piers at z=385/425 stay outside the platform and both tracks. Actual instantiated train bounds measured in Godot: ER2 length 82.286 m, highest point y=5.588 including pantographs; freight length 137.120 m, highest point y=4.611. The level bridge slab underside is y=6.800, leaving 1.212/2.189 m respectively, so the current models need no bridge-height increase. These are model clearances, not a catenary design: overhead wiring is not implemented.

Godot graphical review inspected the compact site beside residential blocks, the platform beneath the bridge, and both existing trains posed on their actual tracks under the span. Local frames and measurement script/log are in ignored `.local/rail-overpass/` (`layout-overview.png`, `layout-platform.png`, `measure.log`). Train poses are review-only; normal shuttle behavior is unchanged and does not stop for boarding. The capture exits 0 with the previously recorded ObjectDB/resource shutdown warnings. No automated tests were added or run.

Next: user review of this composition, then replace all painted elements with individually scaled 3D assets and design the forecourt/access. Keep the existing five-storey blocks and approved rolling stock as scale references. Earlier v7 captures above predate this layout trial.
