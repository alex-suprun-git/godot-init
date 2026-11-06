"""Vehicle trio shape studies. Metres, -Y forward; no borrowed car geometry.

Run in Blender background. Builds asset-owned scenes, writes an editable blend.
Export is deliberately a separate stage. No baking/interiors in this pass.
"""
from pathlib import Path
import math
import bpy
import bmesh

HERE = Path(__file__).resolve().parent
SPECS = {
    'luxury_suv': dict(length=4.45, width=1.80, height=1.94, axles=(-1.40,1.45), radius=.365,
        paint='202426', belt=1.13, roof_front=-.72, roof_rear=1.92, roof_width=.79,
        cabin_front=-.93, cabin_rear=2.05, roof_edge=1.87, crown=.07),
    'luxury_sedan': dict(length=5.12, width=1.90, height=1.49, axles=(-1.52,1.52), radius=.335,
        paint='282B2C', belt=1.00, roof_front=-.67, roof_rear=1.02, roof_width=.765,
        cabin_front=-1.26, cabin_rear=1.65, roof_edge=1.445, crown=.045),
    'rural_4x4': dict(length=3.72, width=1.68, height=1.64, axles=(-1.06,1.14), radius=.325,
        paint='747852', belt=1.00, roof_front=-.48, roof_rear=1.30, roof_width=.705,
        cabin_front=-.89, cabin_rear=1.67, roof_edge=1.595, crown=.045),
}

