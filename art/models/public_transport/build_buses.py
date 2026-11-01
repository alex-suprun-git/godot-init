"""Original bus shape pass. Run inside Blender with tools/blender_mcp.py.

Only recreates PublicTransport_Shape; preserves other scenes. Metres, -Y front.
Exports stay in art/ until visual review; no traffic replacement in this stage.
"""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
STAGE = HERE / 'shape_v1'
STAGE.mkdir(exist_ok=True)
old = bpy.data.scenes.get('PublicTransport_Shape')
if old:
    for obj in list(old.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.scenes.remove(old)
scene = bpy.data.scenes.new('PublicTransport_Shape')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'


def mat(name, color, rough=.55, metal=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = m.diffuse_color
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    return m


ivory = mat('Bus - ivory paint', (.67, .62, .48))
blue = mat('LiAZ - blue paint', (.055, .16, .26))
ochre = mat('PAZ - ochre paint', (.40, .25, .085))
rubber = mat('Bus - rubber', (.018, .021, .020), .85)
glass = mat('Bus - opaque glass', (.038, .065, .076), .25, .15)
steel = mat('Bus - wheel steel', (.28, .30, .28), .45, .55)
lamp = mat('Bus - headlamp', (.76, .75, .60), .25)
red = mat('Bus - tail lamp', (.32, .035, .018), .35)
amber = mat('Bus - indicator', (.62, .26, .035), .4)


def assign(obj, name, material, parent=None):
    obj.name = name
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


def box(name, pos, size, material, parent=None, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    o = bpy.context.object
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(o, name, material, parent)
    if bevel:
        mod = o.modifiers.new('Physical rounded corners', 'BEVEL')
        mod.width, mod.segments = bevel, 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod = o.modifiers.new('Broad panel normals', 'WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def cyl(name, pos, radius, depth, material, parent=None, segments=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius, depth=depth,
                                      rotation=(0, math.pi / 2, 0), location=pos)
    o = assign(bpy.context.object, name, material, parent)
    for p in o.data.polygons:
        p.use_smooth = len(p.vertices) == 4
    return o


def panel(name, points, material, parent):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points, [], [list(range(len(points)))])
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(o)
    return assign(o, name, material, parent)


def rounded_panel(name, axis, depth, u, z, width, height, radius, material, root):
    points = []
    for cu,cz,start in [(u+width/2-radius,z+height/2-radius,0),
                        (u-width/2+radius,z+height/2-radius,90),
                        (u-width/2+radius,z-height/2+radius,180),
                        (u+width/2-radius,z-height/2+radius,270)]:
        for j in range(5):
            a = math.radians(start+j*22.5)
            p,q = cu+radius*math.cos(a),cz+radius*math.sin(a)
            points.append((depth,p,q) if axis=='X' else (p,depth,q))
    return panel(name, points, material, root)


def roof(root, length, width, eave, crown):
    # Crown is actual elliptical geometry; end rings round down into end walls.
    verts = []
    rings = [(-length/2+.04, .88, -.07), (-length/2+.20, 1, 0),
             (length/2-.20, 1, 0), (length/2-.04, .88, -.07)]
    for y, factor, dz in rings:
        for j in range(13):
            a = math.pi * j / 12
            verts.append((-.5 * width * math.cos(a) * factor, y,
                          eave + crown * math.sin(a) + dz))
    faces = []
    for k in range(3):
        for j in range(12):
            a = k*13+j
            faces.append((a, a+1, a+14, a+13))
    faces += [tuple(reversed(range(13))), tuple(range(39, 52))]
    mesh = bpy.data.meshes.new('Crowned roof')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    o = bpy.data.objects.new('Crowned roof', mesh)
    scene.collection.objects.link(o)
    assign(o, o.name, ivory, root)
    for p in mesh.polygons:
        p.use_smooth = len(p.vertices) == 4


def build(model, length, height, axles, radius, accent, small=False):
    root = bpy.data.objects.new(model, None)
    scene.collection.objects.link(root)
    width = 2.5
    bottom, belt, eave = (.52, 1.53, height-.23) if small else (.53, 1.55, height-.20)
    body = box('Continuous rounded body', (0, 0, (bottom+eave)/2),
               (width, length-.15, eave-bottom), ivory, root, .12 if small else .075)
    # True wheel openings through the body. Cutters are removed immediately.
    for y in axles:
        cutter = cyl('Wheel arch cutter', (0, y, radius), radius+.075, 3.0, rubber, segments=32)
        bpy.context.view_layer.objects.active = body
        mod = body.modifiers.new('Open wheel arch', 'BOOLEAN')
        mod.operation, mod.solver, mod.object = 'DIFFERENCE', 'EXACT', cutter
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
    # Assign lower paint band directly on shell faces; arch openings remain real.
    body.data.materials.append(accent)
    accent_index = len(body.data.materials)-1
    # Split at the paint line using a bisect, then classify faces by world height.
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                          plane_co=(0,0,1.13-body.location.z), plane_no=(0,0,1), dist=.00001)
    for f in bm.faces:
        if f.calc_center_median().z + body.location.z < 1.131:
            f.material_index = accent_index
    bm.to_mesh(body.data)
    bm.free()
    roof(root, length-.14, width, eave-.02, height-eave)
    box('Underbody', (0,0,.54), (1.65,length-.7,.18), rubber, root)
    for y in axles:
        for side in (-1,1):
            cyl('Tire', (side*1.075,y,radius), radius,.31,rubber,root)
            if y == axles[1]:
                cyl('Inner rear twin', (side*.78,y,radius), radius,.25,rubber,root)
            cyl('Wheel rim', (side*1.24,y,radius), radius*.60,.035,steel,root)
            cyl('Wheel hub', (side*1.266,y,radius), radius*.24,.055,steel,root,16)
    def window(side, y, span, low=belt+.06, high=eave-.12):
        x = side*1.255
        rounded_panel('Window rubber surround','X',x,y,(low+high)/2,span,high-low,.075,rubber,root)
        rounded_panel('Opaque side glazing','X',x+side*.018,y,(low+high)/2,
                      span-.065,high-low-.065,.055,glass,root)
        box('Sliding vent rail', (x+side*.029,y,high-.24), (.014,span-.055,.022),rubber,root)
    if small:
        for y, span in [(-2.73,.91),(-1.53,1.14),(-.28,1.16),(.98,1.16),(2.30,1.30)]:
            window(-1,y,span)
        for y, span in [(-2.57,1.27),(-.18,1.05),(1.02,1.13),(2.30,1.30)]:
            window(1,y,span)
        doors = [(-1.20,.74)]
    else:
        for y in [-4.70,-3.52,-2.34,-1.16,.02,1.20,2.38,3.56,4.74]:
            window(-1,y,1.07)
        for y,span in [(-3.65,1.45),(-2.08,1.45),(1.19,1.42),(2.75,1.42)]:
            window(1,y,span)
        doors = [(-4.83,1.15),(-.42,1.15),(4.62,1.15)]
    for y, span in doors:
        box('Passenger door frame', (1.264,y,(.57+eave-.11)/2),(.024,span,eave-.68),rubber,root,.01)
        for d in (-1,1):
            yy = y+d*span*.25
            box('Door leaf', (1.283,yy,1.59),(.022,span/2-.033,1.99),ivory,root,.009)
            box('Door lower paint', (1.299,yy,.86),(.012,span/2-.043,.47),accent,root)
            box('Door glass', (1.300,yy,1.95),(.014,span/2-.095,1.17),glass,root,.005)
    # Front glazing split at the centre; rear is a single broad window.
    for side in (-1,1):
        rounded_panel('Front screen seal','Y',-length/2+.024,side*.565,2.12,
                      1.08,1.10 if small else 1.13,.095,rubber,root)
        rounded_panel('Split front windscreen','Y',-length/2+.003,side*.565,2.12,
                      1.015,1.03 if small else 1.06,.072,glass,root)
    rounded_panel('Rear screen seal','Y',length/2-.020,0,2.12,2.13,.87,.10,rubber,root)
    rounded_panel('Rear glass','Y',length/2,0,2.12,2.05,.79,.075,glass,root)
    for y in (-length/2,length/2):
        box('Bumper',(0,y,.62 if small else .64),(2.46,.15,.20),rubber if small else accent,root,.035)
    if small:
        box('Early front grille',(0,-length/2-.012,1.24),(1.35,.03,.28),rubber,root,.012)
        for x in (-.90,.90):
            box('Round lamp surround',(x,-length/2-.008,1.20),(.39,.025,.35),rubber,root,.035)
            # Rotated wheel helper produces X axis cylinders; lamps need Y axis.
            o = cyl('Round headlight',(x,-length/2-.025,1.20),.13,.035,lamp,root,20)
            o.rotation_euler = (math.pi/2,0,0)
        box('Front ventilation',(0,-length/2-.017,1.47),(.64,.028,.12),rubber,root)
    else:
        for x in (-.86,.86):
            box('Twin lamp housing',(x,-length/2-.014,1.02),(.44,.035,.19),rubber,root,.012)
            for dx in (-.10,.10):
                box('Rectangular headlamp',(x+dx,-length/2-.04,1.02),(.16,.025,.12),lamp,root,.007)
        box('Destination panel',(0,-length/2+.014,2.78),(1.65,.028,.18),rubber,root,.01)
        for j in range(6):
            box('Rear engine vent',(0,length/2+.014,1.16+j*.066),(1.69,.018,.022),rubber,root)
    for x in (-1.03,1.03):
        box('Rear tail light',(x,length/2+.021,.95),(.26,.028,.13),red,root,.012)
        box('Rear indicator',(x,length/2+.022,1.09),(.26,.028,.09),amber,root,.009)
        box('Front indicator',(x,-length/2-.014,1.42),(.12,.026,.09),amber,root,.009)
    for side in (-1,1):
        box('Mirror arm',(side*1.30,-length/2+.31,2.25),(.18,.06,.045),rubber,root)
        box('Mirror',(side*1.38,-length/2+.26,2.13),(.09,.18,.31),rubber,root,.025)
    for y in ([-1.5,1.45] if small else [-3.6,0,3.5]):
        box('Roof ventilation hatch',(0,y,height-.01),(.78,.76,.065),ivory,root,.035)
    root['stage'] = 'Shape v1; livery provisional; not visually approved'
    root['body_dimensions_m'] = [length, width, height]
    root['wheelbase_m'] = axles[1]-axles[0]
    return root


liaz = build('LiAZ_5256',11.4,3.007,[-3.19,2.65],.49,blue)
paz = build('PAZ_3205',6.925,2.96,[-2.03,1.57],.44,ochre,True)


def select_root(root):
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for o in root.children_recursive:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root


report = {}
for root in (liaz,paz):
    # The editable source retains separate parts. Export meshes grouped by material.
    copies = []
    for original in list(root.children_recursive):
        if original.type == 'MESH':
            copy = original.copy()
            copy.data = original.data.copy()
            scene.collection.objects.link(copy)
            copies.append(copy)
            original.hide_set(True)
    bpy.ops.object.select_all(action='DESELECT')
    for copy in copies:
        copy.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
    bpy.ops.object.join()
    game = bpy.context.object
    game.name = root.name+'_game'
    # Joining keeps material surfaces; remove temporary game copy after export.
    root.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(STAGE/(root.name+'.glb')),export_format='GLB',
                              use_selection=True,use_active_scene=True)
    bpy.data.objects.remove(game,do_unlink=True)
    for original in root.children_recursive:
        original.hide_set(False)
    report[root.name] = dict(dimensions_m=list(root['body_dimensions_m']),
                             wheelbase_m=root['wheelbase_m'], stage=root['stage'])
(STAGE/'build_report.json').write_text(json.dumps(report,indent=2))
# Separate models spatially only after export. Preview script adds comparisons.
liaz.location.x = -2.2
paz.location.x = 2.2
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'buses.blend'))
print('Saved two original bus shape models to', STAGE)
