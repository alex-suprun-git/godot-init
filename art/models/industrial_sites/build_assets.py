"""Industrial-site meshes, authored in metres from the district reference sheets.

Run Blender --background --factory-startup --python build_assets.py.
Saves editable collections only. Run export_assets.py separately afterwards.
Godot coordinates (east, up, south) become Blender (east, north, up).
Surface maps below are deterministic material bakes, not generated concept art.
"""
from pathlib import Path
import json
import math
import bpy
import bmesh
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent
SCENE = bpy.data.scenes.new('IndustrialSites')
bpy.context.window.scene = SCENE
SCENE.unit_settings.system = 'METRIC'
SCENE.unit_settings.scale_length = 1
MATERIALS = []
FONT = bpy.data.fonts.load('C:/Windows/Fonts/arialbd.ttf')


def material(name, color, roughness=.85, brick=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, 1)
    shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = roughness
    # Portable small base-colour maps. The UV unit covers 2 x 1 physical metres.
    # Geometry supplies joints, window frames, flashings, handles and roof fittings.
    if brick or name in ['Bitumen', 'Pale plaster', 'Old concrete']:
        n = 512
        rng = np.random.default_rng(207 + len(MATERIALS))
        yy, xx = np.mgrid[0:n, 0:n]
        tone = rng.normal(0, .018, (n, n))
        pixels = np.ones((n, n, 4), dtype=np.float32)
        pixels[:, :, :3] = np.array(color)[None, None, :] + tone[:, :, None]
        if brick:
            row = yy // 40
            col = ((xx + (row % 2) * 32) % n) // 64
            variation = rng.uniform(-.045, .045, (13, 9))
            pixels[:, :, :3] += variation[row, col, None]
            mortar = ((yy % 40) < 3) | (((xx + (row % 2) * 32) % 64) < 3)
            pixels[mortar, :3] = np.array(color) * .80 + .06
        pixels[:, :, :3] = np.clip(pixels[:, :, :3], 0, 1)
        image = bpy.data.images.new(name.replace(' ', '_') + '_surface', n, n)
        image.pixels.foreach_set(pixels.ravel())
        image.pack()
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = image
        mat.node_tree.links.new(node.outputs['Color'], shader.inputs['Base Color'])
    MATERIALS.append(mat)
    return len(MATERIALS) - 1


BRICK = material('Warm industrial brick', (.48, .255, .16), brick=True)
PALE_BRICK = material('Buff brick', (.68, .61, .45), brick=True)
PLASTER = material('Pale plaster', (.69, .72, .63))
CONCRETE = material('Old concrete', (.52, .53, .48))
ROOF = material('Grey brown sheet steel', (.32, .31, .27), .77)
BITUMEN = material('Bitumen', (.19, .205, .195))
METAL = material('Grey green painted steel', (.28, .34, .31), .68)
DARK = material('Dark recessed fittings', (.105, .135, .14), .65)
GLASS = material('Cool dusty glazing', (.22, .32, .35), .29)
GLASS_LIGHT = material('Glazing variation', (.32, .40, .40), .35)
CREAM = material('Ivory paint', (.79, .79, .69), .76)
WHITE = material('White tank enamel', (.80, .81, .76), .58)
RED = material('Dull red safety paint', (.58, .19, .12))
YELLOW = material('Ochre crane paint', (.66, .47, .19), .72)
WOOD = material('Wooden pallets', (.39, .29, .18))
COAL = material('Coal', (.12, .125, .12))
DOORS = [material('Garage door ' + str(i), c) for i, c in enumerate([
    (.27, .37, .41), (.35, .39, .28), (.37, .28, .22), (.43, .44, .41)])]


def point(p):
    return (p[0], -p[2], p[1])


