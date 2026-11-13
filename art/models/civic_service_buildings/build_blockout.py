"""Massing study: 1997 district police station (РОВД) and polyclinic. Blender CLI.

Metres, front towards Blender -Y (Godot +Z). Stage 1 only: silhouettes and
plain colours for approval; textures, signage detail and export come after
the user approves the massing. Reuses the civic-venue helpers like the store.

  blender --background --factory-startup --python build_blockout.py
Writes previews/*.png (Workbench renders) and the .blend checkpoint.
"""
from pathlib import Path
import importlib.util
import math
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('venue_helpers', HERE.parent / 'civic_venues/build_assets.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
scene = v.scene
(HERE / 'previews').mkdir(exist_ok=True)

C = v.material
brick = C('Police_pale_brick', (.66, .55, .38), roughness=.9)
plaster = C('Clinic_plaster', (.80, .78, .68), roughness=.9)
band = C('Clinic_green_band', (.36, .50, .40), roughness=.9)
plinth = C('Plinth_concrete', (.38, .38, .36), roughness=.95)
roofmat = C('Flat_roof_felt', (.07, .075, .08), roughness=.95)
frame = C('Window_frame_white', (.80, .80, .76), roughness=.6)
glass = C('Window_glass', (.12, .17, .20), .1, .2)
door = C('Door_dark', (.07, .07, .075), roughness=.7)
concrete = C('Canopy_concrete', (.56, .55, .52), roughness=.9)
blue = C('Sign_blue', (.05, .20, .46), roughness=.5)
white = C('Sign_white', (.90, .90, .86), roughness=.5)
red = C('Cross_red', (.62, .08, .06), roughness=.5)
steel = C('Mast_steel', (.30, .32, .33), .5, .5)
bars = C('Window_bars', (.06, .06, .06), .4, .6)


def box(name, at, size, mat):
    return v.box(name, at, size, mat)


def window(x, y, z, w, h, barred=False):
    box('Window frame', (x, y + .02, z), (w + .16, .12, h + .16), frame)
    box('Window glass', (x, y - .05, z), (w, .05, h), glass)
    box('Mullion', (x, y - .09, z), (.06, .05, h), frame)
    if barred:
        for i in range(-2, 3):
            v.rod('Bar', (x + i * w / 5, y - .13, z - h / 2), (x + i * w / 5, y - .13, z + h / 2), .018, bars)


def shell(width, depth, height, wall, name):
    box(name + ' plinth', (0, 0, .3), (width + .3, depth + .3, .6), plinth)
    box(name + ' body', (0, 0, height / 2), (width, depth, height), wall)
    box(name + ' roof felt', (0, 0, height + .12), (width + .5, depth + .5, .24), roofmat)
    for dy in (-depth / 2, depth / 2):
        box('Parapet', (0, dy, height + .4), (width + .5, .3, .6), concrete)
    for dx in (-width / 2, width / 2):
        box('Parapet', (dx, 0, height + .4), (.3, depth, .6), concrete)


def police():
    W, D, H = 26.0, 10.5, 7.2
    shell(W, D, H, brick, 'Police')
    front = -D / 2
    # Two storeys of window bays; the entrance bay at x = -3 stays free.
    for i in range(8):
        x = -11.4 + i * 3.1 + (1.2 if i >= 4 else 0)
        if abs(x + 3.0) < 2.4:
            continue
        window(x, front, 5.3, 1.6, 1.5)
        window(x, front, 1.9, 1.3, 1.1, barred=True)
    # Projecting entrance with concrete canopy, blue board and a small plaque.
    ex = -3.0
    box('Entrance block', (ex, front - 1.1, 3.9), (5.0, 2.2, 7.8), brick)
    box('Entrance roof', (ex, front - 1.1, 7.95), (5.6, 2.8, .3), concrete)
    box('Entrance door', (ex, front - 2.22, 1.25), (1.9, .1, 2.2), door)
    box('Door canopy', (ex, front - 2.6, 2.9), (3.6, 1.6, .22), concrete)
    for dx in (-1.6, 1.6):
        v.rod('Canopy post', (ex + dx, front - 3.2, .6), (ex + dx, front - 3.2, 2.8), .07, steel)
    box('Blue sign board', (ex, front - 2.24, 4.6), (4.6, .12, 1.1), blue)
    v.text('МИЛИЦИЯ', (ex, front - 2.35, 4.35), .62, white)
    box('Plaque', (ex + 2.9, front - 2.0, 2.0), (.5, .08, .35), blue)
    # Flagpole from the entrance block.
    v.rod('Flagpole', (ex - 2.2, front - 2.0, 5.6), (ex - 4.2, front - 3.7, 8.3), .045, steel)
    # Rear garage wing for the duty vehicles.
    wing_x = 6.0
    box('Garage wing', (wing_x, D / 2 + 3.0, 1.75), (14.0, 6.0, 3.5), brick)
    box('Garage roof', (wing_x, D / 2 + 3.0, 3.62), (14.6, 6.6, .24), roofmat)
    box('Garage gate', (wing_x + 7.02, D / 2 + 3.0, 1.45), (.1, 3.2, 2.7), door)
    # Radio mast with antennas on the roof.
    base = Vector((-9.0, 1.0, H + .5))
    for sx, sy in ((-.6, -.6), (.6, -.6), (.6, .6), (-.6, .6)):
        v.rod('Mast leg', base + Vector((sx, sy, 0)), base + Vector((sx * .35, sy * .35, 13.0)), .04, steel)
    for z in range(2, 13, 3):
        r = .6 - z * .02
        v.rod('Mast brace', base + Vector((-r, -r, z)), base + Vector((r, -r, z)), .02, steel)
        v.rod('Mast brace', base + Vector((r, -r, z)), base + Vector((r, r, z)), .02, steel)
    v.rod('Whip antenna', base + Vector((0, 0, 13.0)), base + Vector((0, 0, 16.0)), .02, steel)
    box('Roof hut', (7.0, -1.0, H + .5 + .7), (2.6, 2.4, 1.4), plinth)
    return {'body': (W, D, H), 'wing': (14.0, 6.0, 3.5), 'mast_height': 16.0}


def clinic():
    W, D, H = 34.0, 12.0, 10.8
    shell(W, D, H, plaster, 'Clinic')
    front = -D / 2
    # Green band between floors and a ribbon of paired windows on each of three floors.
    for z in (3.6, 7.2):
        box('Floor band', (0, front - .04, z), (W + .1, .1, .5), band)
    for floor in range(3):
        for i in range(10):
            x = -15.0 + i * 3.33
            if abs(x) < 4.2:
                continue
            window(x, front, 1.9 + floor * 3.6, 2.0, 1.5)
    # Central entrance block with a full-height glazed stairwell that rises above the roofline.
    box('Entrance block', (0, front - 1.6, 6.6), (8.0, 3.2, 13.2), plaster)
    box('Entrance roof', (0, front - 1.6, 13.35), (8.6, 3.8, .3), concrete)
    box('Stair glazing', (0, front - 3.22, 7.6), (4.4, .12, 9.0), glass)
    for dx in (-2.2, -.73, .73, 2.2):
        box('Stair mullion', (dx, front - 3.3, 7.6), (.12, .14, 9.0), frame)
    for z in (3.2, 6.8, 10.4):
        box('Stair landing line', (0, front - 3.3, z), (4.5, .14, .12), frame)
    box('Entrance doors', (0, front - 3.24, 1.2), (3.2, .1, 2.2), door)
    box('Entrance canopy', (0, front - 4.1, 2.9), (5.6, 2.0, .22), concrete)
    for dx in (-2.4, 2.4):
        v.rod('Canopy post', (dx, front - 4.9, .6), (dx, front - 4.9, 2.8), .08, steel)
    # Red cross plate on the stair block.
    box('Cross plate', (3.6, front - 3.25, 11.4), (1.9, .1, 1.9), white)
    box('Cross bar', (3.6, front - 3.32, 11.4), (1.4, .08, .45), red)
    box('Cross bar', (3.6, front - 3.32, 11.4), (.45, .08, 1.4), red)
    v.text('ПОЛИКЛИНИКА', (0, front - 3.35, 12.1), .55, band)
    # Ambulance porch at the south end: roof on posts, one storey.
    px = -W / 2 + 1.0
    box('Ambulance porch roof', (px - 1.0, front - 3.0, 3.9), (8.0, 6.0, .3), concrete)
    for x in (px - 4.7, px + 2.7):
        v.rod('Porch post', (x, front - 5.7, .6), (x, front - 5.7, 3.8), .1, steel)
    box('Porch door', (px - 1.0, front - .04, 1.3), (2.2, .1, 2.4), door)
    # Roof plant.
    box('Roof hut', (9.0, 1.0, H + .5 + .8), (3.4, 2.6, 1.6), plinth)
    box('Roof vent', (-9.0, 2.0, H + .5 + .5), (1.4, 1.4, 1.0), plinth)
    return {'body': (W, D, H), 'entrance_block': (8.0, 3.2, 13.2)}


def render(name, camera_dir, target, size=48.0):
    cam_data = bpy.data.cameras.new('cam')
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = size
    cam = bpy.data.objects.new('cam', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    direction = Vector(camera_dir).normalized()
    cam.location = Vector(target) + direction * 80
    cam.rotation_euler = (-direction).to_track_quat('-Z', 'Y').to_euler()
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.render.resolution_x, scene.render.resolution_y = 1400, 900
    scene.render.filepath = str(HERE / 'previews' / (name + '.png'))
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)


def clear():
    for ob in list(v.parts):
        bpy.data.objects.remove(ob, do_unlink=True)
    v.parts.clear()


report = {}
report['police'] = police()
# Game-like camera: from the south-east above; plus a straight frontal view.
render('police_iso', (-0.6, -1.0, 0.85), (0, 2, 4))
render('police_front', (0, -1.0, 0.25), (0, 2, 5))
bpy.ops.wm.save_as_mainfile(filepath=str(HERE / 'police_blockout.blend'))
clear()
report['clinic'] = clinic()
render('clinic_iso', (-0.6, -1.0, 0.85), (0, 0, 5), 56.0)
render('clinic_front', (0, -1.0, 0.25), (0, 0, 6), 56.0)
bpy.ops.wm.save_as_mainfile(filepath=str(HERE / 'clinic_blockout.blend'))
print('BLOCKOUT_COMPLETE', report, flush=True)
