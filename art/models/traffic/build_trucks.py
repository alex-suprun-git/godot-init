"""Build the border-zone trucks and the shipping container, and export one GLB each.

Run in the open Blender through the MCP client, e.g.
  uv run --python 3.11 --script tools/blender_mcp.py run art/models/traffic/build_trucks.py
or headless, without the addon:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python art/models/traffic/build_trucks.py

Source units: metres. Front: -Y in Blender (+Z in Godot). Wheels rest on z = 0.
Every vehicle is one root empty with one mesh per material, so a vehicle costs a
handful of draw calls. The material named "... paint" is the one Godot recolours
(VehicleModels._repaint). Original procedural geometry, no external assets.
"""
from pathlib import Path
import json
import math
import bpy
import bmesh
from mathutils import Matrix, Vector

PROJECT = Path(__file__).resolve().parents[3]
SOURCE = PROJECT / 'art/models/traffic'
EXPORT = PROJECT / 'init/assets/models/vehicles'
EXPORT.mkdir(parents=True, exist_ok=True)

SCENE_NAME = 'Trucks_Studio'
if bpy.context.window is None:
    # Headless: blender --background --python build_trucks.py. Work in the default scene.
    scene = bpy.context.scene
    for obj in list(scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    scene.name = SCENE_NAME
else:
    old = bpy.data.scenes.get(SCENE_NAME)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.scenes.remove(old)
    scene = bpy.data.scenes.new(SCENE_NAME)
    bpy.context.window.scene = scene


def linear(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4 for c in values)


MATERIALS = {}


def material(name, color, metal=0.0, rough=0.6):
    if name in MATERIALS:
        return MATERIALS[name]
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*linear(color), 1)
    mat.use_nodes = True
    shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = mat.diffuse_color
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    MATERIALS[name] = mat
    return mat


class Vehicle:
    """Collects geometry per material, then writes one mesh object per material."""

    def __init__(self, name):
        self.name = name
        self.parts = {}

    def _bm(self, mat):
        if mat.name not in self.parts:
            self.parts[mat.name] = (mat, bmesh.new())
        return self.parts[mat.name][1]

    def box(self, mat, center, size):
        bm = self._bm(mat)
        matrix = Matrix.Translation(Vector(center)) @ Matrix.Diagonal(Vector((*size, 1.0)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=matrix)

    def cylinder(self, mat, center, radius, length, axis='X', segments=20):
        bm = self._bm(mat)
        rotation = {'X': Matrix.Rotation(math.pi / 2, 4, 'Y'),
                    'Y': Matrix.Rotation(math.pi / 2, 4, 'X'),
                    'Z': Matrix.Identity(4)}[axis]
        matrix = Matrix.Translation(Vector(center)) @ rotation
        bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius,
                              depth=length, matrix=matrix)

    def finish(self, collection):
        root = bpy.data.objects.new(self.name, None)
        collection.objects.link(root)
        triangles = 0
        for mat, bm in self.parts.values():
            bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
            data = bpy.data.meshes.new(self.name + ' - ' + mat.name)
            bm.to_mesh(data)
            triangles += sum(len(p.vertices) - 2 for p in data.polygons)
            bm.free()
            for polygon in data.polygons:
                polygon.use_smooth = False
            data.materials.append(mat)
            obj = bpy.data.objects.new(data.name, data)
            collection.objects.link(obj)
            obj.parent = root
        root['front_axis'] = '-Y in Blender; +Z in Godot'
        root['triangles'] = triangles
        return root


def wheel(v, x, y, radius=.5, width=.34, tire=None, hub=None):
    side = 1 if x > 0 else -1
    v.cylinder(tire, (x, y, radius), radius, width, 'X', 20)
    v.cylinder(hub, (x + side * width * .52, y, radius), radius * .55, .05, 'X', 16)


