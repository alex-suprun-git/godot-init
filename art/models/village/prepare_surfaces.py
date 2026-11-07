"""Extract the nine source tiles and author subtle portable technical maps.
No image source is overwritten; optimizer preparation is a separate stage.
"""
from pathlib import Path
import bpy, numpy as np
ROOT=Path(__file__).resolve().parents[3]
HERE=ROOT/'art/source_images/village'
names=['rural_grass','compacted_gravel','buff_brick','house_plaster','grey_roof','timber_boards','garden_soil','yard_concrete','fence_steel']
im=bpy.data.images.load(str(HERE/'materials-v1.png'),check_existing=False)
w,h=im.size;p=np.empty(w*h*4,dtype=np.float32);im.pixels.foreach_get(p);p=p.reshape(h,w,4)
for i,name in enumerate(names):
    col=i%3;row=2-i//3
    a=p[row*(h//3):(row+1)*(h//3),col*(w//3):(col+1)*(w//3)].copy();th,tw=a.shape[:2]
    def save(suffix,pixels,data=False):
        out=bpy.data.images.new(name+suffix,width=tw,height=th,alpha=True)
        if data:out.colorspace_settings.name='Non-Color'
        out.pixels.foreach_set(pixels.ravel());out.file_format='PNG';out.filepath_raw=str(HERE/(name+suffix+'.png'));out.save()
    save('',a)
    yy,xx=np.mgrid[0:th,0:tw].astype(np.float32)
    grain=(np.sin(xx*1.83+np.sin(yy*.65))+np.sin(yy*2.03+xx*.43))*.5
    height=grain*(.00012 if name in ['grey_roof','fence_steel'] else .0005)
    dy,dx=np.gradient(height,2/th,2/tw);n=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
    normal=np.ones_like(a);normal[:,:,:3]=n*.5+.5;save('_normal',normal,True)
    rough=np.ones_like(a);r=.72 if name in ['grey_roof','fence_steel'] else .9
    rough[:,:,:3]=np.clip(r+grain[:,:,None]*.025,0,1);save('_roughness',rough,True)
    print('SURFACE_SOURCE',name,tw,th,flush=True)
