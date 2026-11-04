"""1997 rented department store. Blender CLI; metres, -Y avenue frontage.

Reuse original civic-venue geometry/material helpers without rebuilding their assets.
Keep the 24 x30m two-storey body and current map position; new detail is physical.
"""
from pathlib import Path
import importlib.util
import json
import math
import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
spec=importlib.util.spec_from_file_location('venue_helpers',HERE.parent/'civic_venues/build_assets.py')
v=importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
scene=v.scene
scene.name='DepartmentStore_1997'
out=HERE/'exports'
out.mkdir(parents=True,exist_ok=True)

prints=v.material('Department_store_printed_graphics',(1,1,1))
bs=next(n for n in prints.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
tex=prints.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(HERE/'textures/retail-atlas-v1.png'))
prints.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
navy=v.material('Tenant_navy',(.035,.075,.13))
green=v.material('Tenant_green',(.075,.15,.075))
burgundy=v.material('Tenant_burgundy',(.23,.045,.035))
old_red=v.material('Old_institutional_red',(.56,.10,.045))
carton=v.material('Ordinary_cardboard',(.37,.26,.14))
ad_yellow=v.material('Period_advertising_yellow',(.70,.48,.025))
cloth=[v.material('Garment_'+str(i),c) for i,c in enumerate([(.10,.17,.23),(.28,.13,.16),(.48,.44,.36),(.12,.19,.17)])]

def panel(name,corners,index,text_band=False,lower_half=False):
    col=index%3; row=index//3
    a,c=col/3+.003,(col+1)/3-.003
    b,d=(1-row)*.5+.003,(2-row)*.5-.003
    if text_band:b=d-.22
    if lower_half:d=b+.24
    return v.mesh(name,corners,[(0,1,2,3)],prints,[[(a,b),(c,b),(c,d),(a,d)]])

def front_panel(index,x,y,z,w,h,text_band=False):
    return panel('Printed tenant sign',[(x-w/2,y,z-h/2),(x+w/2,y,z-h/2),
        (x+w/2,y,z+h/2),(x-w/2,y,z+h/2)],index,text_band)

def south_panel(index,y,z,w,h,text_band=False):
    return panel('Garden-side retail graphics',[(12.24,y-w/2,z-h/2),(12.24,y+w/2,z-h/2),
        (12.24,y+w/2,z+h/2),(12.24,y-w/2,z+h/2)],index,text_band)

def rear_panel(index,x,z,w,h,text_band=False):
    return panel('Rear tenant graphics',[(x+w/2,15.24,z-h/2),(x-w/2,15.24,z-h/2),
        (x-w/2,15.24,z+h/2),(x+w/2,15.24,z+h/2)],index,text_band)

def oriented_window(y,z,w,h,side=False):
    start=len(v.parts)
    v.front_window(0,0,0,w,h,True)
    for ob in v.parts[start:]:
        for p in ob.data.vertices:
            a,b,c=p.co
            p.co=(12.055-b,y+a,z+c) if side else (-a,15.055-b,z+c)

def front_awning(x,width,mat):
    v.box('Individual avenue canopy',(x,-15.45,2.75),(width,.95,.14),mat)
    v.box('Independent canopy fascia',(x,-15.92,2.59),(width,.08,.28),mat)
    for xx in [-width/2,width/2]:
        v.rod('Canopy bracket',(x+xx,-15.06,2.4),(x+xx,-15.85,2.67),.035)

def south_awning(y,width,mat):
    v.box('Garden tenant canopy',(12.85,y,2.8),(1.65,width,.15),mat)
    v.box('Canvas front valance',(13.65,y,2.62),(.08,width,.3),mat)

# Retained concrete shell, real plinth/cornice and recessed openings.
v.box('Inherited Soviet concrete structure',(0,0,3),(24,30,6),cell=3)
v.box('Repaired ceramic plinth',(0,0,.35),(24.2,30.2,.7),cell=1)
v.box('Upper floor horizontal band',(0,0,3.08),(24.35,30.35,.32),cell=3)
for x in [-11.7,-8,-4,0,4,8,11.7]:
    v.box('Avenue concrete bay pier',(x,-15.13,3.1),(.24,.32,5.8),cell=3)
    v.front_window(x if abs(x)<11 else x*.97,-15.12,4.48,3.55 if abs(x)<11 else 1.0,2.25,True)