# --- Materials ---------------------------------------------------------------
rubber = material('Truck - rubber', '1c1e1d', 0, .9)
steel = material('Truck - steel', '8d8f89', .6, .45)
dark = material('Truck - dark metal', '2b2d2c', .3, .6)
glass = material('Truck - glass', '3a525e', .3, .2)
lamp = material('Truck - lamp', 'd8d3b0', .1, .3)
red_lamp = material('Truck - tail lamp', '8d2825', .1, .35)
wood = material('Truck - weathered boards', '8a7554', 0, .85)
strap = material('Truck - tarpaulin straps', '3d3f37', 0, .9)
# Painted bodies: one material each, so they can be recoloured in Godot.
cab_paint = material('KamAZ - cab paint', '4f6a4a', .15, .5)
tarp_paint = material('KamAZ - tarpaulin paint', '7d7a5f', 0, .85)
zil_paint = material('ZIL - cab paint', '3f5f7a', .15, .5)
box_paint = material('Container - paint', '9b3d2c', .1, .6)


def build_kamaz():
    v = Vehicle('Truck_KamAZ_Semi')
    # Tractor chassis and cab-over cab (front is -Y).
    v.box(dark, (0, -4.6, .78), (1.1, 7.0, .3))
    v.box(cab_paint, (0, -7.2, 1.95), (2.4, 2.1, 1.7))
    v.box(cab_paint, (0, -7.15, 3.0), (2.3, 1.7, .4))
    v.box(glass, (0, -8.27, 2.5), (2.0, .06, .8))
    for sx in (-1, 1):
        v.box(glass, (sx * 1.21, -7.3, 2.45), (.05, 1.1, .75))
        v.box(lamp, (sx * .85, -8.27, 1.45), (.34, .06, .22))
        v.box(dark, (sx * 1.3, -8.0, 2.2), (.12, .3, .8))  # mirror arm
    v.box(dark, (0, -8.3, 1.2), (1.2, .08, .5))  # grille
    v.box(dark, (0, -8.38, .75), (2.45, .3, .28))  # bumper
    v.box(dark, (0, -1.8, 1.05), (1.7, 1.3, .16))  # fifth wheel
    v.cylinder(dark, (1.0, -8.25, 3.35), .07, .3, 'Z', 8)  # exhaust stack stand-in
    # Semi-trailer with a tilt (tarpaulin) body.
    v.box(dark, (0, 3.3, 1.12), (2.4, 9.7, .3))
    v.box(tarp_paint, (0, 3.3, 2.55), (2.5, 9.6, 2.5))
    v.box(tarp_paint, (0, 3.3, 3.85), (2.3, 9.4, .12))
    for y in (-0.6, 1.2, 3.0, 4.8, 6.6, 8.0):
        v.box(strap, (0, y, 2.55), (2.54, .1, 2.54))
    v.box(dark, (0, 8.15, 1.0), (2.2, .08, .3))
    for sx in (-1, 1):
        v.box(red_lamp, (sx * .95, 8.12, 1.2), (.25, .05, .18))
    # Axles: steered front, drive tandem, trailer tandem.
    for y in (-6.8, -3.3, -1.9, 5.6, 7.0):
        wheel(v, -1.05, y, tire=rubber, hub=steel)
        wheel(v, 1.05, y, tire=rubber, hub=steel)
    for y in (-3.3, -1.9):  # duals on the drive axles
        wheel(v, -1.42, y, tire=rubber, hub=steel)
        wheel(v, 1.42, y, tire=rubber, hub=steel)
    return v


