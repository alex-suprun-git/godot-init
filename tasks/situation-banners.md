---
id: situation-banners
status: done   # ready | in-progress | review | blocked | done
worker: codex
branch: task/situation-banners
---

# Banner pictures for the week-one situation cards

## Goal

Every situation card in the first week opens with a wide painted picture of the place and the people involved, like `init/assets/events/pipe_burst.png`. Today only the hot-water request has one (a stand-in); the other ten show a plain colored band. Paint one banner per situation, in the existing oil-painting window manner, so the cards carry place, mood and a little dark humor before the player reads a word.

## Inputs

Read first, in order:

1. `art/PROMPTS.md`: "Rules", "Established looks", the **window style block**, and the earlier window items W2 to W7 (some situations below reuse those scenes).
2. `art/ASSET_PIPELINE.md`: how to preserve the original and prepare the game copy.
3. The reference look: `init/assets/events/pipe_burst.png` and the portraits in `init/assets/portraits/` (use `gusev.png`, `baba_nina.png`, `mikhalych.png`, `tolik.png`, `boss.png`, `protagonist.png` as character references).
4. The data behind each situation: `init/scripts/data/week1.gd`, array `REQUESTS`. The titles and texts there are the scene's story.

## Constraints

- Canvas: wide, about **2.4 : 1** (for example 2400 × 1000). The card crops the image to roughly 3.5 : 1 from the center, so keep every face, hand and key object inside the **central horizontal band** (the middle 60 % of the height). Nothing important in the top or bottom fifth.
- If the generator cannot make 2.4 : 1, use 16 : 9 and keep to the same central-band rule.
- Window style block from `art/PROMPTS.md`. **Late August 1997, 25 to 29 August**: green trees with the first yellow leaves, warm light, summer clothes with the odd jacket. Do not paint October or winter.
- No readable text, signs or lettering anywhere (Cyrillic comes out garbled). Newspapers, ledgers and placards are shapes only.
- Characters with an established look in `art/PROMPTS.md` must match it. New characters get a short established look added to `PROMPTS.md` (see Outputs).
- 1990s only: Ladas, Volgas, UAZ, ZIL, rotary phones, no phones in pockets, no modern cars.
- Quiet dark humor in small details, grounded and a little melancholic, never cartoonish.
- User review update (2026-10-31): an inhabited, functioning city, with modest wear and ordinary upkeep; no pervasive ruin, mud, rust or broken glazing. The courtyard proposal contains exactly two small NEW kiosks with freshly painted metal, not stacks of rusty frames. For `envelope`, reuse the existing empty summer office without a visitor. No Lenin portraits or real-world national flags.
- Further review: daytime lamps are off, windows have natural light rather than artificial orange glow, and summer coat hooks have no heavy clothing. `fuel_offer` keeps the storekeeper with his closed ledger, but uses a quiet depot background with fixed tanks, a small storehouse and barrels; no transfer process, truck, railway wagon, hoses or other workers.

## The eleven pictures

Each is saved as `init/assets/events/<id>.png` (the id is the request id in `week1.gd`). Prompts below are what the picture must show; write the final prompt as `[Window style block] ...` and record it in `art/PROMPTS.md`.

| id | Situation | The picture shows |
|---|---|---|
| `hot_water` | No hot water in house 5 (plea). Replaces the October stand-in. | Late August, evening light. The courtyard of a five-storey panel building. Residents carry kettles and saucepans of heated water across the yard from a ground-floor window where a neighbor boils it on a hot plate; Baba Nina (headscarf, green notebook) stands in the middle counting people; a boy with a basin; a cold radiator pipe visible through a basement window. Tired, slightly absurd. |
| `contractor` | Two contractors want the same boiler house (conflict). | The yard of a red-brick boiler house with one tall chimney. Gusev (burgundy double-breasted jacket, gold chain) and a bulldog-faced foreman in a work jacket argue nose to nose next to their two cars (a new dark jeep, an old UAZ). Between them, a sleepy watchman in a booth turns up a radio. Same scene as item W7 in `PROMPTS.md`; draw that one here. |
| `envelope` | A visitor with an envelope (offer). | Same scene as item W4 in `PROMPTS.md`: across the aide's desk, Gusev slides a thick envelope with two fingers, smiling; his eyes in shadow; rotary phone, tea glass in a metal holder. |
| `church_heat` | The priest asks to heat the church (plea). | The inside of a small whitewashed church. Father Georgiy (about fifty, grey-streaked beard, black cassock, plain wooden cross) stands beside a cold radiator under a window, one hand on the iron pipe as if apologizing for it. Behind him four old women in headscarves and coats in August stand in front of an icon, one with a thermos. Dusty light from a high window. |
| `coal_theft` | Coal is being taken from the boiler house (crisis). | Mid-morning, bright and wrong. The open gate of a boiler house yard; a ZIL truck without plates, tarpaulin back, men with shovels loading coal from the heap; the watchman asleep in his booth with a bottle on the sill and a radio; the dead chimney behind. Urgent and darkly funny. |
| `wasteland_stalls` | Gusev wants kiosks on the wasteland (offer). | A wasteland between panel buildings: birches, glass bottles in the grass, a rusty swing frame. Gusev, pleased, gestures at it as if it were a showroom; a surveyor's stake with ribbon; behind him a trailer with stacks of metal kiosk frames. Residents' windows in the background, a few faces watching. |
| `market_cops` | Traders and the militia divide the market (conflict). | The market by the railway station: rows of tarp-covered stalls and folding tables, shuttle traders' striped plastic bags. In the center the district militiaman (grey uniform, cap pushed back, notebook) and a broad woman trader face each other over a table of jeans, each pointing at something different. Traders crowd behind her, the station building in the haze. |
| `fuel_offer` | The storekeeper offers fuel oil off the books (offer). | The fuel depot: white cylindrical tanks with pipe manifolds, rusty barrels. A storekeeper in a stained padded vest holds a thick ledger closed against his chest and looks past the viewer; a tank wagon behind him, a hose running to a truck whose plates are covered with a rag. Sunlight, oil sheen on the ground. Sly and calm. |
| `residents_meeting` | The tenants ask for a meeting (plea). | Evening in the courtyard of house 5: about fifteen residents stand and sit in a rough half circle on benches and curb stones in front of the entrance. Baba Nina in front with her green notebook open, arms crossed; men with cigarettes at the back; a woman with a baby; a boy on a bicycle at the edge. A single empty stool in the middle is waiting for someone. |
| `journalist` | A reporter asks for a comment (plea). | The aide's office from behind the desk, hands only: a hand on the receiver of a rotary phone, the cord stretched across a folded local newspaper whose headline is only grey shapes, a notepad with scribbles, a tea glass. Through the window, green trees; the pale rectangle on the wall where a portrait used to hang. A feeling of being listened to. |
| `boss_report` | The boss summons the aide for a report (crisis). | The boss's office seen from the padded doorway: Pyotr Petrovich (heavy man in his early sixties, grey swept-back hair, oversized grey suit, loosened burgundy tie) sits at a vast desk with folders in a fan, flag in the corner, window onto the town hall square. He looks up with the exhausted patience of a man who has done this many times. We see him over the shoulder of the protagonist's grey suit sleeve. |

