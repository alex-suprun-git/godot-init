# UI concept transfer: 2026-11-04

Status: the user rejected the initial live implementation twice. The revised
engine result remains a candidate, not an approved style benchmark.

## What failed

The initial attractive concepts showed paper documents, distinct news/memo
objects, framed photographs and a coherent type hierarchy. The first engine
pass substituted flat panels and similar thin borders. It kept colors while
discarding the materials and hierarchy that made the reference work.

The first full-screen concept also invented a more polished city instead of
using the actual map. A later mockup corrected the context, but the code was
still evaluated primarily for readability and successful startup. The user
had to point out the aesthetic gap repeatedly.

Adding one textured folder did not make the rest of the screen coherent.
Mixing textured artwork, generic buttons and old circular portraits weakened
the whole interface. Personal money also lacked a visual explanation.

## Verified technical causes

- office_icons.gd initially rasterized all SVGs at 24 px; a 32 px wallet then
  enlarged that texture. Request textures at each actual output size (or
  larger for downsampling), rather than reusing one small raster everywhere.
- In this installed Godot 4.7.2, a FontVariation with
  `{"wght": 700.0}` returned empty actual variation coordinates. The numeric
  OpenType tag `{2003265652: 700.0}` returned the requested weight. Both bundled
  fonts were confirmed to contain Cyrillic. This was an axis-key problem,
  not missing Cyrillic glyphs. Recheck the installed API if this changes.
- A TextureRect in a horizontal container consumed the folder title's width.
  Explicit shrink flags corrected the icon's layout. Button expand_icon also
  hid navigation symbols when the container supplied too little icon space.
- One generated memo had an alpha range of 27–254, so it did not have a clean
  transparent exterior despite being an RGBA file. Inspect transparency
  numerically and visually before integration; preserve rejected sources.

## Correction and remaining review

Preserve the chosen concept's material as separate optimized backgrounds;
keep type, status and input native. Correct typography and icon sampling;
use one photo-frame language; keep gameplay progress/deadlines legible.

The user-selected concept and generated backgrounds are references. Actual
game captures, not new generated mockups, must establish whether the revision
closes the gap. Do not describe visual parity or user approval without evidence.

## Review-session and capacity failures

Several autoplay instances were left open across iterations. The user reported
an invisible/unclosable demo and excessive machine load. Matching review
processes were terminated and a second process query confirmed zero remained.
Do not confuse showing an in-game result with leaving background renderers alive.

The contact dock was expanded around the one currently enabled contact, even
though the expected roster is five or six. Large repeated detail cards would
consume the map. The first compact correction was made without another launch following the
shutdown request. The user then selected a drawer for the full roster, with
only assigned people remaining in the bottom dock. That implementation was
inspected in the engine; aesthetic approval is still separate.
## Modal, marker and progress defects

The later user review exposed input and render bugs beyond art fidelity:

- Scroll events reached the map's unhandled-input handler, and held keys were
  polled independently of GUI focus. The fix gates map navigation while a modal
  or drawer is open and leaves GUI events available to the ScrollContainer.
  Live input capture confirmed that the folder scrolls while map zoom stays
  fixed, and that map zoom resumes after closing it.
- The photo marker retained its old ring and circular worker badge. Use a
  single paper frame with the assigned worker as its main portrait instead.
- Small themed ProgressBars expanded over card text. The custom drawing now
  stays at the measured 44 x 3 px size; paperwork uses a short row of hour marks.
- A newspaper date wrapped vertically because an expanding sibling consumed
  its width. Explicitly preserve single-line metadata during newspaper layout.

The morning paper shortcut is limited to planning. The redundant tray caption
was removed at the user's request. These are concrete task decisions, not a
universal rule for all document interfaces.