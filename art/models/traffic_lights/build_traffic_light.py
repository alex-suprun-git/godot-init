"""Rebuild the isolated traffic-light source, preview and scoped GLB in Blender."""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'art/models/traffic_lights'
EXPORT = ROOT / 'init/assets/models/street'
SOURCE.mkdir(parents=True, exist_ok=True)
EXPORT.mkdir(parents=True, exist_ok=True)
scene = bpy.data.scenes.new('TrafficLight_Studio')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
parts = []
lenses = []


def material(name, color, metallic=0.0, roughness=0.65):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    return mat


metal = material('Signal_Pole_Grey', (.34, .37, .36), .35)
black = material('Signal_Housing_Charcoal', (.035, .042, .040), .1)
rim = material('Signal_Rim', (.075, .080, .074), .2)
colors = [('Red', (.34, .025, .018)), ('Amber', (.40, .19, .015)), ('Green', (.018, .20, .09))]


def finish(obj, name, mat):
    obj.name = name
    obj.data.materials.append(mat)
    parts.append(obj)
    return obj


def box(name, location, size, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft metal edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj, name, mat)


def cylinder(name, location, radius, depth, mat, lens_axis=False, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    if lens_axis:
        obj.rotation_euler.x = math.pi / 2
    return finish(obj, name, mat)


cylinder('Pole', (0, .09, 1.72), .057, 3.44, metal)
cylinder('Foot', (0, .09, .025), .105, .05, metal)
cylinder('PoleCap', (0, .09, 3.45), .061, .025, metal)
box('Head', (0, -.085, 2.85), (.35, .25, 1.04), black, .015)
for z in [2.37, 3.30]:
    box('RearBracket', (0, .085, z), (.21, .15, .045), metal, .008)
    cylinder('MountClamp', (0, .09, z), .067, .055, metal)
for index, (name, color) in enumerate(colors):
    z = 3.18 - index * .33
    cylinder('LensRim_' + name, (0, -.225, z), .142, .035, rim, True, 24)
    lens = cylinder('Lens_' + name, (0, -.247, z), .122, .015,
                    material('Lens_' + name, color, .05, .28), True, 24)
    lenses.append(lens)
    # Open-bottom, curved metal visor: one thin shell, front points along -Y.
    verts = []
    count = 12
    for y in [-.224, -.32]:
        for j in range(count + 1):
            angle = math.pi * j / count
            verts.append((math.cos(angle) * .148, y, z + math.sin(angle) * .148))
    faces = [(j, j + 1, j + count + 2, j + count + 1) for j in range(count)]
    mesh = bpy.data.meshes.new('VisorMesh')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    visor = bpy.data.objects.new('Visor_' + name, mesh)
    scene.collection.objects.link(visor)
    finish(visor, 'Visor_' + name, black)
    bpy.context.view_layer.objects.active = visor
    mod = visor.modifiers.new('Metal thickness', 'SOLIDIFY')
    mod.thickness = .008
    bpy.ops.object.modifier_apply(modifier=mod.name)
    box('RearCover_' + name, (0, .048, z), (.27, .025, .29), black, .012)

# One shared structural mesh and three independent lens meshes.
bpy.ops.object.select_all(action='DESELECT')
body_parts = [obj for obj in parts if obj not in lenses]
for obj in body_parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = body_parts[0]
bpy.ops.object.join()
body = bpy.context.object
body.name = 'Signal_Body'
root = bpy.data.objects.new('TrafficLight', None)
scene.collection.objects.link(root)
for obj in [body] + lenses:
    obj.parent = root

# Save before exporting; exclude all cameras and unrelated Blender scenes.
bpy.ops.object.select_all(action='DESELECT')
for obj in [root, body] + lenses:
    obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'traffic_light_v1.blend'))
bpy.ops.export_scene.gltf(filepath=str(EXPORT / 'traffic_light_v1.glb'), export_format='GLB',
    use_selection=True, use_active_scene=True, export_apply=True, export_yup=True,
    export_animations=False, export_cameras=False, export_lights=False)
triangles = 0
for obj in [body] + lenses:
    obj.data.calc_loop_triangles()
    triangles += len(obj.data.loop_triangles)
report = dict(triangles=triangles, mesh_objects=4, height_m=3.4625, lens_diameter_m=.244,
    forward_blender='-Y', forward_godot='+Z', units='metres',
    geometry_budget_triangles=2500, textures=0, source='traffic_light_v1.blend',
    export='init/assets/models/street/traffic_light_v1.glb',
    note='Original geometry based on the task concept reference; solid PBR materials, three independently named lenses. No signal controller baked into model.')
(SOURCE / 'asset_report.json').write_text(json.dumps(report, indent=2) + '\n')

# Workbench previews keep silhouette review cheap and reproducible.
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.background_type = 'WORLD'
scene.world = bpy.data.worlds.new('TrafficLight_Background')
scene.world.color = (.55, .55, .55)
scene.render.resolution_x = 600
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
camera_data = bpy.data.cameras.new('ReviewCamera')
camera = bpy.data.objects.new('ReviewCamera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 4.05
for name, pos in [('front', (3, -6, 3.3)), ('rear', (-3, 6, 3.3))]:
    camera.location = pos
    camera.rotation_euler = (Vector((0, 0, 1.75)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(SOURCE / 'previews' / (name + '.png'))
    bpy.ops.render.render(write_still=True)
print('TRAFFIC_LIGHT_REPORT', json.dumps(report))
