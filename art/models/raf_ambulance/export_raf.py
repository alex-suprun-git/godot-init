from pathlib import Path
import runpy
helper=Path(__file__).resolve().parents[1]/'uaz_service/export_vehicle.py'
runpy.run_path(str(helper))['export']('raf')
