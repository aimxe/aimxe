-- Run from the project directory: lune run tools/bake_world.luau <input.rbxlx> <output.rbxlx>
-- Uses real Roblox instance/property serialization, but does not simulate Roblox physics.
local roblox = require('@lune/roblox')
local fs = require('@lune/fs')
local luau = require('@lune/luau')
local process = require('@lune/process')
local serde = require('@lune/serde')
local input, output = process.args[1], process.args[2]
assert(input and output, 'Provide input and output place paths')
local game = roblox.deserializePlace(fs.readFile(input))
local workspace = game:GetService('Workspace')
if not game:FindFirstChildOfClass('Lighting') then
    local lighting = roblox.Instance.new('Lighting'); lighting.Name = 'Lighting'; lighting.Parent = game
end
local globals = { game = game, workspace = workspace, Instance = roblox.Instance,
    Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Color3 = roblox.Color3,
    UDim = roblox.UDim, UDim2 = roblox.UDim2, Enum = roblox.Enum }
local config = luau.load(game:GetService('ReplicatedStorage').Config.Source)()
local source = game:GetService('ServerScriptService').Modules.World.Source
local builder = luau.load(source, { environment = globals, injectGlobals = true })()
local built = builder.build(config)
local before = #workspace:GetDescendants()
assert(builder.build(config).Folder == built.Folder, 'World must reuse the baked map')
assert(#workspace:GetDescendants() == before, 'World construction created duplicate instances')
local camera = roblox.Instance.new('Camera'); camera.Name = 'Camera'
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(155,160,-195), roblox.Vector3.new(0,0,12))
camera.FieldOfView = 65; camera.Parent = workspace; workspace.CurrentCamera = camera
local parts, targets = {}, {}
local function v(vector) return { vector.X, vector.Y, vector.Z } end
for _, item in ipairs(built.Folder:GetDescendants()) do
    if item:IsA('BasePart') then
        table.insert(parts, { Name = item.Name, Position = v(item.CFrame.Position), Size = v(item.Size),
            Collidable = item.CanCollide, Queryable = item.CanQuery, Id = item:GetAttribute('InteractionId') })
    end
end
local count = 0
for id, node in pairs(built.Nodes) do
    count += 1
    assert(node.Prompt.Parent == node.Part, 'Prompt parent mismatch: ' .. id)
    assert(node.Prompt.Enabled and node.Prompt.MaxActivationDistance == 10, 'Invalid prompt: ' .. id)
    targets[id] = v(node.Part.CFrame.Position)
end
assert(count == 12, 'Expected 12 gameplay interaction targets')
for _, cast in ipairs(config.Cast) do assert(built.Inmates[cast.Id].PrimaryPart, 'Missing rescue NPC') end
fs.writeFile(output, roblox.serializePlace(game, true))
fs.writeFile(output .. '.geometry.json', serde.encode('json', { Parts = parts, Targets = targets, Spawn = v(built.Spawn.Position) }, true))
local reloaded = roblox.deserializePlace(fs.readFile(output))
assert(reloaded:GetService('Workspace'):FindFirstChild('LockbreakWorld'), 'Map was not serialized')
assert(reloaded:GetService('ServerScriptService').Game.Source == game:GetService('ServerScriptService').Game.Source, 'Server source changed in serialization')
print('Baked and round-trip verified ' .. #parts .. ' parts and ' .. count .. ' interaction targets. Repeated construction is idempotent.')