class Mesh:
    def __init__(self, name):
        self.name, self.vertices, self.faces, self.slots = name, [], [], []

    def poly(self, vertices, faces, mat):
        offset = len(self.vertices)
        self.vertices.extend(vertices)
        self.faces.extend([tuple(offset + i for i in f) for f in faces])
        self.slots.extend([mat] * len(faces))

    def box(self, at, size, mat):
        x, y, z = at
        a, b, c = [v / 2 for v in size]
        self.poly([(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
                   (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)],
                  [(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)], mat)

    def beam(self, a, b, width, mat, depth=None):
        a, b = Vector(a), Vector(b)
        up = (b-a).normalized()
        side = up.cross(Vector((0,1,0)))
        if side.length < .01:
            side = up.cross(Vector((0,0,1)))
        side.normalize()
        front = side.cross(up).normalized()
        side *= width / 2
        front *= (depth or width) / 2
        self.poly([tuple(p + side*s + front*t) for p in [a,b] for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]],
                  [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], mat)

    def cylinder(self, at, radius, height, mat, top=None, segments=20):
        x,y,z = at
        top = radius if top is None else top
        vertices = [(x+r*math.cos(i*math.tau/segments), y+h, z+r*math.sin(i*math.tau/segments))
                    for h,r in [(-height/2,radius),(height/2,top)] for i in range(segments)]
        self.poly(vertices, [tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))] +
                  [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)], mat)

    def text(self, label, at, size, mat):
        curve = bpy.data.curves.new(label, 'FONT')
        curve.body, curve.font, curve.size = label, FONT, size
        curve.resolution_u = 2
        curve.align_x = 'CENTER'
        curve.extrude = .009
        obj = bpy.data.objects.new(label, curve)
        SCENE.collection.objects.link(obj)
        obj.location = point(at)
        obj.rotation_euler = (math.pi/2, 0, 0)
        obj.data.materials.append(MATERIALS[mat])
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.convert(target='MESH')
        # Extract transformed text into this mesh then discard the temporary object.
        obj = bpy.context.object
        vertices = [obj.matrix_world @ v.co for v in obj.data.vertices]
        self.poly([(v.x,v.z,-v.y) for v in vertices], [tuple(p.vertices) for p in obj.data.polygons], mat)
        bpy.data.objects.remove(obj, do_unlink=True)

    def finish(self):
        data = bpy.data.meshes.new(self.name)
        data.from_pydata([point(v) for v in self.vertices], [], self.faces)
        data.update()
        bm = bmesh.new()
        bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
        for mat in MATERIALS:
            data.materials.append(mat)
        uv = data.uv_layers.new(name='MetreSurfaceUV')
        for poly, slot in zip(data.polygons, self.slots):
            poly.material_index = slot
            normal = poly.normal
            for loop in poly.loop_indices:
                v = data.vertices[data.loops[loop].vertex_index].co
                # Blender Z is height; projection avoids stretched brick courses.
                if abs(normal.z) > .7:
                    u, w = v.x/2, -v.y
                elif abs(normal.y) > abs(normal.x):
                    u, w = v.x/2, v.z
                else:
                    u, w = -v.y/2, v.z
                uv.data[loop].uv = (u,w)
        collection = bpy.data.collections.new('asset_' + self.name)
        SCENE.collection.children.link(collection)
        obj = bpy.data.objects.new(self.name, data)
        collection.objects.link(obj)
        return obj


def window(m, x, y, z, w, h, side=False, back=False):
    # Windows sit in a dark reveal; frames and mullions are separate physical geometry.
    def b(u,v,d,ww,hh,dd,mat):
        m.box((d,v,u) if side else (u,v,d), (dd,hh,ww) if side else (ww,hh,dd), mat)
    face = x if side else z
    along = z if side else x
    sign = -1 if back else 1
    b(along,y,face,w+.16,h+.16,.09,CONCRETE)
    b(along,y,face+sign*.06,w,h,.04,DARK)
    b(along,y,face+sign*.09,w-.16,h-.16,.025,GLASS)
    for u in [along-w/2+.05,along+w/2-.05]:
        b(u,y,face+sign*.13,.09,h,.10,METAL)
    for v in [y-h/2+.05,y+h/2-.05,y]:
        b(along,v,face+sign*.13,w,.075,.10,METAL)
    divisions = max(1,round(w/.85))
    for i in range(1,divisions):
        b(along-w/2+i*w/divisions,y,face+sign*.13,.055,h,.08,METAL)
    b(along,y-h/2-.09,face+sign*.20,w+.26,.12,.38,CONCRETE)


