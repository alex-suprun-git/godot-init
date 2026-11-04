"""Refine trio using the current RAF/PAZ/ZIL exterior finish as the benchmark.

Reconstruct the cheap source, then replace panels/glass/wheels and add fittings.
No generic old sedan geometry, interiors, unseen underside or texture bake.
"""
from pathlib import Path
import runpy
import math
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
source=runpy.run_path(str(HERE/'build_shapes.py'))
references=runpy.run_path(str(HERE/'reference_geometry.py'))
TARGETS=references['TARGETS']

def refine(key,s,scene,root,ctx):
    mesh=ctx['mesh'];box=ctx['box'];line=ctx['line'];cyl=ctx['cyl'];mats=ctx['mats']
    w=s['width']/2;half=s['length']/2;r=s['radius'];belt=s['belt']
    suv=key=='luxury_suv';sedan=key=='luxury_sedan';rural=key=='rural_4x4'
    target=TARGETS[key]
    def top(y):return references['interpolate'](target['deck'],y)
    def body_z(y,z):
        floor=.29 if sedan else (.53 if rural else .48)
        return floor+(z-floor)*(top(y)-floor)/(belt-floor)
    def remove(prefixes):
        for ob in list(scene.objects):
            if any(ob.name.startswith(p) for p in prefixes):bpy.data.objects.remove(ob,do_unlink=True)
    remove(['Rolled lower','Cabin pillars','Crowned roof','Roof gutter','Side glass','Windscreen','Rear glass','Glass perimeter',
        'Passenger door','Side protection','Wheel rim','Wheel hub','Rim recess','Bonnet crown','Boot crown','Cowl vent',
        'Headlamp','Round headlamp','Grille','Dark grille','Front indicator','Tail lamp','Rear indicator','Bumper','Plate recess',
        'Wiper','Tailgate outline','Rear spare rim','Mirror housing','Mirror stalk'])
    # Controlled specular values: glass is opaque, lamps are not emissive white blocks.
    for name,color,rough,metal in [('glass','273640' if suv else ('354A56' if sedan else '52666B'),.29,.12),
        ('lamp','A8B7AF',.26,.28),('steel','9CA4A1',.31,.72),('rubber','202627',.78,0)]:
        bs=next(n for n in mats[name].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value=source['rgba'](color)
        bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    if rural:
        glass_shader=next(n for n in mats['glass'].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        glass_shader.inputs['Roughness'].default_value=.42
        glass_shader.inputs['Specular IOR Level'].default_value=.20
    def rounded(coords, radius=.025, steps=4):
        # Round a polygon in its parameter plane; keep every corner inside its shell.
        out=[]
        for i,p in enumerate(coords):
            p=Vector(p);a=Vector(coords[i-1]);b=Vector(coords[(i+1)%len(coords)])
            d=min(radius,(a-p).length*.22,(b-p).length*.22)
            start=p+(a-p).normalized()*d;end=p+(b-p).normalized()*d
            for j in range(steps):
                t=j/(steps-1);out.append(tuple((1-t)**2*start+2*(1-t)*t*p+t*t*end))
        return out
    def patch(name, coords, mapper,material='glass',seal=True,chrome=False):
        n=len(coords);centre=tuple(sum(p[k] for p in coords)/n for k in (0,1))
        vs=[mapper(*centre)]
        for t in [.35,.70,1]:
            vs.extend(mapper(centre[0]+(p[0]-centre[0])*t,centre[1]+(p[1]-centre[1])*t) for p in coords)
        fs=[]
        for i in range(n):
            j=(i+1)%n;fs.append((0,1+i,1+j))
            for k in range(2):
                a=1+k*n;fs.append((a+i,a+n+i,a+n+j,a+j))
        ob=mesh(name,vs,fs,material,True)
        if seal:line(name+' rubber seal',[mapper(*p) for p in coords],'rubber',.013,True)
        if chrome:
            larger=[(centre[0]+(p[0]-centre[0])*1.035,centre[1]+(p[1]-centre[1])*1.035) for p in coords]
            line(name+' bright surround',[mapper(*p) for p in larger],'steel',.006,True)
        return ob
    # Lower shell uses actual rolled shoulders and recessed sill; rounded plan corners.
    bottom=.29 if sedan else (.53 if rural else .48)
    sections=[(bottom,w-.115),(bottom+.035,w-.075),(bottom+.09,w-.038),
        (belt-.24,w-.009),(belt-.16,w),(belt-.095,w-.004),(belt-.045,w-.025),(belt,w-.065)]
    def side_width(y,z):
        width=sections[-1][1]
        for a,b in zip(sections,sections[1:]):
            if z<=b[0]:
                t=max(0,min(1,(z-a[0])/(b[0]-a[0])));width=a[1]+(b[1]-a[1])*t;break
        taper=(.035 if sedan else .010)*(abs(y)/(half-.07))**4
        return width-taper
    def lower(sign,y,z,offset=.009):return (sign*(side_width(y,z)+offset),y,body_z(y,z))
    vs=[];per=76
    for z,hw in sections:
        cr=.22 if sedan else (.10 if suv else .135)
        corners=[(hw-cr,-half+.07+cr,-90),(hw-cr,half-.07-cr,0),(-hw+cr,half-.07-cr,90),(-hw+cr,-half+.07+cr,180)]
        outline=[]
        for index,(cx,cy,start) in enumerate(corners):
            for j in range(10):
                a=math.radians(start+90*j/9);outline.append((cx+cr*math.cos(a),cy+cr*math.sin(a)))
            nx,ny,na=corners[(index+1)%4]
            end=Vector((nx+cr*math.cos(math.radians(na)),ny+cr*math.sin(math.radians(na))))
            begin=Vector(outline[-1])
            outline.extend(tuple(begin.lerp(end,j/10)) for j in range(1,10))
        for x,y in outline:
            x-=math.copysign((.035 if sedan else .010)*(abs(y)/(half-.07))**4,x)
            vs.append((x,y,body_z(y,z)))
    fs=[tuple(range(per-1,-1,-1))]
    for k in range(len(sections)-1):
        for i in range(per):fs.append((k*per+i,k*per+(i+1)%per,(k+1)*per+(i+1)%per,(k+1)*per+i))
    fs.append(tuple(range((len(sections)-1)*per,len(sections)*per)))
    body=mesh('Detailed rolled shell',vs,fs,smooth=True)
    for axle in s['axles']:
        bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=r+.042,depth=3,location=(0,axle,r),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object;bpy.context.view_layer.objects.active=body
        mod=body.modifiers.new('Open wheel arch','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    bevel=body.modifiers.new('Small rolled arch edges','BEVEL');bevel.width=.008;bevel.segments=2
    bevel.limit_method='ANGLE';bevel.angle_limit=.65
    body.modifiers.new('Broad panel normals','WEIGHTED_NORMAL')
    # Curved cabin and glass are sampled from identical surfaces, including screens.
    z0=belt-.015;z1=s['roof_edge'];bw=w-.065;tw=s['roof_width']
    def cabin_width(z):
        t=(z-z0)/(z1-z0);return bw+(tw-bw)*t+.012*math.sin(math.pi*t)
    def side(sign,y,z,offset=.018):return (sign*(cabin_width(z)+offset),y,z)
    def end(front,x,z,offset=.020):
        t=(z-z0)/(z1-z0);lo=s['cabin_front'] if front else s['cabin_rear'];hi=s['roof_front'] if front else s['roof_rear']
        crown=(.036 if sedan else .014)*(1-(x/max(.1,cabin_width(z)))**2)*math.sin(math.pi*t)
        return (x,lo+(hi-lo)*t+(-1 if front else 1)*(offset+crown),z)
    for sign in [-1,1]:
        vs=[];fs=[];cols=12;rows=8
        for j in range(rows+1):
            t=j/rows;z=z0+(z1-z0)*t
            a=s['cabin_front']+(s['roof_front']-s['cabin_front'])*t
            b=s['cabin_rear']+(s['roof_rear']-s['cabin_rear'])*t
            for i in range(cols+1):vs.append(side(sign,a+(b-a)*i/cols,z,0))
        for j in range(rows):
            for i in range(cols):
                a=j*(cols+1)+i;fs.append((a,a+1,a+cols+2,a+cols+1))
        mesh('Curved cabin side',vs,fs,smooth=True)
    for front in [True,False]:
        vs=[];fs=[];cols=12;rows=8
        for j in range(rows+1):
            z=z0+(z1-z0)*j/rows;ww=cabin_width(z)
            for i in range(cols+1):vs.append(end(front,ww*(-1+2*i/cols),z,0))
        for j in range(rows):
            for i in range(cols):
                a=j*(cols+1)+i;fs.append((a,a+1,a+cols+2,a+cols+1))
        mesh('Screen surround shell',vs,fs,smooth=True)
        # Screen edges narrow toward the roof; avoid gaps at the sloped pillars.
        low=z0+.065;high=z1-.055
        coords=rounded([(-cabin_width(low)+.065,low),(cabin_width(low)-.065,low),
            (cabin_width(high)-.055,high),(-cabin_width(high)+.055,high)],.036)
        patch('Curved front screen' if front else 'Curved rear screen',coords,lambda x,z: end(front,x,z),chrome=sedan)
    vs=[];fs=[];cols=16;rows=10
    for j in range(rows+1):
        t=j/rows;y=s['roof_front']+(s['roof_rear']-s['roof_front'])*t
        for i in range(cols+1):
            q=-1+2*i/cols
            vs.append((tw*q,y,z1+s['crown']*(1-q*q)+.012*math.sin(math.pi*t)*(1-q*q)))
    for j in range(rows):
        for i in range(cols):
            a=j*(cols+1)+i;fs.append((a,a+1,a+cols+2,a+cols+1))
    mesh('Compound crowned roof',vs,fs,smooth=True)
    for sign in [-1,1]:
        line('Rolled rain gutter',[(sign*(tw+.004),s['roof_front'],z1),(sign*(tw+.004),s['roof_rear'],z1)],'steel' if sedan else 'paint',.012)
    low=z0+.070;high=z1-.065
    windows=ctx['windows']
    for sign in [-1,1]:
        for idx,(lb,lt,rb,rt) in enumerate(windows):
            coords=rounded([(lb,low),(rb,low),(rt,high),(lt,high)],.035 if sedan else .045)
            patch('Rounded side window '+str(sign)+' '+str(idx),coords,lambda y,z:side(sign,y,z),chrome=sedan)
            # Lower exterior scraper runs outside the black seal.
            line('Window scraper',[side(sign,lb+.02,low-.019,.023),side(sign,rb-.02,low-.019,.023)],'steel' if sedan else 'rubber',.008)
        if rural:
            # Simple front quarterlight split; only one door per side.
            line('Door quarterlight divider',[side(sign,-.56,low,.035),side(sign,-.42,high-.025,.035)],'rubber',.011)
        if sedan:
            line('Rear quarterlight divider',[side(sign,1.14,low,.035),side(sign,.90,high-.018,.035)],'rubber',.011)
        # Seams sample the rolled body; they no longer float at a fixed box width.
        for i,(a,b) in enumerate(ctx['doors']):
            bottom=.45 if sedan else (.57 if rural else .52)
            pts=[(a,belt-.02),(a,bottom+.05),(a+.055,bottom),(b-.12,bottom),(b-.035,bottom+.06),(b,belt-.02)]
            # Rear door corner rises smoothly in front of its wheel opening.
            if i==1:
                pts=[(a,belt-.02),(a,bottom+.05),(a+.055,bottom),(b-.23,bottom),(b-.15,.66),(b-.08,.80),(b,belt-.02)]
            line('Contoured passenger door seam',[lower(sign,y,z,.012) for y,z in rounded(pts,.022,3)],'seam',.0038)
        for i,y in enumerate(ctx['handle_y']):
            z=belt-.09
            box('Handle recessed escutcheon',lower(sign,y,z,.012),(.027,.184,.064),'rubber',.016)
            box('Raised pull handle',lower(sign,y,z+.006,.037),(.036,.140,.026),'steel' if not rural else 'rubber',.010)
            cyl('Door lock',lower(sign,y-.105,z,.023),.013,.012,'steel',vertices=10)
        # Fender rolls, with distinct rural painted arch and SUV flare treatment.
        for axle in s['axles']:
            rr=r+.047;start=math.asin(max(-.9,(bottom-r)/rr))
            pts=[]
            for j in range(25):
                a=start+(math.pi-2*start)*j/24;y=axle+rr*math.cos(a);z=r+rr*math.sin(a)
                pts.append(lower(sign,y,z,.017))
            line('Rolled wheel arch lip',pts,'paint' if not suv else 'rubber',.018 if not suv else .026)
            box('Rubber mud flap',(sign*(w-.06),axle+r+.075,.34 if not sedan else .25),(.22,.025,.22),'rubber',.007)
        # Narrow continuous body pressing, interrupted only by arches.
        z=belt-.185
        for a,b in [(-half+.16,s['axles'][0]-.41),(s['axles'][0]+.41,s['axles'][1]-.41),(s['axles'][1]+.41,half-.16)]:
            if b>a:
                line('Belt protection',[lower(sign,a,z,.015),lower(sign,b,z,.015)],'rubber',.021 if sedan else .013)
                if sedan:line('Belt bright insert',[lower(sign,a,z+.017,.027),lower(sign,b,z+.017,.027)],'steel',.005)
        line('Sill seam',[lower(sign,s['axles'][0]+.42,bottom+.055,.016),lower(sign,s['axles'][1]-.42,bottom+.055,.016)],'rubber',.012)
        # Fuel hatch and small side marker, asymmetric in real assembly.
        if sign==1:
            y=s['axles'][1]+.25
            hatch=rounded([(y-.075,belt-.15),(y+.075,belt-.15),(y+.075,belt-.015),(y-.075,belt-.015)],.018,3)
            line('Fuel hatch gap',[lower(sign,a,z,.012) for a,z in hatch],'seam',.0035,True)
        box('Wing repeater',lower(sign,s['axles'][0]+.18,belt-.13,.025),(.022,.075,.035),'amber',.008)
        # Exterior hinge blocks on both real SUV doors, never a phantom third door.
        if suv:
            for y in [-.87,.20]:
                for z in [.71,1.04]:
                    box('External hinge leaf',lower(sign,y,z,.028),(.055,.075,.037),'paint',.006)
                    box('Hinge knuckle',lower(sign,y-.028,z,.047),(.040,.023,.067),'steel',.008)
        # Proper mirror mount and inset reflective face.
        y=s['cabin_front']+.12
        box('Mirror mount',side(sign,y,belt+.08,.025),(.05,.13,.11),'rubber',.015)
        mx=w+(.022 if rural else .070)
        line('Mirror stalk',[side(sign,y,belt+.13,.025),(sign*(mx-.015),y,belt+.16)],'rubber',.012)
        box('Rounded mirror housing',(sign*mx,y,belt+.19),(.09 if rural else .13,.19,.13),'paint' if sedan else 'rubber',.026)
        box('Mirror reflective inset',(sign*mx,y+.099,belt+.19),(.070 if rural else .105,.012,.095),'glass',.018)
    # Radial dishes, real ventilation holes, layered rim lips and hub hardware.
    for sign in [-1,1]:
        for axle in s['axles']:
            track=target['tracks'][0 if axle==s['axles'][0] else 1]
            outside=track/2+target['tire_width']/2-.019
            seg=32
            profile=[(.98*r,0),(.85*r,.012),(.70*r,.017),(.67*r,.029),(.60*r,.034),(.42*r,.008),(.20*r,.027),(0,.030)]
            # Only the metal dish, not the tire: outer metal radius is .68r.
            rrim=target['rim_radius']
            profile=[(rrim,0),(rrim*.97,.018),(rrim*.88,.027),(rrim*.63,.012),(rrim*.32,.031),(0,.034)]
            vs=[];fs=[]
            for rr,dx in profile:
                for j in range(seg):
                    a=2*math.pi*j/seg;vs.append((sign*(outside+dx),axle+rr*math.cos(a),r+rr*math.sin(a)))
            for k in range(len(profile)-1):
                for j in range(seg):
                    a=k*seg+j;b=k*seg+(j+1)%seg;fs.append((a,b,b+seg,a+seg))
            dish=mesh('Contoured ventilated wheel',vs,fs,'steel',True)
            # A thin solidify makes an honest open rim suitable for boolean vents.
            bpy.context.view_layer.objects.active=dish
            mod=dish.modifiers.new('Wheel plate thickness','SOLIDIFY');mod.thickness=.009
            bpy.ops.object.modifier_apply(modifier=mod.name)
            holes=8 if rural else 5
            for j in range(holes):
                a=2*math.pi*j/holes;rr=rrim*.70
                bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r*(.070 if rural else .105),depth=.18,
                    location=(sign*(outside+.02),axle+rr*math.cos(a),r+rr*math.sin(a)),rotation=(0,math.pi/2,0))
                cutter=bpy.context.object
                # Oval cast openings on luxury wheels, round perforations on steel wheels.
                if not rural:cutter.scale.y=1.35
                bpy.context.view_layer.objects.active=dish
                mod=dish.modifiers.new('Open rim vent','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter;mod.solver='EXACT'
                bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
            cyl('Dark brake behind openings',(sign*(outside-.024),axle,r),r*.58,.014,'rubber')
            cyl('Domed centre hub',(sign*(outside+.040),axle,r),r*.205,.036,'steel')
            for j in range(5):
                a=2*math.pi*j/5
                cyl('Hex wheel bolt',(sign*(outside+.042),axle+r*.285*math.cos(a),r+r*.285*math.sin(a)),.011,.016,'steel',vertices=6)
            # Fine bead rings pick up a controlled highlight around the tire edge.
            for rr in [r*.69,r*.86]:
                pts=[(sign*(outside-.003),axle+rr*math.cos(2*math.pi*j/32),r+rr*math.sin(2*math.pi*j/32)) for j in range(32)]
                line('Tire bead ring',pts,'rubber',.004,True)
    # Crown decks meet shoulder height at their edges and roll over the nose.
    def deck_z(y,x,front=True):
        a=-half+.07 if front else s['cabin_rear'];b=s['cabin_front'] if front else half-.07
        t=max(0,min(1,(y-a)/max(.001,b-a)));q=x/(w-.065)
        crown=.048 if sedan else .023
        longitudinal=.027*math.sin(math.pi*t)
        return top(y)+(crown+longitudinal)*max(0,1-q*q)
    for front in [True,False]:
        a=-half+.07 if front else s['cabin_rear'];b=s['cabin_front'] if front else half-.07
        if b-a<.07:continue
        vs=[];fs=[];cols=16;rows=10
        for j in range(rows+1):
            y=a+(b-a)*j/rows
            for i in range(cols+1):
                x=side_width(y,belt)*(-1+2*i/cols);vs.append((x,y,deck_z(y,x,front)))
        for j in range(rows):
            for i in range(cols):
                v=j*(cols+1)+i;fs.append((v,v+1,v+cols+2,v+cols+1))
        mesh('Shaped bonnet' if front else 'Shaped boot',vs,fs,smooth=True)
        for sign in [-1,1]:
            x=sign*(w-.17)
            line('Deck panel gap',[(x,a+.045,deck_z(a+.045,x,front)+.005),(x,b-.025,deck_z(b-.025,x,front)+.005)],'seam',.003)
        if front:
            for i in range(8):
                x=-.28+i*.08;y=b-.10
                line('Cowl ventilation slot',[(x,y-.055,deck_z(y-.055,x)+.006),(x,y+.025,deck_z(y+.025,x)+.006)],'rubber',.004)
            if suv or rural:
                for sign in [-1,1]:
                    x=sign*.42
                    line('Bonnet pressed rib',[(x,a+.20,deck_z(a+.20,x)+.009),(x,b-.22,deck_z(b-.22,x)+.009)],'paint',.009)
    # Rounded layered bumpers and their corner returns, sized to the body.
    for front in [True,False]:
        direction=-1 if front else 1;y=direction*half;z=.49 if sedan else .55
        box('Shaped bumper main',(0,y,z),(s['width']-.02,.16,.17 if sedan else .14),'paint' if sedan else 'rubber',.045)
        box('Bumper impact strip',(0,y+direction*.087,z+.018),(s['width']-.10,.025,.052),'rubber',.016)
        for sign in [-1,1]:
            box('Bumper corner return',(sign*(w-.035),y-direction*.12,z),(.10,.30,.14),'paint' if sedan else 'rubber',.030)
        if not sedan:box('Brushed bumper insert',(0,y+direction*.103,z-.012),(s['width']-.27,.017,.050),'steel',.009)
        box('Blank number plate',(0,y+direction*.107,z+.006),(.34,.014,.09),'steel',.006)
        if sedan:
            line('Bumper bright upper lip',[(-w+.12,y+direction*.081,z+.073),(w-.12,y+direction*.081,z+.073)],'steel',.007)
    fy=-half+.012
    # A framed grille, varied apertures and inset lenses replace bright cubes.
    gw=.73 if suv else (.78 if sedan else 1.40);gz=belt-.155;gh=.245 if not rural else .265
    box('Grille metal frame',(0,fy-.018,gz),(gw+.055,.055,gh+.040),'steel' if not rural else 'rubber',.020)
    box('Grille recessed mesh',(0,fy-.050,gz),(gw,.020,gh),'rubber',.014)
    for j in range(5 if sedan else 4):
        z=gz-gh*.40+j*(gh*.8/(4 if sedan else 3))
        box('Grille horizontal bar',(0,fy-.068,z),((gw-.035) if not rural else .90,.013,.008),'steel' if not rural else 'seam',.002)
    for x in [-gw*.25,0,gw*.25]:box('Grille vertical rib',(x,fy-.064,gz),(.009,.012,gh-.025),'steel' if sedan else 'seam',.002)
    for sign in [-1,1]:
        x=sign*(.64 if not rural else .59);z=belt-.145
        if rural:
            cyl('Headlight rubber bowl',(x,fy-.012,z),.143,.046,'rubber','Y',28)
            cyl('Headlight bright rim',(x,fy-.042,z),.124,.026,'steel','Y',28)
            cyl('Headlight inset lens',(x,fy-.058,z),.109,.018,'lamp','Y',28)
            for dx in [-.055,-.027,0,.027,.055]:
                h=math.sqrt(max(0,.100**2-dx*dx))
                line('Headlight lens flute',[(x+dx,fy-.070,z-h),(x+dx,fy-.070,z+h)],'steel',.002)
        else:
            hw=.37 if sedan else .255;hh=.235
            box('Headlight rubber housing',(x,fy-.006,z),(hw+.034,.060,hh+.025),'rubber',.025)
            box('Headlight rim',(x,fy-.041,z),(hw,.024,hh),'steel',.020)
            box('Headlight inset lens',(x,fy-.057,z),(hw-.030,.016,hh-.028),'lamp',.017)
            for j in range(5):
                xx=x-hw*.32+j*hw*.16
                line('Headlight lens flute',[(xx,fy-.067,z-hh*.34),(xx,fy-.067,z+hh*.34)],'steel',.002)
            if sedan:box('Headlight internal divider',(x+sign*.035,fy-.069,z),(.008,.008,hh-.04),'rubber',.002)
        ix=sign*(w-.10) if not rural else sign*.60
        iz=z if not rural else z+.218
        box('Front signal rubber bezel',(ix,fy-.012,iz),(.105 if not rural else .17,.050,.17 if not rural else .088),'rubber',.009)
        box('Front signal lens',(ix,fy-.042,iz),(.085 if not rural else .13,.020,.145 if not rural else .060),'amber',.008)
        # Low fog lamps and an actual lower intake on luxury vehicles.
        if not rural:
            box('Fog lamp bezel',(sign*.62,-half-.088,.48 if sedan else .54),(.20,.025,.10),'rubber',.012)
            box('Fog lamp lens',(sign*.62,-half-.106,.48 if sedan else .54),(.156,.014,.067),'lamp',.009)
        if sedan:
            # Broad W140-type cluster with a sloped inner edge and a real corner return.
            def inner(z):return references['interpolate']([(.705,.34),(.780,.34),(.805,.47),(.972,.59)],z)
            def lamp_map(x,z,offset=.012):
                xx=abs(x);cr=.22
                side_max=side_width(half-.12,z)
                cx=side_max-cr
                dx=max(0,min(cr-.001,xx-cx))
                yy=half-.07-cr+math.sqrt(cr*cr-dx*dx)
                return (x,yy+offset,z)
            outer=.897
            outline=[(sign*inner(.705),.705),(sign*outer,.705),(sign*outer,.972),(sign*inner(.972),.972),
                (sign*inner(.805),.805),(sign*inner(.780),.780)]
            patch('Contoured rear lamp gasket',rounded(outline,.012,3),lambda x,z:lamp_map(x,z,.008),'rubber',False)
            for lo,hi,color in [(.713,.785,'lamp'),(.792,.898,'red'),(.905,.964,'amber')]:
                poly=[(sign*(inner(lo)+.009),lo),(sign*(outer-.008),lo),(sign*(outer-.008),hi),(sign*(inner(hi)+.009),hi)]
                if lo<.780<hi:poly.append((sign*(inner(.780)+.009),.780))
                patch('Shaped rear lens '+color,rounded(poly,.007,3),lambda x,z:lamp_map(x,z,.018),color,False)
            for zz in [.735,.762,.820,.847,.874,.930]:
                line('Rear lens horizontal flute',[lamp_map(sign*(inner(zz)+.016+(outer-inner(zz)-.028)*j/12),zz,.022) for j in range(13)],
                    'red' if .79<zz<.9 else ('lamp' if zz<.79 else 'amber'),.0028)
        else:
            tz=.85;tx=sign*(w-.16);ty=half-.008;hw=.145;hh=.31
            box('Rear lamp gasket',(tx,ty,tz),(hw+.035,.065,hh+.025),'rubber',.014)
            for j,color in enumerate(['amber','red','lamp']):
                zz=tz+hh*(.31-j*.31)
                box('Segmented rear lens',(tx,ty+.041,zz),(hw,.020,hh*.27),color,.007)
        # Real two-piece wiper follows the curved glass plane.
        line('Wiper arm',[end(True,sign*.12,belt+.09,.042),end(True,sign*.45,belt+.19,.042)],'rubber',.007)
        line('Wiper blade',[end(True,sign*.32,belt+.16,.045),end(True,sign*.66,belt+.24,.045)],'rubber',.009)
    if not rural:
        box('Lower cooling intake',(0,-half-.087,.39 if sedan else .48),(.83,.018,.095),'rubber',.010)
        for j in [-1,0,1]:box('Lower intake rib',(j*.21,-half-.101,.39 if sedan else .48),(.011,.012,.078),'seam',.002)
    # Tailgate closures and period roof stampings visible from the map.
    if suv:
        cyl('Spare steel dish',(0,half+.223,1.13),r*.66,.022,'steel','Y',28)
        cyl('Spare dish recess',(0,half+.238,1.13),r*.48,.012,'rubber','Y',28)
        cyl('Spare central hub',(0,half+.250,1.13),r*.24,.026,'steel','Y',24)
        outline=rounded([(-.74,.76),(.74,.76),(.74,1.74),(-.74,1.74)],.045)
        line('Rear tailgate gap',[(x,half+.004,z) for x,z in outline],'seam',.004,True)
        for z in [.88,1.62]:box('Rear tailgate hinge',(.77,half+.023,z),(.09,.055,.04),'steel',.008)
        for x in [-.46,-.23,0,.23,.46]:
            line('Roof pressed strengthening rib',[(x,s['roof_front']+.28,z1+s['crown']*(1-(x/tw)**2)+.017),
                (x,s['roof_rear']-.22,z1+s['crown']*(1-(x/tw)**2)+.017)],'paint',.010)
    elif rural:
        coords=rounded([(-.70,.77),(.70,.77),(.70,1.53),(-.70,1.53)],.045)
        line('Rural rear hatch gap',[(x,min(half-.025,end(False,x,z,.027)[1]),z) for x,z in coords],'seam',.004,True)
        box('Rear hatch handle',(0,half-.13,1.00),(.14,.045,.03),'rubber',.009)
    else:
        line('Boot trailing gap',[(-.72,half-.105,belt+.006),(.72,half-.105,belt+.006)],'seam',.003)
    # Correct tire centre lines and section widths from the specified track.
    for ob in list(scene.objects):
        if ob.type!='MESH' or not ob.name.startswith('Tire '):continue
        sign=-1 if '-1 ' in ob.name else 1
        axle_index=0 if ob.name.split('.')[0].endswith(' 0') else 1
        track=target['tracks'][axle_index]
        old_width=.225 if sedan else .205
        for v in ob.data.vertices:
            v.co.x=sign*track/2+(v.co.x-sign*(w-.065))*target['tire_width']/old_width
    # Front lamps and grille follow the revised nose height; bumpers keep their own height.
    for ob in list(scene.objects):
        if any(ob.name.startswith(p) for p in ['Headlight','Front signal','Grille ']):
            ob.location.z+=top(-half+.07)-belt
        if ob.name.startswith('Bonnet wing indicator'):
            ob.location.z=top(ob.location.y)+.04
    root['stage']='Revision v5: lower SUV glazing, dark burgundy, contoured rear lenses, raised Niva body; pending review'
    root['target_overall_length_m']=target['overall_length']
    root['target_body_width_m']=target['body_width']
    root['target_height_m']=target['height']
    root['tracks_m']=target['tracks']
    print('REFINED',key,'objects',len(scene.objects))

for key,old_spec in source['SPECS'].items():
    s={**old_spec,**TARGETS[key]}
    scene,root,ctx=source['build'](key,s)
    ctx['windows']=s['windows'];ctx['doors']=s['doors'];ctx['handle_y']=s['handles']
    refine(key,s,scene,root,ctx)
    if key=='luxury_suv':
        runpy.run_path(str(HERE/'refine_suv.py'))['refine_suv'](scene,root,s,ctx)
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'vehicle_trio_detailed.blend'))
