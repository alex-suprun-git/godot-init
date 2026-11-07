# District visual reference pack

Requested 2026-11-03: modeling projection sheets plus a view matching the game camera. These are proposals for review, not approved production art, measured blueprints or game integration.

The current police UAZ already has an approved reference and built model: `../../models/uaz_service/README.md`. Reuse it rather than regenerate it.

Current map screenshots were captured from this worktree with `--autoplay --only=map --turbo --no-log`, after importing project assets. The source overview and village frames remain in ignored `.local/visual-pack-review/0_overview.png` and `0_village.png`, rather than repository content. Building dimensions come from `init/scripts/data/building_catalog.gd`; parcel dimensions come from `init/scripts/data/district_layout.gd`. School and kindergarten layouts are proposals inside existing residential core reserves, not settled placements.

Scope: church, adjacent cemetery, two maintained 1940s–1960s cottages plus an owner-altered 1970s masonry house, separate school and kindergarten, alcohol and bread kiosks, two courtyard playgrounds, and the existing industrial/service sites: ATP, truck-stop cafe, customs office and warehouse, both port warehouses, fuel depot, boiler house and garage cooperative. There is no separate factory parcel in the current map.

User refinement: timber houses belong only at the outer edges as older remnants. Inner private-sector plots use maintained masonry/plastered homes, including owner alterations made by the 1990s. Every parcel needs a proper perimeter, vehicle gate and separate pedestrian wicket. The first cottage sheets predate this refinement; v2 revisions address the parcel boundaries.

Completed: 19 new selected sheets, plus the reused police UAZ sheet; 25 generated PNG originals/revisions are preserved, together with a native SVG border-flow diagram. The original batch's selected image links and PNG signatures were checked. Each generated original has an adjacent exact prompt. Generator: built-in ImageGen. No optimization is needed for modeling-only references outside `init/`; any later generated game textures must follow `art/ASSET_PIPELINE.md`.

Review constraints: generated multiviews may disagree on geometry, window counts, proportions and dimensions. Reconcile these against one measured model before production. A generated camera panel is a concept, not evidence of Godot integration.

Industrial implementation: the user authorized translating all seven selected industrial/service concepts into 3D. A first modeled assembly is integrated on their existing parcels; see `art/models/industrial_sites/README.md` from the repository root for actual sources, layout interpretations, captures and remaining checks. The sheets remain references. The user approved the compact ATP in its actual-game context on 2026-11-06; the other industrial sites await their own refinement/review.

Dormitory addition: the user requested the protagonist's home as a small maintained 3–5-storey dormitory with a non-rectangular plan, recalling Tarkov's architecture without its destruction. V1 proposes four storeys, an L-shaped 30 x 23 m bounding box with 11 m-wide wings and a small entrance court; parcel, exact architecture and occupancy remain undecided. The large camera view and roof plan communicate the direction, but the narrow side elevations omit the full extent of the return wing and must be rebuilt from one measured plan before modeling. Historical plausibility references: [four-storey dormitory passport 161-135-214](https://files.stroyinf.ru/Data2/2/4294852/4294852711.pdf); [four-storey U-shaped 1-404-3 repair-project description](https://proekt.sx/socobespechenie/1181-detail.html). The proposal is not a reconstruction of either building.

Border-crossing revision: use [architecture/context v2](industrial-customs-v2.png) with the [canonical flow proposal](border-circulation-v2.svg). V1 incorrectly placed the through road east–west. The real 250 x 120 m parcel lies south of the bridge, with the city/bridge axis running north–south; retain the bridge, highway and adjacent parcels. Import travels south on the western half; export travels north on the eastern half. Both pass border/passport and customs control; document-waiting loops rejoin before control, and optional secondary inspection rejoins the same direction without bypassing remaining checks. Separate cars/trucks, fenced pedestrian in/out control and controlled vehicle gates are required by the brief. The SVG clarifies topology where generated arrows/side loops are ambiguous. The raster also invents a northern frontage road, duplicates inspection halls and changes administration massing between views: do not treat these as approved geometry; the actual map and SVG govern the next measured layout. Separate inspection areas may share support facilities rather than require two full halls. Bus-bay position, long-queue overflow, 17 m rig turning envelopes, pedestrian connection within the bridge width, final staffing and exact building placement remain open. These are references only; no traffic routes, buildings or gameplay were changed. General design reference: [OSCE/UNECE handbook, chapter 6, published pages 148–150](https://cdn.osce.org/sites/default/files/f/documents/7/6/88238.pdf), used for circulation principles, not as evidence of an exact 1997 border regime or national standard.

## Sheets for review

| Group | Selected sheet |
|---|---|
| Police UAZ, existing approved reference | [Six-view sheet](../../models/uaz_service/references/uaz-police-turnaround-v1.png) |
| Church | [v1](church-v1.png) |
| Cemetery west of church | [v2](cemetery-v2.png) |
| Timber cottage, outer edge only | [v2](cottage-timber-v2.png) |
| Maintained 1950s–1960s masonry cottage | [v2](cottage-masonry-v2.png) |
| Owner-altered 1970s masonry home | [v3](house-1970s-v3.png) |
| Protagonist dormitory, proposed four-storey L shape | [v1](dormitory-v1.png) |
| School | [v1](school-v1.png) |
| Kindergarten | [v1](kindergarten-v1.png) |
| Alcohol kiosk | [v1](kiosk-alcohol-v1.png) |
| Bread kiosk | [v1](kiosk-bread-v1.png) |
| Playground with swings/slide | [v1](playground-a-v1.png) |
| Playground with roundabout/seesaw | [v1](playground-b-v1.png) |
| ATP | [v1](industrial-atp-v1.png) |
| Truck-stop cafe | [v1](industrial-truck-stop-v1.png) |
| International road border crossing | [v2](industrial-customs-v2.png), [flow diagram](border-circulation-v2.svg) |
| Both port warehouses | [v1](industrial-port-v1.png) |
| Fuel-depot warehouse, tanks and tower | [v1](industrial-fuel-v1.png) |
| Boiler house and chimney | [v1](industrial-boiler-v1.png) |
| Garage cooperative | [v1](industrial-garages-v1.png) |

Inspection notes: cemetery v1 reverses the church/cemetery relationship; v2 corrects it. Cottage v1 sheets predate the requested complete enclosure; use v2. House-1970s v3 removes unrelated burial markers from both private-garden views. The school sheet mixes a linear and an offset gym arrangement and conflicting overall dimensions: resolve one building plan before modeling. ATP/truck-stop/fuel-depot contextual plans borrow port-like cranes and extra warehouses from the overview: those are not additions to the approved site; retain the real lot/road geometry and omit unrelated props. Playground B's sheet includes an extra near-duplicate layout and misleading A/B headings: its defining modules are the roundabout, seesaw, climbing arch and mushroom sandbox; the separate playground A sheet defines the swing/slide variant. Gate/roof/window details and generated scale annotations remain design references, not verified measurements.
