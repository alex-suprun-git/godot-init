"""Build the Lada Wagon asset (station-wagon body derived from the V2 sedan) in the open Blender through its Python API.

Source units: metres. Front: -Y in Blender, +Z after glTF import in Godot.
The original scene is preserved; generated objects live in Lada_Studio_V2.
"""
from pathlib import Path
import math
import json
import bpy
import bmesh
from mathutils import Vector

PROJECT = Path(__file__).resolve().parents[3]
SOURCE = PROJECT / 'art/models/lada'
PREVIEWS = SOURCE / 'previews'
EXPORT = PROJECT / 'init/assets/models/vehicles'
for directory in (SOURCE, PREVIEWS, EXPORT):
    directory.mkdir(parents=True, exist_ok=True)

SCENE_NAME = 'Lada_Studio_Wagon'
old = bpy.data.scenes.get(SCENE_NAME)
if old:
    for obj in list(old.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.scenes.remove(old)
scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
asset_collection = bpy.data.collections.new('Lada Wagon - export')
scene.collection.children.link(asset_collection)
studio_collection = bpy.data.collections.new('Studio - preview only')
scene.collection.children.link(studio_collection)
root = bpy.data.objects.new('Lada_Wagon', None)
asset_collection.objects.link(root)
root['front_axis'] = '-Y in Blender; +Z in Godot'
root['purpose'] = 'Stylized 1990s station wagon, body variant of the Lada V2 sedan'
asset_objects = []
paint_objects = []


def linear(hex_color):
    values = [int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4 for c in values)


def material(name, color, metal=0, rough=.5):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*linear(color), 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = mat.diffuse_color
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    return mat


paint = material('Lada - aged ivory paint', 'D8D8CA', .14, .46)
rubber = material('Lada - rubber', '202321', 0, .83)
seam = material('Lada - panel gaps', '66685E', .05, .8)
chrome = material('Lada - satin chrome', '9CA1A0', .83, .25)
steel = material('Lada - wheel steel', '92938C', .68, .4)
dark_steel = material('Lada - grille and steel recesses', '353B38', .38, .55)
glass = material('Lada - blue grey glass', '354F5B', .36, .19)
glass.node_tree.nodes.get('Principled BSDF').inputs['Coat Weight'].default_value = .55
headlamp = material('Lada - headlight glass', 'BCC3AF', .28, .2)
amber = material('Lada - amber signal', 'BD6928', .1, .26)
red = material('Lada - red tail lamp', '8D2825', .16, .28)
plate_mat = material('Lada - registration enamel', 'D5D4BD', .1, .5)
rust = material('Lada - worn sill edge', '705444', .05, .85)


def link_asset(obj, mat=None, parent=None):
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    asset_collection.objects.link(obj)
    obj.parent = parent or root
    if mat:
        obj.data.materials.append(mat)
    asset_objects.append(obj)
    if mat == paint:
        paint_objects.append(obj)
    return obj


def finish(obj, bevel=0, smooth=False):
    if obj.type == 'MESH':
        for face in obj.data.polygons:
            face.use_smooth = smooth
    if bevel:
        mod = obj.modifiers.new('Soft manufactured edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = 'ANGLE'
        mod.harden_normals = True
        normal = obj.modifiers.new('Weighted face normals', 'WEIGHTED_NORMAL')
        normal.keep_sharp = True
        normal.weight = 50
    return obj


def box(name, location, size, mat, bevel=.005, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    link_asset(obj, mat, parent)
    return finish(obj, bevel)


def cylinder(name, location, radius, depth, mat, axis='X', vertices=32, parent=None):
    rotation = (0, math.pi / 2, 0) if axis == 'X' else ((math.pi / 2, 0, 0) if axis == 'Y' else (0, 0, 0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    link_asset(obj, mat, parent)
    return finish(obj, .0015, True)


def torus(name, location, major, minor, mat, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                   major_segments=40, minor_segments=10,
                                   location=location, rotation=(0, math.pi / 2, 0))
    obj = bpy.context.object
    obj.name = name
    link_asset(obj, mat, parent)
    return finish(obj, smooth=True)


def mesh(name, vertices, faces, mat, bevel=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    link_asset(obj, mat)
    return finish(obj, bevel)


def line(name, points, radius, mat, cyclic=False, parent=None):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 1
    data.bevel_depth = radius
    data.bevel_resolution = 2
    data.use_fill_caps = True
    spline = data.splines.new('POLY')
    spline.points.add(len(points)-1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1)
    spline.use_cyclic_u = cyclic
    curve_obj = bpy.data.objects.new(name, data)
    asset_collection.objects.link(curve_obj)
    data.materials.append(mat)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    baked = bpy.data.meshes.new_from_object(curve_obj.evaluated_get(depsgraph))
    bpy.data.objects.remove(curve_obj, do_unlink=True)
    obj = bpy.data.objects.new(name, baked)
    link_asset(obj, parent=parent)
    if mat == paint:
        paint_objects.append(obj)
    return obj


# A closed body shell with tapered cross-sections, then actual wheel openings.
stations = [(-2.0, .885, .965), (-1.84, .925, 1), (-.84, .945, 1),
            (1.20, .945, 1), (1.98, .91, .975)]
vertices = []
for y, top, taper in stations:
    for x, z in [(-.735, .35), (.735, .35), (.805, .49), (.81, top-.045),
                 (.748, top), (-.748, top), (-.81, top-.045), (-.805, .49)]:
        vertices.append((x*taper, y, z))
faces = []
for i in range(len(stations)-1):
    for k in range(8):
        faces.append((i*8+k, i*8+(k+1)%8, (i+1)*8+(k+1)%8, (i+1)*8+k))
faces.extend([tuple(range(7, -1, -1)), tuple(range(32, 40))])
body = mesh('Wagon body shell', vertices, faces, paint)
for axle in [-1.21, 1.21]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.337, depth=3,
                                      location=(0, axle, .30), rotation=(0, math.pi/2, 0))
    cutter = bpy.context.object
    boolean = body.modifiers.new('Wheel arch cut', 'BOOLEAN')
    boolean.operation = 'DIFFERENCE'
    boolean.object = cutter
    boolean.solver = 'EXACT'
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=boolean.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
finish(body, .009)
box('Chassis underside', (0, 0, .34), (1.26, 3.55, .10), rubber, .025)

cab_vertices = [(-.772, -.84, .945), (.772, -.84, .945), (.772, 1.93, .93), (-.772, 1.93, .93),
                (-.635, -.38, 1.44), (.635, -.38, 1.44), (.635, 1.74, 1.44), (-.635, 1.74, 1.44)]
cab_faces = [(0,1,5,4), (1,2,6,5), (2,3,7,6), (3,0,4,7), (4,5,6,7), (3,2,1,0)]
mesh('Cabin and roof (wagon)', cab_vertices, cab_faces, paint, .014)


def glass_panel(name, points):
    obj = mesh(name, points, [tuple(range(len(points)))], glass)
    line(name + ' rubber seal', points, .010, rubber, cyclic=True)
    line(name + ' bright trim', points, .0036, chrome, cyclic=True)
    return obj


glass_panel('Windscreen', [(-.710,-.807,.987), (.710,-.807,.987),
                          (.595,-.433,1.390), (-.595,-.433,1.390)])
glass_panel('Tailgate glass', [(-.707,1.904,1.02), (.707,1.904,1.02),
                              (.597,1.772,1.38), (-.597,1.772,1.38)])


def side_point(sign, y, z, offset=.004):
    x = .772 - (z-.945) / .495 * .137
    return (sign*(x+offset), y, z)


for sign in [-1, 1]:
    side = 'L' if sign < 0 else 'R'
    front_window = [side_point(sign,-.743,1.001), side_point(sign,.127,1.001),
                    side_point(sign,.127,1.384), side_point(sign,-.363,1.384)]
    back_window = [side_point(sign,.205,1.001), side_point(sign,1.80,1.001),
                   side_point(sign,1.64,1.384), side_point(sign,.205,1.384)]
    glass_panel(side+' front window', front_window)
    glass_panel(side+' rear window', back_window)
    line(side+' B pillar', [side_point(sign,.166,1.0,.008), side_point(sign,.166,1.39,.008)], .022, rubber)
    # Four doors, shaped rear edges, recessed handles and a fuel flap.
    x = sign*.812
    for label, yz in [('front',[(-.775,.944),(-.695,.424),(.168,.407),(.168,.944)]),
                      ('rear',[(.203,.944),(.203,.408),(.900,.408),(.900,.944)])]:
        line(side+' '+label+' door seam', [(x,y,z) for y,z in yz], .0028, seam)
    for y in [.015,.895]:
        box(side+' handle recess', (sign*.815,y,.862), (.012,.172,.047), rubber, .008)
        box(side+' handle chrome', (sign*.827,y,.873), (.013,.138,.015), chrome, .004)
    cylinder(side+' keyhole', (sign*.831,.013,.819), .010, .012, chrome, vertices=12)
    line(side+' sill edge', [(sign*.766,-.83,.375),(sign*.766,.84,.375)], .008, rust)
    line(side+' body moulding', [(sign*.813,-1.96,.686),(sign*.813,1.94,.686)], .008, chrome)
    # Thin folded fender lips follow the cutout rather than hiding the wheel.
    for axle in [-1.21,1.21]:
        low_angle = math.asin(.05/.340)
        points = [(sign*.814, axle+math.cos(a)*.340, .30+math.sin(a)*.340)
                  for a in [low_angle+i*(math.pi-2*low_angle)/24 for i in range(25)]]
        line(side+' rolled wheel arch', points, .006, paint)
    if sign > 0:
        line('Fuel flap outline', [(x,1.57,.827),(x,1.78,.827),(x,1.78,.67),(x,1.57,.67)], .0028, seam, True)
    box(side+' mirror arm',(sign*.827,-.672,1.016),(.10,.035,.030),rubber,.005)
    box(side+' mirror housing',(sign*.891,-.672,1.065),(.085,.165,.106),rubber,.016)
    box(side+' mirror surface',(sign*.891,-.583,1.066),(.065,.008,.080),chrome,.008)
    box(side+' wing indicator',(sign*.816,-1.69,.754),(.014,.080,.034),amber,.006)

line('Hood panel outline',[(-.708,-1.925,.912),(.708,-1.925,.912),(.716,-.896,.948),(-.716,-.896,.948)],.0026,seam,True)
line('Tailgate panel outline',[(-.70,1.985,.60),(.70,1.985,.60),(.70,1.975,.92),(-.70,1.975,.92)],.0026,seam,True)
for sign in [-1,1]:
    line('Roof rain gutter',[(sign*.781,-.833,.968),(sign*.651,-.373,1.437),
                             (sign*.651,1.74,1.437),(sign*.781,1.93,.95)],.0055,chrome)
    # Roof rails along the longer roof.
    line('Roof rail',[(sign*.50,-.25,1.462),(sign*.50,1.62,1.462)],.011,chrome)
    for ry in [-.20,.60,1.55]:
        box('Roof rail foot',(sign*.50,ry,1.452),(.03,.05,.025),rubber,.004)
    for i in range(12):
        box('Cowl ventilation slot',(sign*(.20+i*.024),-.875,.947),(.011,.072,.003),rubber,.001)
    # Wipers lie on the sloping windscreen.
    line('Wiper arm',[(sign*.31,-.795,1.004),(sign*.42,-.695,1.114)],.005,rubber)
    line('Wiper blade',[(sign*.56,-.693,1.12),(sign*.20,-.693,1.12)],.006,rubber)

# Separate grille, headlight bezels, bumper trim and registration plates.
box('Front grille surround',(0,-2.009,.764),(.83,.035,.29),chrome,.009)
box('Front grille recess',(0,-2.031,.764),(.777,.019,.245),rubber,.005)
for i in range(7):
    box('Grille horizontal rib',(0,-2.044,.667+i*.032),(.746,.012,.010),dark_steel,.0015)
for x in [-.245,0,.245]:
    box('Grille upright',(x,-2.049,.762),(.009,.009,.222),chrome,.001)
box('Grille badge',(0,-2.058,.79),(.046,.012,.068),chrome,.004)
box('Grille badge inset',(0,-2.067,.792),(.026,.003,.046),glass,.001)
for sign in [-1,1]:
    x=sign*.604
    box('Headlight chrome bezel',(x,-2.003,.77),(.385,.032,.254),chrome,.008)
    box('Headlight rubber gasket',(x,-2.024,.77),(.355,.017,.228),rubber,.004)
    box('Headlight lens',(x,-2.038,.77),(.334,.017,.208),headlamp,.006)
    for i in range(10):
        box('Pressed glass lens rib',(x-.145+i*.032,-2.048,.77),(.0024,.002,.189),chrome,.0007)
    box('Front amber signal',(sign*.806,-2.002,.764),(.057,.038,.205),amber,.006)
    box('Rear lamp rubber bezel',(sign*.593,2.001,.772),(.39,.033,.236),rubber,.007)
    for j,(mat,width) in enumerate([(red,.166),(amber,.091),(headlamp,.091)]):
        offset=[-.104,.037,.136][j]
        box('Rear lamp segment',(sign*(.593+offset),2.024,.772),(width,.019,.208),mat,.005)
for y in [-2.102,2.088]:
    box('Bumper chrome beam',(0,y,.447),(1.72,.130,.138),chrome,.019)
    box('Bumper rubber rub strip',(0,y+(-.070 if y<0 else .070),.434),(1.75,.040,.078),rubber,.013)
    for x in [-.805,.805]:
        box('Bumper rubber endcap',(x,y,.443),(.135,.179,.157),rubber,.018)


def plate(name, y, z, back=False):
    box(name+' backing',(0,y,z),(.405,.015,.111),rubber,.004)
    box(name+' enamel',(0,y+(.010 if back else -.010),z),(.388,.008,.096),plate_mat,.003)
    data=bpy.data.curves.new(name+' lettering','FONT')
    data.body='A 2107 KC'
    data.align_x='CENTER'
    data.align_y='CENTER'
    data.size=.062
    data.extrude=.0003
    text=bpy.data.objects.new(name+' lettering',data)
    asset_collection.objects.link(text)
    text.location=(0,y+(.016 if back else -.016),z)
    text.rotation_euler=(math.pi/2,0,math.pi if back else 0)
    data.materials.append(rubber)
    text.parent=root
    asset_objects.append(text)


plate('Front plate',-2.025,.565)
plate('Rear plate',2.015,.555,True)

# Four editable wheel assemblies with sidewall rings, steel rims and lug nuts.
for sign in [-1,1]:
    for axle in [-1.21,1.21]:
        side='L' if sign<0 else 'R'
        wheel=bpy.data.objects.new('Wheel_'+side+('_F' if axle<0 else '_R'),None)
        asset_collection.objects.link(wheel)
        wheel.parent=root
        x=sign*.775
        torus('Tire',(x,axle,.30),.232,.068,rubber,wheel)
        cylinder('Tire inner wall',(x,axle,.30),.247,.171,rubber,parent=wheel)
        for offset,radius in [(.084,.252),(.087,.225),(.088,.198)]:
            torus('Sidewall embossed ring',(x+sign*offset,axle,.30),radius,.0025,rubber,wheel)
        cylinder('Steel rim',(x+sign*.087,axle,.30),.181,.026,steel,parent=wheel)
        cylinder('Wheel dish',(x+sign*.103,axle,.30),.145,.012,chrome,parent=wheel)
        torus('Rim rolled lip',(x+sign*.106,axle,.30),.171,.0075,chrome,wheel)
        for i in range(8):
            a=math.tau*i/8
            cylinder('Rim ventilation recess',(x+sign*.112,axle+math.cos(a)*.124,.30+math.sin(a)*.124),.016,.003,rubber,vertices=16,parent=wheel)
        cylinder('Hub centre',(x+sign*.116,axle,.30),.060,.019,steel,parent=wheel)
        cylinder('Hub cap',(x+sign*.128,axle,.30),.032,.014,dark_steel,parent=wheel)
        for i in range(4):
            a=math.tau*i/4+math.pi/4
            cylinder('Lug nut',(x+sign*.125,axle+math.cos(a)*.074,.30+math.sin(a)*.074),.010,.014,chrome,vertices=6,parent=wheel)

# Studio setup is excluded from the exported asset.
floor_mat=material('Studio charcoal olive','424A46',0,.77)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.008))
floor=bpy.context.object
floor.name='Studio floor'
for collection in list(floor.users_collection):
    collection.objects.unlink(floor)
studio_collection.objects.link(floor)
floor.data.materials.append(floor_mat)


def area(name, location, energy, size, color):
    data=bpy.data.lights.new(name,'AREA')
    data.energy=energy
    data.shape='DISK'
    data.size=size
    data.color=color
    obj=bpy.data.objects.new(name,data)
    studio_collection.objects.link(obj)
    obj.location=location
    obj.rotation_euler=(Vector((0,0,.65))-obj.location).to_track_quat('-Z','Y').to_euler()


area('Large softbox',(2,-3.5,6),750,4.0,(1.0,.91,.77))
area('Cool fill',(-4,-1,3.5),550,4.0,(.76,.86,1.0))
area('Rear rim',(1,4,5),950,3.0,(1.0,.98,.9))
world=bpy.data.worlds.new('Lada wagon studio world')
world.use_nodes=True
world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.2,.25,.29,1)
world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.4
scene.world=world
camera_data=bpy.data.cameras.new('Lada wagon presentation camera')
camera=bpy.data.objects.new('Lada wagon presentation camera',camera_data)
studio_collection.objects.link(camera)
camera.location=(5,-7,4.0)
camera.rotation_euler=(Vector((0,0,.74))-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='ORTHO'
camera_data.ortho_scale=5.8
scene.camera=camera
scene.render.engine='CYCLES'
scene.cycles.samples=48
scene.cycles.use_denoising=True
scene.render.resolution_x=1600
scene.render.resolution_y=1100
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
try:
    prefs=bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type='METAL'
    prefs.get_devices()
    for device in prefs.devices:
        device.use=device.type=='METAL'
    scene.cycles.device='GPU'
except Exception:
    scene.cycles.device='CPU'

for screen in bpy.data.screens:
    for area_item in screen.areas:
        if area_item.type=='VIEW_3D':
            area_item.spaces.active.region_3d.view_perspective='CAMERA'
            area_item.spaces.active.shading.type='MATERIAL'
            area_item.spaces.active.overlay.show_overlays=False
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'lada_wagon.blend'))
print(json.dumps({'scene':scene.name,'asset_objects':len(asset_objects),'source':str(SOURCE/'lada_wagon.blend')}))
