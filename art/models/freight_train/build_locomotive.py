"""M62-inspired original locomotive; reuses ER2 mesh/material helpers, not its body.

Run in live Blender with runpy.run_path(..., run_name='__main__').
Set LOCOMOTIVE_BLOCKOUT=1 for the cheap silhouette checkpoint. No unrelated scene is removed.
"""
from pathlib import Path
import importlib.util
import json
import math
import os
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ER2 = ROOT / 'art/models/public_transport/er2'
spec = importlib.util.spec_from_file_location('er2_geometry_helpers', ER2 / 'build_er2.py')
helpers = importlib.util.module_from_spec(spec)
# Execute source directly so reusing ER2 helpers does not create cache files there.
exec(compile((ER2 / 'build_er2.py').read_text(), str(ER2 / 'build_er2.py'), 'exec'), helpers.__dict__)
Geometry = helpers.Geometry
SL, SW, SH = json.loads((ER2 / 'volga_measurements.json').read_text())['train_lwh_factors']
BLOCKOUT = os.environ.get('LOCOMOTIVE_BLOCKOUT') == '1'
GREEN, LIGHT, CREAM = '43584b', '536658', 'c9c3a1'
ROOF, DARK, METAL, GLASS = '787e7c', '283030', '626c69', '334d59'
SCENE_NAME = 'M62_Blockout' if BLOCKOUT else 'M62_Studio'
ASSET_NAME = 'M62_Locomotive'


def front_y(z, end):
    return end * (8.15 - max(0, z - 2.65) * .27)


def body(g):
    # Longitudinal rings share a crowned profile and two equally raked cab faces.
    half = [(0,1.15),(1.36,1.15),(1.475,1.32),(1.475,2.15),
            (1.475,2.57),(1.475,3.53),(1.45,3.72),(1.36,3.94),
            (1.18,4.14),(.91,4.29),(.48,4.38),(0,4.40)]
    profile = half + [(-x,z) for x,z in half[-2:0:-1]]
    rings = []
    for y in [-8.15,-7.9,-6.25,-4.3,0,4.3,6.25,7.9,8.15]:
        cap = abs(y) > 8
        rings.append([(x * (.94 if cap else 1), front_y(z,1 if y>0 else -1) if cap else y,z)
                      for x,z in profile])
    for a,b in zip(rings[:-1],rings[1:]):
        for i in range(len(profile)):
            j=(i+1)%len(profile)
            z=(profile[i][1]+profile[j][1])/2
            color=ROOF if z>3.73 else (CREAM if 2.15<z<2.57 else GREEN)
            g.polygon([a[i],a[j],b[j],b[i]],color,0,z>3.73)
    # Section the end caps too: same cream belt and roof color, no floating paint planes.
    for end,ring in [(-1,rings[0]),(1,rings[-1])]:
        n=len(half)
        for k in range(n-1):
            x0,z0=half[k]; x1,z1=half[k+1]
            points=[(-x0*.94,front_y(z0,end),z0),(x0*.94,front_y(z0,end),z0),
                    (x1*.94,front_y(z1,end),z1),(-x1*.94,front_y(z1,end),z1)]
            if x0==0: points=points[1:]
            if x1==0: points=points[:-1]
            g.polygon(points,ROOF if z0>3.73 else (CREAM if 2.15<=z0<2.57 else GREEN))
    g.box((0,0,1.13),(2.86,16.35,.22),DARK,2)
    for s in [-1,1]:
        g.box((s*1.47,0,1.27),(.065,15.75,.12),METAL,2)
        g.box((s*1.479,0,2.13),(.025,15.4,.035),LIGHT)
        g.box((s*1.47,0,3.67),(.045,14.95,.05),METAL,2)


