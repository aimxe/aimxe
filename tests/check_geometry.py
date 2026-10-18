"""Static clearance/line-of-sight checks, not a Roblox physics or playtest substitute."""
import json
import math
import sys
from collections import deque
from pathlib import Path

geometry = json.loads(Path(sys.argv[1]).read_text())
parts = geometry['Parts']
for p in parts:
    p['lo'] = [c - s / 2 for c, s in zip(p['Position'], p['Size'])]
    p['hi'] = [c + s / 2 for c, s in zip(p['Position'], p['Size'])]


def standing_height(x, z):
    supports = [p['hi'][1] for p in parts if p['Collidable']
                and -0.1 <= p['hi'][1] <= 1.6
                and p['lo'][0] + 0.1 <= x <= p['hi'][0] - 0.1
                and p['lo'][2] + 0.1 <= z <= p['hi'][2] - 0.1]
    if not supports:
        return None
    floor = max(supports)
    for p in parts:
        if (p['Collidable'] and p['hi'][1] > floor + 0.6 and p['lo'][1] < floor + 5.8
                and p['lo'][0] - 1.5 < x < p['hi'][0] + 1.5
                and p['lo'][2] - 1.5 < z < p['hi'][2] + 1.5):
            return None
    return floor


def intersects(origin, target, part):
    low, high = 0.0, 1.0
    for axis in range(3):
        direction = target[axis] - origin[axis]
        if abs(direction) < 1e-8:
            if not part['lo'][axis] <= origin[axis] <= part['hi'][axis]:
                return False
        else:
            a = (part['lo'][axis] - origin[axis]) / direction
            b = (part['hi'][axis] - origin[axis]) / direction
            low, high = max(low, min(a, b)), min(high, max(a, b))
            if low > high:
                return False
    return low <= high

walkable = {}
for x in range(-96, 97, 2):
    for z in range(-110, 153, 2):
        height = standing_height(x, z)
        if height is not None:
            walkable[x, z] = height
start = (round(geometry['Spawn'][0] / 2) * 2, round(geometry['Spawn'][2] / 2) * 2)
assert start in walkable, 'Spawn is obstructed'
reachable = {start}
queue = deque([start])
while queue:
    x, z = queue.popleft()
    for next_tile in [(x + 2, z), (x - 2, z), (x, z + 2), (x, z - 2)]:
        if next_tile in walkable and next_tile not in reachable:
            reachable.add(next_tile)
            queue.append(next_tile)

for identifier, position in sorted(geometry['Targets'].items()):
    candidates = []
    for x, z in reachable:
        origin = (x, walkable[x, z] + 3.0, z)
        if math.dist(origin, position) <= 9.8:
            candidates.append(origin)
    assert candidates, f'{identifier}: no reachable approach within prompt range'
    assert any(not any(intersects(origin, position, p) for p in parts
                       if p['Queryable'] and p.get('Id') != identifier)
               for origin in candidates), f'{identifier}: all reachable approaches block line of sight'
    print(f'PASS {identifier}: reachable approach and clear interaction ray')
print(f'{len(geometry["Targets"])} targets passed; {len(reachable)} connected standing positions checked.')