def doors(m,x,z,w,h,mat=METAL,back=False):
    sign = -1 if back else 1
    m.box((x,h/2,z),(w+.32,h+.12,.14),CONCRETE)
    m.box((x,h/2,z+sign*.10),(w,h,.10),DARK)
    for dx in [-w/4,w/4]:
        m.box((x+dx,h/2,z+sign*.17),(w/2-.09,h-.12,.08),mat)
    for dx in [-w/2+.06,0,w/2-.06]:
        m.box((x+dx,h/2,z+sign*.23),(.07,h,.09),METAL)
    for yy in [.10,h*.48,h-.07]:
        m.box((x,yy,z+sign*.23),(w,.065,.08),METAL)
    for dx in [-.15,.15]:
        m.box((x+dx,h*.43,z+sign*.29),(.05,.28,.07),CREAM)
    for dx in [-w/2+.17,w/2-.17]:
        for yy in [.6,h-.6]:
            m.box((x+dx,yy,z+sign*.26),(.14,.22,.09),DARK)


def pitched(m,w,d,h,rise,wall=BRICK):
    m.box((0,h/2,0),(w,h,d),wall)
    # Solid gables and two separate sheet planes, with roof flashing and standing seams.
    m.poly([(-w/2,h,-d/2),(-w/2,h,d/2),(-w/2,h+rise,0),
            (w/2,h,-d/2),(w/2,h,d/2),(w/2,h+rise,0)],[(0,1,2),(3,5,4)],wall)
    for sign in [-1,1]:
        m.poly([(-w/2-.4,h,sign*(d/2+.4)),(w/2+.4,h,sign*(d/2+.4)),
                (w/2+.4,h+rise+.12,0),(-w/2-.4,h+rise+.12,0)],
               [(0,1,2,3)] if sign==1 else [(3,2,1,0)],ROOF)
        m.beam((-w/2-.45,h,sign*(d/2+.4)),(w/2+.45,h,sign*(d/2+.4)),.16,METAL)
        for x in np.arange(-w/2-.3,w/2+.3,1.4):
            m.beam((x,h+.035,sign*(d/2+.4)),(x,h+rise+.155,0),.035,METAL)
    m.beam((-w/2-.5,h+rise+.2,0),(w/2+.5,h+rise+.2,0),.22,ROOF)
    m.box((0,.30,0),(w+.1,.6,d+.1),CONCRETE)
    for x in [-w/2+.16,w/2-.16]:
        for z in [-d/2-.16,d/2+.16]:
            m.beam((x,.2,z),(x,h+.02,z),.12,METAL)


def flat_roof(m,w,d,h,wall):
    m.box((0,h/2,0),(w,h,d),wall)
    m.box((0,.28,0),(w+.10,.56,d+.10),CONCRETE)
    m.box((0,h+.08,0),(w+.25,.16,d+.25),BITUMEN)
    for z in [-d/2,d/2]:
        m.box((0,h+.26,z),(w+.42,.35,.24),CONCRETE)
        m.box((0,h+.46,z),(w+.46,.06,.34),METAL)
    for x in [-w/2,w/2]:
        m.box((x,h+.26,0),(.24,.35,d),CONCRETE)
        m.box((x,h+.46,0),(.34,.06,d),METAL)


def hall(name,w,d,h,rise,bays,wall=BRICK):
    m=Mesh(name)
    pitched(m,w,d,h,rise,wall)
    for side in [-1,1]:
        for i in range(bays):
            x=(i-(bays-1)/2)*(w-6)/bays
            width=min(5.4,(w-6)/bays-.7)
            doors(m,x,side*(d/2+.04),width,min(4.9,h-2.3),back=side<0)
            window(m,x,h-1.25,side*(d/2+.06),width,1.15,back=side<0)
        for x in np.linspace(-w/2+.3,w/2-.3,bays+1):
            m.box((x,h/2,side*(d/2+.13)),(.32,h,.25),CONCRETE)
    for side in [-1,1]:
        for z in [-d*.28,0,d*.28]:
            window(m,side*(w/2+.04),h-1.7,z,3.6,1.4,side=True,back=side<0)
    for x in [-w*.28,w*.25]:
        m.cylinder((x,h+rise+.60,0),.25,1.05,METAL,segments=12)
        m.box((x,h+rise+1.15,0),(.85,.14,.85),CONCRETE)
    return m


