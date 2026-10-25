#!/usr/bin/env python3
"""Call the App Store Connect JSON API using existing ASC_* credentials."""

import argparse
import base64
import json
import os
from pathlib import Path
import shlex
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HOST = 'https://api.appstoreconnect.apple.com'
CONFIG_KEYS = ('ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_FILEPATH')


def credentials(env_file):
    config = {key: os.environ[key] for key in CONFIG_KEYS if os.environ.get(key)}
    if env_file.is_file():
        for line in env_file.read_text().splitlines():
            if '=' not in line or line.lstrip().startswith('#'):
                continue
            name, value = line.split('=', 1)
            name = name.strip().removeprefix('export ').strip()
            if name in CONFIG_KEYS and name not in config:
                fields = shlex.split(value, comments=True)
                if fields:
                    config[name] = fields[0]
    missing = [key for key in CONFIG_KEYS if not config.get(key)]
    if missing:
        raise ValueError('Missing credential settings: ' + ', '.join(missing))
    return config


def jwt(config):
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec, utils

    key_path = Path(os.path.expandvars(config['ASC_KEY_FILEPATH'])).expanduser()
    key = serialization.load_pem_private_key(key_path.read_bytes(), password=None)

    def encode(value):
        return base64.urlsafe_b64encode(value).rstrip(b'=')

    now = int(time.time())
    header = {'alg': 'ES256', 'kid': config['ASC_KEY_ID'], 'typ': 'JWT'}
    claims = {'iss': config['ASC_ISSUER_ID'], 'iat': now - 30, 'exp': now + 900, 'aud': 'appstoreconnect-v1'}
    unsigned = encode(json.dumps(header).encode()) + b'.' + encode(json.dumps(claims).encode())
    r, s = utils.decode_dss_signature(key.sign(unsigned, ec.ECDSA(hashes.SHA256())))
    return (unsigned + b'.' + encode(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))).decode()


def api_url(endpoint):
    parsed = urllib.parse.urlsplit(endpoint)
    if parsed.scheme or parsed.netloc or parsed.fragment or not parsed.path.startswith(('/v1/', '/v2/')):
        raise ValueError('Use a relative /v1/ or /v2/ App Store Connect endpoint')
    return HOST + endpoint


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        raise urllib.error.URLError('Unexpected API redirect; request not followed')


def request(method, endpoint, config, payload=None):
    url = api_url(endpoint)
    token = jwt(config)
    req = urllib.request.Request(
        url, method=method,
        headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
        data=json.dumps(payload).encode() if payload is not None else None,
    )
    # Never automatically repeat mutations after an uncertain network outcome.
    with urllib.request.build_opener(NoRedirect()).open(req, timeout=45) as response:
        raw = response.read()
        return response.status, json.loads(raw) if raw else {'status': response.status}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('method', choices=('GET', 'POST', 'PATCH', 'DELETE'))
    parser.add_argument('endpoint', help='Relative /v1/ or /v2/ endpoint, including query parameters')
    parser.add_argument('--body-file', type=Path, help='JSON request payload file')
    parser.add_argument('--output', type=Path, help='Save response JSON; use AppStore/private/ for operational records')
    parser.add_argument('--env-file', type=Path, default=Path.home() / '.env')
    args = parser.parse_args(argv)
    try:
        api_url(args.endpoint)
        if args.method == 'GET' and args.body_file:
            raise ValueError('GET requests must not contain a body')
        payload = json.loads(args.body_file.read_text()) if args.body_file else None
        status, result = request(args.method, args.endpoint, credentials(args.env_file), payload)
        content = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(content)
            print(f'HTTP {status}; response saved to {args.output}')
        else:
            print(content, end='')
        return 0
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            errors = json.loads(raw).get('errors', [])
        except (ValueError, AttributeError):
            errors = [{'detail': 'Non-JSON API error response'}]
        print(json.dumps({'status': error.code, 'errors': errors}, ensure_ascii=False), file=sys.stderr)
    except urllib.error.URLError:
        print('API request failed. The outcome may be unknown; read the current API state before retrying a mutation.', file=sys.stderr)
    except ModuleNotFoundError:
        print('Python dependency missing: cryptography. Use a Python runtime that provides it.', file=sys.stderr)
    except (OSError, ValueError) as error:
        print(f'Configuration or input error: {type(error).__name__}. Check the environment settings, key path and JSON input.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
