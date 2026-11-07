"""Apply the agreed10% area reduction from a preserved100% layout, idempotently.
Source road widths and all building dimensions stay fixed. Pure data preparation.
"""
from pathlib import Path
import json,math,re
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
LAYOUT=ROOT/'init/scripts/data/district_layout.gd'
CHURCH=ROOT/'init/scripts/data/church_site.json'
BASE=HERE/'layout_before_compaction.json'
S=math.sqrt(.9);ANCHOR=(150.,-75.)
def point(v):return [round(ANCHOR[i]+(float(v[i])-ANCHOR[i])*S,4) for i in range(2)]
def rect(v,road=False):
    x,y,w,d=v
    if road:
        c=point([x+w/2,y+d/2]);nw,nd=(w*S,d) if w>d else (w,d*S)
        return [round(c[0]-nw/2,4),round(c[1]-nd/2,4),round(nw,4),round(nd,4)]
    return point(v[:2])+[round(w*S,4),round(d*S,4)]
def values(raw):return [float(x.strip()) for x in raw.split(',')]
text=LAYOUT.read_text(encoding='utf-8')
if 'village_south_exit' in text:
    print('Compaction already applied; preserve the subsequently packed frontages and new exit.')
    raise SystemExit(0)
if not BASE.exists():
    lines=[]
    in_lots=False
    for line in text.splitlines():
        if line.startswith('const LOTS'):in_lots=True
        elif in_lots and line=='}':in_lots=False
        selected=(in_lots and re.search(r'"(?:d_\d+|church|cemetery|pond_bank|village_shop)":',line))
        selected=selected or ('"id": "village_' in line and '"kind": "dirt"' in line)
        selected=selected or '"village": {"rect":' in line or '"rects": [Rect2(150, -80, 245, 375)]' in line
        selected=selected or '"church_cemetery":' in line or ('"pond": {"rect":' in line)
        if selected:lines.append(line)
    BASE.write_text(json.dumps({'area_factor':.9,'anchor':ANCHOR,'layout_lines':lines,'church':json.loads(CHURCH.read_text())},indent=2)+'\n',encoding='utf-8')
base=json.loads(BASE.read_text());changes=[]
for source in base['layout_lines']:
    target=source
    target=re.sub(r'Rect2\(([^)]+)\)',lambda m:'Rect2('+', '.join(str(v) for v in rect(values(m[1]),'"kind": "dirt"' in source))+')',target)
    target=re.sub(r'Vector2\(([^)]+)\)',lambda m:'Vector2('+', '.join(str(v) for v in point(values(m[1])))+')',target)
    # Match by the stable ID prefix rather than old numerical coordinates.
    if '"id":' in source:
        id=re.search(r'"id": "([^"]+)"',source)[1];pattern=r'^.*"id": "'+id+r'".*$'
    elif '"rects":' in source:pattern=r'^\s*"rects": \[Rect2\(150(?:\.0)?, -80(?:\.0)?,.*$'
    else:
        prefix=source.split('Rect2(')[0];pattern=r'^'+re.escape(prefix)+r'.*$'
    matches=list(re.finditer(pattern,text,re.MULTILINE))
    if not matches and '"rects":' in source:
        # The village district is the only rect-list beginning with our compressed west edge.
        start=text.index('\t"village": {',text.index('const DISTRICTS'))
        a=text.index('\t\t"rects":',start);b=text.index('\n',a);text=text[:a]+target+text[b:];continue
    if len(matches)!=1:raise RuntimeError('Ambiguous layout record: '+source)
    m=matches[0];text=text[:m.start()]+target+text[m.end():]
text=text.replace('Additional homes use previously empty frontage; all existing roads stay fixed.','Additional homes use previously empty frontage; the village is compacted10% in area.')
LAYOUT.write_text(text,encoding='utf-8')
p=base['church']
for id in ['church','parish_house','shed']:
    p[id]['center']=point(p[id]['center'])
    if 'entrance' in p[id]:p[id]['entrance']=point(p[id]['entrance'])
p['perimeter']=[point(v) for v in p['perimeter']]
p['gate']['center']=point(p['gate']['center']);p['gate']['pedestrian_entry']=point(p['gate']['pedestrian_entry'])
p['paths']=[point(v[:2])+point(v[2:4])+v[4:] for v in p['paths']]
for key in ['trees','benches','flowerbeds']:p[key]=[point(v[:2])+v[2:] for v in p[key]]
CHURCH.write_text(json.dumps(p,indent=2)+'\n',encoding='utf-8')
print('VILLAGE_AREA_COMPACTION',240*370,'->',240*370*S*S,'m2; placement scale',S,'; road widths and model dimensions unchanged')
