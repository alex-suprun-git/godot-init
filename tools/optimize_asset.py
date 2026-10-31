#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["Pillow==12.0.0"]
# ///
"""Prepare an approved source image for Godot; never modify its source."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROFILES = ROOT / "tools/asset_profiles.json"


def main():
    profiles = json.loads(PROFILES.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Approved original outside init/")
    parser.add_argument("--output", required=True, type=Path, help="New .png path")
    parser.add_argument("--profile", required=True, choices=sorted(profiles))
    parser.add_argument("--approved", action="store_true", help="Confirm recorded visual approval")
    parser.add_argument("--max-edge", type=int, help="Documented per-asset budget override")
    parser.add_argument("--reason", help="Required explanation for a budget override")
    parser.add_argument("--overwrite", action="store_true", help="Replace an existing output copy")
    parser.add_argument("--report", type=Path, help="JSON report (default: art/optimization_reports/)")
    parser.add_argument("--dry-run", action="store_true", help="Inspect and plan without writing files")
    args = parser.parse_args()
    if not args.approved and not args.dry_run:
        parser.error("Visual approval is required before processing; use --approved after review.")
    if args.max_edge is not None and (args.max_edge < 1 or not args.reason):
        parser.error("--max-edge must be positive and requires --reason.")
    source = args.source.expanduser().resolve()
    output = args.output.expanduser().resolve()
    if source == output or source.is_relative_to((ROOT / "init").resolve()):
        parser.error("Keep the original outside init/ and write a separate output copy.")
    if output.suffix.lower() != ".png":
        parser.error("Output must be PNG to preserve full color and transparency.")
    report_path = (args.report or ROOT / "art/optimization_reports" / (output.name + ".json")).resolve()
    if report_path in (source, output) or report_path.is_relative_to((ROOT / "init").resolve()):
        parser.error("Write the report outside init/, separate from both images.")
    if not args.dry_run and not args.overwrite:
        for path in (output, report_path):
            if path.exists():
                parser.error(f"Output already exists: {path}; use --overwrite deliberately.")
    max_edge = args.max_edge or profiles[args.profile]["max_edge"]
    with Image.open(source) as original:
        if getattr(original, "n_frames", 1) != 1:
            parser.error("Animated images are not supported; process static source images only.")
        icc = original.info.get("icc_profile")
        image = ImageOps.exif_transpose(original)
        has_alpha = "A" in image.getbands() or "transparency" in image.info
        image = image.convert("RGBA" if has_alpha else "RGB")
        before_size = image.size
        alpha_before = image.getchannel("A").getextrema() if has_alpha else None
        image.thumbnail((max_edge, max_edge), Image.Resampling.LANCZOS)
        # Explicitly construct pixels-only output: discard EXIF/text, retain ICC.
        clean = Image.new(image.mode, image.size)
        clean.paste(image)
        report = {
            "source": str(source), "output": str(output),
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "profile": args.profile, "max_edge": max_edge,
            "override_reason": args.reason, "approved": args.approved,
            "before": {"size": before_size, "bytes": source.stat().st_size,
                       "estimated_rgba_bytes": before_size[0] * before_size[1] * 4},
            "after": {"size": clean.size, "estimated_rgba_bytes": clean.width * clean.height * 4},
            "has_alpha": has_alpha, "source_alpha_extrema": alpha_before,
            "output_alpha_extrema": clean.getchannel("A").getextrema() if has_alpha else None,
            "icc_preserved": bool(icc), "cropped": False, "palette_quantized": False,
            "dry_run": args.dry_run,
        }
        if not args.dry_run:
            output.parent.mkdir(parents=True, exist_ok=True)
            handle, temp_name = tempfile.mkstemp(suffix=".png", dir=output.parent)
            os.close(handle)
            try:
                options = {"icc_profile": icc} if icc else {}
                clean.save(temp_name, format="PNG", optimize=True, compress_level=9, **options)
                report["after"]["bytes"] = Path(temp_name).stat().st_size
                report["after"]["sha256"] = hashlib.sha256(Path(temp_name).read_bytes()).hexdigest()
                os.replace(temp_name, output)
            finally:
                Path(temp_name).unlink(missing_ok=True)
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"Asset optimization failed: {error}", file=sys.stderr)
        sys.exit(1)
