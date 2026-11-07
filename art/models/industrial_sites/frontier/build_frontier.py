"""Reference-led finish for the six sites adjoining the approved ATP.

Metres, Godot east/up/south -> Blender east/north/up. Run in an isolated
Blender background process. Build, export and actual-game review are separate.
Reuses the prepared ATP materials; does not generate new raster artwork.
"""
from pathlib import Path
import json
import math
import runpy
import bpy
import bmesh

HERE = Path(__file__).resolve().parent
PACK = HERE.parent
H = runpy.run_path(str(PACK / 'build_assets.py'), run_name='frontier_helpers')
Mesh, MATS, SCENE = H['Mesh'], H['MATERIALS'], H['SCENE']
SCENE.name = 'Frontier_Refinement'
with bpy.data.libraries.load(str(PACK / 'atp/atp.blend'), link=False) as (src, dst):
    dst.materials = [name for name in src.materials if name.startswith('ATP ')]
REMAP = {}
for old, name in [
    ('BRICK', 'ATP red brown brick'), ('CONCRETE', 'ATP precast concrete'),
    ('PLASTER', 'ATP dispatch mineral facing'), ('PALE_BRICK', 'ATP dispatch mineral facing'),
    ('ROOF', 'ATP oxide roofing'), ('METAL', 'ATP dark galvanized fittings'),
    ('GLASS', 'ATP dusty industrial glass'), ('CREAM', 'ATP cream lettering')]:
    mat = next(m for m in dst.materials if m and m.name == name)
    MATS.append(mat)
    REMAP[H[old]] = len(MATS) - 1

# Existing, separately prepared silicate masonry and roof felt distinguish
# service buildings from the red-brick halls without inventing another atlas.
for old,name,path in [
    ('PALE_BRICK','Frontier silicate masonry',PACK.parents[2]/'init/assets/models/dormitory/silicate_brick.png'),
    ('BITUMEN','Frontier roof felt',PACK.parents[2]/'art/models/civic_center/textures/clean_roof_felt.png')]:
    index=H['material'](name,(1,1,1),.91)
    mat=MATS[index]
    shader=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    texture=mat.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image=bpy.data.images.load(str(path),check_existing=True)
    texture.image.pack()
    mat.node_tree.links.new(texture.outputs['Color'],shader.inputs['Base Color'])
    REMAP[H[old]]=index

B, C, R, S, D = (H[n] for n in ['BRICK', 'CONCRETE', 'ROOF', 'METAL', 'DARK'])
P, W, G, I = (H[n] for n in ['PLASTER', 'WHITE', 'GLASS', 'CREAM'])


def fittings(m, w, d, height, pitched=False):
    for x in [-w / 2 + .35, w / 2 - .35]:
        for z in [-d / 2 - .25, d / 2 + .25]:
            m.beam((x, .3, z), (x, height, z), .085, S)
            m.beam((x, .3, z), (x, .15, z + .40), .085, S)
    for x in [-w * .28, w * .28]:
        m.box((x, height - .7, d / 2 + .3), (.65, .20, .24), S)
        m.box((x, height - .73, d / 2 + .44), (.46, .11, .04), I)
    if not pitched:
        for x in range(-int(w / 2) + 2, int(w / 2), 4):
            m.box((x, height + .18, 0), (.055, .02, d - .6), S)


def roof(m, w, d, height, rise):
    m.poly([(-w/2,height,-d/2),(-w/2,height,d/2),(-w/2,height+rise,0),
            (w/2,height,-d/2),(w/2,height,d/2),(w/2,height+rise,0)],
           [(0,1,2),(3,5,4)], B)
    for sign in [-1, 1]:
        m.poly([(-w/2-.35,height,sign*(d/2+.4)),(w/2+.35,height,sign*(d/2+.4)),
                (w/2+.35,height+rise+.1,0),(-w/2-.35,height+rise+.1,0)],
               [(0,1,2,3)], R)
        m.beam((-w/2-.4,height,sign*(d/2+.4)),
               (w/2+.4,height,sign*(d/2+.4)), .16, S)
        for index in range(int(w / 1.4) + 1):
            x = -w/2 + index*1.4
            m.beam((x,height+.035,sign*(d/2+.4)),(x,height+rise+.145,0),.045,R)
    m.beam((-w/2-.45,height+rise+.16,0),(w/2+.45,height+rise+.16,0),.22,S)