for y in [-12,-8,-4,0,4,8,12]:
    oriented_window(y,4.48,3.6,2.25,True)
    v.box('Side structural concrete pier',(12.16,y+1.92,3),(.32,.23,5.85),cell=3)
for x in [-9,-5,-1,3,7,10.5]:oriented_window(x,4.48,2.9,2.25)

# Three independent street-facing rentals rather than one undifferentiated lobby.
for i,x in enumerate([-8,0,8]):
    mat=[navy,green,burgundy][i]
    v.front_window(x-1.8,-15.16,1.65,3.4,1.85,True)
    front_panel(5,x-1.8,-15.30,1.65,3.25,1.7)
    v.front_window(x+1.8,-15.22,1.4,1.5,2.35,True)
    v.rod('Shop door handle',(x+2.1,-15.4,1),(x+2.1,-15.4,1.65),.035)
    front_awning(x,7.3,mat)
    front_panel([2,3,4][i],x,-15.99,2.60,7.0,.32,True)

# Main old sign, newly rented electronics frontage, old roof retained.
front_panel(0,0,-15.25,5.6,12.5,.7,True)
v.box('Blue electronics banner backing',(0,15.22,4.45),(17.5,.08,2.35),navy)
panel('CRT VHS and hi-fi advertising',[( -2.0,15.29,3.3),(-8.6,15.29,3.3),
    (-8.6,15.29,5.6),(-2.0,15.29,5.6)],1,lower_half=True)
curve=bpy.data.curves.new('Readable1997 electronics headline','FONT')
curve.body='ИМПОРТНАЯ\nТЕХНИКА';curve.font=v.font;curve.size=.90;curve.align_x='CENTER'
curve.extrude=.008;curve.offset=.008
headline=bpy.data.objects.new('Authored electronics headline',curve)
scene.collection.objects.link(headline);headline.data.materials.append(ad_yellow)
headline.rotation_euler=(math.pi/2,0,math.pi);headline.location=(3.5,15.30,4.9)
bpy.context.view_layer.objects.active=headline
bpy.ops.object.select_all(action='DESELECT');headline.select_set(True)
bpy.ops.object.convert(target='MESH');v.parts.append(headline)
for x in [-8,0,8]:
    v.rod('Banner mounting steel',(x,15.08,3.25),(x,15.36,5.8),.035)
v.box('Dark bituminous roof',(0,0,6.18),(24.7,30.7,.26),v.felt)
for x in [-12.2,12.2]:v.box('Roof coping',(x,0,6.42),(.24,30.6,.24),cell=3)
for y in [-15.2,15.2]:v.box('Roof coping',(0,y,6.42),(24.6,.24,.24),cell=3)
for x,y in [(-5,-4),(4,1),(0,10)]:
    v.box('Original roof vent',(x,y,6.7),(1.1,1.2,.8),cell=3)
    v.box('Vent rain cap',(x,y,7.12),(1.35,1.45,.12),v.metal)
# Old red roof letters face south toward the administration, per user correction.
sign_start=len(v.parts)
curve=bpy.data.curves.new('Old red roof lettering','FONT')
curve.body='УНИВЕРМАГ';curve.font=v.font;curve.size=2.8;curve.align_x='CENTER'
curve.extrude=.035;curve.offset=.045
bpy.ops.object.select_all(action='DESELECT')
lettering=bpy.data.objects.new('УНИВЕРМАГ — administration-facing roof letters',curve)
scene.collection.objects.link(lettering)
lettering.data.materials.append(old_red)
lettering.rotation_euler=(math.pi/2,0,math.pi)
lettering.location=(0,14.25,6.75)
bpy.context.view_layer.objects.active=lettering;lettering.select_set(True)
bpy.ops.object.convert(target='MESH')
v.parts.append(lettering)
for x in [-9,0,9]:
    v.rod('Roof sign upright',(x,14.0,6.35),(x,14.0,8.75),.045)
    v.rod('Roof sign brace',(x,12.7,6.35),(x,14.0,8.2),.035)
