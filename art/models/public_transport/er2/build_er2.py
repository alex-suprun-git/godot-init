"""Original ER2 geometry; separate build/export/preview stages, no external geometry.

Blender --background --factory-startup --python build_er2.py [-- --blockout]
Real-metre construction is converted through the measured Volga L/W/H factors.
Blender -Y is forward; wheel treads touch Z=0; glTF forward is Godot +Z.
"""
from pathlib import Path
import bpy
import bmesh
import json
import math
import sys
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BLOCKOUT = '--blockout' in sys.argv
MEASURE = json.loads((HERE / 'volga_measurements.json').read_text())
SL, SW, SH = MEASURE['train_lwh_factors']
SCALE = Vector((SW, SL, SH))
GREEN = '304c3f'
GREEN_LIGHT = '3c5849'
CREAM = 'd1c79b'
ROOF = '989d9b'
DARK = '252c2d'
METAL = '6b7474'
GLASS = '314b55'


def rgb(value):
    c = [int(value[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4 for v in c)


def material(name, rough, metallic=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metallic
    color = m.node_tree.nodes.new('ShaderNodeVertexColor')
    color.layer_name = 'Color'
    m.node_tree.links.new(color.outputs['Color'], p.inputs['Base Color'])
    m.diffuse_color = (*rgb(GREEN if metallic == 0 else METAL), 1)
    return m


class Geometry:
    def __init__(self):
        self.verts, self.faces, self.colors, self.mats, self.smooth = [], [], [], [], []

    def polygon(self, points, color, mat=0, smooth=False):
        start = len(self.verts)
        self.verts.extend(points)
        self.faces.append(tuple(range(start, start + len(points))))
        self.colors.append((*rgb(color), 1))
        self.mats.append(mat)
        self.smooth.append(smooth)

    def box(self, center, size, color, mat=0):
        x, y, z = center
        a, b, c = [v / 2 for v in size]
        p = [(x+i*a, y+j*b, z+k*c) for i,j,k in
             [(-1,-1,-1), (1,-1,-1), (1,1,-1), (-1,1,-1),
              (-1,-1,1), (1,-1,1), (1,1,1), (-1,1,1)]]
        for f in [(0,3,2,1), (4,5,6,7), (0,1,5,4), (1,2,6,5), (2,3,7,6), (3,0,4,7)]:
            self.polygon([p[i] for i in f], color, mat)

    def cylinder(self, a, b, radius, color, mat=2, segments=12):
        a, b = Vector(a), Vector(b)
        axis = (b-a).normalized()
        v = axis.cross(Vector((0,0,1)))
        if v.length < .01:
            v = axis.cross(Vector((1,0,0)))
        v.normalize()
        w = axis.cross(v).normalized()
        rings = [[p + radius * (v*math.cos(i*math.tau/segments) + w*math.sin(i*math.tau/segments))
                  for i in range(segments)] for p in (a,b)]
        for i in range(segments):
            j = (i+1)%segments
            self.polygon([rings[0][i],rings[0][j],rings[1][j],rings[1][i]],color,mat,True)
        self.polygon(rings[0][::-1],color,mat)
        self.polygon(rings[1],color,mat)

    def beam(self, a, b, radius, color, mat=2):
        self.cylinder(a,b,radius,color,mat,6)

    def panel(self, mapper, width, height, radius, color, mat=0):
        # Rounded outline is sampled on the same surface for frames and glazing.
        points = []
        for cx,cy,start in [(width/2-radius,height/2-radius,0),
                            (-width/2+radius,height/2-radius,90),
                            (-width/2+radius,-height/2+radius,180),
                            (width/2-radius,-height/2+radius,270)]:
            for step in range(4):
                t=math.radians(start+step*30)
                points.append(mapper(cx+radius*math.cos(t), cy+radius*math.sin(t)))
        # Fan is safe for flat side panels and gently raked planar cab faces.
        center = mapper(0,0)
        for i in range(len(points)):
            self.polygon([center,points[i],points[(i+1)%len(points)]], color, mat)

    def object(self, name, collection, materials):
        data = bpy.data.meshes.new(name)
        data.from_pydata(self.verts, [], self.faces)
        data.update()
        for m in materials:
            data.materials.append(m)
        col = data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
        for p, color, mat, smooth in zip(data.polygons,self.colors,self.mats,self.smooth):
            p.material_index=mat
            p.use_smooth=smooth
            for index in p.loop_indices:
                col.data[index].color=color
        # Fix winding without splitting the intentionally smooth roof strips.
        bm=bmesh.new(); bm.from_mesh(data)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000001)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(data); bm.free()
        o=bpy.data.objects.new(name,data)
        collection.objects.link(o)
        return o


def shell(g, head):
    half = [(0,1.107),(1.55,1.107),(1.69,1.19),(1.74,1.38),(1.74,3.55),
            (1.72,3.70),(1.63,3.88),(1.40,4.055),(1.02,4.18),(.53,4.235),(0,4.253)]
    profile=half+[(-x,z) for x,z in half[-2:0:-1]]
    rings=[]
    for y, end_scale in [(-9.8,.94),(-9.52,1),(-8.8,1),(8.9,1),(9.55,1),(9.8,.97)]:
        points=[]
        for x,z in profile:
            yy=y
            if head and y < -9.5:
                yy += max(0,z-2.65)*.28
            points.append((x*end_scale,yy,z))
        rings.append(points)
    for a,b in zip(rings[:-1],rings[1:]):
        for i in range(len(profile)):
            j=(i+1)%len(profile)
            roof=(profile[i][1]+profile[j][1])/2 > 3.72
            g.polygon([a[i],a[j],b[j],b[i]],ROOF if roof else GREEN,0,roof)
    g.polygon(rings[0][::-1],GREEN)
    g.polygon(rings[-1],GREEN)


def side_window(g, side, y, z, w, h):
    for offset, inset, color, mat in [(0.012,0,'858d82',2),(.020,.035,DARK,2),(.025,.070,GLASS,1)]:
        g.panel(lambda u,v:(side*(1.741+offset),y+u,z+v),w-inset,h-inset,.09,color,mat)
    if not BLOCKOUT:
        g.box((side*1.778,y,z+.23),(0.014,w-.08,.025),'8d948d',2)


def passenger_door(g, side, y):
    # One paired sliding door at each end, on BOTH sides, closed for the static asset.
    g.panel(lambda u,v:(side*1.754,y+u,2.32+v),1.40,2.24,.06,DARK,2)
    for d in [-1,1]:
        center=y+d*.34
        g.panel(lambda u,v:(side*1.763,center+u,2.32+v),.655,2.18,.045,GREEN_LIGHT)
        g.panel(lambda u,v:(side*1.773,center+u,2.82+v),.42,.84,.07,DARK,2)
        g.panel(lambda u,v:(side*1.782,center+u,2.82+v),.34,.76,.055,GLASS,1)
    if not BLOCKOUT:
        for level in [1.08,.84,.60]:
            g.box((side*1.44,y,level),(.50,1.30,.07),METAL,2)
        g.box((side*1.78,y-.10,2.03),(.025,.035,.16),'8d948d',2)


def bogies(g, motor):
    wheelbase=2.6 if motor else 2.4
    radius=.525 if motor else .475
    for cy in [-6.65,6.65]:
        for yy in [cy-wheelbase/2,cy+wheelbase/2]:
            g.cylinder((-.88,yy,radius),(.88,yy,radius),.09,DARK)
            for s in [-1,1]:
                # Tread centres at +/- half gauge; exposed wheel faces remain inside body.
                x=s*.76
                g.cylinder((x-.085,yy,radius),(x+.085,yy,radius),radius,'3b4243',2,16)
                g.cylinder((x-.095,yy,radius),(x+.095,yy,radius),radius*.73,'535d5b',2,16)
                g.box((s*1.02,yy,.55),(.19,.33,.31),DARK,2)
        for s in [-1,1]:
            g.box((s*1.06,cy,.72),(.20,wheelbase+.55,.25),DARK,2)
            if not BLOCKOUT:
                for dy in [-.47,.47]:
                    g.cylinder((s*1.08,cy+dy,.61),(s*1.08,cy+dy,.94),.15,'505a55',2,10)
                    for z in [.66,.74,.82,.90]:
                        g.cylinder((s*1.08,cy+dy,z),(s*1.08,cy+dy,z+.025),.17,DARK,2,10)
        g.box((0,cy,.88),(1.65,.75,.25),DARK,2)


def cab_front_y(z):
    return -9.8 + max(0,z-2.65)*.28 - .018


def front(g):
    # A broad planar, raked square cab, with crowned roof rather than a bulbous nose.
    g.polygon([(-1.56,cab_front_y(2.48),2.48),(1.56,cab_front_y(2.48),2.48),
               (1.58,cab_front_y(2.91),2.91),(-1.58,cab_front_y(2.91),2.91)],CREAM)
    g.polygon([(-.48,cab_front_y(2.50)-.005,2.50),(.48,cab_front_y(2.50)-.005,2.50),
               (0,cab_front_y(2.20),2.20)],CREAM)
    for x in [-.80,.80]:
        for depth,inset,color,mat in [(0,0,'9caa9b',2),(.009,.045,DARK,2),(.018,.105,GLASS,1)]:
            g.panel(lambda u,v:(x+u,cab_front_y(3.28+v)-depth,3.28+v),1.42-inset,.85-inset,.11,color,mat)
        if not BLOCKOUT:
            g.beam((x-.30,cab_front_y(2.96)-.032,2.96),(x+.17,cab_front_y(3.28)-.032,3.28),.014,DARK)
    # Roof brow and central headlight.
    g.panel(lambda u,v:(u,cab_front_y(3.90+v)-.015,3.90+v),2.65,.32,.10,CREAM)
    for rad,y,color,mat in [(.225,-9.49,DARK,2),(.177,-9.53,METAL,2),(.137,-9.565,'d9d5bd',0)]:
        g.cylinder((0,y,3.99),(0,y-.035,3.99),rad,color,mat,20)
    for side in [-1,1]:
        for dx,rad,color in [(0,.12,'c9c8b1'),(.24,.07,'713b35')]:
            x=side*(1.20+dx)
            g.cylinder((x,-9.84,1.98),(x,-9.90,1.98),rad+.035,DARK,2,12)
            g.cylinder((x,-9.905,1.98),(x,-9.917,1.98),rad,color,0,12)
    if not BLOCKOUT:
        for z,width in [(.33,2.15),(.60,2.40),(.88,2.65)]:
            g.box((0,-9.88,z),(width,.11,.09),METAL,2)
        for side in [-1,1]:
            g.beam((side*.98,-9.88,.30),(side*1.45,-9.88,1.10),.045,DARK)


def end_face(g, y, front_end=False):
    sign=-1 if y<0 else 1
    for w,h,z,color,mat,depth in [(1.17,2.41,2.45,DARK,2,.04),(.95,2.20,2.45,GREEN_LIGHT,0,.055),
                                 (.57,.74,2.90,DARK,2,.065),(.48,.65,2.90,GLASS,1,.075)]:
        g.panel(lambda u,v:(u,y+sign*depth,z+v),w,h,.07,color,mat)
    for side in [-1,1]:
        g.panel(lambda u,v:(side*1.12+u,y+sign*.035,2.88+v),.52,.77,.065,GLASS,1)
    if not BLOCKOUT:
        for x in [-.61,.61]:
            g.box((x,y+sign*.10,2.39),(.055,.12,2.27),DARK,2)


def pantograph(g):
    py=-6.3
    for x in [-.63,.63]:
        for yy in [py-.90,py+.90]:
            g.cylinder((x,yy,4.20),(x,yy,4.48),.11,'766655',2,10)
    g.box((0,py,4.49),(1.45,2.00,.12),DARK,2)
    for x in [-.55,.55]:
        for direction in [-1,1]:
            mid=(x,py+direction*1.04,5.05)
            g.beam((x,py,4.59),mid,.035,'73574a')
            g.beam(mid,(x,py,5.421),.035,'73574a')
    g.box((0,py,5.4535),(1.66,.24,.065),METAL,2)
    if not BLOCKOUT:
        for yy in [-3.0,-1.8,0,1.8,3.6]:
            for z in [4.26,4.34,4.42]:
                g.cylinder((0,yy,z),(0,yy,z+.06),.12,'807363',2,10)
        g.beam((0,py,4.49),(0,3.6,4.52),.025,'756756')


def build_car(name,motor=False):
    g=Geometry()
    shell(g,not motor)
    bogies(g,motor)
    for side in [-1,1]:
        doors=[-7.05,7.05] if motor else [-6.65,6.90]
        for yy in doors:
            passenger_door(g,side,yy)
        for i in range(8):
            side_window(g,side,-4.85+i*1.38,2.98,1.12,1.00)
        if motor:
            for yy in [-8.65,8.65]:
                side_window(g,side,yy,2.98,.77,.96)
        else:
            side_window(g,side,-9.00,3.18,.95,.83)
            side_window(g,side,8.18,2.98,.60,.96)
            side_window(g,side,9.01,2.98,.60,.96)
            g.panel(lambda u,v:(side*1.758,-7.94+u,2.39+v),.63,2.18,.035,'263e35')
            side_window(g,side,-7.94,2.96,.39,.66)
        if not BLOCKOUT:
            # Modest long corrugations below the glazing, interrupted at doors.
            intervals=[(-9.40,doors[0]-.73),(doors[0]+.73,doors[1]-.73),(doors[1]+.73,9.45)]
            for a,b in intervals:
                for z in [1.45,1.66,1.86,2.09,2.30]:
                    g.box((side*1.751,(a+b)/2,z),(.018,b-a,.025),GREEN_LIGHT)
                g.box((side*1.755,(a+b)/2,2.43),(.022,b-a,.035),CREAM)
            for yy in [-4.30,-1.9,.6,3.3]:
                g.box((side*.94,yy,.86),(.98,1.50,.48),DARK,2)
            g.cylinder((side*.85,4.9,.82),(side*.85,6.0,.82),.24,'555c56',2,12)
        g.box((side*1.68,0,3.72),(.045,18.65,.045),METAL,2)
    if motor:
        end_face(g,-9.8)
        pantograph(g)
    else:
        front(g)
    end_face(g,9.8)
    for side in [-1,1]:
        y=side*9.89
        g.box((0,y,1.07),(.25,.40,.23),DARK,2)
        g.box((0,side*10.01,1.07),(.46,.16,.30),'626b64',2)
    if not BLOCKOUT:
        for yy in [-4.5,-1.6,1.4,4.3,7.0]:
            g.box((0,yy,4.26),(.42,.47,.10),METAL,2)
        g.box((0,-7.9,4.23),(.70,.70,.08),ROOF)
    o=g.object(name,collection,materials)
    for v in o.data.vertices:
        v.co=Vector((v.co.x*SW,v.co.y*SL,v.co.z*SH))
    o['source_dimensions']='ER2 handbook: body 19.6 x 3.522 x 4.253 m; bogie centres 13.3 m'
    o['scale_factors_lwh']=list(MEASURE['train_lwh_factors'])
    o['forward']='Blender -Y, Godot +Z'
    return o


def studio():
    world=bpy.data.worlds.new('ER2 review diffuse world')
    world.use_nodes=True
    next(n for n in world.node_tree.nodes if n.type=='BACKGROUND').inputs[0].default_value=(.18,.21,.25,1)
    scene.world=world
    sun=bpy.data.lights.new('ER2 review sun','SUN'); sun.energy=2.4; sun.angle=.12
    obj=bpy.data.objects.new('ER2 review sun',sun); scene.collection.objects.link(obj)
    obj.rotation_euler=(math.radians(28),math.radians(-25),math.radians(-30))
    for area in bpy.context.screen.areas if bpy.context.screen else []:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            area.spaces.active.region_3d.view_location=(0,0,2)
            area.spaces.active.region_3d.view_distance=32
            area.spaces.active.region_3d.view_rotation=Vector((1,-1,.82)).to_track_quat('Z','Y')


if __name__=='__main__':
    # New scene only: live execution preserves other user scenes.
    scene=bpy.data.scenes.new('ER2_Blockout' if BLOCKOUT else 'ER2_Studio')
    if bpy.context.window:
        bpy.context.window.scene=scene
    collection=bpy.data.collections.new('ER2 - authored assets')
    scene.collection.children.link(collection)
    materials=[material('ER2 body paint and livery',.62),material('ER2 opaque blue-grey glass',.28),
               material('ER2 mechanical and trim',.65,.42)]
    head=build_car('ER2_Head',False)
    motor=build_car('ER2_Motor',True)
    motor.location.x=7.5
    studio()
    scene.unit_settings.system='METRIC'
    scene.unit_settings.scale_length=1
    bpy.context.view_layer.objects.active=head
    head.select_set(True)
    path=HERE/('er2_blockout.blend' if BLOCKOUT else 'er2.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    print('ER2 checkpoint:',path)
