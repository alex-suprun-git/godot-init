# Sidewalk surface textures

## Current checkpoint — 2026-11-01

The user authorized executing `tasks/sidewalk-textures.md` after the generated candidates were presented. That authorizes preparation/integration of the discussed material direction; final in-game appearance is still for user review.

Implemented: light square concrete slabs on the civic `axis` south of the `north_street` junction, fine lighter asphalt on every other existing asphalt-road sidewalk. No new sidewalks were introduced. Winter uses the existing snow paving/asphalt. Detailed implementation, captures and rebuild commands: `../../sidewalks/README.md`.

| Untouched original | State |
| --- | --- |
| `sidewalk-slabs-clean-v1.png` | Selected; separately optimized to `init/assets/textures/ground_sidewalk_slabs.png`. |
| `sidewalk-slabs-aged-v1.png` | Preserved optional candidate, not integrated; no third placement rule invented. |
| `sidewalk-asphalt-v1.png` | Selected; separately optimized to `init/assets/textures/ground_sidewalk_asphalt.png`. |
| `sidewalk-slabs-clean-v2.png` | ImageGen perimeter-correction attempt, preserved but not selected; offset perimeter joints remained. |

Exact prompts are adjacent `.prompt.md` files. Original sources remain untouched. Optimizer reports are under `art/optimization_reports/ground_sidewalk_{slabs,asphalt}.png.json`; both prepared images are opaque 1024 × 1024, surface profile, no cropping or palette quantization. PNG totals fell from 7,710,663 to 4,511,718 bytes.

## Repetition and scale

The clean source's perimeter did not form a complete 4 × 4 slab grid. Instead of modifying its pixels, the Godot sidewalk material repeats a measured interior region of the optimized v1: x=12..767, y=36..796, in 1024px coordinates. These are joint centres spanning three slabs per axis; the region repeats every 1.5 m, giving approximately 50 cm squares. Small generated spacing variations remain (under about 1% overall aspect mismatch), not a surveyed construction drawing. Recheck sampling if the optimized source dimensions change.

The world-XZ shader keeps UV phase/scale continuous across split strips and road orientations, using unwrapped derivatives for mip selection. Visual inspection of 4 × 4 slab repeats and 3 × 3 asphalt repeats is saved in `../../sidewalks/materials.png`. No conspicuous double edge-joints or asphalt seams were seen in that preview or actual game captures; exact pixel-identical seamlessness is not claimed. At extreme close-up the generated slab grain/tones still repeat slightly.

These are top-down surface materials, not transparent prop sprites. No sprite-anchor regeneration applies. Existing road/lot textures were not bulk processed. No automated tests were added or run.

## Rendering revision after user feedback

The user found the first asphalt implementation too flat and noticed camera-clipped building geometry. No source images were changed: the current asphalt material uses a 4 m repeat, a 0.65 linear-albedo multiplier and restrained world-anchored metre-scale tonal variation. Slabs use a 0.85 multiplier. The orthographic camera is pulled back independently of zoom to avoid clipping nearby buildings. Current evidence and exact parameters: `../../sidewalks/README.md`, `../../sidewalks/review-v2/`. Winter keeps the existing snow appearance.

The user subsequently restricted slab paving to south of the north junction and removed the northern median trees. The river approach uses pedestrian asphalt. Current placement evidence: `../../sidewalks/review-v3/`; renderer/source details otherwise remain as recorded above.
