"""Asset-owned, resumable service-van geometry. Metres, Blender -Y forward.

Build uses coordinated horizontal shell sections; glazing samples those same
surfaces. Editable palette vertex colours become an embedded atlas at export.
No unrelated Blender scene is removed. Export is a separate script/stage.
"""
from pathlib import Path
import math
import bpy
import bmesh
from mathutils import Vector

PROJECT = Path(__file__).resolve().parents[3]

def linear(hex_value):
    v = [int(hex_value[i:i+2], 16)/255 for i in (0, 2, 4)]
    return tuple(c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in v)+(1,)

COLORS = {k: linear(v) for k, v in dict(
    ivory='D6CEB8', white='D9D9CD', blue='345A78', red='AD4438',
    glass='3D515B', rubber='252A2B', steel='8D9692', dark='454B49',
    seam='777A70', lamp='D5D5B9', amber='C28438', beacon='286AA6',
    frost='829396').items()}

def build(kind='uaz'):
    uaz = kind == 'uaz'
    folder = PROJECT/'art/models'/('uaz_service' if uaz else 'raf_ambulance')
    scene_name = 'UAZ_Police' if uaz else 'RAF_Ambulance'
    old = bpy.data.scenes.get(scene_name)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.scenes.remove(old)
    scene = bpy.data.scenes.new(scene_name)
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    collection = bpy.data.collections.new(scene_name+' export')
    scene.collection.children.link(collection)
    root = bpy.data.objects.new(scene_name, None)
    collection.objects.link(root)
    root['forward'] = 'Blender -Y; Godot +Z'
    root['origin'] = 'ground centre of overall bumper bounds'
    mats = []
    for name, rough, metal in [('paint', .48, .12), ('glass', .24, .22), ('fittings', .57, .25)]:
        mat = bpy.data.materials.new(scene_name+' '+name)
        mat.use_nodes = True
        shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        shader.inputs['Roughness'].default_value = rough
        shader.inputs['Metallic'].default_value = metal
        color = mat.node_tree.nodes.new('ShaderNodeVertexColor')
        color.layer_name = 'Color'
        mat.node_tree.links.new(color.outputs['Color'], shader.inputs['Base Color'])
        mats.append(mat)

    def adopt(obj, color, material=0, parent=None):
        for col in list(obj.users_collection):
            col.objects.unlink(obj)
        collection.objects.link(obj)
        obj.parent = parent or root
        obj.data.materials.append(mats[material])
        colors = obj.data.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='CORNER')
        for item in colors.data:
            item.color = COLORS[color]
        return obj

    def mesh(name, verts, faces, color, material=0, smooth=False):
        data = bpy.data.meshes.new(name)
        data.from_pydata(verts, [], faces)
        data.update()
        bm = bmesh.new(); bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data); bm.free()
        obj = bpy.data.objects.new(name, data)
        adopt(obj, color, material)
        for face in data.polygons:
            face.use_smooth = smooth
        return obj

    def box(name, pos, dims, color, bevel=.006, parent=None):
        bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
        obj = bpy.context.object; obj.name = name; obj.dimensions = dims
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        adopt(obj, color, 2, parent)
        if bevel:
            mod = obj.modifiers.new('Rolled edges', 'BEVEL'); mod.width = bevel; mod.segments = 2
            mod = obj.modifiers.new('Face normals', 'WEIGHTED_NORMAL')
        return obj

    def cylinder(name, pos, radius, depth, color, axis='X', vertices=20, parent=None):
        rot = (0, math.pi/2, 0) if axis == 'X' else ((math.pi/2, 0, 0) if axis == 'Y' else (0, 0, 0))
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos, rotation=rot)
        obj = bpy.context.object; obj.name = name
        adopt(obj, color, 2, parent)
        for p in obj.data.polygons:
            p.use_smooth = len(p.vertices) == 4
        return obj

    def line(name, points, radius, color, cyclic=False):
        # Low-sided tubes, retaining geometry only where it changes a silhouette.
        data = bpy.data.curves.new(name, 'CURVE'); data.dimensions = '3D'
        data.resolution_u = 1; data.bevel_depth = radius; data.bevel_resolution = 0
        data.use_fill_caps = True
        spline = data.splines.new('POLY'); spline.points.add(len(points)-1)
        for p, co in zip(spline.points, points): p.co = (*co, 1)
        spline.use_cyclic_u = cyclic
        obj = bpy.data.objects.new(name, data); collection.objects.link(obj)
        bpy.ops.object.select_all(action='DESELECT')
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.convert(target='MESH')
        adopt(bpy.context.object, color, 2)
        bpy.ops.object.select_all(action='DESELECT')
        return bpy.context.object

    # z, half-width, front y, rear y. Crown and cab slope are actual geometry.
    if uaz:
        sections = [(.45,.88,-2.08,2.08),(.52,.95,-2.12,2.12),
            (.82,.97,-2.12,2.12),(.88,.97,-2.12,2.12),
            (1.24,.97,-2.10,2.12),(1.31,.965,-2.04,2.12),
            (1.39,.955,-1.99,2.11),(1.86,.925,-1.73,2.08),
            (1.96,.91,-1.67,2.06),(2.015,.885,-1.64,2.04),
            (2.065,.83,-1.60,2.00),(2.095,.72,-1.54,1.94),
            (2.101,.58,-1.48,1.88)]
        axles = [-1.27, 1.03]; radius = .365; stripe = (.88,1.24)
    else:
        sections = [(.38,.88,-2.37,2.35),(.45,.95,-2.435,2.435),
            (.83,.97,-2.435,2.435),(1.04,.97,-2.435,2.425),
            (1.21,.97,-2.40,2.415),(1.29,.962,-2.30,2.405),
            (1.83,.917,-1.61,2.32),(1.91,.90,-1.51,2.30),
            (1.95,.87,-1.48,2.275),(1.978,.78,-1.45,2.235),
            (1.985,.63,-1.42,2.19)]
        axles = [-1.325,1.295]; radius = .335; stripe = (1.04,1.21)
    def section(z):
        for a,b in zip(sections,sections[1:]):
            if z <= b[0]:
                t = max(0,(z-a[0])/(b[0]-a[0]))
                return tuple(a[j]+(b[j]-a[j])*t for j in range(1,4))
        return sections[-1][1:]
    def side(sign,y,z,offset=.006):
        return (sign*(section(z)[0]+offset),y,z)
    def front(x,z,offset=.008):
        return (x,section(z)[1]-offset,z)
    def back(x,z,offset=.008):
        return (x,section(z)[2]+offset,z)
    # Rounded plan corners avoid a box-fronted generic van.
    verts=[]; count=24
    for z,w,f,b in sections:
        r=.15 if uaz else .095
        for cx,cy,start in [(w-r,f+r,-90),(w-r,b-r,0),(-w+r,b-r,90),(-w+r,f+r,180)]:
            for i in range(6):
                a=math.radians(start+90*i/5)
                verts.append((cx+r*math.cos(a),cy+r*math.sin(a),z))
    faces=[tuple(range(count-1,-1,-1))]
    for j in range(len(sections)-1):
        for i in range(count): faces.append((j*count+i,j*count+(i+1)%count,(j+1)*count+(i+1)%count,(j+1)*count+i))
    faces.append(tuple(range((len(sections)-1)*count,len(sections)*count)))
    body=mesh('Coordinated rounded body shell',verts,faces,'ivory' if uaz else 'white')
    colors=body.data.color_attributes['Color']
    for p in body.data.polygons:
        mid=sum(body.data.vertices[i].co.z for i in p.vertices)/len(p.vertices)
        if stripe[0] < mid < stripe[1]:
            for i in p.loop_indices: colors.data[i].color=COLORS['blue' if uaz else 'red']
    for axle in axles:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=radius+.055,depth=3,location=(0,axle,radius),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object
        bpy.context.view_layer.objects.active=body
        mod=body.modifiers.new('Open wheel arch','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
    box('Chassis',(0,0,.32 if uaz else .28),(1.36,3.8 if uaz else 4.3,.12),'rubber',.012)

    def rounded(a,b,c,d,r=.045):
        result=[]
        for x,z,st in [(c-r,b+r,-90),(c-r,d-r,0),(a+r,d-r,90),(a+r,b+r,180)]:
            for i in range(4):
                angle=math.radians(st+i*30)
                result.append((x+r*math.cos(angle),z+r*math.sin(angle)))
        return result
    def panel(name,coords,mapper,color='glass',seal=True):
        # Concentric sampled rings keep a curved/sloping panel on its shell.
        centre=tuple(sum(p[i] for p in coords)/len(coords) for i in (0,1))
        vs=[mapper(*centre)]
        for t in (.5,1):
            vs += [mapper(centre[0]+(p[0]-centre[0])*t,centre[1]+(p[1]-centre[1])*t) for p in coords]
        n=len(coords); fs=[]
        for i in range(n):
            j=(i+1)%n;fs.append((0,1+i,1+j));fs.append((1+i,1+n+i,1+n+j,1+j))
        mesh(name,vs,fs,color,1 if color in ('glass','frost') else 0)
        if seal: line(name+' seal',[mapper(*p) for p in coords],.012,'rubber',True)

    wind_bottom,wind_top=(1.39,1.94) if uaz else (1.30,1.90)
    if not uaz:
        panel('Single RAF windscreen',rounded(-.79,wind_bottom,.79,wind_top,.045),front)
    for sign in [-1,1]:
        if uaz:
            a,b=(-.79,-.035) if sign<0 else (.035,.79)
            panel('Divided windscreen',rounded(a,wind_bottom,b,wind_top,.045),front)
        wiper=[front(sign*.12,wind_bottom+.045,.026),front(sign*.67,wind_bottom+.10,.026)]
        line('Windscreen wiper',wiper,.010,'rubber')
    for sign in [-1,1]:
        mapper=lambda y,z,s=sign:side(s,y,z,.010)
        # Forward edge follows the slope of the actual A pillar.
        low=1.39 if uaz else 1.30; high=1.94 if uaz else 1.90
        first_front=-1.86 if uaz else -2.17; upper_front=-1.60 if uaz else -1.48
        end=-1.08 if uaz else -.90
        coords=[(first_front+.035,low),(end-.035,low),(end,low+.035),(end,high-.035),
                (end-.035,high),(upper_front+.04,high),(upper_front,high-.04),(first_front,low+.04)]
        panel('Cab door glazing',coords,mapper)
        # Actual passenger access: one forward compartment door on the right.
        windows=[(-.98,-.04),(.06,1.00),(1.10,1.88)] if uaz else [(-.79,.18),(.28,1.27)]
        for a,b in windows:
            panel('Compartment glass',rounded(a,low,b,high,.05),mapper)
            if not uaz:
                panel('Frosted medical glass',rounded(a+.02,low+.018,b-.02,low+.28,.025),lambda y,z,s=sign:side(s,y,z,.016),'frost',False)
        # Door outline follows side shape; lower cab edge stops above front arch.
        cab_seam=[(first_front-.015,low-.06),(end+.025,low-.06),(end+.025,.79),(axles[0]+.40,.79)]
        line('Cab door seam',[side(sign,y,z,.012) for y,z in cab_seam],.0035,'seam')
        for y in [end+.025, -.995 if uaz else -.83]:
            line('Door pillar seam',[side(sign,y,.80,.012),side(sign,y,1.96 if uaz else 1.92,.012)],.0035,'seam')
        # Shared longitudinal seams and gutter, a single consistent layout.
        line('Roof drip rail',[side(sign,section(1.985 if uaz else 1.94)[1]+.14,1.985 if uaz else 1.94,.015),side(sign,section(1.985 if uaz else 1.94)[2]-.13,1.985 if uaz else 1.94,.015)],.012,'ivory' if uaz else 'white')
        for y in [end-.14]+([-.18] if sign>0 else []):
            box('Door handle',(sign*.981,y,1.30 if uaz else 1.25),(.026,.15,.026),'dark',.008)
        if sign>0:
            door_end=-.02 if uaz else .22
            line('Side passenger door seam',[side(sign,door_end,.48,.012),side(sign,door_end,1.96 if uaz else 1.92,.012)],.0035,'seam')
        # Rolled arch lip does not hide the tire.
        for axle in axles:
            rr=radius+.058; start=math.asin((sections[0][0]-radius)/rr)
            pts=[side(sign,axle+rr*math.cos(a),radius+rr*math.sin(a),.010) for a in [start+(math.pi-2*start)*i/18 for i in range(19)]]
            line('Rolled fender lip',pts,.012,'ivory' if uaz else 'white')
        # Slim stalk and opaque mirror.
        y=-1.85 if uaz else -1.98
        line('Mirror stalk',[(sign*.96,y,1.36),(sign*1.095,y,1.43)],.012,'dark')
        box('Mirror housing',(sign*1.095,y,1.48),(.09,.13,.23),'rubber',.025)
        box('Mirror face',(sign*1.10,y+.071,1.48),(.065,.009,.18),'steel',.01)
        # Rear-quarter cooling louvers.
        for i in range(5):
            y=1.97 if uaz else 2.10
            line('Rear quarter vent',[side(sign,y-.075,1.65+i*.034,.012),side(sign,y+.075,1.65+i*.034,.012)],.004,'seam')

    # Grounded wheels are standalone assemblies, with steel dishes and hub bolts.
    for sign in [-1,1]:
        for axle in axles:
            wheel=bpy.data.objects.new('Wheel',None);collection.objects.link(wheel);wheel.parent=root
            x=sign*.82
            bpy.ops.mesh.primitive_torus_add(major_radius=radius-.078,minor_radius=.078,major_segments=28,minor_segments=8,location=(x,axle,radius),rotation=(0,math.pi/2,0))
            tire=bpy.context.object;tire.name='Tire';adopt(tire,'rubber',2,wheel)
            for p in tire.data.polygons:p.use_smooth=True
            outside=sign*.93
            cylinder('Steel wheel dish',(outside,axle,radius),radius*.60,.035,'steel',parent=wheel)
            cylinder('Wheel recess',(outside+sign*.019,axle,radius),radius*.43,.008,'dark',parent=wheel)
            cylinder('Hub',(outside+sign*.035,axle,radius),radius*.23,.045,'steel',parent=wheel)
            for i in range(5):
                a=2*math.pi*i/5
                cylinder('Hub bolt',(outside+sign*.046,axle+math.cos(a)*radius*.32,radius+math.sin(a)*radius*.32),.013,.012,'steel',vertices=6,parent=wheel)
            box('Rear mud flap',(sign*.82,axle+radius+.08,.32),(.26,.035,.27),'rubber',0)
    for axle in axles: cylinder('Axle',(0,axle,radius),.07,1.6,'dark')
    end=2.161 if uaz else 2.476
    for s in [-1,1]:
        box('Bumper',(0,s*end,.54 if uaz else .47),(1.92,.10,.15),'rubber',.035)
        box('Blank plate',(0,s*(end+.053),.57 if uaz else .49),(.31,.012,.10),'white',.006)
    if uaz:
        for x in [-.64,.64]:
            cylinder('Headlight rubber ring',(x,-2.125,1.04),.14,.035,'rubber',axis='Y',vertices=24)
            cylinder('Headlight rim',(x,-2.148,1.04),.117,.025,'steel',axis='Y',vertices=24)
            cylinder('Round headlamp',(x,-2.166,1.04),.098,.018,'lamp',axis='Y',vertices=24)
            cylinder('Amber front signal',(x,-2.137,.78),.058,.025,'amber',axis='Y',vertices=16)
        # Classic small horizontal grille (generated trapezoid superseded).
        box('Front grille',(0,-2.132,.86),(.60,.025,.14),'rubber',.025)
        for i in range(4): box('Grille slat',(0,-2.15,.815+i*.029),(.52,.012,.009),'dark',0)
        for x in [-.42,.42]: panel('Rear door glass',rounded(x-.33,1.39,x+.33,1.92,.05),back)
        line('Rear double door centre',[back(0,.65,.018),back(0,1.99,.018)],.004,'seam')
        for x in [-.80,.80]:
            line('Rear door outer seam',[back(x,.68,.012),back(x,1.98,.012)],.0035,'seam')
            for z in [.88,1.84]: box('Door hinge',(x,section(z)[2]+.025,z),(.08,.045,.035),'steel',.004)
        box('Rear handle',(.11,2.145,1.30),(.17,.025,.03),'dark')
    else:
        box('Rectangular front grille',(0,-2.453,.81),(.92,.035,.38),'rubber',.018)
        for i in range(7): box('Horizontal grille slat',(0,-2.478,.65+i*.05),(.86,.012,.012),'dark',0)
        for x in [-.70,.70]:
            box('Square headlight surround',(x,-2.45,.83),(.34,.045,.31),'rubber',.018)
            box('Square headlight',(x,-2.48,.83),(.26,.025,.22),'lamp',.02)
            box('Amber front signal',(x,-2.449,.61),(.19,.025,.065),'amber',.007)
        panel('Rear hatch glass',rounded(-.77,1.30,.77,1.88,.065),back)
        panel('Rear frosted glass',rounded(-.75,1.32,.75,1.52,.025),lambda x,z:back(x,z,.016),'frost',False)
        line('Rear hatch seam',[back(-.83,.64,.016),back(-.83,1.92,.016),back(.83,1.92,.016),back(.83,.64,.016)],.0035,'seam')
        box('Rear hatch handle',(0,section(1.24)[2]+.025,1.24),(.18,.03,.025),'dark')
        # Medical crosses on a solid rear-quarter panel and the hatch.
        for sign in [-1,1]:
            for ya,za,yb,zb in [(1.59,1.50,1.72,1.84),(1.48,1.61,1.83,1.73)]:
                panel('Medical cross',[(ya,za),(yb,za),(yb,zb),(ya,zb)],lambda y,z,s=sign:side(s,y,z,.017),'red',False)
        for xa,za,xb,zb in [(-.065,.70,.065,1.04),(-.17,.81,.17,.93)]:
            panel('Rear medical cross',[(xa,za),(xb,za),(xb,zb),(xa,zb)],lambda x,z:back(x,z,.018),'red',False)
        cylinder('Roof ventilator',(0,.25,2.015),.13,.05,'white',axis='Z',vertices=20)
    for x in [-.84,.84]:
        z=.91 if uaz else .82
        box('Rear lamp housing',(x,section(z)[2]+.018,z),(.105,.04,.29),'rubber',.009)
        for dz,color in [(.09,'amber'),(0,'red'),(-.09,'red')]:
            box('Rear lamp',(x,section(z)[2]+.043,z+dz),(.075,.018,.072),color,.005)
    roof=2.101 if uaz else 1.985
    cylinder('Beacon base',(0,-1.14,roof+.022),.095,.044,'rubber',axis='Z',vertices=20)
    cylinder('Plain blue beacon',(0,-1.14,roof+(.105 if uaz else .163)),.077,.13 if uaz else .238,'beacon',axis='Z',vertices=20)
    cylinder('Beacon crown',(0,-1.14,roof+(.174 if uaz else .288)),.064,.014,'beacon',axis='Z',vertices=20)
    root['body_length_m']=4.24 if uaz else 4.87
    root['wheelbase_m']=axles[1]-axles[0]
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True);bpy.context.view_layer.objects.active=root
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/(scene_name.lower()+'.blend')))
    print('BUILT',scene_name,'objects',len(collection.objects),'source',folder)
    return scene,root

if __name__ == '__main__':
    build('uaz')