def atp():
    m=hall('atp_hall',64,24,8,3.2,8)
    # The dispatcher is a distinct entrance in the end wall, within the 64x24 envelope.
    for z in [-3.7,0,3.7]:
        for y in [1.7,4.7]:
            window(m,32.08,y,z,2.4,1.5,side=True)
    m.box((32.85,3.15,0),(2,.18,4),CONCRETE)
    m.box((33.2,.11,0),(2.6,.22,3.8),CONCRETE)
    m.box((32.22,1.3,0),(.1,2.6,1.6),DARK)
    m.text('АТП',(-23,6.0,12.32),1.1,CREAM)
    m.box((-24,7.95,0),(5.5,.12,1.8),METAL)
    return m


def cafe():
    m=Mesh('truck_cafe')
    flat_roof(m,32,12,4,PALE_BRICK)
    for x in [-12,-7,-2,7,12]:
        window(m,x,2.1,6.07,3.5,2.25)
    doors(m,2.5,6.12,1.7,2.7)
    m.box((2.5,3.05,7.0),(4.6,.16,2.2),METAL)
    m.box((2.5,.10,7),(4.9,.20,2.5),CONCRETE)
    m.box((0,3.5,6.20),(11,.65,.16),METAL)
    m.text('КАФЕ',(0,3.28,6.31),.58,CREAM)
    for x in [-12,-5,5,12]:
        window(m,x,2.6,-6.08,2.0,.85,back=True)
    doors(m,8,-6.1,1.5,2.4,back=True)
    for x in [-10,10]:
        m.cylinder((x,4.85,-2),.24,1.25,METAL,segments=12)
        m.box((x,5.52,-2),(.8,.14,.75),METAL)
    m.box((-8,4.6,-2),(2,.9,1.6),METAL)
    for x in [-11,-5]:
        m.box((x,.75,9),(2.2,.13,.85),WOOD)
        for dx in [-.85,.85]:
            m.box((x+dx,.37,9),(.12,.74,.7),METAL)
    return m


def office():
    m=Mesh('customs_office')
    flat_roof(m,30,18,6.1,PLASTER)
    for sign in [-1,1]:
        for x in [-12,-8,-4,4,8,12]:
            for y in [1.8,4.6]:
                window(m,x,y,sign*9.07,1.6,1.6,back=sign<0)
    doors(m,0,9.13,2.6,2.8)
    m.box((0,3.15,10.0),(5.0,.20,2.4),CONCRETE)
    m.box((0,.14,10.25),(5.5,.28,3),CONCRETE)
    m.box((0,3.8,9.20),(8,.7,.14),METAL)
    m.text('ТАМОЖНЯ',(0,3.57,9.31),.52,CREAM)
    for side in [-1,1]:
        for z in [-5,0,5]:
            for y in [1.8,4.6]:
                window(m,side*15.07,y,z,1.5,1.6,side=True,back=side<0)
    for x in [-9,9]:
        m.box((x,6.8,-3),(1.1,1.3,1.0),CONCRETE)
    return m


def canopy():
    m=Mesh('control_canopy')
    for x in [-5.55,5.55]:
        for z in [-4.7,4.7]:
            m.box((x,.15,z),(.85,.30,.85),CONCRETE)
            m.box((x,3.0,z),(.24,6.0,.24),METAL)
        m.box((x,5.95,0),(.27,.35,12.0),METAL)
    m.box((0,6.2,0),(11.9,.24,12.8),ROOF)
    for z in [-6.35,6.35]:
        m.box((0,6.05,z),(12,.42,.12),CREAM)
    for x in [-5.94,5.94]:
        m.box((x,6.05,0),(.12,.42,12.7),CREAM)
    for x in [-3,3]:
        for z in [-3,3]:
            m.box((x,5.93,z),(1.1,.08,.32),CREAM)
    return m


def booth():
    m=Mesh('control_booth')
    flat_roof(m,1.6,3.0,2.8,PLASTER)
    for sign in [-1,1]:
        window(m,0,1.85,sign*1.54,1.2,1.1,back=sign<0)
        for z in [-.65,.65]:
            window(m,sign*.84,1.85,z,.95,1.05,side=True,back=sign<0)
    return m


def pedestrian():
    m=Mesh('pedestrian_control')
    flat_roof(m,8,10,3.6,PLASTER)
    for x in [-2.3,2.3]:
        doors(m,x,5.08,1.4,2.6)
        doors(m,x,-5.08,1.4,2.6,back=True)
    for sign in [-1,1]:
        for z in [-3,0,3]:
            window(m,sign*4.08,2,z,2,1.8,side=True,back=sign<0)
    m.text('КОНТРОЛЬ',(0,3.0,5.18),.40,METAL)
    return m