def hall(name, w, d, height, rise, bays, label, pale=False, opening=False, drive_through=False):
    m = Mesh(name)
    wall = H['PALE_BRICK'] if pale else B
    # Real openings at the working facade. The open bay has a dark shallow
    # service recess; hidden interiors do not consume the map-camera budget.
    if not drive_through:
        m.box((0,height/2,-d/2+.16),(w,height,.32),wall)
    else:
        m.box((0,.02,0),(w,.04,d),C)
    for sign in [-1,1]:
        m.box((sign*(w/2-.16),height/2,0),(.32,height,d),wall)
    pitch = w / bays
    door_w, door_h = min(5.4,pitch-1.4), min(4.8,height-2.1)
    cursor = -w/2
    for index in range(bays):
        x = -w/2 + (index+.5)*pitch
        left, right = x-door_w/2, x+door_w/2
        m.box(((cursor+left)/2,height/2,d/2-.16),(left-cursor,height,.32),wall)
        m.box((x,(height+door_h)/2,d/2-.16),(door_w,height-door_h,.32),wall)
        if drive_through:
            m.box(((cursor+left)/2,height/2,-d/2+.16),(left-cursor,height,.32),wall)
            m.box((x,(height+door_h)/2,-d/2+.16),(door_w,height-door_h,.32),wall)
            if not (opening and index==1):
                H['doors'](m,x,-d/2-.03,door_w,door_h,back=True)
        cursor = right
        if opening and index == 1:
            if not drive_through:
                m.box((x,door_h/2,d/2-2),(door_w,door_h,.10),D)
            m.box((x,.09,d/2-.8),(door_w,.18,2.4),C)
            for dx in [-door_w/2,door_w/2]:
                m.box((x+dx,door_h/2,d/2-.9),(.14,door_h,2.0),C)
            m.box((x,door_h-.35,d/2+.16),(door_w,.70,.18),S)
        else:
            H['doors'](m,x,d/2+.03,door_w,door_h)
        H['window'](m,x,height-1.05,d/2+.05,door_w,1.05)
        H['window'](m,x,height-1.05,-d/2-.05,door_w,1.05,back=True)
        m.box((x+door_w/2-.4,door_h+.3,d/2+.23),(.54,.35,.045),S)
        m.text(str(index+1),(x+door_w/2-.4,door_h+.2,d/2+.27),.22,I)
    m.box(((cursor+w/2)/2,height/2,d/2-.16),(w/2-cursor,height,.32),wall)
    if drive_through:
        m.box(((cursor+w/2)/2,height/2,-d/2+.16),(w/2-cursor,height,.32),wall)
    roof(m,w,d,height,rise)
    for sign in [-1,1]:
        for index in range(bays+1):
            x = -w/2+index*pitch
            m.box((x,height/2,sign*(d/2+.07)),(.26,height,.21),C)
        for z in [-d*.27,d*.27]:
            H['window'](m,sign*(w/2+.04),height-1.5,z,2.8,1.25,side=True,back=sign<0)
    for x in [-w*.25,w*.25]:
        m.cylinder((x,height+rise+.47,0),.22,.70,S,segments=12)
        m.box((x,height+rise+.86,0),(.75,.12,.75),S)
    m.box((0,.18,0),(w+.12,.36,d+.12),C)
    fittings(m,w,d,height,True)
    if label:
        m.box((0,height+.53,d/2+.13),(min(w-2,14),.67,.13),S)
        m.text(label,(0,height+.32,d/2+.22),.43,I)
    return m


