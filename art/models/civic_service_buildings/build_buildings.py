"""1997 district police station (РОВД) and polyclinic, textured and exported. Blender CLI.

Stage 2 after the approved massing (build_blockout.py). Metres; front towards
Blender -Y (Godot +Z). Origin: centre of the main body at ground level.
Front walls carry the project's existing facade textures (windows included);
everything else uses the civic-venue PBR surfaces.

  blender --background --factory-startup --python build_buildings.py
"""
from pathlib import Path
import importlib.util
import json
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
spec = importlib.util.spec_from_file_location('venue_helpers', HERE.parent / 'civic_venues/build_assets.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
scene = v.scene
OUT = HERE / 'exports'
OUT.mkdir(exist_ok=True)

C = v.material
plinth = C('Plinth_concrete', (.38, .38, .36), roughness=.95)
door = C('Door_dark', (.07, .07, .075), roughness=.7)
blue = C('Sign_blue', (.05, .20, .46), roughness=.5)
white = C('Sign_white', (.90, .90, .86), roughness=.5)
red = C('Cross_red', (.62, .08, .06), roughness=.5)
steel = C('Mast_steel', (.30, .32, .33), .5, .5)
frame = C('Frame_white', (.80, .80, .76), roughness=.6)
green = C('Clinic_green', (.36, .50, .40), roughness=.9)


def facade_material(name, filename):
    m = C(name, (1, 1, 1), roughness=.85)
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    tex = m.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = bpy.data.images.load(str(ROOT / 'init/assets/textures' / filename), check_existing=True)
    tex.extension = 'REPEAT'
    m.node_tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
    return m


police_facade = facade_material('Police_facade', 'facade_police_new_wing.png')
clinic_facade = facade_material('Clinic_facade', 'facade_polyclinic_new_wing.png')


def box(name, at, size, mat=None, cell=None):
    if cell is not None:
        return v.box(name, at, size, cell=cell)
    return v.box(name, at, size, mat or v.metal)


def facade_quad(name, x0, x1, y, h, mat, tile_w, flip=False):
    """Front/back wall; u runs one full texture per tile_w metres, centred on x = 0."""
    u0, u1 = x0 / tile_w, x1 / tile_w
    if flip:
        corners = [(x1, y, 0), (x0, y, 0), (x0, y, h), (x1, y, h)]
        uvs = [(u1, 0), (u0, 0), (u0, 1), (u1, 1)]
    else:
        corners = [(x0, y, 0), (x1, y, 0), (x1, y, h), (x0, y, h)]
        uvs = [(u0, 0), (u1, 0), (u1, 1), (u0, 1)]
    return v.mesh(name, corners, [(0, 1, 2, 3)], mat, [uvs])


def shell(W, D, H, mat, tile_w, side_cell):
    facade_quad('Front facade', -W / 2, W / 2, -D / 2, H, mat, tile_w)
    facade_quad('Rear facade', -W / 2, W / 2, D / 2, H, mat, tile_w, flip=True)
    for sx, order in ((-W / 2, 1), (W / 2, -1)):
        y0, y1 = (-D / 2, D / 2) if order == 1 else (D / 2, -D / 2)
        v.surface_quad('Gable wall', [(sx, y0, 0), (sx, y1, 0), (sx, y1, H), (sx, y0, H)], side_cell,
                       v.concrete_pbr if side_cell == 3 else v.surface_pbr, 3.6)
    v.surface_quad('Flat roof felt', [(-W / 2, -D / 2, H), (W / 2, -D / 2, H), (W / 2, D / 2, H), (-W / 2, D / 2, H)],
                   0, v.surface_pbr, 4.0)
    for dy in (-D / 2, D / 2):
        box('Parapet', (0, dy, H + .3), (W + .1, .32, .6), cell=3)
    for dx in (-W / 2, W / 2):
        box('Parapet', (dx, 0, H + .3), (.32, D, .6), cell=3)


def police():
    W, D, H = 28.8, 10.5, 7.2
    shell(W, D, H, police_facade, 14.4, 2)
    front = -D / 2
    ex = 0.0
    box('Entrance block', (ex, front - 1.1, 3.9), (5.0, 2.2, 7.8), cell=3)
    box('Entrance roof', (ex, front - 1.1, 7.95), (5.6, 2.8, .3), cell=3)
    box('Entrance door', (ex, front - 2.22, 1.25), (1.9, .1, 2.2), door)
    box('Door frame', (ex, front - 2.2, 1.25), (2.15, .06, 2.4), frame)
    box('Door canopy', (ex, front - 2.6, 2.9), (3.6, 1.6, .22), cell=3)
    for dx in (-1.6, 1.6):
        v.rod('Canopy post', (ex + dx, front - 3.2, 0), (ex + dx, front - 3.2, 2.8), .07, steel)
    box('Door steps', (ex, front - 3.0, .1), (3.2, 1.8, .2), cell=3)
    box('Blue sign board', (ex, front - 2.24, 4.6), (4.6, .12, 1.1), blue)
    v.text('МИЛИЦИЯ', (ex, front - 2.35, 4.35), .62, white)
    box('Plaque', (ex + 3.0, front - .08, 2.0), (.5, .06, .35), blue)
    v.rod('Flagpole', (ex - 2.3, front - 2.0, 5.6), (ex - 4.3, front - 3.7, 8.3), .045, steel)
    # Rear garage wing for the duty vehicles.
    wx = 7.0
    box('Garage wing', (wx, D / 2 + 3.0, 1.75), (14.0, 6.0, 3.5), cell=2)
    box('Garage roof', (wx, D / 2 + 3.0, 3.62), (14.6, 6.6, .24), v.felt)
    # Three roller doors face the rear yard (Blender +Y), which the lot keeps free for parking.
    for gx in (wx - 4.2, wx, wx + 4.2):
        box('Garage gate frame', (gx, D / 2 + 6.0, 1.5), (3.5, .08, 3.0), frame)
        box('Garage gate', (gx, D / 2 + 6.03, 1.45), (3.2, .1, 2.7), door)
    # Radio mast with antennas.
    base = Vector((-10.0, 1.0, H + .6))
    for sx, sy in ((-.6, -.6), (.6, -.6), (.6, .6), (-.6, .6)):
        v.rod('Mast leg', base + Vector((sx, sy, 0)), base + Vector((sx * .35, sy * .35, 13.0)), .04, steel)
    for z in range(2, 13, 3):
        r = .6 - z * .02
        v.rod('Mast brace', base + Vector((-r, -r, z)), base + Vector((r, -r, z)), .02, steel)
        v.rod('Mast brace', base + Vector((r, -r, z)), base + Vector((r, r, z)), .02, steel)
        v.rod('Mast brace', base + Vector((r, r, z)), base + Vector((-r, r, z)), .02, steel)
    v.rod('Whip antenna', base + Vector((0, 0, 13.0)), base + Vector((0, 0, 16.0)), .02, steel)
    box('Roof hut', (8.0, -1.0, H + .6 + .7), (2.6, 2.4, 1.4), cell=3)
    box('Roof hut cap', (8.0, -1.0, H + .6 + 1.45), (3.0, 2.8, .12), plinth)
    return {'body_m': [W, D, H], 'wing_m': [14.0, 6.0, 3.5], 'mast_m': 16.0,
            'depth_front_m': 3.8, 'depth_rear_m': D / 2 + 6.0}


def clinic():
    W, D, H = 36.0, 12.0, 10.8
    shell(W, D, H, clinic_facade, 18.0, 3)
    front = -D / 2
    box('Entrance block', (0, front - 1.6, 6.6), (7.0, 3.2, 13.2), cell=3)
    box('Entrance roof', (0, front - 1.6, 13.35), (7.6, 3.8, .3), cell=3)
    box('Stair glazing', (0, front - 3.22, 7.6), (4.4, .12, 9.0), v.dk_glass)
    for dx in (-2.2, -.73, .73, 2.2):
        box('Stair mullion', (dx, front - 3.3, 7.6), (.12, .14, 9.0), frame)
    for z in (3.2, 6.8, 10.4):
        box('Stair landing line', (0, front - 3.3, z), (4.5, .14, .12), frame)
    box('Entrance doors', (0, front - 3.24, 1.2), (3.2, .1, 2.2), door)
    box('Entrance canopy', (0, front - 4.1, 2.9), (7.0, 2.0, .22), cell=3)
    for dx in (-3.2, 3.2):
        v.rod('Canopy post', (dx, front - 4.9, 0), (dx, front - 4.9, 2.8), .08, steel)
    box('Entrance steps', (0, front - 4.3, .1), (6.4, 1.8, .2), cell=3)
    # Name in capitals on the canopy fascia, as on period polyclinics.
    box('Canopy fascia', (0, front - 5.14, 3.28), (7.0, .12, .85), white)
    v.text('ПОЛИКЛИНИКА', (0, front - 5.23, 2.98), .62, red)
    box('Cross plate', (4.6, front - .08, 8.4), (1.9, .08, 1.9), white)
    box('Cross bar', (4.6, front - .14, 8.4), (1.4, .06, .45), red)
    box('Cross bar', (4.6, front - .14, 8.4), (.45, .06, 1.4), red)
    # Ambulance porch at the south end.
    px = -W / 2 + 1.0
    box('Ambulance porch roof', (px - 1.0, front - 3.0, 3.9), (8.0, 6.0, .3), cell=3)
    for x in (px - 4.7, px + 2.7):
        v.rod('Porch post', (x, front - 5.7, 0), (x, front - 5.7, 3.8), .1, steel)
    box('Porch door', (px - 1.0, front - .04, 1.3), (2.2, .1, 2.4), door)
    box('Roof hut', (9.0, 1.0, H + .6 + .8), (3.4, 2.6, 1.6), cell=3)
    box('Roof hut cap', (9.0, 1.0, H + .6 + 1.65), (3.8, 3.0, .12), plinth)
    box('Roof vent', (-9.0, 2.0, H + .6 + .5), (1.4, 1.4, 1.0), cell=3)
    return {'body_m': [W, D, H], 'entrance_block_m': [7.0, 3.2, 13.2],
            'depth_front_m': 5.9, 'depth_rear_m': D / 2}


def finish(name, info):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in v.parts:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = v.parts[0]
    bpy.ops.object.join()
    asset = bpy.context.object
    asset.name = name
    scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    for image in bpy.data.images:
        if image.source == 'FILE' and not image.packed_file:
            image.pack()
    asset.data.calc_loop_triangles()
    info.update({'bounds_m': [round(d, 3) for d in asset.dimensions],
                 'triangles': len(asset.data.loop_triangles), 'materials': len(asset.data.materials),
                 'front': 'Blender -Y, Godot +Z'})
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), export_format='GLB', use_selection=True,
                              use_active_scene=True, export_yup=True, export_apply=True, export_materials='EXPORT')
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / (name + '.blend')))
    bpy.data.objects.remove(asset, do_unlink=True)
    v.parts.clear()
    return info


report = {'police_station_1997': finish('police_station_1997', police()),
          'polyclinic_1997': finish('polyclinic_1997', clinic())}
(HERE / 'export_report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('SERVICE_BUILDINGS_COMPLETE', json.dumps(report), flush=True)