def boiler():
    m=Mesh('boiler_house')
    flat_roof(m,28,20,9,BRICK)
    for x in [-10,-4,3,10]:
        window(m,x,6.9,10.06,4.2,2.05)
        window(m,x,6.9,-10.06,4.2,2.05,back=True)
    doors(m,-7,10.12,4.4,4.1)
    doors(m,6.2,10.12,3.3,3.2)
    for sign in [-1,1]:
        for z in [-5,1,6]:
            window(m,sign*14.06,6.5,z,3.2,2.2,side=True,back=sign<0)
    for x,z in [(-8,-4),(2,1),(9,-5)]:
        m.box((x,9.6,z),(1.2,1.1,1.2),CONCRETE)
        m.box((x,10.2,z),(1.6,.16,1.6),METAL)
    m.box((-7,4.65,10.15),(8,.7,.10),CREAM)
    m.text('КОТЕЛЬНАЯ №3',(-7,4.42,10.25),.47,METAL)
    return m


def chimney():
    m=Mesh('boiler_chimney')
    m.box((0,.45,0),(6.4,.9,6.4),CONCRETE)
    m.cylinder((0,2.3,0),2.7,3.7,BRICK,top=2.4,segments=32)
    m.cylinder((0,18.5,0),2.35,30.0,BRICK,top=1.24,segments=32)
    m.cylinder((0,33.7,0),1.4,.55,BRICK,segments=32)
    m.cylinder((0,34.0,0),1.20,.04,DARK,segments=32)
    for y in [6,12,18,24,30]:
        r=2.35-(y-3.5)*1.11/30
        m.cylinder((0,y,0),r+.045,.11,METAL,segments=32)
    for x in [-.38,.38]:
        m.beam((x,2,2.65),(x,33,1.52),.065,METAL)
    for y in np.arange(2,33,.4):
        z=2.65-(y-2)*1.13/31
        m.box((0,y,z),(.85,.05,.09),METAL)
    return m


def tank():
    m=Mesh('fuel_tank')
    m.cylinder((0,.22,0),4.3,.44,CONCRETE,segments=32)
    m.cylinder((0,4.35,0),3.8,8.0,WHITE,segments=32)
    m.cylinder((0,8.65,0),3.88,.60,WHITE,top=.55,segments=32)
    for y in [.5,2.4,4.35,6.3,8.28]:
        m.cylinder((0,y,0),3.82,.065,CREAM,segments=32)
    m.cylinder((0,9.10,0),.55,.35,METAL,segments=16)
    for x in [-.34,.34]:
        m.beam((x,.4,3.98),(x,9,3.98),.06,METAL)
    for y in np.arange(.5,9,.38):
        m.box((0,y,3.98),(.75,.055,.09),METAL)
    for i in range(24):
        a=i*math.tau/24
        m.beam((3.95*math.cos(a),8.4,3.95*math.sin(a)),
               (3.95*math.cos(a),9.35,3.95*math.sin(a)),.055,METAL)
        b=(i+1)*math.tau/24
        m.beam((3.95*math.cos(a),9.35,3.95*math.sin(a)),
               (3.95*math.cos(b),9.35,3.95*math.sin(b)),.055,METAL)
    m.beam((3.6,.65,0),(5.0,.65,0),.30,METAL)
    m.box((4.5,1.05,0),(.08,.60,.60),RED)
    return m


def tower():
    m=Mesh('water_tower')
    for x in [-2.5,2.5]:
        for z in [-2.5,2.5]:
            m.box((x,.25,z),(1.2,.5,1.2),CONCRETE)
            m.beam((x,.5,z),(x*.72,14,z*.72),.24,METAL)
    for y in [1,5,9,13]:
        extent=2.5-(y/14)*.7
        for sign in [-1,1]:
            m.beam((-extent,y,sign*extent),(extent,y,sign*extent),.18,METAL)
            m.beam((sign*extent,y,-extent),(sign*extent,y,extent),.18,METAL)
            if y<13:
                m.beam((-extent,y,sign*extent),(extent-.2,y+4,sign*(extent-.2)),.12,METAL)
                m.beam((sign*extent,y,-extent),(sign*(extent-.2),y+4,extent-.2),.12,METAL)
    m.cylinder((0,15.8,0),3.2,4.4,PALE_BRICK,segments=24)
    m.cylinder((0,18.5,0),3.5,1.0,ROOF,top=.12,segments=24)
    m.cylinder((0,13.6,0),3.35,.25,CONCRETE,segments=24)
    m.beam((2.6,.3,0),(2.0,14.0,0),.12,METAL)
    return m