def office():
    m = H['office']()
    fittings(m,30,18,6.1)
    for y in [.72,3.1,6.0]:
        for z in [-9.14,9.14]:
            m.box((0,y,z),(30.15,.12,.12),C)
    for x in [-14.85,14.85]:
        m.box((x,3.1,9.1),(.4,5.95,.16),C)
    for x in [-4,4]:
        m.box((x,1.7,9.27),(.65,.85,.08),S)
    for x in [-2.3,2.3]:
        m.beam((x,.3,10.8),(x,1.05,10.8),.06,S)
        m.beam((x,1.05,10.8),(x,1.05,8.9),.06,S)
    return m


def pump():
    m = Mesh('fuel_pump_house')
    H['flat_roof'](m,7,5,3.4,P)
    H['doors'](m,0,2.55,2,2.6)
    H['window'](m,-3.56,2,0,2.6,1.1,side=True,back=True)
    for x in [-2.4,2.4]:
        for y in [1.0,1.25,1.5]:
            m.box((x,y,2.64),(1.1,.13,.12),S)
    m.box((0,3.0,2.67),(4.8,.40,.10),S)
    m.text('НАСОСНАЯ',(0,2.87,2.75),.27,I)
    fittings(m,7,5,3.4)
    return m


def loading():
    m = Mesh('fuel_loading_gantry')
    for x in [-3.8,3.8]:
        m.box((x,1.5,0),(.20,3.0,.20),S)
    m.box((0,2.65,0),(8,.18,1.5),C)
    for z in [-.72,.72]:
        m.beam((-3.9,3.6,z),(3.9,3.6,z),.07,S)
        for x in [-3.8,-1.9,0,1.9,3.8]:
            m.beam((x,2.7,z),(x,3.6,z),.055,S)
    for x in [-2.2,2.2]:
        m.beam((x,.5,-1.5),(x,4.2,-1.5),.18,S)
        m.beam((x,4.2,-1.5),(x,4.2,3),.18,S)
        m.beam((x,4.2,3),(x,2.2,3),.10,D)
        m.box((x,.8,-1.5),(.6,.08,.6),H['RED'])
    for y in range(8):
        m.box((-4.8+y*.18,.18+y*.32,0),(.4,.12,1.3),C)
    return m


def shelter():
    m=Mesh('frontier_rest_shelter')
    for x in [-3.7,3.7]:
        for z in [-2.3,2.3]:
            m.box((x,1.5,z),(.12,3,.12),S)
    roof(m,8,5,3,.6)
    for x in [-2,2]:
        m.box((x,.78,0),(2.2,.12,1),H['WOOD'])
        for z in [-1,1]:
            m.box((x,.46,z),(2.6,.10,.37),H['WOOD'])
            for dx in [-.85,.85]:
                m.box((x+dx,.35,z),(.08,.7,.08),S)
    return m


def booth():
    m=H['booth']()
    # Doors on short faces stay inside the median refuge.
    m.box((0,1,-1.62),(.8,2,.08),S)
    m.box((0,1.8,-1.68),(.6,.55,.04),G)
    return m


def lane_canopy(stage):
    m=Mesh('customs_'+stage+'_canopy')
    # Two 17 m modules meet over the median. Columns stand on refuge islands,
    # outside the four road lanes, with 6 m unobstructed working clearance.
    for x in [-7.4,7.4]:
        for z in [-5.5,5.5]:
            m.box((x,.15,z),(.75,.3,.9),C)
            m.box((x,3.15,z),(.23,6.3,.23),S)
        m.beam((x,6.05,-8.8),(x,6.05,8.8),.24,S)
    for z in [-7.8,-3.9,0,3.9,7.8]:
        m.beam((-8.3,6.0,z),(8.3,6.0,z),.22,S)
        m.beam((-8.3,6.5,z),(8.3,6.5,z),.15,S)
        for i in range(8):
            x=-8.3+i*2.075
            m.beam((x,6,z),(x+2.075,6.5,z),.065,S)
    m.box((0,6.6,0),(17,.16,18.5),S)
    for x in range(-8,9):
        m.box((x,6.71,0),(.045,.06,18.4),S)
    for z in [-9.25,9.25]:
        m.box((0,6.38,z),(17,.54,.14),I)
    label='ПАСПОРТНЫЙ КОНТРОЛЬ' if stage=='passport' else 'ТАМОЖЕННЫЙ КОНТРОЛЬ'
    m.box((0,6.4,9.36),(14,.60,.08),H['DOORS'][0])
    m.text(label,(0,6.24,9.44),.42,I)
    for x in [-4.6,0,4.6]:
        for z in [-5,5]:
            m.box((x,5.91,z),(1.25,.08,.35),I)
    return m


