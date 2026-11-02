"""Reusable four-axle container flat wagon. Cargo has its own tintable material."""
from pathlib import Path
import runpy
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
H=runpy.run_path(str(HERE/'build_locomotive.py'),run_name='m62_helpers')
Geometry=H['Geometry']
SL,SW,SH=H['SL'],H['SW'],H['SH']
DARK,STEEL,FRAME='303a3a','6c7773','48534e'
NAME='Container_Wagon_Studio'


def chassis(g,detail):
    g.box((0,0,1.19),(2.95,13.40,.24),FRAME,0)
    for s in [-1,1]:
        g.box((s*1.46,0,1.10),(.12,13.40,.34),DARK,0)
        g.box((s*1.47,0,1.32),(.15,13.40,.055),STEEL,2)
        for y in [-6.03,6.03]:
            g.box((s*1.145,y,1.365),(.18,.18,.07),'b29a55',2)
    for y in [-6.56,-4.6,-2.2,0,2.2,4.6,6.56]:
        g.box((0,y,1.08),(2.87,.15,.29),DARK,0)
    for end in [-1,1]:
        g.box((0,end*6.95,1.05),(.28,.58,.25),DARK,2)
        g.box((0,end*7.205,1.05),(.46,.21,.31),STEEL,2)
        for s in [-1,1]:
            g.box((s*1.19,end*6.67,.75),(.40,.35,.07),STEEL,2)
            if detail:
                g.beam((s*1.35,end*6.65,.77),(s*1.35,end*6.65,1.66),.022,STEEL)
                g.beam((s*.97,end*6.65,1.39),(s*1.35,end*6.65,1.66),.022,STEEL)
    for cy in [-4.6,4.6]:
        g.box((0,cy,.86),(1.95,2.35,.27),DARK,2)
        for yy in [cy-.925,cy+.925]:
            g.cylinder((-.9,yy,.475),(.9,yy,.475),.09,DARK,2,10)
            for s in [-1,1]:
                x=s*.76
                g.cylinder((x-.085,yy,.475),(x+.085,yy,.475),.475,DARK,2,16)
                g.cylinder((x-.095,yy,.475),(x+.095,yy,.475),.35,STEEL,2,12)
                g.box((s*1.04,yy,.52),(.20,.28,.26),STEEL,2)
        for s in [-1,1]:
            g.box((s*1.06,cy,.69),(.20,2.38,.23),DARK,2)
            if detail:
                for dy in [-.22,.22]:
                    g.cylinder((s*1.07,cy+dy,.53),(s*1.07,cy+dy,.90),.11,STEEL,2,8)
                    for z in [.59,.68,.77,.86]:
                        g.cylinder((s*1.07,cy+dy,z),(s*1.07,cy+dy,z+.025),.125,DARK,2,8)
        if detail:
            for s in [-1,1]:
                g.beam((s*1.05,cy-.8,.57),(s*1.05,cy-.35,.80),.045,STEEL)
                g.beam((s*1.05,cy+.35,.80),(s*1.05,cy+.8,.57),.045,STEEL)
    if detail:
        g.cylinder((0,-1.25,.86),(0,.1,.86),.18,STEEL,2,12)
        g.box((.6,0,.92),(.32,.75,.25),DARK,2)
        g.beam((-.7,-5.95,.97),(-.7,5.95,.97),.025,STEEL)