def garage(variant):
    m=Mesh('garage_row_' + str(variant))
    pitched(m,21,6,2.6,.45,PALE_BRICK)
    for i in range(6):
        x=(i-2.5)*3.5
        doors(m,x,3.07,2.88,2.25,DOORS[(i+variant)%4])
        m.text(str(31+variant*6+i),(x+.9,2.28,3.34),.16,CREAM)
    for x in [-8.75,-1.75,5.25]:
        m.box((x,1.96,-3.055),(.55,.25,.08),DARK)
        for dx in [-.15,0,.15]:
            m.box((x+dx,1.96,-3.11),(.045,.24,.07),METAL)
    return m


def crane():
    m=Mesh('port_crane')
    # Portal carries the slewing machinery; trolley wheels align to the quay rails.
    for x in [-4.4,4.4]:
        for z in [-4,4]:
            m.box((x,.7,z),(1.05,1.25,2),DARK)
            m.beam((x,1.2,z),(x*.68,8.4,z*.65),.55,YELLOW)
        m.beam((x,1.2,-4),(x,1.2,4),.45,YELLOW)
    for z in [-2.6,2.6]:
        m.beam((-3.0,8.2,z),(3.0,8.2,z),.65,YELLOW)
    m.cylinder((0,9,0),2.4,.7,DARK,segments=24)
    m.box((0,10.2,0),(4.6,2.0,4.8),YELLOW)
    m.box((-1.7,11.1,2.5),(2.5,2.7,2.4),YELLOW)
    window(m,-1.7,11.55,3.74,2.1,1.5)
    m.box((0,12,-3),(3.3,1.6,2.5),CONCRETE)
    # Triangulated boom reaches towards the river (-Z), held by twin tension rods.
    for x in [-.85,.85]:
        m.beam((x,11.2,-1),(x,20.7,-25),.22,YELLOW)
        m.beam((x,13.2,-1),(x,21.7,-25),.22,YELLOW)
        for t in np.linspace(0,1,9):
            z=-1-t*24
            y=11.2+t*9.5
            m.beam((x,y,z),(x,y+2-t,z),.10,YELLOW)
        m.beam((x,11,1.5),(x,16.5,3),.17,YELLOW)
        m.beam((x,16.5,3),(x,21.3,-24.5),.065,DARK)
    for t in np.linspace(0,1,9):
        z=-1-t*24
        y=11.2+t*9.5
        m.beam((-.85,y,z),(.85,y+2-t,z),.1,YELLOW)
    m.beam((0,21.0,-25),(0,1.0,-25),.045,DARK)
    m.box((0,.8,-25),(.45,.55,.35),DARK)
    return m


def barge():
    m=Mesh('river_barge')
    # Low polygon hull, dry deck and actual open cargo hold. Local +X is length.
    lower=[(-20,-.85,-3.4),(18,-.85,-3.4),(21,-.85,-1.8),(21,-.85,1.8),
           (18,-.85,3.4),(-20,-.85,3.4),(-22,-.85,1.4),(-22,-.85,-1.4)]
    upper=[(x,1.0,z*1.18) for x,_,z in lower]
    m.poly(lower+upper,[tuple(range(7,-1,-1))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)],METAL)
    m.poly(upper,[tuple(range(8))],ROOF)
    m.box((0,1.3,0),(27,.55,5.8),DARK)
    m.box((0,1.6,0),(25,.12,5.0),COAL)
    for z in [-3,3]:
        m.box((0,1.6,z),(28,.9,.18),METAL)
    for x in [-14,14]:
        m.box((x,1.6,0),(.18,.9,6),METAL)
    m.box((17.0,2.1,0),(4.5,2.1,5.4),CREAM)
    for z in [-2.76,2.76]:
        for x in [15.7,17.1,18.5]:
            window(m,x,2.35,z,1.0,.85,back=z<0)
    m.box((17,3.25,0),(5,.20,5.8),METAL)
    for x in [-19,12]:
        for z in [-3.4,3.4]:
            m.cylinder((x,1.3,z),.18,.55,DARK,segments=10)
    return m