def staff_wing():
    m=Mesh('customs_staff_wing')
    H['flat_roof'](m,18,8,3.5,P)
    for x in [-6.8,-3.5,3.5,6.8]:
        H['window'](m,x,1.9,4.07,1.8,1.55)
        H['window'](m,x,2.0,-4.07,1.8,1.3,back=True)
    H['doors'](m,0,4.12,1.7,2.5)
    m.box((0,2.85,4.8),(3.5,.14,1.8),S)
    m.box((0,.13,4.9),(3.8,.26,2.0),C)
    m.box((0,3.2,4.18),(6.7,.40,.10),S)
    m.text('СЛУЖЕБНЫЙ ВХОД',(0,3.06,4.26),.24,I)
    fittings(m,18,8,3.5)
    return m


def documents():
    m=Mesh('customs_documents')
    H['flat_roof'](m,24,6,3.2,P)
    for x in [-9.5,-5.5,5.5,9.5]:
        H['window'](m,x,1.85,3.08,2.7,1.6)
    H['doors'](m,0,3.12,2.1,2.5)
    m.box((0,2.9,4.25),(24.8,.15,2.7),S)
    for x in [-11,11]:
        m.box((x,1.45,5.3),(.12,2.9,.12),S)
    m.box((0,3.3,3.25),(13,.6,.12),H['DOORS'][0])
    m.text('ОФОРМЛЕНИЕ ДОКУМЕНТОВ',(0,3.10,3.34),.37,I)
    for x in [-8,8]:
        m.box((x,.5,4.45),(4,.14,.55),H['WOOD'])
        for dx in [-1.5,1.5]:
            m.box((x+dx,.25,4.45),(.1,.5,.45),S)
    fittings(m,24,6,3.2)
    return m


def tank():
    m=H['tank']()
    for i in range(16):
        a=i*math.tau/16
        x,z=3.81*math.cos(a),3.81*math.sin(a)
        m.beam((x,.5,z),(x,8.25,z),.025,C)
    m.box((-2,4.6,3.2),(1.25,1.35,.10),S)
    m.text('МАЗУТ',(-2,4.75,3.27),.19,I)
    m.text('Р-01',(-2,4.25,3.27),.27,I)
    return m


