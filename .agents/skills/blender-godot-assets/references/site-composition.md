# Complete map-location composition

Apply this guidance to every new or reworked map location: building ensembles, industrial and service sites, churches, kiosks, private houses and courtyards. The user approved the compact ATP's actual-game appearance on 2026-11-06 after rejecting a large, sparsely used paved parcel. The worked example, measured layout, sources and inspected frames are recorded in [the ATP asset record](../../../../art/models/industrial_sites/README.md). Keep those asset-specific facts there rather than copying its layout to every location.

## Locations are set dressing: size them by need, not by lot

Most map locations are scenery for the city, not simulated facilities. The city feels alive when many different small places fit into it, not when one function is spread over a large parcel (twenty containers in three rows 50 m apart). The lot rectangles in `init/scripts/data/district_layout.gd` come from an early zoning sketch and are often far larger than the location needs. Treat a lot as an upper bound, never as the target size. Oversized parcels were rejected before (the first ATP).

1. **Brief the place before the first polygon.** Write five short answers into the asset README: who uses it, when, what typically happens there, its condition in 1997, and what was added informally or has decayed since Soviet times. Derive zones and props from these answers.
2. **Compute the need.** Sum the real footprints of the buildings and the minimum circulation (aisles, turning space, paths, a forecourt), then multiply by 1.3. Use the reference sizes below unless a cited source gives better ones.
3. **Compare with the lot.** If the lot is more than 1.5 times the need, stop before building. Propose a reduced lot and what goes into the freed land (another small location such as a kiosk, workshop, wasteland with a desire path or a playground), and ask the user. Do not fill an oversized lot with repetition or empty paving.
4. **Keep distances.** Streets, junctions and walking times to quest locations stay unchanged unless the user explicitly agrees; the README makes travel time part of the gameplay. Shrink the parcel inside the street grid and fill the freed space with new places, never pull the streets together.
5. **Show the function with the minimum area.** Three garage rows tell the same story as ten. Spend the area on variety, not on repeating one element.

Approximate reference sizes for a starting estimate (a cited real reference wins over this table):

| Element | Size |
| --- | --- |
| Soviet garage box | 3.0–3.5 × 6 m; aisle between facing rows 7–9 m |
| Street kiosk (ларёк) | 2–3 × 3–4 m |
| Bus stop pavilion | about 3 × 1.5 m |
| Grave with its iron railing (оградка) | about 2.5 × 2 m; paths 1–1.5 m |
| Small parish church with churchyard | about 40 × 50 m in total |
| Private house plot | 600 m² (six sotki), for example 20 × 30 m |
| 1990s petrol station | about 30 × 40 m |
| Small district boiler house with chimney and coal yard | about 50 × 60 m |
| Courtyard playground | about 15 × 20 m |

## Compose a lived-in place

Correct dimensions are a requirement, not a result. Report these composition checks, not only measurements:

- **Hierarchy from the game camera:** one focal point per location, an approach axis from the street, a marked gate or threshold and a forecourt. In the standard capture the entrance must be readable at a glance.
- **Purpose for open space:** every open area larger than about 15 × 15 m has a named use or is removed. Report the share of the lot that buildings, circulation and purposeful yards occupy.
- **Planned and informal layers:** the Soviet base layout may be a grid, but add an informal layer on top: lean-tos and self-built additions, desire paths across lawns, dumped material along fences, gaps in fences, objects turned 5–15° off the grid.
- **Wear where people go:** trampled earth at gates and short cuts, puddles in low spots, litter in corners. Keep wear tied to real movement.
- **No visible repetition:** no two identical variants side by side; vary rotation, mirroring, colour and condition. Each private plot gets its own character (vegetable beds, shed, washing line, dog kennel).
- **Vegetation in groups:** clustered trees of mixed species and ages (birch, poplar, maple, lilac), hedges along fences, overgrown corners. Avoid single evenly spaced trees.
- **Treated edges:** every parcel edge meets its neighbour with a ditch, kerb, hedge, verge or a fence of a stated type. Plain grass meeting grass is unfinished.
- **Period details:** add elements typical for the place in 1997 that also give quests a stage (where people wait, where something is sold). Ask the user or Claude Code for period details when the brief does not give them.

## Review the blockout before detailing

Before modelling details or materials, build the composition with simple volumes, zones and paths, integrate it at its real place and capture it from the standard game camera. Report the size calculation, the five-answer brief and the composition checks above, then stop for the user's review (Claude Code may review it too). Offer a second layout variant when the arrangement is a real choice. Detail only an approved blockout; changes are cheap at this stage and expensive afterwards.

