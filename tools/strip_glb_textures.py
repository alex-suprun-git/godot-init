#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Remove embedded textures from GLB files that use shared materials.

Blender embeds every texture into every GLB it exports, and Godot extracts a PNG
copy next to each one. For a set of models that share the same materials this
multiplies the same few textures by the number of models. This tool deletes the
embedded images, textures and samplers and the texture references in the
materials, and compacts the binary chunk. The shared textures live once under
``init/assets/materials/<set>/`` as ``<material_slug>.tres``; the Godot post-import
script ``init/scripts/dev/shared_material_import.gd`` swaps them back in by material
name.

Safety check: a material that references a texture must have a matching shared
material file in the library, otherwise the tool stops without writing anything.

Usage (from the repository root):
    uv run tools/strip_glb_textures.py --library init/assets/materials/frontier \
        init/assets/models/industrial_sites/frontier_*.glb
    add --dry-run to only report what would change.
"""
from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

TEXTURE_SLOTS = ("baseColorTexture", "metallicRoughnessTexture")
MATERIAL_TEXTURE_SLOTS = ("normalTexture", "occlusionTexture", "emissiveTexture")


def slug(name: str) -> str:
    """Material name to library file stem; must match shared_material_import.gd."""
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2:
        raise ValueError(f"{path}: not a glTF 2.0 binary")
    json_length, json_type = struct.unpack_from("<II", data, 12)
    if json_type != 0x4E4F534A:
        raise ValueError(f"{path}: first chunk is not JSON")
    document = json.loads(data[20 : 20 + json_length])
    offset = 20 + json_length
    if offset >= len(data):
        return document, b""
    bin_length, bin_type = struct.unpack_from("<II", data, offset)
    if bin_type != 0x004E4942:
        raise ValueError(f"{path}: second chunk is not BIN")
    return document, data[offset + 8 : offset + 8 + bin_length]


def pad(data: bytes, filler: bytes) -> bytes:
    return data + filler * (-len(data) % 4)


def write_glb(path: Path, document: dict, binary: bytes) -> None:
    json_bytes = pad(json.dumps(document, separators=(",", ":")).encode("utf-8"), b" ")
    bin_bytes = pad(binary, b"\x00")
    total = 12 + 8 + len(json_bytes) + (8 + len(bin_bytes) if bin_bytes else 0)
    out = struct.pack("<4sII", b"glTF", 2, total)
    out += struct.pack("<II", len(json_bytes), 0x4E4F534A) + json_bytes
    if bin_bytes:
        out += struct.pack("<II", len(bin_bytes), 0x004E4942) + bin_bytes
    path.write_bytes(out)


def strip(document: dict, binary: bytes, library: Path) -> tuple[dict, bytes, dict]:
    images = document.get("images", [])
    if not images:
        return document, binary, {"images": 0, "bytes_removed": 0}

    # Every material that points at a texture needs a shared counterpart.
    for material in document.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        uses_texture = any(slot in pbr for slot in TEXTURE_SLOTS) or any(
            slot in material for slot in MATERIAL_TEXTURE_SLOTS
        )
        if uses_texture:
            name = material.get("name", "")
            if not name or not (library / f"{slug(name)}.tres").exists():
                raise ValueError(
                    f"textured material '{name}' has no shared material "
                    f"{library / (slug(name) + '.tres')}"
                )

    removed_views = {image["bufferView"] for image in images if "bufferView" in image}
    if any("uri" in image for image in images):
        raise ValueError("external image URIs are not supported")

    for material in document.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        for slot in TEXTURE_SLOTS:
            pbr.pop(slot, None)
        for slot in MATERIAL_TEXTURE_SLOTS:
            material.pop(slot, None)
        if not pbr:
            material.pop("pbrMetallicRoughness", None)

    for key in ("images", "textures", "samplers"):
        document.pop(key, None)

    # Compact the binary chunk and renumber the buffer views that remain.
    views = document.get("bufferViews", [])
    new_index: dict[int, int] = {}
    new_views: list[dict] = []
    new_binary = bytearray()
    for old_index, view in enumerate(views):
        if old_index in removed_views:
            continue
        start = view.get("byteOffset", 0)
        chunk = binary[start : start + view["byteLength"]]
        new_binary += b"\x00" * (-len(new_binary) % 4)
        updated = dict(view)
        updated["byteOffset"] = len(new_binary)
        new_binary += chunk
        new_index[old_index] = len(new_views)
        new_views.append(updated)
    document["bufferViews"] = new_views
    for accessor in document.get("accessors", []):
        if "bufferView" in accessor:
            accessor["bufferView"] = new_index[accessor["bufferView"]]
        sparse = accessor.get("sparse")
        if sparse:
            sparse["indices"]["bufferView"] = new_index[sparse["indices"]["bufferView"]]
            sparse["values"]["bufferView"] = new_index[sparse["values"]["bufferView"]]
    final = bytes(new_binary)
    if document.get("buffers"):
        document["buffers"][0]["byteLength"] = len(pad(final, b"\x00"))
    extensions = document.get("extensionsUsed")
    if extensions and "KHR_texture_transform" in extensions:
        extensions.remove("KHR_texture_transform")
        if not extensions:
            document.pop("extensionsUsed")
    return document, final, {"images": len(images), "bytes_removed": len(binary) - len(final)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--library", type=Path, required=True, help="folder with the shared <material_slug>.tres files")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    results = []
    for path in args.files:
        document, binary = read_glb(path)
        before = path.stat().st_size
        document, new_binary, info = strip(document, binary, args.library)
        if info["images"] and not args.dry_run:
            write_glb(path, document, new_binary)
        after = before if args.dry_run or not info["images"] else path.stat().st_size
        results.append((path, before, after, info["images"]))
        print(f"{path.name}: {info['images']} images, {before} -> {after} bytes")
    total_before = sum(r[1] for r in results)
    total_after = sum(r[2] for r in results)
    print(f"total: {len(results)} files, {total_before / 1048576:.1f} MB -> {total_after / 1048576:.1f} MB")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
