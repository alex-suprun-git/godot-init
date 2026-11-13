"""Build the measured residential-core assets with Blender in background mode."""

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


HERE = Path(__file__).resolve().parent
PALETTE = {
    "silicate": (.58, .53, .42), "cream": (.67, .58, .42), "ochre": (.54, .34, .13),
    "blue": (.14, .24, .30), "ivory": (.62, .59, .47), "green": (.18, .24, .17),
    "concrete": (.40, .38, .32), "plinth": (.26, .21, .17), "roof": (.068, .078, .079),
    "roof_seam": (.094, .102, .098), "reveal": (.17, .17, .15), "frame": (.65, .61, .48),
    "glass": (.11, .19, .23), "curtain": (.35, .34, .26),
    "paint": (.68, .64, .49), "grass": (.20, .23, .105), "soil": (.25, .20, .12),
    "wire": (.17, .19, .14),
}


def make_materials():
    materials = {}
    for key, color in PALETTE.items():
        material = bpy.data.materials.new(key)
        material.diffuse_color = (*color, 1)
        material.use_nodes = True
        surface = material.node_tree.nodes.get("Principled BSDF")
        surface.inputs["Base Color"].default_value = (*color, 1)
        surface.inputs["Roughness"].default_value = .30 if key == "glass" else .83
        materials[key] = material
    return materials


