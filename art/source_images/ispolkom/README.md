# Executive committee design exploration

Production continued after these concept iterations. Current implementation status, saved Blender/GLB assets, remaining work and the new-chat handoff are in `art/models/civic_center/README.md` ("Resume here — unfinished task"). Historical approval/status statements below describe each concept stage, not the current production state.

Built-in ImageGen concepts, 2026-11-02. Awaiting user art feedback; no visual approval, model production, optimization or game integration.

- `map-reference.png`: user's actual Godot screenshot with civic textures in development.
- `map-direction-v1.png`: initial square and village-edge proposal; superseded because the ceremonial entrance incorrectly faces the rear street.
- `map-direction-v2.png`: revised square-facing entrance, broad pale modernist office bar, relief-bearing hall volume, open gathering square with planted edges, and a screened service court between administration and the local street. Village and principal roads remain in place. This is a generated paintover, not an engine screenshot or validated site plan.
- `building-multiview-v1.png`: front/rear three-quarter views and front/side elevations derived from map v2. A design reference, not measured construction drawings: floor count, hall proportions, canopy and annex details vary between panels and must be resolved before modeling. The generated hall became a taller solid volume rather than the originally proposed low wing.

Exact prompts are adjacent to their outputs. Map v2 uses map v1 as its edit target; the multiview sheet uses map v2 as its building reference. Originals are preserved unchanged. Existing shared `art/PROMPTS.md` and root README were already being edited by another session and were left untouched; index this record there when those edits are finished.

## Compact site revision

The user liked the building design, requested roughly half the square area and relocation toward the avenue, and accepted exploring a rear green square with the original building site left vacant for now. `map-direction-v3.png` is the built-in ImageGen proposal responding to that feedback; its exact prompt is adjacent. It relocates and reduces the administration, leaves a compact forecourt, introduces a rear green square and keeps a rough-grass reserved plot at the former site. Architecture is positively received; this revised site plan still awaits review. The generated canopy again faces the rear service parking, contrary to the intended square-facing main entrance; resolve that before production. Human/car/window scale is indicative, not measured or validated by this image.

## Culture house, cafe and village land enclosure

User-directed v4 replaces the northern residential tower with a late-Soviet district House of Culture and adds a small private 1990s cafe at the street edge of the park. The user clarified that the long PO-2 diamond-panel fence belongs on the VILLAGE side of the local road: someone is acquiring most of the western village land and has already marked control with a fence, even while residents still live inside. Preserve inhabited cottages, gardens and access gates; this is narrative land pressure, not a civic park boundary. Wealthy residents are intended for a separate forest-side cottage/dacha area. These decisions should be transferred to the root README once its other-session edits are finished.

`map-direction-v4.png` is the untouched built-in ImageGen edit of v3; exact prompt is adjacent. Inspected: northern tower replaced by a foyer/auditorium building with mosaic, small green-roof cafe beside park, concrete relief fence on village road frontage with gates and inhabited gardens behind. Site and architecture remain conceptual; the entrance orientation issue from v3 is inherited and dimensions are not validated. Awaiting user feedback; nothing integrated.

## Nouveau-riche restaurant revision

User requested a richer, more prestigious first post-Soviet architectural addition, with less greenery and greater pomp at the cafe corner. `map-direction-v5.png` replaces the cafe with a newly built two-storey red-brick restaurant mansion: cream classical trim, burgundy roof, balcony, fenced paved forecourt, small fountain and expensive period cars. This is an original provincial interpretation, not a replica of a historical restaurant. Context references: Tsarskaya Okhota (opened 1996, https://tsarskayaokhota.ru/) for elite restaurant positioning; Cafe Pushkin (opened 1999, https://cafe-pushkin.ru/o-restorane/istoriya/) for mansion-style historical imagery, used as a near-period aesthetic reference rather than an establishment existing in our 1997 setting. Current source photographs are not claimed to show original 1990s exteriors.

Untouched built-in ImageGen edit of v4; exact prompt adjacent. Inspected in the map composition: local restaurant grounds are more formal and paved; surrounding civic buildings, village fence and remaining public greenery are retained. Awaiting user art review, not integrated. The administration entrance orientation and measured scale remain unresolved as recorded above.

## Restaurant-casino and revised parcel

V6 uses `user-casino-reference.jpg` (user-supplied reference URL: https://f.kyivmaps.com/location/795/NH10N.jpg) to develop a newly built 1990s restaurant-casino with pre-revolutionary commercial-arcade and Greek/neoclassical motifs. The reference photograph is not original generated project art and is retained for reference only. V7 reduces the complex, rotates the entrance toward the village-fence street, and revises parking, sidewalks and neighboring green space. Exact built-in ImageGen prompts are adjacent to both untouched outputs. V7 also replaces the earlier rough-grass vacant plot with landscaped green; this is a generated departure, not a separately approved land-use decision.

The user chose to leave v7 as the current working image while explicitly remaining dissatisfied with its visual quality. This is a provisional selection, not final art approval or authorization to integrate into Godot. No model or game changes have been made. Administration entrance orientation and measured world scale remain unresolved.

Next: retain v7 for future review; do not continue generating or start production without a new request. The House of Culture's gameplay purpose is being discussed and is not decided.
