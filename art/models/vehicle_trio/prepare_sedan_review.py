"""Prepare the matched pre-rebuild/current sedan comparison using shared studio."""
from pathlib import Path
import shutil, runpy
HERE=Path(__file__).resolve().parent
runpy.run_path(str(HERE/'prepare_preview.py'))
target=HERE/'preview_project'
before=HERE.parents[2]/'.local/vehicle_trio/sedan-before-v2/luxury_sedan.glb'
shutil.copy2(before,target/'models/luxury_sedan_before.glb')
text=(target/'review_suv.gd').read_text()
text=text.replace('luxury_suv_before','luxury_sedan_before').replace('luxury_suv','luxury_sedan')
text=text.replace('SUV SHAPE REWORK / SAME SCALE, CAMERAS AND LIGHTING','LUXURY SEDAN / RECONSTRUCTION FROM NEW REFERENCE SHEET')
text=text.replace('BEFORE / v5','BEFORE / previous sedan').replace('AFTER / fresh reference v3, model v6','AFTER / new sedan v2')
text=text.replace('New front / round lamps, square pods, raised bonnet and angular flares','New front and rear / seated optics, integrated bumper covers')
(target/'review_sedan_v2.gd').write_text(text)
(target/'review_sedan_v2.tscn').write_text((target/'review_suv.tscn').read_text().replace('review_suv.gd','review_sedan_v2.gd'))
