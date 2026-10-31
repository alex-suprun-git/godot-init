# First city ambience trial

## Selection and source

- User selected `~/Desktop/city-sound.wav` as the first city ambience on 2026-10-31.
- Original remains at `/Users/oleksiisuprun/Desktop/city-sound.wav`, outside `init/`.
  It has not been moved or modified and is not duplicated in the repository.
- Source: https://freesound.org/people/klankbeeld/sounds/641255/
- Title: `pasture city summer 1158AM 220623_0429.wav`, by klankbeeld.
- The Freesound page was inspected through Computer Use. Title, duration, size,
  sample rate, bit depth and channels match the supplied file. The page specifies
  CC BY 4.0: https://creativecommons.org/licenses/by/4.0/.
- Author and Freesound attribution are included in
  `init/assets/audio/ATTRIBUTION.md` and the F3 audio panel.
- Source SHA-256:
  `5d9293f0744a60a15dc1d0968dbf1580ee7c37366fda9e9f3287ab40a343ba6e`.
- Author describes countryside near a city, including distant traffic, a dog,
  train, birds, church bell and wind. This is an initial background trial for the
  map, not a verified historical recording or final approved soundscape.

## Preparation (completed)

```sh
uv run --with numpy --with soundfile python tools/prepare_ambience.py \
  /Users/oleksiisuprun/Desktop/city-sound.wav \
  init/assets/audio/ambience/city_outskirts.ogg
```

The tool preserves the original, refuses an existing output, and overlaps the
last four seconds with the first four using an equal-power crossfade. The output
begins after the original head and ends at the same point, preserving continuity
around the loop. It writes bounded chunks for libsndfile's Vorbis encoder.

- Original: 134,435,842 bytes, 466.790083 seconds, 48 kHz, stereo, 24-bit PCM.
- Prepared Ogg: 6,935,348 bytes, 462.790083 seconds, 48 kHz, stereo.
- Preparation gain: 0 dB (no normalization was needed).
- Decoded output peak: -7.79 dBFS. Loop boundary sample step: 0.007535 full scale.
- No listening assessment was performed by the agent. The user should assess
  tonal fit, identifiable modern sounds, repetition, and the loop transition.

## Integration

- `init/scripts/audio/city_ambience.gd`: dedicated looping player, `Ambience` bus,
  two-second fade-in, default linear gain 0.5. It does not use one-shot voices.
- `AudioManager` creates it after setting up buses. Simulation speed does not
  change audio speed; playback continues through pause and phase transitions.
- F3 offers a session-only level slider and visible author/source/license credit.
  Zero mutes while the recording keeps advancing. One-shot quiet-tier controls
  are independent of this ambience.
- Persistent audio settings, positional sources and day/night variants remain
  future work. No other sound effects or music have been added.

## Verification and next action

- Ogg decoded successfully with libsndfile; preparation measurements are above.
- Godot 4.7.1 import completed successfully; the Ogg importer has `loop=true`.
- The game was launched locally. F3 showed playback advancing (0:07 in planning,
  then 0:49 during the live week), the 7:42 duration, visible attribution, and
  the level slider reflecting a changed 12% level. Runtime log contained no
  script errors. The user was interacting with the game, so further UI actions
  were stopped and the game was left running.
- A full loop rollover and audible output were not independently assessed by
  the agent. No automated tests were added or run.
- Next creative step: user listens in the map, adjusts the F3 level, and reports
  whether the recording feels appropriate or needs a different source.
