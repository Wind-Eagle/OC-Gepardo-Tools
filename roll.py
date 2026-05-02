#!/usr/bin/env python3
import tomllib
import sys
import shutil
from pathlib import Path
from typing import Any
from collections.abc import Callable
import re


def ensure(src: dict[str, Any], key: str, ty: type, default: Callable[[], Any] | None = None) -> Any:
    if key not in src:
        if default is None:
            raise Exception(f'key not found: {key!r}')
        val = default()
    else:
        val = src[key]
    if not isinstance(val, ty):
        raise Exception(f'bad type for {key!r}: expected {ty.__name__}, got {type(val).__name__}')
    return val


def ensure_list(src: dict[str, Any], key: str, ty: type, default: Callable[[], Any] | None = None) -> list[Any]:
    val = ensure(src, key, list, default=default)
    for idx, item in enumerate(val):
        if not isinstance(item, ty):
            raise Exception(f'bad type for {key!r}, item {idx}: expected {ty.__name__}, got {type(item).__name__}')
    return val


UUID_RE = re.compile('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')


preset = None
if len(sys.argv) > 2:
    print('error: too many arguments')
    print(f'usage: {sys.argv[0] if len(sys.argv) > 0 else "roll.py"} [PRESET]')
    sys.exit(1)
if len(sys.argv) == 2:
    preset = sys.argv[1]

repo = Path.cwd().resolve(strict=True)
while True:
    if (repo / '.git').is_dir():
        break
    parent = repo.parent
    if parent == repo:
        raise Exception('not a git repo!')
    repo = parent

with (repo / 'roll.toml').open('rb') as f:
    conf = tomllib.load(f)

default_preset = ensure(conf, 'default', str)
if preset is None:
    preset = default_preset
params = ensure(conf, 'preset', dict).get(preset)
if not isinstance(params, dict):
    raise Exception(f'preset {preset!r} is bad or unknown!')
path = Path(ensure(params, 'path', str))
if path.name != 'opencomputers':
    raise Exception(f'{str(path)!r} must end with "opencomputers"')
comps = ensure_list(params, 'comps', str)
dirs = ensure_list(params, 'dirs', str)
rmdirs = ensure_list(params, 'rmdirs', str, default=lambda: [])
for comp in comps:
    if not UUID_RE.fullmatch(comp):
        raise Exception(f'{comp!r} is not a valid uuid!')
for dir in dirs + rmdirs:
    if dir == '.' or dir == '..' or '/' in dir or '\\' in dir:
        raise Exception(f'{dir!r} contains forbidden patterns and isn\'t a valid dir name!')

for comp in comps:
    print(f'copying to comp {comp}...')
    target = path / comp / 'home'
    for dir in dirs:
        src = repo / dir
        dst = target / dir
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst, symlinks=False, dirs_exist_ok=False)
    for dir in rmdirs:
        dst = target / dir
        if dst.exists():
            shutil.rmtree(dst)
print('done.')
