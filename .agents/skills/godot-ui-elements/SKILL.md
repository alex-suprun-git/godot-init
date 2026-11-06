---
name: godot-ui-elements
description: "Design, implement, and visually compare HUDs, windows, icons, and reusable interface elements in this Godot game, using actual game captures and selected references. Use for UI art integration and visual revisions; not for city models or map-area assets."
---

# Godot UI Elements

Deliver the interface in the running game. A generated mockup is a reference,
not evidence that the implementation matches it. Read README.md for current
design and art/ASSET_PIPELINE.md when preparing generated raster artwork.

## Establish the comparison

- Start with a current capture at the normal map camera and the actual UI scale.
  Reuse an existing frame if it still represents the checkout. Do not invent a
  replacement city to make a UI proposal look better.
- Identify the selected reference and the qualities that must survive: shape,
  material, typography, proportions, depth, spacing, icon weight, and semantic
  meaning. Separate requested changes from incidental generated details.
- When the user needs visual explanation, show the element in game context
  before a long textual design discussion. Distinguish reference art, an image
  edited over a screenshot, and an actual engine capture.

## Choose the implementation before promising fidelity

- Use native controls and editable vector geometry for type, icons, values,
  selection, and layout. Use prepared artwork when paper edges, cloth, grain,
  folds, or contact shadows carry the reference's identity. A flat beige box
  is not a faithful substitute for those materials.
- Keep text and state out of background art. Decide fixed-size vs nine-slice
  before slicing; do not stretch a clip, fold, border, or photographic face.
- Carry the same material and type decisions across related components.
  Different document types can have distinct layouts within that system.
- An icon must communicate the right resource or action: personal money can
  use a wallet; a district budget needs another meaning. Keep faction identity
  stable across standings and consequences; show changing state separately.
- Size the persistent HUD for the expected roster, not just the currently
  enabled character. The agreed contact flow uses a drawer for the full roster and compact
  entries only for assigned people in the persistent dock. Bound the dock and provide overflow
  rather than letting the roster consume the map or collide with navigation.
- Build one representative component and compare it at its actual display
  size before spreading the treatment to the rest of the HUD.

## Integrate without losing interaction or sharpness

- Follow the project's source preservation, applicable visual approval,
  separate optimization, and import steps. Check numeric alpha data as well
  as a preview; an RGBA file can still contain a white matte.
- Rasterize vector icons for their intended output size or larger, then
  downsample. Do not upscale a small texture for a larger control. Match
  optical size, stroke weight, ink and padding across the icon family.
- Inspect the installed Godot API when a font or draw setting seems to have
  no effect. Verify Cyrillic support and the actual variation coordinates,
  rather than assuming that assigning a property changed the rendered font.
- Keep decorative children mouse-ignoring. Check minimum sizes, clipping,
  portrait aspect ratio, label wrapping, focus/hover/pressed states, and live
  availability/progress. Preserve the map anchors and deadline information.
- For very small progress indicators, inspect the actual runtime size; a themed
  ProgressBar can exceed the requested height. Use explicit thin geometry when
  its minimum size conflicts with the design. Short metadata such as dates and
  names must retain their intended line count inside expanding containers.
- Modal input ownership includes wheel, magnify gestures and held navigation
  keys. Prevent the map handler and its per-frame key polling while a modal or
  drawer is open, without consuming the event before the GUI can scroll.
- The main implementation is init/scripts/ui/hud.gd; shared style is in
  office_theme.gd, pictograms in office_icons.gd, map photos in person_token.gd,
  and request type/deadline cues in request_marker.gd in that same directory.

## Inspect and report

Use the narrowest applicable project autoplay, not a new automated test suite.
For HUDs and windows, office covers the map, contact detail, task tabs and
request card. Add contacts for availability changes; add week when changing
the summary. Keep captures in scratch or an ignored local folder.

Run one graphical review instance at a time and track its process. Prefer the
autoplay's normal automatic exit; use --keep-open only when the user asks to
interact with that live instance. Close your previous instance before another
capture, and verify its termination. Do not leave a renderer running while
waiting for feedback. A request to close or stop takes priority over capture
and visual-verification steps.
Compare a reference and engine result at the same apparent scale. A successful
launch only establishes that it runs. If the shape, material, type hierarchy or
clarity is visibly weaker, name the gap and fix its cause before calling the
component complete. Do not keep adding unrelated polish to compensate.

Record what exists and what remains unapproved in the existing source of truth.
Report a real game capture and the worktree's exact editor launch command.
Do not turn a candidate style into a permanent visual rule before live approval.

For the concrete failure that motivated this workflow and verified engine
pitfalls, read [the UI transfer postmortem](references/ui-transfer-postmortem.md).