## Establish the working site

- Start from an actual current Godot frame and the existing concept. Reconcile the ensemble's dimensions, road/rail interfaces and intended map camera before detailing individual objects.
- Compose a main building, functionally justified support buildings, circulation, enclosure and landscape as one place. Basic volumes are a useful intermediate stage; a finished-site request also needs readable materials and a purposeful yard.
- Give open space a use: manoeuvring, working apron, storage, parking, pedestrian access or planted buffer. Fit the parcel to those needs as described above. Reclaimed land should become another location or deliberate landscape, with the old paving removed.
- When changing a parcel, update its geometry and dependent records, such as the district subzone, ground coverage and access placement. Keep the building's own real dimensions unless a separate size change is agreed.

## Place vehicles by activity and access

- Establish a connected route from the existing street, through the gate and between the working areas. Separate entry/exit where useful; put control, pedestrian access and staff parking where their purpose is clear.
- Preserve turning space at corners and in front of working doors. Use the actual current bus/truck/car instances and their approved presentation scales as the yard's size references. ATP's painted route uses an 8 m aisle and 9 m centreline turns; these are an example, not a validated envelope for other vehicles.
- Put stored vehicles in marked bays off the circulation aisle, service vehicles at service bays, deliveries beside stores and employee cars beside office access. Keep doors and through routes clear. A partially open bay with one appropriately placed vehicle can explain the site's function.
- Connect driveways to the real road edge and reconcile surface heights. ATP uses the highway's approximately 0.14 m surface level; the general map-ground helper alone does not supply this height.
- Distinguish modeled/painted access from implemented traffic behavior. Stationary scenery, guide arrows and open barriers do not implement bus visits, gate control, navigation collision or validated swept paths.

## Make the enclosure and landscape part of the composition

- Follow the facility's brief. The approved ATP has an opaque precast-concrete perimeter, controlled vehicle openings, a gatehouse and a separate pedestrian wicket. Its exact fence treatment is specific to that location.
- Use planted verges, small interior beds and an irregular rear tree/shrub belt to define edges and reclaim excess paving. Preserve sightlines, gate openings and turning space. Reuse the project's seasonal vegetation with restrained scale variation.
- Differentiate asphalt circulation, concrete work aprons, pedestrian approaches and planted ground. Keep patching and wear tied to real use; broad repeating checkerboard variation makes a yard look like a placeholder texture.

## Finish and review in context

- Give masonry, concrete, roofing, painted steel and glass their own surface response and physical UV scale. A flat tint or simple noise map can support massing, but does not by itself reproduce the material character visible in the concept.
- Model the visible structure: window/door reveals and frames, roof profile and overlaps, gutters, downpipes, service fittings and thresholds. Match detail to what survives the ordinary game camera; hidden closures can stay simple.
- Reuse suitable props, vehicles, vegetation and prepared materials. For new generated surfaces, follow `art/ASSET_PIPELINE.md`: preserve the original, apply the relevant visual/batch approval, prepare a separate optimized copy, then build the portable material. Keep generated base color distinct from authored roughness/normal response.
- Share textured materials; never ship one copy per model. Blender embeds every texture into every GLB it exports and Godot extracts a PNG beside each one, so 30 models using the same six materials once produced 185 PNGs holding 14 distinct images and 71 MB of duplicated data (the first frontier pass, PR #104). Put each texture once under `init/assets/materials/<set>/` with one shared material file per material name, strip the embedded images from the GLBs (`tools/strip_glb_textures.py`) and swap the shared material in with an import script set in each model's `.import` file (`init/scripts/dev/shared_material_import.gd`). `art/models/industrial_sites/export_assets.py` and its README show the working pipeline. Before committing a batch of models, check the size: `git ls-files -s` shows identical files as one blob, but every distinct GLB is stored in full, so look at the total size of the new `.glb` files, not only the file count. Compare before and after captures numerically and report the megabytes saved.
- Keep building, support-asset build, export and graphical capture stages resumable. Preserve refined source overrides when rebuilding a broader pack. Batch repeated walls, markings and small props where practical.
- Inspect the complete site from the standard game camera, with surrounding roads and existing vehicles. Use a focused capture rather than replaying the whole game. Record the user's approval against the actual inspected version and retain meaningful limits such as unverified turns or unreviewed seasonal/night appearance.
