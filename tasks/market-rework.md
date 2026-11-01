---
id: market-rework
status: review
worker: lead
issue: "#26"
---

# Compact, colourful station market

## Goal

Replace the current long, sparse field of identical market sprites with a compact clothing market directly beside the passenger station. The user requested separate 3D stall models, a substantially shorter market, denser stall placement and pedestrian aisles, and visibly colourful tents ("bunt!"). Discuss the 3D assets separately before producing or integrating them.

**Current authorized scope:** the user subsequently chose one combined 2D market/bus station/railway station image in the moved market lot as the interim implementation. This phase is integrated with asset v7 for review. Separate 3D models and internal aisle simulation are deferred; they are not acceptance requirements for this 2D phase.

## Inputs

- `README.md`: the campaign setting and market direction (source of truth).
- User screenshot: `/Users/oleksiisuprun/Desktop/Bildschirmfoto 2026-11-01 um 09.26.27.png` shows the current problem: repeated pale stalls on a large elongated paved lot with broad empty gaps.
- `art/concepts/isometric-city-direction-v2.png`: existing city concept with a compact, colourful clothing market. Candidate reference for discussion; its market layout and colours are not yet approved for this rework. Do not copy the surrounding architecture, tram or autumn season.
- `art/source_images/situation_banners/market_cops_v1.png`: existing close-up illustration of the station market, useful for clothes, tarpaulins, tables and shuttle traders' bags; not a map layout reference.
- Current lot coordinates and market construction: `init/scripts/data/district_layout.gd`, `init/scripts/data/building_catalog.gd`, and the map renderer.
- For subsequent model work: `.agents/skills/blender-godot-assets/SKILL.md` and `tasks/README.md`.

## Agreed requirements

- Substantially reduce the market's length and move it directly beside the station; retain usable station access.
- Pack stalls and aisles more closely while keeping actual pedestrian routes passable.
- Make the varied tent colours readable under the real map camera.
- Use separate 3D models for stalls; discuss model types, appearance and production approach before asset work.
- Preserve the market's clothing-trade identity and role as an event location.
- Latest user-directed layout (supersedes v2's unchanged bus/station positions): remove the static freight wagon from the passenger tracks entirely; move the railway building almost up to the rails with a narrow platform between; double the market width relative to v2 and extend it close beside the building; move the bus station into one straight row behind the railway building on the road side.
- Show the vacated old market site as open grass for now; its eventual use is not settled.
- Later corrections: a metal mesh fence on the market's railway boundary; no decorative planting/furniture along that boundary; no ambiguous dark structure in front of the station; slightly larger station and smaller stalls with a clear gap between. Keep the station fixed while widening its platform so the fenced market concrete edge and station platform edge form one straight line. Both through tracks must remain outside the painting.

## Open design choices

- Confirm which visual reference the user means and discuss what to take from it.
- Agree on exact footprint, position relative to the station, stall count, row arrangement and aisle widths.
- Agree on the stall kit, roof shapes, palette, merchandise detail and asset sourcing/creation approach.
- Exact platform extent, bus bay access/turning and clear pedestrian connections. The old market site's eventual use remains open; grass is the provisional concept treatment.

## Outputs

The lead integrated the user-authorized 2D phase in the main checkout: versioned sources under `art/source_images/market_hub/`, optimized game image and report, catalog/layout data, the shared painted-lot placement, passenger-wagon removal, sprite anchors and an autoplay hub view. Campaign state is in `README.md`; asset state, actual frames, calibration and limitations are in `art/market_hub/README.md`. The requested real-map workflow is recorded in `AGENTS.md` and `art/ASSET_PIPELINE.md`. The PR branch is based on the latest origin/main.

## Acceptance criteria for this 2D phase

- [x] Approved map-based direction is represented by a combined 2D image in the moved market lot; actual dimensions and source are documented.
- [x] Original is preserved, game copy separately optimized, genuine transparency checked and sprite anchors refreshed.
- [x] Old market becomes grass; no duplicate station or original stall rows remain. Market event ID is preserved.
- [x] Passenger-line wagon is removed; platform/market edge is straight and both original tracks remain free. Road-side buses form one straight row in the image.
- [x] Actual Godot overview and close-up inspected; no automated tests added or run.
- [ ] User accepts the final in-game v7 framing. Source percentages/gap are visual targets; independent internal pedestrian/bus movement is not implemented by the painting.

## Report

- **Status summary:** Interim 2D implementation complete for visual review, using asset v7. Detailed current state and verification: `art/market_hub/README.md`. Separate 3D production is deferred.
- **References inspected:** City concept and market conflict illustration listed above, plus the user's current-game screenshot.
- **Concept produced:** `art/concepts/market-direction-v1.png`, generated and visually inspected. Prompt and limitations: `art/concepts/market-direction-v1.prompt.md`. User review pending; no game changes.
- **User review of v1:** Visual treatment generally promising; composition inconsistent with the map because it omits the bus station. Do not use v1 as a placement plan.
- **Existing map verified:** Current west-to-east order is market, bus shelter/bus area in the western part of the shared station lot, railway station building farther east. The user subsequently explicitly directed relocation of the bus area and railway building for v3; preserving their current positions is no longer a constraint.
- **Map-based v2 produced:** `art/concepts/market-direction-v2.png` uses a fresh actual Godot screenshot (`market-direction-v2.map-reference.png`). Proposed market footprint about 70 x 45 m in the gap west of the bus station (x=-35..35, z=325..370), retaining bus shelter/apron and railway building in place. This is a proposal beyond the current market lot boundary, not an implemented or approved layout. Exact prompt and caveats: `art/concepts/market-direction-v2.prompt.md`. Former market paving is left unassigned.
- **User-directed v3 produced:** `art/concepts/market-direction-v3.png`, visually inspected. Removes the wagon, moves the railway building close to the tracks with a platform, enlarges the market toward the building, puts buses in a straight row on the street side, and shows the old market site as grass. Exact prompt and limitations: `art/concepts/market-direction-v3.prompt.md`. The user approved v3 as the visual and spatial direction on 2026-11-01; no game files changed.
- **Final asset revisions:** v1's distorted first integration was rejected. v2–v7 follow the subsequent concrete user corrections; versioned originals are preserved and exact prompts are in `art/market_hub/REVISIONS.md`. Current game source is v7, not the earlier concept or asset v1.
- **Next action:** User review of `art/market_hub/in-game-v7.png` and `platform-v7.png`. Discuss any later 3D asset work separately; do not resume it automatically.