def build_zil():
    v = Vehicle('Truck_ZIL_Flatbed')
    v.box(dark, (0, -.2, .8), (1.1, 6.3, .28))
    v.box(zil_paint, (0, -2.95, 1.15), (1.9, 1.25, 1.0))  # long hood
    v.box(zil_paint, (0, -1.75, 1.85), (2.3, 1.5, 1.7))  # cab
    v.box(glass, (0, -2.52, 2.1), (1.9, .05, .75))
    for sx in (-1, 1):
        v.box(glass, (sx * 1.16, -1.8, 2.1), (.05, 1.0, .7))
        v.box(lamp, (sx * .65, -3.58, 1.2), (.32, .06, .28))
        v.box(dark, (sx * 1.0, -3.0, .62), (.5, 1.3, .1))  # wings
    v.box(dark, (0, -3.62, .75), (2.1, .2, .22))
    v.box(dark, (0, -3.6, 1.1), (.9, .06, .5))
    v.box(wood, (0, 1.75, 1.0), (2.4, 4.0, .16))
    for sx in (-1, 1):
        v.box(wood, (sx * 1.2, 1.75, 1.35), (.08, 4.0, .6))
    v.box(wood, (0, -.2, 1.35), (2.4, .08, .6))
    v.box(wood, (0, 3.72, 1.35), (2.4, .08, .6))
    v.box(red_lamp, (-.9, 3.78, .9), (.2, .05, .16))
    v.box(red_lamp, (.9, 3.78, .9), (.2, .05, .16))
    for y in (-2.5, 1.9):
        wheel(v, -1.0, y, radius=.52, width=.3, tire=rubber, hub=steel)
        wheel(v, 1.0, y, radius=.52, width=.3, tire=rubber, hub=steel)
    return v


def build_container():
    v = Vehicle('Shipping_Container_20ft')
    length, width, height = 6.06, 2.44, 2.59
    v.box(box_paint, (0, 0, height / 2 + .02), (width - .06, length - .06, height - .08))
    # Corrugated sides: thin vertical ribs.
    count = 22
    for i in range(count):
        y = -length / 2 + .28 + i * (length - .56) / (count - 1)
        for sx in (-1, 1):
            v.box(box_paint, (sx * (width / 2 - .015), y, height / 2 + .02), (.06, .1, height - .22))
    for sy in (-1, 1):
        for i in range(8):
            x = -width / 2 + .3 + i * (width - .6) / 7
            v.box(box_paint, (x, sy * (length / 2 - .02), height / 2 + .02), (.1, .05, height - .22))
    # Frame: corner posts, top and bottom rails, doors with locking bars at +Y.
    for sx in (-1, 1):
        for sy in (-1, 1):
            v.box(dark, (sx * (width / 2 - .08), sy * (length / 2 - .08), height / 2 + .02), (.16, .16, height))
        v.box(dark, (sx * (width / 2 - .05), 0, .08), (.1, length, .16))
        v.box(dark, (sx * (width / 2 - .05), 0, height - .06), (.1, length, .12))
    for sy in (-1, 1):
        v.box(dark, (0, sy * (length / 2 - .05), .08), (width, .1, .16))
        v.box(dark, (0, sy * (length / 2 - .05), height - .06), (width, .1, .12))
    for x in (-.55, -.2, .2, .55):
        v.box(steel, (x, length / 2 + .02, height / 2), (.05, .04, height - .3))
    v.box(dark, (0, length / 2 + .01, height / 2), (.03, .03, height - .2))
    return v


def export(root, filename):
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(EXPORT / filename), export_format='GLB', use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_animations=False, export_cameras=False, export_lights=False)


collection = bpy.data.collections.new('Trucks - export')
scene.collection.children.link(collection)
report = {}
for builder, filename, offset in ((build_kamaz, 'truck_kamaz_semi.glb', -9.0),
                                  (build_zil, 'truck_zil_flatbed.glb', 0.0),
                                  (build_container, 'container_20ft.glb', 7.0)):
    vehicle = builder()
    root = vehicle.finish(collection)
    export(root, filename)
    report[filename] = {'triangles': root['triangles'], 'materials': list(vehicle.parts.keys())}
    root.location = (offset, 0, 0)  # lay them side by side for the preview only

# Studio: floor, light, camera for a quick overview render.
floor = bpy.data.objects.new('Studio floor', bpy.data.meshes.new('floor'))
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=40)
bm.to_mesh(floor.data)
bm.free()
scene.collection.objects.link(floor)
light = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', 'SUN'))
light.data.energy = 3
light.rotation_euler = (math.radians(50), 0, math.radians(35))
scene.collection.objects.link(light)
world = bpy.data.worlds.new('Trucks world')
world.use_nodes = True
next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND').inputs['Color'].default_value = (.3, .35, .4, 1)
scene.world = world

(SOURCE / 'trucks_report.json').write_text(json.dumps(report, indent=2) + '\n')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'trucks.blend'))
print(json.dumps(report))