def garage(variant,bays=6):
    m=Mesh(('garage_row_' if bays==6 else 'garage_short_')+str(variant))
    width=bays*3.5
    m.box((0,1.3,0),(width,2.6,6),H['PALE_BRICK'])
    m.box((0,.13,0),(width+.1,.26,6.1),C)
    # Adjacent owners use different roofing, in small clusters rather than
    # an alternating checkerboard. Each 3.5 x 6 m bay keeps its own scale.
    palettes=[(0,0,4,2,5,1),(3,5,5,0,2,4),(4,1,1,3,0,5),
              (2,4,0,0,5,3),(5,3,1,4,4,2),(1,2,5,3,0,0)]
    for i in range(bays):
        x=(i-(bays-1)/2)*3.5
        H['doors'](m,x,3.07,2.88,2.25,H['DOORS'][(i+variant)%4])
        m.text(str(31+variant*6+i),(x+.9,2.28,3.34),.16,I)
        tone=palettes[variant][i]
        material=GARAGE_ROOFS[tone]
        profile=2 if tone==5 else (i+variant)%3
        a,b=x-1.75,x+1.75
        if i==0:
            a-=.15
        if i==bays-1:
            b+=.15
        if profile==0:
            eave=2.69
            ridge=3.02+.10*((i+variant)%2)
            for sign in [-1,1]:
                m.poly([(a,eave,sign*3.18),(b,eave,sign*3.18),
                        (b,ridge,0),(a,ridge,0)],
                       [(0,1,2,3)] if sign>0 else [(3,2,1,0)],material)
                for dx in [a+.4,a+1.3,a+2.2,a+3.1]:
                    if dx<b:
                        m.beam((dx,eave+.025,sign*3.18),(dx,ridge+.025,0),.035,material)
            m.beam((a, ridge+.045,0),(b,ridge+.045,0),.12,material)
            for edge in [a,b]:
                m.poly([(edge,2.6,-3),(edge,2.6,3),(edge,ridge,0)],[(0,1,2)],H['PALE_BRICK'])
        else:
            high=2.96 if profile==1 else 2.79
            low=2.69 if profile==1 else 2.73
            m.poly([(a,high,-3.18),(b,high,-3.18),(b,low,3.18),(a,low,3.18)],[(3,2,1,0)],material)
            for edge in [a,b]:
                m.poly([(edge,2.6,-3),(edge,2.6,3),(edge,low,3),(edge,high,-3)],[(0,1,2,3)],H['PALE_BRICK'])
            m.box((x,(2.6+high)/2,-2.95),(3.5,high-2.6,.10),H['PALE_BRICK'])
            if profile==1:
                for dx in [.4,1.3,2.2,3.1]:
                    m.beam((a+dx,high+.025,-3.18),(a+dx,low+.025,3.18),.035,material)
            else:
                for z in [-1.1,1.1]:
                    y=high+(low-high)*(z+3.18)/6.36
                    m.box((x,y+.015,z),(3.45,.025,.07),D)
                # A small felt repair follows the roof slope.
                m.poly([(x-.65,2.796,-1.6),(x+.45,2.796,-1.6),
                        (x+.45,2.780,.05),(x-.65,2.780,.05)],[(3,2,1,0)],S)
        for z in [-3.18,3.18]:
            m.beam((a,2.67,z),(b,2.67,z),.10,S)
        if (i+variant)%4==0:
            m.cylinder((x+.9,3.10,-1.9),.095,.65,S,segments=8)
            m.box((x+.9,3.46,-1.9),(.32,.06,.32),S)
        m.box((x,1.96,-3.055),(.55,.25,.08),D)
        for dx in [-.15,0,.15]:
            m.box((x+dx,1.96,-3.11),(.045,.24,.07),S)
    for i in range(bays):
        x=(i-(bays-1)/2)*3.5
        m.box((x,.045,3.25),(3.1,.09,.9),C)
        for y in [.55,1.7]:
            m.box((x-1.25,y,3.29),(.15,.16,.09),S)
            m.box((x+1.25,y,3.29),(.15,.16,.09),S)
    return m


def garage_lean_to():
    m=Mesh('garage_lean_to')
    # Owner-built storage at the back wall: shallow timber/steel enclosure.
    m.box((0,1,0),(3.4,2,1.9),H['WOOD'])
    m.poly([(-1.8,2.12,-1.05),(1.8,2.12,-1.05),
            (1.8,1.98,1.05),(-1.8,1.98,1.05)],[(3,2,1,0)],GARAGE_ROOFS[3])
    H['doors'](m,.4,.99,1.2,1.75,H['DOORS'][1])
    for x in [-1.45,1.45]:
        m.box((x,1.0,1.02),(.10,2.0,.10),S)
    return m


GARAGE_ROOFS=[H['material']('Garage roofing '+name,color,roughness) for name,color,roughness in [
    ('charcoal',(.14,.17,.18),.78),('blue grey',(.18,.28,.31),.74),
    ('olive',(.25,.28,.17),.84),('oxide',(.38,.20,.13),.85),
    ('galvanized',(.43,.46,.44),.66)]]+[H['BITUMEN']]


