#!/usr/bin/env python3
"""Start the pinned server with only its required environment and private credentials."""
import json
import os
from pathlib import Path
import stat
import sys
from urllib.parse import urlsplit

root = Path(__file__).resolve().parent
path = root.parents[1] / '.encrypted' / 'caldav.json'
try:
    info = path.stat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) & 0o077:
        raise ValueError('.encrypted/caldav.json must be owned by you and chmod 600')
    config = json.loads(path.read_text())
    url = urlsplit(config['url'])
    if url.scheme != 'https' or not url.hostname or url.username or url.password:
        raise ValueError('Use an HTTPS CalDAV URL without embedded credentials')
    if not config['username'] or not config['password']:
        raise ValueError('Fill in username and app password in .encrypted/caldav.json')
    env = {k: os.environ[k] for k in ('HOME', 'PATH', 'LANG') if k in os.environ}
    env.update(CALDAV_PERSONAL_URL=config['url'], CALDAV_PERSONAL_USER=config['username'],
               CALDAV_PERSONAL_PASS=config['password'], CALENDAR_TIMEZONE_MODE=config.get('timezone', 'auto'),
               CALENDAR_TIMEZONE_FALLBACK=config.get('timezone_fallback', ''),
               CALENDAR_SUBSCRIPTION_ORIGINS=json.dumps(config.get('allowed_subscription_origins', [])))
    if os.environ.get('TZ'):
        env['TZ'] = os.environ['TZ']
    os.chdir(root)
    os.execve('/usr/bin/node', ['/usr/bin/node', str(root / 'server.mjs')], env)
except (OSError, ValueError, KeyError) as error:
    print(f'Calendar MCP setup: {error}', file=sys.stderr)
    sys.exit(1)