## Outputs

Write only to these paths:

- `art/source_images/situation_banners/<id>_v<n>.png`: untouched, versioned originals (create the folder); retain superseded drafts and identify the selected version in the report.
- `init/assets/events/<id>.png`: the prepared game copies, produced with `uv run tools/optimize_asset.py ... --profile scene --approved` as in `art/ASSET_PIPELINE.md`. Do not overwrite `pipe_burst.png`.
- `art/optimization_reports/<id>.json`: written by the optimizer.
- `art/source_images/situation_banners/contact_sheet.png` and `center_crop_sheet.png`: overview of selected full images and their 3.5:1 card crops.
- `art/PROMPTS.md`: add a section "Situation banners" with each final prompt, and add "Established looks" entries for the new characters (Father Georgiy, the watchman, the storekeeper, the market woman trader, the militiaman, the foreman) so later art matches.

## Acceptance criteria

- [x] Eleven images exist under `init/assets/events/`, one per id above, each backed by an original under `art/source_images/situation_banners/` and an optimizer report.
- [x] Each image is wide (about 2.4 : 1, or 16 : 9 with the central-band rule) and its key content survives a center crop to 3.5 : 1. Check by cropping each one yourself and reading the crop.
- [x] No readable text or lettering in any image.
- [x] Late-August season in every image; established characters match their portraits.
- [x] A contact sheet of all eleven at reduced size, saved to `art/source_images/situation_banners/contact_sheet.png`, to check they look like one series.
- [x] `art/PROMPTS.md` updated as above.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a picture needs a creative choice this brief does not cover (for example a character's face that differs from the portrait and cannot be fixed);
- the generator keeps producing readable garbled text after three attempts;
- the work would require editing files outside *Outputs*.

## Report

- **Status summary:** All eleven prepared banners are ready for final creative review, including the user's in-chat corrections. Produced in the main session on 2026-10-31; no worker dispatch, commit or push. The final fuel-depot image has a quiet stationary background, with no pumping process. The user has directed individual revisions; this report does not imply blanket final visual sign-off.
- **Files created or changed:** Versioned originals in `art/source_images/situation_banners/`; eleven optimized game PNGs under `init/assets/events/`; reports under `art/optimization_reports/<id>.json`; prompts and character appearances in `art/PROMPTS.md`. `pipe_burst.png` is untouched.
- **Measurements / previews:** Ten selected generated scenes have 1942×809 originals and 1920×800 game copies. The user-selected reused office is 1672×941. Selected game PNGs total 27.11 MiB. Both `contact_sheet.png` (full images) and `center_crop_sheet.png` (3.5:1 card previews) are current and visually inspected. Main faces and story actions remain readable in the crops. Godot 4.7.1 headless import completed with exit 0 and imported the final fuel texture. The sandbox emitted macOS certificate and external editor-settings save diagnostics; no texture import failure was reported. No automated tests or gameplay playthrough were run; the later audit below confirms request wiring already exists in the HUD.
- **Open questions:** Final visual review is pending. The teal/ochre/ivory flag is a fictional visual proposal, not finalized worldbuilding.
- **Requests for the integrator (updated audit 2026-11-01):** No request-data wiring is needed: `hud.gd::_card_banner()` already defaults to `res://assets/events/<id>.png`, and all eleven files exist. Final visual review remains. No gameplay scripts or scenes have been edited by this art task. `envelope` intentionally uses the existing empty summer office rather than a visitor scene, per user review.
- **Selected originals:** `hot_water_v4`, `contractor_v4`, `envelope_v3` (reused office), `church_heat_v1`, `coal_theft_v2`, `wasteland_stalls_v3`, `market_cops_v1`, `fuel_offer_v6`, `residents_meeting_v3`, `journalist_v3`, `boss_report_v2` (all `.png`). Superseded versions are preserved; the current selection table and complete prompts are in `art/PROMPTS.md`.

## Review notes

_Filled in by the lead after each review round._

- Audit 2026-11-01: verified all eleven game images, versioned originals and optimization reports exist. Verified the HUD banner loader uses request IDs automatically; the previous request for explicit `week1.gd` image fields is superseded. Status remains `review` because final visual approval is not recorded. No new gameplay run was performed.