v.rod('Roof sign beam',(-9.2,14,6.7),(9.2,14,6.7),.045)
sign_transform=Matrix.Translation(Vector((10.5,0,0))) @ Matrix.Rotation(-math.pi/2,4,'Z') @ Matrix.Translation(Vector((0,-14,0)))
bpy.context.view_layer.update()
for ob in v.parts[sign_start:]:
    ob.matrix_world=sign_transform @ ob.matrix_world

# Side entrances/display bays make the garden elevation an inhabited retail face.
for y,mat,index in [(-8,navy,2),(6,green,3)]:
    oriented_window(y,1.5,1.7,2.35,True)
    oriented_window(y+3.1,1.6,3.3,1.85,True)
    south_panel(5,y+3.1,1.6,3.1,1.72)
    south_awning(y,6.2,mat)
    south_panel(index,y,3.45,6.5,.85,True)
south_panel(2,-8,4.75,7.2,1.35,True)
south_panel(4,7,4.75,6.6,1.35,True)
# Two small tables and clothes rails stay short of the public garden walk.
for y in [-6.5,7.0]:
    v.box('Outdoor wooden table',(13.4,y,.88),(1.25,2.3,.12),cell=5)
    for yy in [-.85,.85]:v.box('Display table leg',(13.4,y+yy,.45),(.10,.10,.85),v.metal)
    for i in range(4):
        v.box('Folded clothing and shoe boxes',(13.4,y-.8+i*.52,1.04),(.8,.42,.18),cloth[i])
for yy in [11.0,12.8]:v.rod('Clothes rail leg',(13.6,yy,0),(13.6,yy,1.8),.035)
v.rod('Clothes rail',(13.6,11,1.8),(13.6,12.8,1.8),.035)
for i in range(5):
    y=11.15+i*.33
    v.box('Hanging garment',(13.6,y,1.25),(.07,.28,.65),cloth[i%4])
    v.box('Garment shoulders',(13.6,y,1.52),(.09,.48,.18),cloth[i%4])
    v.rod('Wire hanger',(13.6,y,1.6),(13.6,y,1.79),.015)

# Service corner, modest boxes and a vent; not a ruined loading yard.
v.box('Rear service door',(-8,15.10,1.35),(1.5,.14,2.4),v.metal)
for x,y,z in [(-8.9,16,.35),(-9.6,16,.35),(-9.3,16,.95)]:
    v.box('Appliance carton',(x,y,z),(.65,.6,.65),carton)
v.box('Old side ventilation unit',(12.38,1,2.1),(.55,1.2,.75),cell=3)
for y in [.5,.7,.9,1.1,1.3,1.5]:v.box('Vent grille',(12.68,y,2.1),(.025,.025,.55),v.metal)

# Explicit single-mesh export; the blend retains editable geometry and materials.
bpy.ops.object.select_all(action='DESELECT')
for ob in v.parts:ob.select_set(True)
bpy.context.view_layer.objects.active=v.parts[0]
bpy.ops.object.join()
asset=bpy.context.object;asset.name='department_store_1997'
scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
for image in bpy.data.images:
    if image.source=='FILE' and not image.packed_file:image.pack()
asset.data.calc_loop_triangles()
report={'body_m':[24,30,6],'bounds_blender_m':list(asset.dimensions),
        'triangles':len(asset.data.loop_triangles),'materials':len(asset.data.materials),
        'front':'Blender -Y, Godot +Z; map yaw -90 degrees','objects_exported':1}
bpy.ops.export_scene.gltf(filepath=str(out/'department_store_1997.glb'),export_format='GLB',
    use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_materials='EXPORT')
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'department_store_1997.blend'))
(HERE/'export_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('DEPARTMENT_STORE_COMPLETE',json.dumps(report),flush=True)