def bogies(g):
    radius=.525
    for cy in [-4.3,4.3]:
        g.box((0,cy,.93),(2.05,4.10,.30),DARK,2)
        for yy in [cy-1.85,cy,cy+1.85]:
            g.cylinder((-.90,yy,radius),(.90,yy,radius),.105,DARK,2,10)
            for side in [-1,1]:
                x=side*.76
                g.cylinder((x-.09,yy,radius),(x+.09,yy,radius),radius,'414a49',2,16)
                g.cylinder((x-.10,yy,radius),(x+.10,yy,radius),radius*.73,METAL,2,12)
                g.box((side*1.12,yy,.59),(.24,.37,.32),METAL,2)
        for side in [-1,1]:
            g.box((side*1.12,cy,.82),(.20,4.4,.25),DARK,2)
            if not BLOCKOUT:
                for dy in [-.94,.94]:
                    for yy in [cy+dy-.19,cy+dy+.19]:
                        g.cylinder((side*1.13,yy,.61),(side*1.13,yy,1.03),.115,METAL,2,8)
                        for z in [.68,.78,.88,.98]:
                            g.cylinder((side*1.13,yy,z),(side*1.13,yy,z+.025),.13,DARK,2,8)
                g.beam((side*1.16,cy-1.75,.60),(side*1.16,cy-.35,.94),.055,METAL)
                g.beam((side*1.16,cy+.35,.94),(side*1.16,cy+1.75,.60),.055,METAL)
    g.box((0,0,.65),(2.04,3.30,.75),DARK,2)
    for side in [-1,1]:
        g.box((side*1.05,0,.71),(.08,3.00,.57),METAL,2)
        g.cylinder((side*.96,-1.55,.87),(side*.96,-1.55,1.16),.10,DARK,2,10)
        g.cylinder((side*.95,1.60,.78),(side*.95,2.15,.78),.20,METAL,2,12)


def side_glass(g,s,y,z,w,h):
    for depth,inset,color,mat in [(0,0,METAL,2),(.009,.035,DARK,2),(.018,.085,GLASS,1)]:
        g.panel(lambda u,v:(s*(1.488+depth),y+u,z+v),w-inset,h-inset,.075,color,mat)


def cabs(g):
    for end in [-1,1]:
        for x in [-.66,.66]:
            for depth,inset,color,mat in [(.025,0,METAL,2),(.035,.04,DARK,2),(.046,.10,GLASS,1)]:
                g.panel(lambda u,v:(x+u,front_y(3.25+v,end)+end*depth,3.25+v),
                        1.16-inset,.80-inset,.105,color,mat)
            if not BLOCKOUT:
                g.beam((x-.35,front_y(2.96,end)+end*.065,2.96),
                       (x+.13,front_y(3.25,end)+end*.065,3.25),.014,DARK)
        for x,z,r in [(0,3.99,.195),(-1.02,2.01,.145),(1.02,2.01,.145)]:
            y=front_y(z,end)
            g.cylinder((x,y+end*.025,z),(x,y+end*.11,z),r+.045,DARK,2,16)
            g.cylinder((x,y+end*.112,z),(x,y+end*.14,z),r,METAL,2,16)
            g.cylinder((x,y+end*.142,z),(x,y+end*.15,z),r*.77,'d0cdb7',0,16)
        for side in [-1,1]:
            side_glass(g,side,end*7.17,3.22,.97,.85)
            g.panel(lambda u,v:(side*1.487,end*6.13+u,2.37+v),.72,2.05,.035,DARK,2)
            g.panel(lambda u,v:(side*1.498,end*6.13+u,2.37+v),.65,1.98,.03,LIGHT)
            side_glass(g,side,end*6.13,2.96,.40,.66)
            if not BLOCKOUT:
                g.box((side*1.515,end*6.35,2.22),(.035,.035,.17),METAL,2)
                for z in [.38,.64,.90,1.15]:
                    g.box((side*1.34,end*6.10,z),(.43,.67,.065),METAL,2)
                for yy in [end*5.69,end*6.57]:
                    g.beam((side*1.53,yy,1.30),(side*1.53,yy,2.81),.022,METAL)
        g.box((0,end*8.28,1.05),(.32,.40,.27),DARK,2)
        # Exact nominal overall length: 17.550 m before the ER2 presentation conversion.
        g.box((0,end*8.605,1.05),(.46,.34,.31),METAL,2)
        if not BLOCKOUT:
            for z,w in [(.39,2.03),(.68,2.35),(.98,2.62)]:
                g.box((0,end*8.20,z),(w,.13,.08),METAL,2)
            for side in [-1,1]:
                g.beam((side*1.0,end*8.22,.38),(side*1.32,end*8.22,1.10),.045,DARK)
                g.beam((side*.45,end*8.24,.99),(side*.55,end*8.31,.49),.035,DARK)
            g.panel(lambda u,v:(u,front_y(2.76+v,end)+end*.023,2.76+v),.49,.17,.035,METAL,2)