BUILDERS={
    'customs_office':office,
    'inspection_hall':lambda:hall('inspection_hall',40,24,7,2.4,3,'ДОСМОТР',opening=True,drive_through=True),
    'customs_bonded_store':lambda:hall('customs_bonded_store',20,10,4.8,1.1,2,'ЗАДЕРЖАННЫЕ ГРУЗЫ',pale=True),
    'customs_staff_wing':staff_wing, 'customs_documents':documents,
    'customs_passport_canopy':lambda:lane_canopy('passport'),
    'customs_control_canopy':lambda:lane_canopy('control'),
    'control_canopy':H['canopy'], 'control_booth':booth,
    'pedestrian_control':H['pedestrian'],
    'fuel_warehouse':lambda:hall('fuel_warehouse',28,12,6,2,3,'МАЗУТНЫЙ СКЛАД',pale=True),
    'fuel_tank':tank, 'water_tower':H['tower'],
    'fuel_pump_house':pump,'fuel_loading_gantry':loading,
    'port_warehouse_main':lambda:hall('port_warehouse_main',65,22,8,3.2,8,'РЕЧНОЙ ПОРТ',opening=True),
    'port_warehouse_small':lambda:hall('port_warehouse_small',40,12,6,2.2,5,'СКЛАД №2'),
    'truck_cafe':H['cafe'], 'frontier_rest_shelter':shelter,
    'boiler_house':H['boiler'], 'boiler_chimney':H['chimney'],
    'garage_row_0':lambda:garage(0), 'garage_row_1':lambda:garage(1),
    'garage_row_2':lambda:garage(2), 'garage_row_3':lambda:garage(3),
    'garage_row_4':lambda:garage(4), 'garage_row_5':lambda:garage(5),
    'garage_short_0':lambda:garage(0,3),'garage_short_3':lambda:garage(3,3),
    'garage_lean_to':garage_lean_to,
}


def build():
    reports=[]
    for name,builder in BUILDERS.items():
        m=builder()
        if name in ['truck_cafe','boiler_house','pedestrian_control']:
            dims={'truck_cafe':(32,12,4),'boiler_house':(28,20,9),'pedestrian_control':(8,10,3.6)}
            fittings(m,*dims[name])
        m.name='frontier_'+name if not name.startswith('frontier_') else name
        m.slots=[REMAP.get(slot,slot) for slot in m.slots]
        obj=m.finish()
        if name.startswith('garage_'):
            # These roof sheets are intentionally single-sided disconnected
            # surfaces. A general closed-volume normal pass can flip them;
            # explicitly orient the large top sheets and felt patches upward.
            bm=bmesh.new()
            bm.from_mesh(obj.data)
            for face in bm.faces:
                roof_height=1.9 if name=='garage_lean_to' else 2.65
                if face.calc_area()>1.0 and face.normal.z<-.5 and all(v.co.z>roof_height for v in face.verts):
                    face.normal_flip()
            bm.normal_update()
            bm.to_mesh(obj.data)
            bm.free()
            obj.data.update()
        # Prepared surface tiles use physical repeat scale. Retain inherited
        # repeat for door variation and non-textured metal/glass.
        uv=obj.data.uv_layers.active
        for face in obj.data.polygons:
            material=obj.data.materials[face.material_index]
            if material.name.startswith('ATP '):
                sx=sy=2.0 if 'brick' in material.name else 3.0
                if 'roof' in material.name:
                    sx=sy=4.0
                for loop in face.loop_indices:
                    v=obj.data.vertices[obj.data.loops[loop].vertex_index].co
                    if abs(face.normal.z)>.7:
                        point=(v.x/sx,-v.y/sy)
                    elif abs(face.normal.y)>abs(face.normal.x):
                        point=(v.x/sx,v.z/sy)
                    else:
                        point=(-v.y/sx,v.z/sy)
                    uv.data[loop].uv=point
        obj.data.calc_loop_triangles()
        bpy.context.view_layer.update()
        reports.append({'asset':m.name,'triangles':len(obj.data.loop_triangles),
                        'dimensions_blender':[round(x,3) for x in obj.dimensions]})
        print('BUILT',m.name,reports[-1],flush=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'frontier.blend'))
    (HERE/'build_report.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
    print('FRONTIER_BUILD_COMPLETE',flush=True)


if __name__=='__main__':
    build()
