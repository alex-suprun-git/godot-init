---
id: car-junction-turns
issue: 67
status: review
branch: fix/car-junction-turns
---

# Ambient traffic routes, turns and the western loop

## Agreed scope

The user approved one combined PR on 2026-11-02, explicitly overriding the usual split-by-feature rule and authorizing the PR work. Smooth turns were positively reviewed. Moving cars must remain visible; traffic density now belongs to routes rather than district visibility.

- Highway traffic goes straight through; border traffic connects the bridge head to either highway end in both directions.
- City traffic circulates on eastern/western loops.
- A western street joins north and south streets, with the forest moved west and space reserved east of the street for future buildings. No new buildings are included.
- Courtyard traffic is rare and passenger-only. Explicit courtyard roads use speed 0.5, normal roads 1.0 and the highway 2.0. Other paths remain excluded; rural-road speed can be configured later.
- After reviewing the initial excessive density, the user requested fewer cars. Final slots: 30 highway, 14 border, 18 city and 4 courtyard, 66 total including gateway legs/waiting. The bus cap remains five.
- No collisions, yielding, signal phases, bridge crossing, or automated tests.

## Implementation

`traffic_flows.gd` owns stream budgets, fleets and named road itineraries. `traffic_routes.gd` resolves each itinerary over actual graph edges, validating connectivity, closed loops, gateway endpoints and vehicle restrictions. `ambient_life.gd` follows directed routes and continuous lane-to-lane Bezier turns by travelled distance, with tangent heading and corner slowdown. Initial open trips are distributed over the graph and gateway legs to avoid a startup surge. Pedestrian visibility rules remain independent; only off-map waiting hides a car.

`district_layout.gd` adds the western street at x=-480 and extends the two streets to meet it. The west reserve is 76.5 m deep beside the sidewalk. `nature_places.gd` moves the forest/clearing 30 m west; paths and the western haze boundary follow. Housing-spine/cross-street roads explicitly opt into passenger-only courtyard traffic, with lane offsets sized for their 4 m width. Existing road-graph and pedestrian movement implementations are unchanged; new road geometry is derived as usual.

The follow-up bus rule lives in `traffic_rules.gd`, shared by route access validation and lane placement on straights, turn endpoints and gateway legs. Buses take the outer right lane in their direction. Highway/axis data declares two lanes per direction; other roads default to one. Median width is excluded from lane geometry. The user requested this policy module as a foundation for later traffic rules.

## Verification and review

- [x] Original turn implementation: inspected right/left/highway turn sequences; the user confirmed the turns look good.
- [x] Inspected live-game western layout, highway/border traffic and a passenger car entering the courtyard connection. Reviewed the reduced-density highway frame after the user's feedback.
- [x] Final 480-second runtime observation, fixed 1/60 s step: 66 slots throughout, 56 city laps and 10 courtyard laps, bus count never above five, no unexpected visibility changes or forbidden courtyard vehicles/roads, and no through traffic leaving the highway. Maximum displacement 0.3952 m/frame; excess over the travel budget 0.00109 m; zero motion warnings.
- [x] `--autoplay --only=traffic,map,week --turbo=10 --traffic-debug --no-log` completed through week two without errors or invariant violations. Turbo displacement is assessed against its longer simulated frame, rather than a fixed 1 m threshold.
- [x] `git diff --check` passed. No automated tests were added or run. Verification used installed Godot 4.7.2 on Windows.
- [x] Bus follow-up: inspected highway, axis and turning frames; 120 seconds at 1/60 s completed with 66 slots, no motion warnings or policy violations, maximum excess 0.00091 m. Local evidence: `.local/bus-lanes-shots/`, `bus-visual.log`, `bus-measure.log` in the parent checkout scratch directory.
- [ ] User's final review of reduced density and precise road/reserve placement.

Local evidence is ignored scratch content under `C:/Users/alexe/Desktop/Development/godot-init/.local/`: `flows-final-shots/`, `flows-final-visual.log`, `flows-final-measure.log`, and the original `turns-*-strip.jpg` turn sequences. Temporary gameplay measurement drivers stay outside the deliverable diff. PR frames are attachments, never committed.

Worktree project: `C:/Users/alexe/Desktop/Development/godot-init/.local/worktrees/car-junction-turns/init`.
Open with PowerShell:

```powershell
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe' --editor --path 'C:/Users/alexe/Desktop/Development/godot-init/.local/worktrees/car-junction-turns/init'
```
