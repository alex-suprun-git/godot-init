"""Executed inside Blender by blender_mcp.py start, with three injected paths/IDs."""
from datetime import datetime, timezone
import json
from pathlib import Path
import traceback
import bpy

script_path = Path(SCRIPT_PATH)
status_path = Path(STATUS_PATH)
job_id = JOB_ID


def update(state, **details):
    status_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {'job_id': job_id, 'script': str(script_path), 'state': state,
               'updated_at': datetime.now(timezone.utc).isoformat(), **details}
    pending = status_path.with_name(status_path.name + '.tmp')
    pending.write_text(json.dumps(payload, indent=2) + '\n')
    pending.replace(status_path)


def work():
    update('running')
    try:
        namespace = {'__name__': '__main__', '__file__': str(script_path), 'job_checkpoint': update}
        exec(compile(script_path.read_text(), str(script_path), 'exec'), namespace)
    except Exception:
        update('error', traceback=traceback.format_exc())
    else:
        update('complete')
    return None


update('queued')
bpy.app.timers.register(work, first_interval=.5)
print(json.dumps({'job_id': job_id, 'status_file': str(status_path), 'state': 'queued'}))
