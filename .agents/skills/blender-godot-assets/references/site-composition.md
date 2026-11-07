# Complete map-location composition

Apply this guidance to a building ensemble or industrial/service site. The user approved the compact ATP's actual-game appearance on 2026-11-06 after rejecting a large, sparsely used paved parcel. The worked example, measured layout, sources and inspected frames are recorded in [the ATP asset record](../../../../art/models/industrial_sites/README.md). Keep those asset-specific facts there rather than copying its layout to every location.

## Establish the working site

- Start from an actual current Godot frame and the existing concept. Reconcile the ensemble's dimensions, road/rail interfaces and intended map camera before detailing individual objects.
- Compose a main building, functionally justified support buildings, circulation, enclosure and landscape as one place. Basic volumes are a useful intermediate stage; a finished-site request also needs readable materials and a purposeful yard.
- Give open space a use: manoeuvring, working apron, storage, parking, pedestrian access or planted buffer. When the user authorizes compaction, fit the parcel to those needs. Reclaimed land should become deliberate landscape or reserve, with the old paving removed.
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
- Keep building, support-asset build, export and graphical capture stages resumable. Preserve refined source overrides when rebuilding a broader pack. Batch repeated walls, markings and small props where practical.
- Inspect the complete site from the standard game camera, with surrounding roads and existing vehicles. Use a focused capture rather than replaying the whole game. Record the user's approval against the actual inspected version and retain meaningful limits such as unverified turns or unreviewed seasonal/night appearance.
