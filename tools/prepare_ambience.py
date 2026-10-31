#!/usr/bin/env python3
"""Prepare a long stereo recording as an Ogg Vorbis ambience loop.

Run with: uv run --with numpy --with soundfile tools/prepare_ambience.py INPUT OUTPUT
The source is preserved. The tail overlaps the head with an equal-power fade;
the resulting loop begins just after the head and ends at that same point.
"""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import soundfile as sf


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--crossfade", type=float, default=4.0)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error("The output must differ from the original recording.")
    if args.output.exists():
        parser.error("The output already exists; choose a new path.")

    samples, rate = sf.read(args.source, dtype="float32", always_2d=True)
    overlap = round(args.crossfade * rate)
    if overlap < 2 or len(samples) <= overlap * 2:
        parser.error("Crossfade must be positive and shorter than half the recording.")
    phase = np.linspace(0, np.pi / 2, overlap, dtype=np.float32)[:, None]
    transition = samples[-overlap:] * np.cos(phase) + samples[:overlap] * np.sin(phase)
    loop = np.concatenate((samples[overlap:-overlap], transition))
    peak = float(np.abs(loop).max())
    # Leave encoding headroom if overlapping two loud passages raises the peak.
    gain = min(1.0, 0.89 / max(peak, 1e-12))
    loop *= gain
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # libsndfile's Vorbis encoder needs bounded writes for long recordings.
    with sf.SoundFile(args.output, "w", samplerate=rate, channels=loop.shape[1],
                      format="OGG", subtype="VORBIS") as output:
        for start in range(0, len(loop), rate * 10):
            output.write(loop[start:start + rate * 10])

    with args.source.open("rb") as source:
        source_hash = hashlib.file_digest(source, "sha256").hexdigest()
    decoded, _ = sf.read(args.output, dtype="float32", always_2d=True)
    print(json.dumps({
        "source": str(args.source.resolve()),
        "source_sha256": source_hash,
        "source_bytes": args.source.stat().st_size,
        "output": str(args.output),
        "output_bytes": args.output.stat().st_size,
        "duration_seconds": len(decoded) / rate,
        "sample_rate": rate,
        "channels": decoded.shape[1],
        "crossfade_seconds": args.crossfade,
        "preparation_gain_db": float(20 * np.log10(gain)),
        "decoded_peak_dbfs": float(20 * np.log10(max(float(np.abs(decoded).max()), 1e-12))),
        "decoded_loop_boundary_step": float(np.abs(decoded[-1] - decoded[0]).max()),
    }, indent=2))


if __name__ == "__main__":
    main()