def box(collection, materials, name, center, size, material):
    x, y, z = (component / 2 for component in size)
    vertices = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z),
                (-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z)]
    faces = [(0, 3, 2, 1), (0, 1, 5, 4), (1, 2, 6, 5),
             (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(materials[material])
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = center
    return obj


def facade_box(add, name, face, line, at, z, width, depth, height, material, offset=0):
    if face in ("front", "rear"):
        y = line + offset * (-1 if face == "front" else 1)
        return add(name, (at, y, z), (width, depth, height), material)
    x = line + offset * (-1 if face == "left" else 1)
    return add(name, (x, at, z), (depth, width, height), material)


def window(add, face, line, at, z, width, height, variation, kiosk):
    def detail(name, pos, level, w, depth, h, material, offset):
        facade_box(add, name, face, line, pos, level, w, depth, h, material, offset)

    detail("Window reveal", at, z, width + .12, .06, height + .12, "reveal", .025)
    detail("Glazing", at, z, width, .04, height, "glass", .065)
    if not kiosk and variation % 4 == 0:
        detail("Curtain", at + width * .29, z, width * .32, .01, height - .08, "curtain", .085)
    for i in (-.5, 0, .5):
        detail("Window upright", at + i * width, z, .07, .08, height + .05, "frame", .095)
    for i in (-.5, .5):
        detail("Window crosspiece", at, z + i * height, width + .07, .08, .065, "frame", .095)
    detail("Sill or counter", at, z - height / 2 - .065, width + .22, .30, .105,
           "concrete" if not kiosk else "frame", .16)


def building(add, name, plan):
    kiosk = name.startswith("kiosk_")
    for volume in plan["volumes"]:
        x, y, z, w, d, h = volume["bounds"]
        cx, cy, top = x + w / 2, y + d / 2, z + h
        add(volume["name"], (cx, cy, z + h / 2), (w, d, h), plan.get("shell_material", volume["material"]))
        add("Plinth", (cx, cy, .22), (w + .012, d + .012, .44), "plinth")
        add("Flat roof", (cx, cy, top + .075), (w, d, .15), "roof")
        if not kiosk:
            for rx in (-.33, 0, .33):
                add("Felt seam", (cx + rx * w, cy, top + .155), (.055, d - .3, .012), "roof_seam")
            add("Vent shaft", (cx - .2 * w, cy + .19 * d, top + .28), (.54, .55, .48), "plinth")
            add("Vent cap", (cx - .2 * w, cy + .19 * d, top + .55), (.72, .70, .09), "concrete")
        else:
            for fx in (x + .12, x + w - .12):
                add("Folded steel corner", (fx, y - .025, 1.32), (.10, .07, 2.24), "frame")
    for group in plan["facades"]:
        for i, at in enumerate(group["at"]):
            for j, level in enumerate(group["levels"]):
                window(add, group["face"], group["line"], at, level, *group["size"], i + 3 * j, kiosk)
    for entry in plan["entries"]:
        face, line, at = entry.get("face", "front"), entry["line"], entry["at"]
        w, h, canopy = entry["width"], entry["height"], entry["canopy"]
        leaf = plan.get("shell_material", entry["material"]) if kiosk else entry["material"]
        facade_box(add, "Door surround", face, line, at, h / 2, w + .24, .16, h + .19, "reveal", .07)
        facade_box(add, "Door leaves", face, line, at, h / 2, w, .06, h, leaf, .18)
        if name in ("school", "kindergarten"):
            for pane in (-.24, .24):
                facade_box(add, "Entry glazing", face, line, at + pane * w, h * .64,
                           w * .37, .018, h * .43, "glass", .216)
        if canopy:
            facade_box(add, "Entrance canopy", face, line, at, h + .45,
                       w + .9, canopy, .18, leaf, canopy / 2)
            facade_box(add, "Entrance landing", face, line, at, .09,
                       w + .60, min(canopy, 1.65), .18, "concrete", min(canopy, 1.65) / 2)
    if name == "maintenance":
        add("Pipe rack feet", (6.3, -5.2, .24), (2.8, .78, .48), "green")
        for offset in (-.24, 0, .24):
            beam(add, "Stock pipe", (4.7, -5.2 + offset, .55), (7.8, -5.2 + offset, .55), .13, "wire")


def beam(add, name, start, end, width, material):
    start, end = Vector(start), Vector(end)
    delta = end - start
    obj = add(name, (start + end) / 2, (width, width, delta.length), material)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()


def football_pitch(add, pitch):
    length, width = pitch["field"]
    goal_width, depth, height = pitch["goal"]
    margin = pitch["runoff"]
    x, y = length / 2, width / 2
    outer_x, outer_y = x + margin, y + margin
    add("Grassed pitch", (0, 0, .035), (2 * outer_x, 2 * outer_y, .07), "grass")
    for end in (-1, 1):
        add("Worn goalmouth", (end * (x - .70), 0, .073), (1.8, goal_width + .35, .006), "soil")
        add("Goal line", (end * x, 0, .080), (.08, width, .009), "paint")
        add("Touch line", (0, end * y, .080), (length, .08, .009), "paint")
        for side in (-1, 1):
            gy = side * goal_width / 2
            beam(add, "Goal upright", (end * x, gy, .08), (end * x, gy, height + .08), .08, "paint")
            beam(add, "Goal brace", (end * x, gy, height + .08), (end * (x + depth), gy, .08), .05, "wire")
        beam(add, "Goal crossbar", (end * x, -goal_width / 2, height + .08),
             (end * x, goal_width / 2, height + .08), .08, "paint")
        for i in range(1, 8):
            gy = -goal_width / 2 + i * goal_width / 8
            beam(add, "Net strand", (end * x, gy, height + .08),
                 (end * (x + depth), gy, .08), .017, "wire")
    add("Halfway line", (0, 0, .080), (.08, width, .009), "paint")
    circle = [(2.4 * math.cos(a * math.tau / 36), 2.4 * math.sin(a * math.tau / 36), .083)
              for a in range(36)]
    for start, end in zip(circle, circle[1:] + circle[:1]):
        delta = Vector(end) - Vector(start)
        obj = add("Centre circle", (Vector(start) + Vector(end)) / 2, (delta.length, .075, .009), "paint")
        obj.rotation_euler.z = math.atan2(delta.y, delta.x)
    gate = pitch["gate_width"] / 2
    corners = [(-gate, -outer_y), (-outer_x, -outer_y), (-outer_x, outer_y),
               (outer_x, outer_y), (outer_x, -outer_y), (gate, -outer_y)]
    fence_height = pitch["fence_height"]
    for start, end in zip(corners, corners[1:]):
        bays = math.ceil(math.dist(start, end) / 3)
        for i in range(bays + 1):
            a, b = (start[j] + (end[j] - start[j]) * i / bays for j in range(2))
            add("Fence post", (a, b, fence_height / 2), (.065, .065, fence_height), "wire")
        for level in (.22, .70, 1.10, fence_height):
            beam(add, "Fence rail", (*start, level), (*end, level), .031, "wire")


def main():
    plans = json.loads((HERE / "plans.json").read_text(encoding="utf-8"))
    output = HERE / "exports"
    output.mkdir(exist_ok=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    for obj in list(scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    materials = make_materials()
    collections = {}
    for name, plan in plans.items():
        if "same_as" in plan:
            plan = {**plans[plan["same_as"]], **plan}
        collection = bpy.data.collections.new(name)
        scene.collection.children.link(collection)
        collections[name] = collection

        def add(label, center, size, material):
            return box(collection, materials, label, center, size, material)

        if "pitch" in plan:
            football_pitch(add, plan["pitch"])
        else:
            building(add, name, plan)

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / "residential_cores.blend"))
    for name, collection in collections.items():
        bpy.ops.object.select_all(action="DESELECT")
        parts = list(collection.objects)
        for obj in parts:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        bpy.ops.object.join()
        joined = bpy.context.object
        joined.name = name
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bpy.ops.export_scene.gltf(filepath=str(output / f"{name}.glb"), export_format="GLB",
                                  use_selection=True, use_active_scene=True, export_yup=True)


if __name__ == "__main__":
    main()
