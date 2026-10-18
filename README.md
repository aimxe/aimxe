# Lockbreak Island — rebuilt

An original Roblox escape game with a stylized island prison, a mission HUD, patrolling guards, optional rescues, side quests, permanent cash upgrades, and a shop. You play as a fictional parody of Andrew Tate; Jeffrey Epstein and Diddy appear as optional parody rescue characters. The story is invented and does not assert facts about any real person's conduct or legal status. All characters use original block figures, without likeness assets or audio.

## Play the downloaded game

1. Extract `Lockbreak-Island-Rebuilt.zip`.
2. Open **Roblox Studio → File → Open from File** and choose `Lockbreak-Island-Rebuilt.rbxlx`.
3. Press **Play** (F5). Use WASD to move, Space to jump, E to interact, Shift to sprint, and B for the shop. The HUD also has touch/click controls; gamepads use X to interact and L3 to sprint.
4. Play as a solo practice session, or use Studio's **Server & Clients** test mode with two players.

Rojo is optional. Studio practice works without publishing, API keys, or DataStore access. Practice cash and upgrades reset when the session ends, and Robux purchases are disabled.

The downloadable place includes the map for editing before you press Play. Source-only Rojo builds generate the same map when the server starts. After changing the procedural world builder or cast names, rebuild with `python tools/build.py`; alternatively, remove only the generated `Workspace/LockbreakWorld` folder in your development place so it regenerates on the next Play.

## Escape route

- Begin at intake in the south. Enter the guard office in the west and steal the glowing keycard.
- Reach the east utility yard and hold E at the generator controls to cut security power.
- Optionally free the two inmates at their cell-release controls. They follow you visually on your client; the server tracks each rescue independently for rewards.
- Go north through the perimeter opening, cross the dock, and board the escape boat.

A successful escape pays 150 cash, plus 75 per rescued inmate. Collect five distinct scrap bundles and deliver them to the workshop foreman for another 100. Send coordinates from the dock radio for another 80. A full run pays 480. Bonuses are banked only at extraction; capture or death discards unbanked mission progress. Earned cash, purchased skins, and upgrades remain.

Police use sight distance, a field of view, line-of-sight raycasts, suspicion, and pursuit. Walls block sight, and guards request paths around obstacles. Sprinting spends stamina; it recharges while resting. Stealth upgrades slow detection. These systems need engine playtesting for difficulty and navigation tuning.

## Shop and rankings

Five outfits: Intake, Midnight, Arctic, Neon, and Gold. Sprint, stamina, and stealth each have three upgrade levels, bought with earned cash. The shop validates prices, funds, ownership, and caps on the server.

The built-in player list shows cash, escapes, and rescues. The Rankings window shows the global top ten by saved escapes in live games, or the current session in Studio. Global rankings refresh about once a minute. A personal best escape time is also stored.

## Live saving

Live servers use DataStores automatically. Studio defaults to session-only profiles. To test persistence, publish a **separate private test experience**, enable Studio API access in its settings, and set `StudioPersistence = true` in `ReplicatedStorage/Config`.

Profiles use an exclusive lease renewed on saves. Other servers cannot load an active profile; a crashed server's lease expires after 180 seconds. Failed profile loads do not silently substitute blank profiles. A lost lease stops progress and requires rejoining. Saves occur every 45 seconds, after escapes, on departure, and at shutdown. Global rankings are updated only from confirmed profile saves.

Earned/spent cash and purchased credits use separate stored fields so an uncertain purchase response or a later autosave cannot overwrite credited purchases. Product receipt IDs are committed atomically with credits and are never evicted. The current design retains receipt IDs in the profile; monitor profile size and add an archival design before very large purchase histories approach Roblox's DataStore size limit. Severe storage outages can still prevent unsaved gameplay progress from persisting after shutdown.

This version uses `LockbreakProfiles_v2`; it does not migrate the earlier untested prototype's v1 data.

## Configure optional Robux purchases

In Creator Dashboard, create these items for **your** experience and copy their IDs into `ReplicatedStorage/Config` (or `src/ReplicatedStorage/Config.lua` if editing source):

| Setting | Item | Benefit |
| --- | --- | --- |
| `Passes.VIP.Id` | Game pass | Permanent gold trail and VIP nameplate |
| `Products.Cash500.Id` | Developer product | 500 cash |
| `Products.Cash1500.Id` | Developer product | 1,500 cash |

Zero IDs keep the items unavailable. Set prices in Creator Dashboard. The client requests current prices from Roblox; the official purchase prompt confirms the actual price. Cash can fund the same skins and upgrades available through play. VIP does not multiply rewards.

Grants use server-side `ProcessReceipt`; client purchase-completion claims cannot grant currency. Keep retired product IDs mapped on the server until all pending receipts can be processed. Use unique product IDs. Test receipts, retries, disconnects, and VIP ownership before enabling purchases for players.

## Source and optional developer tools

- `src/ReplicatedStorage/Config.lua`: cast, prices, rewards, IDs, storage settings.
- `src/ReplicatedStorage/Rules.lua`: pure gameplay rules.
- `src/ReplicatedStorage/ProfileData.lua`: pure storage transactions.
- `src/ServerScriptService/Modules/World.lua`: procedural prison construction.
- `src/ServerScriptService/Modules/Patrols.lua`: guard sight and pursuit.
- `src/ServerScriptService/Modules/Profiles.lua`: DataStore session lifecycle.
- `src/ServerScriptService/Game.server.lua`: server orchestration and network validation.
- `src/StarterPlayer/StarterPlayerScripts/HUD.client.lua`: interface and visual escorts.

Install [Rojo 7](https://rojo.space/docs/v7/getting-started/installation/) only if you want live file syncing. From the project folder, `rojo serve` connects to its Studio plugin. `rojo build default.project.json -o Lockbreak-Island-Rebuilt.rbxlx` builds a place from the source. Use this checkout directly; a cloud task is already isolated and does not need a worktree.

Run the pure tests with the official [Luau CLI](https://github.com/luau-lang/luau):

```sh
luau tests/rules.spec.luau
```

The complete build and packaging workflow, including the baked map and storage tests, is documented in `VALIDATION.md`.

## Validation status and remaining Studio checks

See `VALIDATION.md` for the checks actually executed. The Roblox engine, Roblox MCP, and Higgsfield were unavailable during this rebuild. No live publication, asset generation through Higgsfield, or engine playtest is claimed.

Before publishing publicly, run these checks in Studio:

- Complete a basic run and a full 480-cash run. Check that gates, desk, generator, cell controls, and boat are reachable and prompts work from their intended approach.
- Run two players. One player's collection/rescue/reset must not change the other's objectives or rewards. Check catch, death, and respawn behavior.
- Observe guard patrols, blocked sight lines, chase paths, stamina, and all upgrade levels. Tune speeds and routes after observing real physics.
- Check phone portrait/landscape, tablet, desktop, and controller. Confirm buttons, scrolling, text, and native interaction prompts remain usable.
- Verify profile saves and rankings after rejoining the private persistence test experience. Exercise a second-server join and storage interruption.
- Test configured products using Roblox's supported test flow, including duplicate/delayed receipts and disconnection during saving. Check owned and newly purchased VIP after respawn/rejoin.
