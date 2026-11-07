"""ATP support buildings / solid perimeter. Reuses the prepared ATP materials.

Run after build_atp.py; export yard.blend as a separate stage.
"""
from pathlib import Path
import json
import math
import runpy
import bpy

HERE=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(HERE/'atp.blend'))
H=runpy.run_path(str(HERE.parent/'build_assets.py'),run_name='industrial_helpers')
SCENE=H['SCENE']
SCENE.name='ATP_Yard'
Mesh=H['Mesh']
MATS=H['MATERIALS']
REMAP={}
for old,name in [('BRICK','ATP red brown brick'),('CONCRETE','ATP precast concrete'),
                 ('ROOF','ATP oxide roofing'),('METAL','ATP dark galvanized fittings'),
                 ('PLASTER','ATP dispatch mineral facing'),('PALE_BRICK','ATP dispatch mineral facing'),
                 ('GLASS','ATP dusty industrial glass'),('CREAM','ATP cream lettering')]:
    mat=bpy.data.materials.get(name)
    if mat is None:
        raise RuntimeError('Missing prepared material: '+name)
    MATS.append(mat)
    REMAP[H[old]]=len(MATS)-1


def store():
    m=Mesh('atp_parts_store')
    H['pitched'](m,14,8,3.8,.9)
    H['doors'](m,-2.7,4.08,5,3.0)
    H['doors'](m,5.0,4.08,1.2,2.35)
    H['window'](m,2.4,1.95,4.08,2.0,1.3)
    for x in [-4,1,5]:
        H['window'](m,x,2.5,-4.08,1.8,.85,back=True)
    m.box((0,3.42,4.22),(9,.5,.10),H['METAL'])
    m.text('СКЛАД ЗАПЧАСТЕЙ',(0,3.24,4.31),.32,H['CREAM'])
    m.box((-2.7,.08,4.9),(5.5,.16,1.8),H['CONCRETE'])
    return m


def workshop():
    m=Mesh('atp_tire_shop')
    H['pitched'](m,10,8,3.6,.75)
    H['doors'](m,0,4.08,3.6,3.0)
    H['doors'](m,3.6,4.08,1.0,2.3)
    H['window'](m,-3.4,2.2,4.08,1.2,1.3)
    for sign in [-1,1]:
        H['window'](m,sign*5.08,2.3,0,3.0,1.3,side=True,back=sign<0)
    m.box((0,3.3,4.22),(4.6,.48,.09),H['METAL'])
    m.text('ШИННАЯ',(0,3.14,4.30),.30,H['CREAM'])
    m.box((0,.07,5.0),(4.4,.14,2.2),H['CONCRETE'])
    return m


def gatehouse():
    m=Mesh('atp_gatehouse')
    H['flat_roof'](m,5,4,3.0,H['PLASTER'])
    H['window'](m,0,1.8,2.08,3.7,1.3)
    for sign in [-1,1]:
        H['window'](m,sign*2.58,1.8,.3,2.8,1.3,side=True,back=sign<0)
    H['doors'](m,-1,-2.08,1.1,2.25,back=True)
    m.text('КПП',(0,2.65,2.22),.34,H['METAL'])
    m.box((0,3.05,2.38),(5.3,.12,1.2),H['ROOF'])
    return m


def wall():
    m=Mesh('atp_wall_4m')
    m.box((0,.18,0),(4,.36,.30),H['CONCRETE'])
    # Continuous solid panels and recessed horizontal seams; no wire infill.
    for y in [.65,1.37,2.09]:
        m.box((0,y,0),(3.86,.74,.16),H['CONCRETE'])
        for z in [-.10,.10]:
            m.box((0,y-.27,z),(3.7,.06,.045),H['CONCRETE'])
    for x in [-2,2]:
        m.box((x,1.4,0),(.24,2.8,.30),H['CONCRETE'])
    m.box((0,2.57,0),(4,.14,.30),H['CONCRETE'])
    return m


def gate():
    m=Mesh('atp_solid_gate')
    m.box((0,1.3,0),(4.5,2.6,.12),H['METAL'])
    for x in [-2.2,2.2]:
        m.box((x,1.3,.09),(.10,2.6,.10),H['METAL'])
    for y in [.15,1.3,2.45]:
        m.box((0,y,.09),(4.5,.10,.10),H['METAL'])
    for x in [-1.5,-.75,0,.75,1.5]:
        m.box((x,1.3,.08),(.04,2.4,.05),H['METAL'])
    return m


def torus(m,at,major=.36,minor=.14):
    x,y,z=at
    vertices=[]
    for i in range(16):
        a=i*math.tau/16
        for j in range(8):
            b=j*math.tau/8
            vertices.append((x+(major+minor*math.cos(b))*math.cos(a),y+minor*math.sin(b),
                             z+(major+minor*math.cos(b))*math.sin(a)))
    faces=[(i*8+j,((i+1)%16)*8+j,((i+1)%16)*8+(j+1)%8,i*8+(j+1)%8)
           for i in range(16) for j in range(8)]
    m.poly(vertices,faces,H['DARK'])


def rack():
    m=Mesh('atp_tire_rack')
    for x in [-1.8,1.8]:
        for z in [-.5,.5]:
            m.box((x,1, z),(.07,2,.07),H['METAL'])
    for y in [.2,1.05]:
        for z in [-.5,.5]:
            m.box((0,y,z),(3.7,.08,.07),H['METAL'])
        for x in [-1.2,0,1.2]:
            for dy in [.18,.48]:
                torus(m,(x,y+dy,0))
    return m


def compressor():
    m=Mesh('atp_compressor')
    for x in [-.6,.6]:
        m.cylinder((x,.65,0),.38,1.1,H['METAL'],segments=16)
        m.box((x,.12,0),(.8,.24,.8),H['CONCRETE'])
    m.box((0,1.37,0),(1.9,.25,.9),H['METAL'])
    m.cylinder((.3,1.70,0),.18,.55,H['METAL'],segments=12)
    return m


report=[]
for build in [store,workshop,gatehouse,wall,gate,rack,compressor]:
    m=build()
    m.slots=[REMAP.get(slot,slot) for slot in m.slots]
    obj=m.finish()
    uv=obj.data.uv_layers.active
    for face in obj.data.polygons:
        normal=face.normal
        mat=obj.data.materials[face.material_index]
        tile=2.0 if 'brick' in mat.name else 4.0 if 'roof' in mat.name else 3.0
        for loop in face.loop_indices:
            v=obj.data.vertices[obj.data.loops[loop].vertex_index].co
            uv.data[loop].uv=(v.x/tile,(-v.y if abs(normal.z)>.7 else v.z)/tile) if abs(normal.x)<.7 else (-v.y/tile,v.z/tile)
    obj.data.calc_loop_triangles()
    report.append({'asset':obj.name,'triangles':len(obj.data.loop_triangles)})
    print('BUILT',obj.name,report[-1]['triangles'],flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'yard.blend'))
(HERE/'yard_build_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ATP_YARD_BUILD_COMPLETE',flush=True)
