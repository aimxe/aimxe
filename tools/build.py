"""Rebuild, validate, and package the standalone Roblox place and its source."""
import argparse
import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
parser.add_argument('--luau-compile', default='luau-compile')
parser.add_argument('--lune', default='lune')
parser.add_argument('--rojo', default='rojo')
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
dist = root / 'dist'
dist.mkdir(exist_ok=True)


def run(*command, quiet=False):
    subprocess.run([str(c) for c in command], cwd=root, check=True,
                   stdout=subprocess.DEVNULL if quiet else None)


sources = sorted((root / 'src').rglob('*.lua'))
for source in sources:
    run(args.luau_compile, source, quiet=True)
print(f'PASS compilation: {len(sources)} Roblox source files', flush=True)
run(args.luau, 'tests/rules.spec.luau')
run(args.lune, 'run', 'tests/profiles.spec.luau')
run(args.rojo, 'build', 'default.project.json', '-o', 'dist/source.rbxlx')
run(args.lune, 'run', 'tools/bake_world.luau', 'dist/source.rbxlx', 'dist/Lockbreak-Island-Rebuilt.rbxlx')
place = dist / 'Lockbreak-Island-Rebuilt.rbxlx'
geometry = Path(str(place) + '.geometry.json')
run(sys.executable, 'tests/check_geometry.py', geometry)

# Verify actual serialized script types, hierarchy, and exact source contents.
model = ET.parse(place).getroot()
embedded = {}


def inspect(item, parents):
    props = item.find('Properties')
    name = props.find("string[@name='Name']").text
    path = parents + [name]
    source = props.find("*[@name='Source']")
    if source is not None:
        embedded['/'.join(path)] = (item.attrib['class'], source.text or '')
    for child in item.findall('Item'):
        inspect(child, path)


for item in model.findall('Item'):
    inspect(item, [])
for path in sources:
    relative = path.relative_to(root / 'src')
    name = path.name
    if name.endswith('.server.lua'):
        script_class, name = 'Script', name.removesuffix('.server.lua')
    elif name.endswith('.client.lua'):
        script_class, name = 'LocalScript', name.removesuffix('.client.lua')
    else:
        script_class, name = 'ModuleScript', name.removesuffix('.lua')
    key = '/'.join([*relative.parts[:-1], name])
    assert embedded[key] == (script_class, path.read_text()), f'Place source mismatch: {key}'
assert len(embedded) == len(sources), 'Unexpected executable scripts in place'
print(f'PASS embedded hierarchy/types/source: {len(embedded)} scripts', flush=True)

files = {}
for pattern in ['src/**/*.lua', 'tests/*.luau', 'tests/*.py', 'tools/*.py', 'tools/*.luau']:
    for path in sorted(root.glob(pattern)):
        files[path.relative_to(root).as_posix()] = path.read_bytes()
for filename in ['README.md', 'START_HERE.txt', 'VALIDATION.md', 'default.project.json', '.gitignore']:
    files[filename] = (root / filename).read_bytes()
files[place.name] = place.read_bytes()
files['validation/world.geometry.json'] = geometry.read_bytes()
manifest = ''.join(f'{hashlib.sha256(content).hexdigest()}  {name}\n' for name, content in sorted(files.items()))
files['SHA256SUMS.txt'] = manifest.encode()
zip_path = dist / 'Lockbreak-Island-Rebuilt.zip'
with ZipFile(zip_path, 'w', ZIP_DEFLATED) as archive:
    for name, content in sorted(files.items()):
        archive.writestr('Lockbreak-Island-Rebuilt/' + name, content)
with ZipFile(zip_path) as archive:
    assert archive.testzip() is None
    for name, content in files.items():
        assert archive.read('Lockbreak-Island-Rebuilt/' + name) == content
print(f'PASS package integrity: {len(files)} files; {zip_path.stat().st_size:,} bytes', flush=True)
print(f'Place: {place}\nDownload: {zip_path}', flush=True)