def fence():
    m=Mesh('fence_4m')
    for x in [-2,2]:
        m.box((x,.16,0),(.40,.32,.42),CONCRETE)
        m.box((x,1.2,0),(.10,2.4,.10),METAL)
    for y in [.38,2.1]:
        m.box((0,y,0),(4,.07,.06),METAL)
    # Open mesh represented by physical wires; no transparency sorting at overview.
    for x in np.arange(-1.9,2,.27):
        m.beam((x,.4,0),(x,2.08,0),.018,METAL)
    for y in np.arange(.55,2.05,.30):
        m.box((0,y,0),(4,.018,.018),METAL)
    return m


def gate():
    m=Mesh('gate_6m')
    for sign in [-1,1]:
        m.box((sign*3,1.3,0),(.18,2.6,.18),METAL)
    for y in [.35,2.2]:
        m.box((0,y,0),(6,.10,.10),METAL)
    for x in np.arange(-2.8,3,.3):
        m.box((x,1.3,0),(.04,1.85,.04),METAL)
    m.beam((-2.9,.35,0),(2.9,2.2,0),.07,METAL)
    return m


def lamp():
    m=Mesh('yard_lamp')
    m.box((0,.22,0),(.8,.44,.8),CONCRETE)
    m.cylinder((0,4.1,0),.12,7.8,METAL,top=.075,segments=12)
    m.beam((0,7.8,0),(1.4,8.0,0),.09,METAL)
    m.box((1.4,7.95,0),(.8,.20,.35),CREAM)
    m.box((1.4,7.83,0),(.64,.035,.25),GLASS_LIGHT)
    return m


def barrier():
    m=Mesh('raised_barrier')
    m.box((0,.65,0),(.55,1.3,.55),METAL)
    # Raised to leave actual ambient traffic unobstructed; no simulated control yet.
    m.beam((0,1.15,0),(.6,6.0,0),.13,CREAM)
    for t in [.1,.3,.5,.7,.9]:
        m.beam((.6*t,1.15+4.85*t,0),(.6*(t+.07),1.15+4.85*(t+.07),0),.14,RED)
    return m


def pallets():
    m=Mesh('pallet_stack')
    for y in [.16,.42,.68]:
        for x in [-.50,0,.50]:
            m.box((x,y-.07,0),(.14,.16,1),WOOD)
        for z in [-.45,-.23,0,.23,.45]:
            m.box((0,y+.06,z),(1.2,.08,.16),WOOD)
    return m


BUILDERS = {
    'atp_hall':atp, 'truck_cafe':cafe, 'customs_office':office,
    'inspection_hall':lambda:hall('inspection_hall',40,24,7,2.4,3),
    'control_canopy':canopy, 'control_booth':booth, 'pedestrian_control':pedestrian,
    'port_warehouse_main':lambda:hall('port_warehouse_main',65,22,8,3.2,8),
    'port_warehouse_small':lambda:hall('port_warehouse_small',40,12,6,2.2,5),
    'fuel_warehouse':lambda:hall('fuel_warehouse',28,12,6,2.0,3,PALE_BRICK),
    'fuel_tank':tank, 'water_tower':tower, 'boiler_house':boiler, 'boiler_chimney':chimney,
    'garage_row_0':lambda:garage(0), 'garage_row_1':lambda:garage(1),
    'port_crane':crane, 'river_barge':barge, 'fence_4m':fence, 'gate_6m':gate,
    'yard_lamp':lamp, 'raised_barrier':barrier, 'pallet_stack':pallets,
}

def build_all():
    report=[]
    for name, build in BUILDERS.items():
        obj=build().finish()
        obj.data.calc_loop_triangles()
        report.append({'asset':name,'triangles':len(obj.data.loop_triangles),
                       'dimensions_blender':[round(v,3) for v in obj.dimensions]})
        print('BUILT',name,report[-1]['triangles'],flush=True)
    for image in bpy.data.images:
        if image.has_data and not image.packed_file:
            image.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'industrial_sites.blend'))
    (HERE/'build_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('INDUSTRIAL_BUILD_COMPLETE',flush=True)


if __name__ == '__main__':
    build_all()