def equipment(g):
    for s in [-1,1]:
        for y in [-2.28,-.76,.76,2.28]:
            side_glass(g,s,y,3.11,.88,.55)
        for y,w in [(-4.55,1.67),(4.55,1.67)]:
            g.panel(lambda u,v:(s*1.489,y+u,2.98+v),w,1.24,.025,DARK,2)
            if not BLOCKOUT:
                for i in range(14):
                    yy=y-w/2+.08+i*(w-.16)/13
                    g.box((s*1.515,yy,2.98),(.055,.040,1.11),LIGHT)
                for z in [2.42,3.54]:
                    g.box((s*1.52,y,z),(.065,w,.04),METAL,2)
        if not BLOCKOUT:
            for y in [-2.4,-.8,.8,2.4]:
                for z in [1.56,1.76,1.96]:
                    g.box((s*1.49,y,z),(.024,1.43,.035),LIGHT)
                g.box((s*1.49,y,3.53),(.024,1.43,.025),METAL,2)
    g.box((0,-1.15,4.42),(.68,.65,.146),DARK,2)
    g.box((0,1.08,4.42),(.61,.48,.12),DARK,2)
    # Roof fans are inset-looking dark disks with a modest painted rim.
    for y in [-4.25,3.65]:
        g.cylinder((0,y,4.30),(0,y,4.43),.67,METAL,2,20)
        g.cylinder((0,y,4.431),(0,y,4.447),.57,DARK,2,20)
        if not BLOCKOUT:
            for a in range(0,180,30):
                t=math.radians(a)
                g.beam((-.54*math.cos(t),y-.54*math.sin(t),4.457),
                       (.54*math.cos(t),y+.54*math.sin(t),4.457),.012,METAL)
    for y in [-6.4,6.4]:
        g.box((0,y,4.37),(.81,.90,.09),ROOF)
    if not BLOCKOUT:
        for s in [-1,1]:
            g.beam((s*.26,-7.30,4.35),(s*.26,-7.55,4.42),.025,METAL)
            g.cylinder((s*.26,-7.55,4.42),(s*.26,-7.79,4.42),.060,METAL,2,10)


def build():
    if SCENE_NAME in bpy.data.scenes:
        old=bpy.data.scenes[SCENE_NAME]
        for obj in list(old.objects):
            bpy.data.objects.remove(obj,do_unlink=True)
        bpy.data.scenes.remove(old)
    scene=bpy.data.scenes.new(SCENE_NAME)
    bpy.context.window.scene=scene
    scene.unit_settings.system='METRIC'
    coll=bpy.data.collections.new(SCENE_NAME+' authored asset')
    scene.collection.children.link(coll)
    mats=[helpers.material('M62 body paint and livery',.65),
          helpers.material('M62 opaque glass',.30),helpers.material('M62 mechanical trim',.7,.35)]
    g=Geometry()
    body(g);bogies(g);cabs(g);equipment(g)
    obj=g.object(ASSET_NAME,coll,mats)
    for v in obj.data.vertices:
        v.co=Vector((v.co.x*SW,v.co.y*SL,v.co.z*SH))
    obj['design']='M62-inspired fictional single-section freight diesel, 1997'
    obj['nominal_lwh_m']=[17.55,2.95,4.493]
    obj['presentation_lwh']=list((SL,SW,SH))
    obj['forward']='Blender -Y / Godot +Z; wheel tread bottoms Z=0'
    obj['comparison_rule']='Shorter/narrower than ER2 car; roof slightly higher; below ER2 pantograph'
    helpers.scene=scene
    helpers.studio()
    for light in scene.objects:
        if light.type=='LIGHT':light.name='M62 review sun'
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    # Save only the asset scene, leaving the user's other live Blender scenes untouched.
    path=HERE/('locomotive_blockout.blend' if BLOCKOUT else 'locomotive.blend')
    bpy.data.libraries.write(str(path),{scene},fake_user=True)
    print('Locomotive checkpoint:',path,'triangles:',sum(len(p.vertices)-2 for p in obj.data.polygons))


if __name__=='__main__':build()