def cargo(g,detail):
    # 40 ft standard-height design targets; independent of the reference sheet's pixels.
    length,width,height=12.192,2.438,2.591
    bottom=1.40
    top=bottom+height
    g.box((0,0,(bottom+top)/2),(width-.08,length-.08,height-.08),'eeeeee',1)
    if detail:
        # Folded side walls and roof: actual shallow corrugation, shared repeated profile.
        n=44
        start=-length/2+.16
        pitch=(length-.32)/n
        for i in range(n):
            ys=[start+pitch*(i+t) for t in [0,.18,.50,.68,1]]
            relief=[0,.035,.035,0,0]
            for j in range(4):
                a,b=ys[j:j+2]
                for s in [-1,1]:
                    xa=s*(width/2-.025+relief[j])
                    xb=s*(width/2-.025+relief[j+1])
                    g.polygon([(xa,a,bottom+.13),(xb,b,bottom+.13),
                               (xb,b,top-.13),(xa,a,top-.13)],'ffffff',1)
                za=top-.025+relief[j]*.65
                zb=top-.025+relief[j+1]*.65
                g.polygon([(-width/2+.09,a,za),(width/2-.09,a,za),
                           (width/2-.09,b,zb),(-width/2+.09,b,zb)],'f3f3f3',1)
    for s in [-1,1]:
        for end in [-1,1]:
            x=s*(width/2-.065);y=end*(length/2-.065)
            g.box((x,y,(bottom+top)/2),(.13,.13,height),'ffffff',1)
            for z in [bottom+.055,top-.055]:
                g.box((x,y,z),(.16,.16,.11),'c5c5c5',1)
                g.box((x,y+end*.083,z),(.065,.006,.04),DARK,2)
        for z in [bottom+.06,top-.055]:
            g.box((s*(width/2-.04),0,z),(.08,length,.11),'dddddd',1)
    for end in [-1,1]:
        for z in [bottom+.06,top-.055]:
            g.box((0,end*(length/2-.04),z),(width,.08,.11),'dddddd',1)
    # Closed paired doors at the rear, separate seams and four locking rods.
    for s in [-1,1]:
        g.box((s*.58,length/2+.005,(bottom+top)/2),(1.10,.055,height-.25),'f2f2f2',1)
    g.box((0,length/2+.04,(bottom+top)/2),(.035,.025,height-.20),DARK,2)
    if detail:
        for x in [-.91,-.27,.27,.91]:
            g.cylinder((x,length/2+.075,bottom+.22),(x,length/2+.075,top-.22),.023,STEEL,2,8)
            g.box((x+.07,length/2+.09,bottom+.80),(.18,.04,.035),STEEL,2)
        for s in [-1,1]:
            for z in [bottom+.4,bottom+1.25,top-.4]:
                g.box((s*1.07,length/2+.065,z),(.13,.09,.07),STEEL,2)
        for x in [-.94,-.62,-.31,0,.31,.62,.94]:
            g.box((x,-length/2-.005,(bottom+top)/2),(.07,.035,height-.27),'ffffff',1)


def build(blockout=False):
    name=NAME+'_Blockout' if blockout else NAME
    if name in bpy.data.scenes:
        old=bpy.data.scenes[name]
        for obj in list(old.objects):bpy.data.objects.remove(obj,do_unlink=True)
        bpy.data.scenes.remove(old)
    scene=bpy.data.scenes.new(name)
    bpy.context.window.scene=scene
    scene.unit_settings.system='METRIC'
    collection=bpy.data.collections.new(name+' authored wagon')
    scene.collection.children.link(collection)
    mats=[H['helpers'].material('Freight wagon frame',.72,.3),
          H['helpers'].material('Freight container paint',.66,.1),
          H['helpers'].material('Freight mechanical fittings',.72,.4)]
    g=Geometry();chassis(g,not blockout);cargo(g,not blockout)
    obj=g.object('Container_Flat_Wagon',collection,mats)
    for v in obj.data.vertices:v.co=Vector((v.co.x*SW,v.co.y*SL,v.co.z*SH))
    obj['nominal_coupler_pitch_m']=14.62
    obj['container_lwh_m']=[12.192,2.438,2.591]
    obj['forward']='Blender -Y / Godot +Z; wheels at ground zero'
    obj['tint_surface']='Freight container paint; shared geometry, independent instance paint'
    H['helpers'].scene=scene
    H['helpers'].studio()
    obj.select_set(True);bpy.context.view_layer.objects.active=obj
    path=HERE/('wagon_blockout.blend' if blockout else 'container_wagon.blend')
    bpy.data.libraries.write(str(path),{scene},fake_user=True)
    print('Wagon checkpoint:',path,'triangles:',sum(len(p.vertices)-2 for p in obj.data.polygons))


if __name__=='__main__':build()
