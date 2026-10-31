# /// script
# requires-python = ">=3.11"
# dependencies = ["mcp==1.30.0"]
# ///
"""Use the configured Blender MCP from this checkout, including queued jobs.

Run with: uv run --script tools/blender_mcp.py --help
"""
import argparse
import asyncio
import base64
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sys
import tempfile
import tomllib
import uuid

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

PROJECT = Path(__file__).resolve().parents[1]


def script_code(script, **extra):
    path = str(Path(script).resolve())
    namespace = {'__name__': '__main__', '__file__': path, **extra}
    return f"exec(compile(open({path!r}, encoding='utf-8').read(), {path!r}, 'exec'), {namespace!r})"


def server_parameters(name, config_path):
    global_path = config_path or Path(os.environ.get('CODEX_HOME', Path.home() / '.codex')) / 'config.toml'
    entry = {}
    paths = [Path(global_path)]
    if not config_path:
        paths.append(PROJECT / '.codex/config.toml')
    for path in paths:
        if path.is_file():
            config = tomllib.loads(path.read_text())
            entry.update(config.get('mcp_servers', {}).get(name, {}))
    if not entry or not entry.get('enabled', True):
        raise ValueError(f'No enabled MCP server named {name!r} in the Codex configuration.')
    if 'command' not in entry:
        raise ValueError('This helper supports the local STDIO Blender MCP configuration.')
    return StdioServerParameters(command=entry['command'], args=entry.get('args', []),
                                 env=entry.get('env'), cwd=entry.get('cwd'))


def print_result(result, output_dir, tool_name):
    failed = bool(result.isError)
    for index, block in enumerate(result.content):
        if block.type == 'text':
            print(block.text, flush=True)
            if block.text.startswith(('Error executing code:', 'Error checking addon status:',
                                      'Error getting scene info:', 'Could not determine addon status.')):
                failed = True
        elif block.type == 'image':
            output_dir.mkdir(parents=True, exist_ok=True)
            stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')
            suffix = '.jpg' if block.mimeType == 'image/jpeg' else '.png'
            image = output_dir / f'{tool_name}-{stamp}-{index}-{uuid.uuid4().hex[:6]}{suffix}'
            image.write_bytes(base64.b64decode(block.data))
            print(f'IMAGE: {image.resolve()}', flush=True)
    return 1 if failed else 0


async def connect_and_call(args):
    params = server_parameters(args.server, args.config)
    with tempfile.NamedTemporaryFile(mode='w+', prefix='blender-mcp-', suffix='.log', delete=False) as log:
        try:
            async with asyncio.timeout(args.timeout):
                async with stdio_client(params, errlog=log) as (reader, writer):
                    async with ClientSession(reader, writer) as client:
                        await client.initialize()
                        if args.action == 'list':
                            result = await client.list_tools()
                            for tool in result.tools:
                                if args.tool is None or tool.name == args.tool:
                                    print(json.dumps({'name': tool.name, 'description': tool.description,
                                                      'schema': tool.inputSchema}, ensure_ascii=False))
                            return 0
                        if args.action == 'status':
                            name, payload = 'get_addon_status', {}
                        elif args.action == 'call':
                            name, payload = args.tool, json.loads(args.json.read_text())
                        else:
                            name = 'execute_blender_code'
                            if args.action == 'run':
                                code = script_code(args.script)
                            else:
                                status = (args.status_file or args.script.with_suffix('.job.json')).resolve()
                                code = script_code(Path(__file__).with_name('blender_job_runner.py'),
                                                   SCRIPT_PATH=str(args.script.resolve()),
                                                   STATUS_PATH=str(status), JOB_ID=uuid.uuid4().hex)
                                print(f'JOB STATUS: {status}', flush=True)
                            payload = {'code': code}
                        if args.user_prompt:
                            payload['user_prompt'] = args.user_prompt
                        result = await client.call_tool(name, payload)
                        return print_result(result, args.output_dir, name)
        except Exception:
            print(f'MCP log: {log.name}', file=sys.stderr)
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, help='Override the Codex config file')
    parser.add_argument('--server', default='blender')
    parser.add_argument('--timeout', type=float, default=45, help='Client timeout; does not cancel Blender work')
    parser.add_argument('--output-dir', type=Path, default=PROJECT / 'art/previews/blender')
    parser.add_argument('--user-prompt', default='', help="The user's original request, quoted verbatim")
    sub = parser.add_subparsers(dest='action', required=True)
    sub.add_parser('status')
    listing = sub.add_parser('list')
    listing.add_argument('--tool', help='Only show this tool definition')
    call = sub.add_parser('call')
    call.add_argument('tool')
    call.add_argument('--json', required=True, type=Path, help='Tool arguments as a JSON file')
    run = sub.add_parser('run', help='Run a short Blender Python script synchronously')
    run.add_argument('script', type=Path)
    start = sub.add_parser('start', help='Queue a long script and write durable job status')
    start.add_argument('script', type=Path)
    start.add_argument('--status-file', type=Path)
    status = sub.add_parser('job-status', help='Read a job status file without contacting Blender')
    status.add_argument('path', type=Path)
    args = parser.parse_args()
    if args.action == 'job-status':
        data = json.loads(args.path.read_text())
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return 1 if data.get('state') == 'error' else 0
    return asyncio.run(connect_and_call(args))


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except TimeoutError:
        print('MCP timed out. Blender may still be running the operation; inspect job status before retrying.', file=sys.stderr)
        raise SystemExit(2)