def rgba(value):
    c = [int(value[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in c)+(1,)

def build(key, s):
    old = bpy.data.scenes.get(key)
    if old:
        for o in list(old.objects): bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.scenes.remove(old)
    scene = bpy.data.scenes.new(key)
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    col = bpy.data.collections.new(key+' geometry'); scene.collection.children.link(col)
    root = bpy.data.objects.new(key, None); col.objects.link(root)
    root['wheelbase_m'] = s['axles'][1]-s['axles'][0]
    root['reference'] = 'luxury-suv-v2' if key=='luxury_suv' else ('luxury-sedan-v1' if key=='luxury_sedan' else 'rural-4x4-v1')
    root['forward'] = 'Blender -Y; Godot +Z'
    mats = {}
    for name, color, rough, metal in [
        ('paint',s['paint'],.31 if key!='rural_4x4' else .65,.28),
        ('glass','35414A' if key!='rural_4x4' else '64757A',.23,.30),
        ('rubber','232629',.85,0),('steel','A1AAA9',.29,.75),
        ('lamp','D4D4BF',.26,.15),('red','A83D30',.35,.10),
        ('amber','D18A36',.40,.10),('seam','171C1D',.65,0)]:
        mat=bpy.data.materials.new(key+' '+name); mat.diffuse_color=rgba(color);mat.use_nodes=True
        bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value=rgba(color)
        bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
        mats[name]=mat
    def adopt(obj, material):
        for c in list(obj.users_collection): c.objects.unlink(obj)
        col.objects.link(obj);obj.parent=root;obj.data.materials.append(mats[material]);return obj
    def mesh(name, vertices, faces, material='paint', smooth=False):
        data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
        ob=bpy.data.objects.new(name,data);adopt(ob,material)
        for p in data.polygons:p.use_smooth=smooth
        return ob
    def box(name,loc,dims,material='paint',bevel=.012):
        bpy.ops.mesh.primitive_cube_add(size=1,location=loc);ob=bpy.context.object;ob.name=name;ob.dimensions=dims
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);adopt(ob,material)
        if bevel:
            m=ob.modifiers.new('Rolled edges','BEVEL');m.width=bevel;m.segments=2
            ob.modifiers.new('Panel normals','WEIGHTED_NORMAL')
        return ob
    def line(name, points, material='seam', radius=.005, cyclic=False):
        data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius;data.bevel_resolution=0
        sp=data.splines.new('POLY');sp.points.add(len(points)-1)
        for a,p in zip(sp.points,points):a.co=(*p,1)
        sp.use_cyclic_u=cyclic
        ob=bpy.data.objects.new(name,data);col.objects.link(ob);ob.parent=root;data.materials.append(mats[material]);return ob
    def cyl(name,loc,radius,depth,material='rubber',axis='X',vertices=24):
        rot=(0,math.pi/2,0) if axis=='X' else (math.pi/2,0,0)
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc,rotation=rot)
        ob=bpy.context.object;ob.name=name;adopt(ob,material)
        for p in ob.data.polygons:p.use_smooth=len(p.vertices)==4
        return ob
    w=s['width']/2;half=s['length']/2;belt=s['belt'];r=s['radius'];suv=key=='luxury_suv';sedan=key=='luxury_sedan'
    # Lower shell: actual rolled shoulder, tapered ends and crowned decks.
    levels=[(.29 if sedan else .39,w-.11),(.43 if sedan else .50,w-.035),
            (belt-.18,w),(belt-.055,w-.008),(belt,w-.045)]
    verts=[];ring=24
    for z,hw in levels:
        corner=.14 if sedan else .08
        for cx,cy,start in [(hw-corner,-half+.07+corner,-90),(hw-corner,half-.07-corner,0),(-hw+corner,half-.07-corner,90),(-hw+corner,-half+.07+corner,180)]:
            for i in range(6):
                a=math.radians(start+18*i);verts.append((cx+corner*math.cos(a),cy+corner*math.sin(a),z))
    faces=[tuple(range(ring-1,-1,-1))]
    for j in range(len(levels)-1):
        for i in range(ring): faces.append((j*ring+i,j*ring+(i+1)%ring,(j+1)*ring+(i+1)%ring,(j+1)*ring+i))
    faces.append(tuple(range((len(levels)-1)*ring,len(levels)*ring)))
    body=mesh('Rolled lower body shell',verts,faces,smooth=False)
    # Cut real wheel openings rather than black circles painted on the sides.
    for axle in s['axles']:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=r+.045,depth=3,location=(0,axle,r),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object;bpy.context.view_layer.objects.active=body
        mod=body.modifiers.new('Wheel arch','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter;mod.solver='EXACT'
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    # Cabin continuous surfaces, sampled glazing and crowned roof share landmarks.
    z0=belt-.015;z1=s['roof_edge'];bw=w-.065;tw=s['roof_width']
    def side(sign,y,z,offset=.004):
        t=(z-z0)/(z1-z0);return (sign*(bw+(tw-bw)*t+offset),y,z)
    def end(front,x,z,offset=.004):
        t=(z-z0)/(z1-z0)
        lo=s['cabin_front'] if front else s['cabin_rear'];hi=s['roof_front'] if front else s['roof_rear']
        return (x,lo+(hi-lo)*t+(-offset if front else offset),z)
    cabin=[(-bw,s['cabin_front'],z0),(bw,s['cabin_front'],z0),(bw,s['cabin_rear'],z0),(-bw,s['cabin_rear'],z0),
        (-tw,s['roof_front'],z1),(tw,s['roof_front'],z1),(tw,s['roof_rear'],z1),(-tw,s['roof_rear'],z1)]
    mesh('Cabin pillars and shoulder',cabin,[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(0,3,2,1)])
    roof=[];roof_faces=[];steps=12
    for y in [s['roof_front']-.025,s['roof_front']+.08,(s['roof_front']+s['roof_rear'])/2,s['roof_rear']-.08,s['roof_rear']+.025]:
        for j in range(steps+1):
            t=-1+2*j/steps;roof.append((tw*t,y,z1+s['crown']*(1-t*t)))
    for i in range(4):
        for j in range(steps):
            a=i*(steps+1)+j;roof_faces.append((a,a+1,a+steps+2,a+steps+1))
    mesh('Crowned roof',roof,roof_faces,smooth=True)
    for sign in [-1,1]:
        line('Roof gutter',[(sign*(tw+.005),s['roof_front'],z1),(sign*(tw+.005),s['roof_rear'],z1)],'rubber',.009)
    def panel(name, coords, mapper,material='glass',trim='rubber'):
        points=[mapper(a,b) for a,b in coords]
        # Quads split on a grid for curved/sloped continuous surfaces.
        ob=mesh(name,points,[tuple(range(len(points)))],material)
        if trim:line(name+' seal',points,trim,.012,True)
        return ob
    for front in [True,False]:
        # Parametric windscreen grid conforms to the same shell, with a shallow crown.
        vs=[];fs=[];cols=10;rows=4
        for i in range(rows+1):
            t=i/rows;z=z0+.07+(z1-z0-.13)*t
            width=(bw+(tw-bw)*(z-z0)/(z1-z0))-.07
            for j in range(cols+1):
                x=width*(-1+2*j/cols);p=list(end(front,x,z,.012));p[1]+=(-1 if front else 1)*.018*(1-(x/width)**2);vs.append(p)
        for i in range(rows):
            for j in range(cols):
                a=i*(cols+1)+j;fs.append((a,a+1,a+cols+2,a+cols+1))
        mesh('Windscreen' if front else 'Rear glass',vs,fs,'glass',True)
        border=[vs[j] for j in range(cols+1)]+[vs[i*(cols+1)+cols] for i in range(1,rows+1)]+[vs[rows*(cols+1)+j] for j in range(cols-1,-1,-1)]+[vs[i*(cols+1)] for i in range(rows-1,0,-1)]
        line('Glass perimeter',border,'steel' if sedan else 'rubber',.012,True)
    # Paired windows and doors, with a separate fixed cargo window on the SUVs.
    low=z0+.08;high=z1-.075
    if suv:
        windows=[(-.82,-.66,.15,.15),(.23,.23,.96,.96),(1.06,1.06,1.86,1.79)]
        doors=[(-.86,.20),(.20,1.04)];handle_y=[.03,.87]
    elif sedan:
        windows=[(-1.10,-.62,.12,.12),(.21,.21,1.45,.96)]
        doors=[(-1.15,.17),(.17,1.49)];handle_y=[-.03,1.16]
    else:
        windows=[(-.79,-.43,.38,.38),(.48,.48,1.50,1.23)]
        doors=[(-.82,.44)];handle_y=[.24]
    for sign in [-1,1]:
        for i,(lb,lt,rb,rt) in enumerate(windows):
            panel('Side glass '+str(sign)+' '+str(i),[(lb,low),(rb,low),(rt,high),(lt,high)],lambda y,z:side(sign,y,z,.012),trim='steel' if sedan else 'rubber')
        for i,(a,b) in enumerate(doors):
            # Seams bend above the rear arch where needed.
            bottom=.48 if sedan else .55
            pts=[(sign*(w+.004),a,belt-.03),(sign*(w+.004),a,bottom),(sign*(w+.004),b-.09,bottom),(sign*(w+.004),b,belt-.03)]
            line('Passenger door seam '+str(sign)+' '+str(i),pts,radius=.004)
        for y in handle_y:box('Passenger door handle',(sign*(w+.022),y,belt-.09),(.035,.16,.027),'steel',.008)
        for i,axle in enumerate(s['axles']):
            # Rounded tire profile built as a lathe about X, with recessed hub.
            tire=[];tf=[];seg=32;thick=.205 if not sedan else .225
            profile=[(-thick/2,.69*r),(-thick/2,.87*r),(-thick*.34,.985*r),(thick*.34,.985*r),(thick/2,.87*r),(thick/2,.69*r)]
            for dx,rr in profile:
                for j in range(seg):
                    a=2*math.pi*j/seg;tire.append((sign*(w-.065)+dx,axle+rr*math.sin(a),r+rr*math.cos(a)))
            for k in range(len(profile)-1):
                for j in range(seg):
                    a=k*seg+j;b=k*seg+(j+1)%seg;tf.append((a,b,b+seg,a+seg))
            mesh('Tire '+str(sign)+' '+str(i),tire,tf,'rubber',True)
            x=sign*(w-.065+thick/2+.003)
            cyl('Wheel rim',(x,axle,r),r*.68,.022,'steel')
            cyl('Wheel hub',(x+sign*.02,axle,r),r*.25,.028,'steel')
            for j in range(6 if sedan else 5):
                a=2*math.pi*j/(6 if sedan else 5)
                cyl('Rim recess',(x+sign*.013,axle+math.sin(a)*r*.46,r+math.cos(a)*r*.46),r*.08,.008,'rubber',vertices=10)
        box('Mirror stalk',(sign*(bw+.025),s['cabin_front']+.17,belt+.10),(.13,.04,.035),'rubber',.008)
        box('Mirror housing',(sign*(w+.10),s['cabin_front']+.13,belt+.17),(.115,.19,.12),'paint' if sedan else 'rubber',.025)
        # Period side rubbing strip and rocker panel.
        for a,b in [(-half+.17,s['axles'][0]-.40),(s['axles'][0]+.40,s['axles'][1]-.40),(s['axles'][1]+.40,half-.17)]:
            if b>a:line('Side protection',[(sign*(w+.006),a,belt-.18),(sign*(w+.006),b,belt-.18)],'steel' if sedan else 'rubber',.015)
        if suv:box('Running board',(sign*(w+.025),.03,.43),(.12,1.95,.07),'rubber',.02)
    # Crown bonnet and boot with transverse cross-sections, not bevelled boxes.
    for front in [True,False]:
        a=-half+.07 if front else s['cabin_rear']
        b=s['cabin_front'] if front else half-.07
        if b-a<.08:continue
        deck=[];df=[]
        for j in range(5):
            t=j/4;y=a+(b-a)*t
            z=belt+(.025 if suv else .035)*math.sin(math.pi*t)
            for i in range(13):
                q=-1+2*i/12;deck.append((q*(w-.045),y,z+.025*(1-q*q)))
        for j in range(4):
            for i in range(12):
                c=j*13+i;df.append((c,c+1,c+14,c+13))
        mesh('Bonnet crown' if front else 'Boot crown',deck,df,smooth=True)
    # Period face and bumpers; no emblems or lettering.
    for front in [True,False]:
        y=(-half if front else half);direction=-1 if front else 1
        box('Bumper',(0,y,.49 if sedan else .55),(s['width']+.035,.15,.14),'paint' if sedan else 'rubber',.035)
        if not sedan:box('Bumper steel face',(0,y+direction*.081,.57),(s['width']-.16,.018,.055),'steel',.009)
        box('Plate recess',(0,y+direction*.085,.52),(.41,.012,.095),'rubber',.005)
    fy=-half+.018
    box('Grille surround',(0,fy,belt-.145),(.79 if sedan else .77,.065,.255),'steel' if not key=='rural_4x4' else 'rubber',.025)
    box('Dark grille',(0,fy-.038,belt-.145),(.73,.02,.205),'rubber',.008)
    for z in [belt-.22,belt-.17,belt-.12,belt-.07]:box('Grille slat',(0,fy-.052,z),(.70,.012,.009),'steel',.002)
    for sign in [-1,1]:
        if sedan or suv:
            box('Headlamp',(sign*.64,fy-.008,belt-.14),(.37 if sedan else .25,.075,.23),'lamp',.025)
        else:cyl('Round headlamp',(sign*.59,fy-.028,belt-.15),.125,.045,'lamp','Y',32)
        box('Front indicator',(sign*(w-.12),fy-.01,belt-.15),(.10,.07,.16),'amber',.009)
        if suv:box('Bonnet wing indicator',(sign*(w-.10),-half+.22,belt+.04),(.10,.16,.07),'amber',.015)
        rear_z=belt-.12 if sedan else .85
        box('Tail lamp',(sign*(w-.16),half-.005,rear_z),(.27 if sedan else .14,.065,.19 if sedan else .30),'red',.014)
        box('Rear indicator',(sign*(w-.16),half+.031,rear_z+.04),(.26 if sedan else .13,.012,.055),'amber',.004)
        # Wipers lie directly in the front glass plane.
        line('Wiper',[end(True,sign*.10,belt+.10,.034),end(True,sign*.57,belt+.18,.034)],'rubber',.009)
    if suv:
        cyl('Rear spare tire',(0,half+.10,1.13),r,.22,'rubber','Y',32)
        cyl('Rear spare rim',(0,half+.222,1.13),r*.65,.025,'steel','Y',24)
        box('Tailgate handle',(-.59,half+.023,1.05),(.15,.04,.03),'steel',.006)
        line('Tailgate outline',[(-.75,half-.002,.77),(-.75,half-.002,1.73),(.75,half-.002,1.73),(.75,half-.002,.77)],radius=.005)
    # Shallow ventilation grooves, visible from the intended elevated camera.
    for i in range(6):
        y=s['cabin_front']-.12-i*.025
        line('Cowl vent',[(-.26,y,belt+.028),(.26,y,belt+.028)],radius=.004)
    box('Simple underbody',(0,0,.30),(s['width']-.4,s['length']-.55,.10),'rubber',.015)
    print('BUILT',key,'objects',len(scene.objects),'wheelbase',root['wheelbase_m'])
    return scene, root, locals()

if __name__=='__main__':
    for key,spec in SPECS.items():build(key,spec)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'vehicle_trio_shapes.blend'))
