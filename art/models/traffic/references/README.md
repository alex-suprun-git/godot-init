# Freight vehicle modeling references

Generated with built-in ImageGen on 2026-11-01 in response to the user's request for two ZIL variants and a KamAZ carrying consumer goods. All three untouched originals are preserved here. Exact prompts are in the adjacent `.prompt.md` files. These sheets are generated modeling aids, not measured blueprints or verified historical records. They have been visually inspected and are presented for user review; the user requested 3D production from these sheets and positively reviewed the resulting model direction on 2026-11-01.

| Variant | Original | Construction proposal |
| --- | --- | --- |
| Food ZIL | `zil-food-turnaround-v1.png` | Blue classic ZIL-130-family cab, off-white insulated food-delivery box. No refrigeration machinery assumed. |
| Coal ZIL | `zil-coal-turnaround-v1.png` | Green classic ZIL-130-family cab, wooden drop-side bed, olive canvas partly pulled back over visible coal. |
| Container KamAZ | `kamaz-container-turnaround-v1.png` | Beige classic KamAZ-5410-family three-axle tractor, two-axle skeletal semi-trailer and one blue closed 40-foot ISO dry container. |

## Inputs and scope

The coal sheet directly referenced `zil-coal-original-sprite.png` (originally `init/assets/sprites/truck_zil_plain.png`) using ImageGen's image-reference mechanism. The food and KamAZ sheets were new text-guided generations. Existing KamAZ concept `art/concepts/truck_kamaz_candidate_2.png` was inspected for project context, but was not passed as an image reference: it depicts a tarpaulin trailer, whereas this request explores a container.

Each sheet has full left/right, front, rear and top views and a three-quarter preview. The food sheet also includes a small open-rear cargo inset. All principal views are closed. No raster optimization or Godot import is needed for these modeling references outside `init/`. No existing GLB, sprite, scene or gameplay script was changed. The existing rough freight models remain under `art/models/traffic/` with exports in the game.

## Visual inspection

### Food ZIL

All six requested views are complete. Blue cab, pale grille, two-axle chassis, light box body and rear double doors are clear. Rear inset suggests plain cartons/crates without vehicle signage. Side views agree broadly on wheel placement and body proportions; minor cab curvature, mirror positions and box seams differ in front/three-quarter projections. The exact insulated body subtype, dimensions and material are proposals, not settled specifications. Do not mistake the closed food box for a detachable shipping container.

### Coal ZIL

All six views are complete. The source's green cab, wooden sides, covered forward bed and exposed rear coal are retained; severe original corrosion is reduced, though the sheet remains visibly more worn than the food truck. Resolve cab roof-marker shape/count (side projection differs from front/top), tarp height/folds and coal opening into one coherent construction. The cab family matches the food ZIL, but both generated cabs need shared landmarks before modeling; they are not interchangeable measured drawings. A rigid wooden bed is proposed, not a tipper.

### Container KamAZ

All six views show the full coupled combination. The main side views clearly show three tractor axles and two trailer axles; front/rear views and top panel provide useful construction cues. Closed blue corrugated container has rear double doors/locking rods and distinct trailer chassis. Resolve fifth-wheel/container clearance, skeletal frame, landing-gear mounting, axle positions and corrugation spacing before modeling; generated details and proportions are not engineering proof. Consumer goods are conceptually inside the closed container, not visible externally. The 40-foot ISO interpretation remains a visual proposal because the user's container wording was tentative; a plain box semi-trailer is an alternative requiring creative selection.

## Next action

The three variants have been modeled and integrated on `art/truck-model-upgrade`; see `../README.md` for current source, scale, measured exports, review commands and limitations. The user positively reviewed the shown visual direction. The generated sheets remain source references, separate from the game assets.
