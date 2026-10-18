# Rebuild validation

These checks were run in the cloud workspace. They do not constitute a Roblox Studio engine playtest.

| Check | Outcome |
| --- | --- |
| Luau compilation | All 8 Roblox source files compile |
| Pure game rules and transaction tests | 28 passed, 0 failed |
| Actual profile module with a deterministic DataStore double | 10 passed, 0 failed |
| Luau analysis of pure rules, transaction module, and rules tests | Passed without diagnostics |
| Rojo 7.6.1 place build | Passed |
| Lune 0.11.0 world construction / Roblox property serialization | 235 map parts and 12 interaction targets built |
| Repeated world construction | Reuses the baked map without duplicating instances |
| Place deserialize/serialize round trip | Passed |
| Static map clearance and interaction ray checks | All 12 targets have reachable approaches and clear sight lines |
| Embedded scripts | All 8 source texts, class types, and hierarchy paths match the project |
| ZIP integrity and file contents | Verified; SHA-256 manifest included |
| Roblox physics, pathfinding, UI rendering, and multiplayer play | Not run: Roblox Studio unavailable |
| Live DataStores, global rankings, and real purchase fulfillment | Not run: no published test experience or product IDs |
| Roblox MCP / Higgsfield | No callable integration available in this session |

The geometry check uses axis-aligned boxes and a standing-clearance grid. It establishes a plausible accessible layout, not exact humanoid movement, camera visibility, or Roblox raycast behavior. The storage tests simulate failure and scheduling scenarios against the actual profile code; they do not test Roblox service availability.

## Reproduce

Install Python 3.9+, the official Luau CLI (including `luau-compile`), Rojo 7.6.1, and Lune 0.11.0. From this project directory:

```sh
python tools/build.py
```

Supply `--luau`, `--luau-compile`, `--rojo`, or `--lune` with executable paths if the tools are not on PATH. The script compiles source, runs both suites, builds and bakes the world, checks static accessibility and embedded source, and packages the results in `dist/`.

To run individual checks:

```sh
luau tests/rules.spec.luau
lune run tests/profiles.spec.luau
python tests/check_geometry.py validation/world.geometry.json
```

See the README's Studio acceptance checks before a public release.
