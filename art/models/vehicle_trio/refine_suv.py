"""File the existing SUV towards fresh ImageGen v3; preserve the other cars.

Reference priorities: broad angular fender flares, level high bonnet, round
lamps in square housings, five-spoke wheels and exposed off-road tire shoulders.
The sheet guides shape, not certified projection/dimensional accuracy.
"""
import math
import bpy
from mathutils import Vector

def refine_suv(scene,root,s,ctx):
    mesh=ctx['mesh'];box=ctx['box'];cyl=ctx['cyl'];line=ctx['line']
    w=s['width']/2;r=s['radius'];half=s['length']/2
    prefixes=['Headlight','Grille ','Front signal','Contoured ventilated wheel','Domed centre hub',
        'Hex wheel bolt','Tire bead ring','Rolled wheel arch lip','Spare steel dish','Spare dish recess','Spare central hub',
        'Rear lamp gasket','Segmented rear lens']
    for ob in list(scene.objects):
        if any(ob.name.startswith(p) for p in prefixes):bpy.data.objects.remove(ob,do_unlink=True)
    def profile_width(z):
        # Use a broad shoulder without covering the tires with an uncut cube.
        return w+.065
    inner=[(-.465,.35),(-.440,.63),(-.290,.835),(.290,.835),(.440,.63),(.465,.35)]
    outer=[(-.555,.35),(-.530,.73),(-.355,.980),(.355,.980),(.530,.73),(.555,.35)]
    for sign in [-1,1]:
        for axle in s['axles']:
            # Two concentric angular contours, front and rear, form a real flare.
            vs=[]
            for xx in [w-.020,w+.065]:
                for contour in [inner,outer]:
                    vs.extend((sign*xx,axle+y,z) for y,z in contour)
            n=len(inner);fs=[]
            for j in range(n-1):
                fs.extend([(j,j+1,n+j+1,n+j),
                    (2*n+j,3*n+j,3*n+j+1,2*n+j+1),
                    (j,2*n+j,2*n+j+1,j+1),
                    (n+j,n+j+1,3*n+j+1,3*n+j)])
            for j in [0,n-1]:fs.append((j,n+j,3*n+j,2*n+j))
            ob=mesh('Angular sculpted fender flare',vs,fs,'paint')
            mod=ob.modifiers.new('Soft pressed flare edges','BEVEL');mod.width=.010;mod.segments=2
            ob.modifiers.new('Flare panel normals','WEIGHTED_NORMAL')
            line('Flare outer edge',[(sign*(w+.068),axle+y,z) for y,z in outer],'rubber',.008)
            # Retain current tire geometry and add visible shoulder blocks only.
            # No invisible underbody detailing; 24 coarse tread shoulders per wheel.
            track=s['tracks'][0 if axle==s['axles'][0] else 1]
            outside=track/2+s['tire_width']/2-.019
            for j in range(24):
                angle=2*math.pi*j/24
                ob=box('Offroad tire shoulder',(sign*(track/2+s['tire_width']*.40),axle+r*.947*math.sin(angle),r+r*.947*math.cos(angle)),
                    (.075,.060,.025),'rubber',.004)
                ob.rotation_euler.x=-angle
            # Cast wheel: annular rim and five actual spokes, not a perforated plate.
            rim=.2032;segments=32;vs=[];fs=[]
            rings=[(rim,.0),(rim*.97,.019),(rim*.89,.027),(rim*.84,.018)]
            for rr,dx in rings:
                for j in range(segments):
                    a=2*math.pi*j/segments
                    vs.append((sign*(outside+dx),axle+rr*math.sin(a),r+rr*math.cos(a)))
            for k in range(len(rings)-1):
                for j in range(segments):
                    a=k*segments+j;b=k*segments+(j+1)%segments;fs.append((a,b,b+segments,a+segments))
            mesh('Cast alloy rim lip',vs,fs,'steel',True)
            cyl('Five spoke wheel centre',(sign*(outside+.030),axle,r),.068,.040,'steel',vertices=24)
            for j in range(5):
                a=2*math.pi*j/5
                ob=box('Broad cast alloy spoke',(sign*(outside+.024),axle+.121*math.sin(a),r+.121*math.cos(a)),(.025,.050,.135),'steel',.010)
                ob.rotation_euler.x=-a
                cyl('Recessed lug bolt',(sign*(outside+.054),axle+.048*math.sin(a),r+.048*math.cos(a)),.010,.008,'seam',vertices=8)
        # Flat fender shoulders are separate from the central stamped bonnet.
        y0=-half+.15;y1=s['cabin_front']-.025
        vs=[]
        for yy,zz in [(y0,1.205),(y1,1.260)]:
            vs.extend([(sign*(w-.045),yy,zz),(sign*(w-.260),yy,zz+.010)])
        mesh('Flat front wing shoulder',vs,[(0,1,3,2)],'paint')
        line('Bonnet rolled side seam',[(sign*.63,y0,1.224),(sign*.63,y1,1.276)],'seam',.005)
        box('Bonnet rear hinge',(sign*.52,y1-.055,1.277),(.09,.14,.022),'paint',.008)
    # Near-vertical classic front: full-width panel, square pods and round glass.
    fy=-half-.024;z=1.015
    box('Classic flat front panel',(0,fy,1.035),(1.67,.055,.320),'paint',.025)
    box('Classic grille rim',(0,fy-.034,z),(.875,.020,.295),'rubber',.018)
    box('Classic dark grille',(0,fy-.048,z),(.810,.012,.250),'seam',.009)
    for i in range(6):box('Classic horizontal grille blade',(0,fy-.058,z-.105+i*.042),(.790,.012,.010),'steel',.002)
    for sign in [-1,1]:
        x=sign*.634
        box('Square headlamp pod',(x,fy-.035,z),(.336,.055,.320),'rubber',.024)
        cyl('Round headlight metal rim',(x,fy-.071,z),.139,.025,'steel','Y',32)
        cyl('Round headlight reflector',(x,fy-.087,z),.122,.017,'lamp','Y',32)
        cyl('Round headlight inner glass',(x,fy-.099,z),.100,.008,'lamp','Y',32)
        for dx in [-.060,-.030,0,.030,.060]:
            h=math.sqrt(.105**2-dx*dx)
            line('Headlight glass rib',[(x+dx,fy-.106,z-h),(x+dx,fy-.106,z+h)],'steel',.002)
        # Square upper wing indicators, visible from the elevated game camera.
        box('Upper wing indicator foot',(sign*.759,-half+.255,1.224),(.14,.19,.032),'rubber',.010)
        box('Upper wing indicator glass',(sign*.759,-half+.255,1.248),(.11,.16,.035),'amber',.010)
    # Spare has the same cast wheel language; retain the existing spare tire.
    cyl('Spare cast rim',(0,half+.223,1.13),.2032,.022,'steel','Y',28)
    cyl('Spare dark recess',(0,half+.239,1.13),.177,.012,'rubber','Y',28)
    cyl('Spare cast hub',(0,half+.258,1.13),.067,.030,'steel','Y',24)
    for j in range(5):
        a=2*math.pi*j/5
        ob=box('Spare alloy spoke',(.121*math.sin(a),half+.254,1.13+.121*math.cos(a)),(.050,.022,.135),'steel',.009)
        ob.rotation_euler.y=a
    for sign in [-1,1]:
        # Fresh sheet has horizontal corner lamps, not vertical van-style stacks.
        box('Horizontal tail lamp housing',(sign*.740,half+.020,.760),(.275,.055,.135),'rubber',.009)
        box('Red rear lens',(sign*.705,half+.054,.760),(.170,.020,.100),'red',.006)
        box('Amber outer rear lens',(sign*.830,half+.054,.760),(.065,.020,.100),'amber',.006)
        box('Lower rear reflector',(sign*.685,half+.090,.535),(.13,.014,.055),'red',.005)
    line('Rear glass wiper',[(-.22,half-.025,1.64),(.28,half-.025,1.82)],'rubber',.012)
    root['stage']='Fresh ImageGen v3 SUV shape refinement v6; awaiting user visual review'
    root['modeling_reference']='art/source_images/vehicle_trio/luxury-suv-v3.png'
    print('SUV V6',len(scene.objects),'objects')
