local Lighting = game:GetService("Lighting")
local World = {}
local C = {
    Concrete = Color3.fromRGB(76, 86, 99), Dark = Color3.fromRGB(30, 39, 51),
    White = Color3.fromRGB(220, 233, 235), Orange = Color3.fromRGB(244, 155, 65),
    Mint = Color3.fromRGB(79, 230, 186), Blue = Color3.fromRGB(66, 147, 224),
}
local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = if typeof(cf) == "CFrame" then cf else CFrame.new(cf)
    p.Anchored = true; p.Color = color or C.Concrete; p.Material = material or Enum.Material.Concrete
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
    return p
end
local function label(parent, text, color, offset, width)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"; gui.Size = UDim2.fromOffset(width or 230, 56); gui.StudsOffset = offset or Vector3.new(0, 4, 0)
    gui.MaxDistance = 85; gui.AlwaysOnTop = false; gui.Parent = parent
    local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundColor3 = C.Dark
    t.BackgroundTransparency = 0.15; t.TextColor3 = color or C.White; t.Font = Enum.Font.GothamBold
    t.TextSize = 15; t.TextWrapped = true; t.Text = text; t.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = t
    return t
end
function World.figure(parent, name, position, color, police)
    local model = Instance.new("Model"); model.Name = name; model.Parent = parent
    local root = part(model, "Root", Vector3.new(2, 2, 1), position, color); root.Transparency = 1; root.CanCollide = false
    model.PrimaryPart = root
    part(model, "Torso", Vector3.new(2, 2, 1), position, color)
    part(model, "Head", Vector3.new(1.35, 1.35, 1.35), position + Vector3.new(0, 1.7, 0), Color3.fromRGB(194, 149, 112))
    for _, x in ipairs({ -0.53, 0.53 }) do part(model, "Leg", Vector3.new(0.9, 2, 1), position + Vector3.new(x, -2, 0), C.Dark) end
    for _, x in ipairs({ -1.5, 1.5 }) do part(model, "Arm", Vector3.new(0.8, 2, 1), position + Vector3.new(x, 0, 0), color) end
    -- Stylized original block figures; no external likeness or asset dependency.
    part(model, "Visor", Vector3.new(1.4, 0.35, 0.12), position + Vector3.new(0, 1.8, -0.72), C.Dark)
    if police then
        part(model, "Cap", Vector3.new(1.6, 0.35, 1.6), position + Vector3.new(0, 2.4, 0), C.Blue)
        part(model, "Badge", Vector3.new(0.3, 0.45, 0.08), position + Vector3.new(-0.5, 0.3, -0.55), C.Orange, Enum.Material.Metal)
    end
    for _, p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false; p.CanQuery = false end end
    label(root, name, if police then C.Blue else C.Orange, Vector3.new(0, 4.5, 0))
    return model
end
function World.build(config)
    local existing = workspace:FindFirstChild("LockbreakWorld")
    if existing then
        assert(existing:GetAttribute("GeneratedBy") == "Lockbreak", "An unrelated LockbreakWorld folder already exists.")
        local nodes, inmates = {}, {}
        local actors = assert(existing:FindFirstChild("Actors"), "Generated world is missing Actors")
        for _, item in ipairs(existing:GetDescendants()) do
            if item:IsA("BasePart") and item:GetAttribute("InteractionId") then
                nodes[item:GetAttribute("InteractionId")] = { Part = item, Prompt = assert(item:FindFirstChildOfClass("ProximityPrompt")) }
            elseif item:IsA("Model") and item:GetAttribute("InmateId") then inmates[item:GetAttribute("InmateId")] = item end
        end
        return { Folder = existing, Actors = actors, Nodes = nodes, Inmates = inmates, Spawn = CFrame.new(0, 5, -70) }
    end
    local folder = Instance.new("Folder"); folder.Name = "LockbreakWorld"; folder.Parent = workspace
    folder:SetAttribute("GeneratedBy", "Lockbreak")
    local actors = Instance.new("Folder"); actors.Name = "Actors"; actors.Parent = folder
    local nodes, inmates = {}, {}
    local function p(name, size, pos, color, material) return part(folder, name, size, pos, color, material) end
    local function interact(id, target, title, description)
        local q = Instance.new("ProximityPrompt"); q.Name = "Interact"; q.ActionText = title; q.ObjectText = description
        q.HoldDuration = if id == "power" then 2 else 0.7; q.MaxActivationDistance = 10; q.RequiresLineOfSight = true
        q.KeyboardKeyCode = Enum.KeyCode.E; q.GamepadKeyCode = Enum.KeyCode.ButtonX; q.Parent = target
        target:SetAttribute("InteractionId", id)
        nodes[id] = { Part = target, Prompt = q }
    end
    local function room(name, x, z, w, d)
        p(name .. " foundation", Vector3.new(w, 0.3, d), Vector3.new(x, 0.15, z), C.Dark)
        p(name .. " rear", Vector3.new(w, 13, 1), Vector3.new(x, 6.5, z + d/2))
        for _, side in ipairs({ -1, 1 }) do
            p(name .. " side", Vector3.new(1, 13, d), Vector3.new(x + side*w/2, 6.5, z))
            p(name .. " front", Vector3.new(w/2-5, 13, 1), Vector3.new(x + side*(w/4+2.5), 6.5, z-d/2))
        end
        local lintel = p(name .. " lintel", Vector3.new(w, 2, 1), Vector3.new(x, 12, z-d/2), C.Dark)
        label(lintel, name, C.White, Vector3.new(0, 2, 0))
        p(name .. " light", Vector3.new(w-3, 0.3, 0.4), Vector3.new(x, 10.6, z+d/2-1), C.Orange, Enum.Material.Neon)
    end
    local ocean = p("Ocean", Vector3.new(1600, 2, 1600), Vector3.new(0, -5, 0), Color3.fromRGB(22, 71, 91), Enum.Material.SmoothPlastic)
    ocean.CanCollide = false; ocean.CanQuery = false
    p("Island", Vector3.new(195, 5, 235), Vector3.new(0, -2.5, 0), Color3.fromRGB(88, 102, 82), Enum.Material.Grass)
    p("Prison yard", Vector3.new(146, 0.2, 178), Vector3.new(0, 0.1, -5), Color3.fromRGB(100, 110, 111))
    p("Main walkway", Vector3.new(22, 0.25, 172), Vector3.new(0, 0.24, -5), C.Dark, Enum.Material.Asphalt)
    for z = -76, 72, 13 do p("Walkway marking", Vector3.new(0.35, 0.05, 5), Vector3.new(0, 0.39, z), C.Orange) end
    for _, x in ipairs({ -75, 75 }) do p("Perimeter wall", Vector3.new(3, 20, 184), Vector3.new(x, 10, -5)) end
    p("South wall", Vector3.new(153, 20, 3), Vector3.new(0, 10, -97))
    for _, x in ipairs({ -44, 44 }) do p("North wall", Vector3.new(64, 20, 3), Vector3.new(x, 10, 87)) end
    for _, x in ipairs({ -75, 75 }) do
        for z = -90, 85, 7 do
            p("Fence post", Vector3.new(0.35, 4, 0.35), Vector3.new(x, 22, z), C.Dark, Enum.Material.Metal)
        end
        for y = 21, 23, 1 do p("Fence rail", Vector3.new(0.16, 0.16, 180), Vector3.new(x, y, -3), C.Dark, Enum.Material.Metal) end
    end
    for _, x in ipairs({ -67, 67 }) do
        for _, z in ipairs({ -85, 74 }) do
            p("Watchtower", Vector3.new(9, 24, 9), Vector3.new(x, 12, z), C.Dark)
            p("Watchtower cabin", Vector3.new(14, 7, 14), Vector3.new(x, 27, z))
            p("Watchtower roof", Vector3.new(17, 1, 17), Vector3.new(x, 31, z), C.Dark)
            local lamp = p("Tower beacon", Vector3.new(1, 1, 1), Vector3.new(x, 32, z), C.Orange, Enum.Material.Neon)
            local light = Instance.new("PointLight"); light.Color = C.Orange; light.Range = 25; light.Brightness = 1; light.Parent = lamp
        end
    end
    local spawn = Instance.new("SpawnLocation"); spawn.Name = "IntakeSpawn"; spawn.Size = Vector3.new(12, 0.4, 12)
    spawn.CFrame = CFrame.new(0, 0.6, -70); spawn.Anchored = true; spawn.Neutral = true; spawn.Duration = 0
    spawn.Transparency = 1; spawn.Parent = folder
    local sign = p("Welcome sign", Vector3.new(25, 5, 0.7), Vector3.new(0, 8, -87), C.Dark)
    label(sign, "LOCKBREAK ISLAND\nINTAKE / SOUTH WING", C.Orange, Vector3.zero, 300)
    for _, x in ipairs({ -42, 42 }) do
        room("INTAKE", x, -70, 34, 28)
        for offset = -10, 10, 10 do
            p("Bunk frame", Vector3.new(6, 1, 4), Vector3.new(x + offset, 1.5, -73), C.Dark, Enum.Material.Metal)
            p("Bunk mattress", Vector3.new(6, 0.5, 4), Vector3.new(x + offset, 2.25, -73), Color3.fromRGB(109, 133, 146))
        end
    end
    room("GUARD OFFICE", -48, -20, 32, 34)
    p("Guard desk", Vector3.new(14, 3, 5), Vector3.new(-48, 1.5, -14), C.Dark)
    local key = p("Guard keycard", Vector3.new(2.5, 0.2, 1.6), Vector3.new(-44, 3.2, -14), C.Orange, Enum.Material.Neon)
    label(key, "01 / KEYCARD", C.Orange, Vector3.new(0, 3, 0)); interact("key", key, "Steal keycard", "Guard desk")
    local monitor = p("Security monitor", Vector3.new(5, 3, 0.5), Vector3.new(-52, 4.5, -12), C.Dark)
    p("Monitor display", Vector3.new(4.5, 2.4, 0.1), monitor.CFrame * CFrame.new(0, 0, -0.3), C.Mint, Enum.Material.Neon)
    room("UTILITY YARD", 47, 15, 34, 36)
    local generator = p("Security generator", Vector3.new(10, 6, 7), Vector3.new(47, 3, 18), C.Dark, Enum.Material.Metal)
    for x = 43, 51, 2 do p("Generator fin", Vector3.new(0.5, 5, 7.5), Vector3.new(x, 3, 18), C.Concrete, Enum.Material.Metal) end
    local switch = p("Power switch", Vector3.new(2, 2, 0.3), Vector3.new(47, 4, 14.2), C.Mint, Enum.Material.Neon)
    label(generator, "02 / SECURITY POWER", C.Mint, Vector3.new(0, 6, 0)); interact("power", switch, "Cut security power", "Generator controls")
    for i, cast in ipairs(config.Cast) do
        local x = if i == 1 then -42 else 42
        room("CELL " .. cast.Cell, x, 57, 32, 24)
        for barX = x-4, x+4, 2 do p("Cell bars", Vector3.new(0.3, 10, 0.3), Vector3.new(barX, 5, 45), C.Dark, Enum.Material.Metal) end
        local inmate = World.figure(actors, cast.Name, Vector3.new(x, 3.3, 52), C.Orange, false)
        inmate:SetAttribute("InmateId", cast.Id); inmates[cast.Id] = inmate
        local release = p("Cell release", Vector3.new(1.4, 2, 0.8), Vector3.new(x + 7, 4, 44), C.Orange, Enum.Material.Neon)
        interact("rescue:" .. cast.Id, release, "Free " .. cast.Name, "Optional rescue / +75 on escape")
    end
    local workshop = World.figure(actors, "Workshop foreman", Vector3.new(-47, 3.3, 22), C.Mint, false)
    interact("foreman", workshop.PrimaryPart, "Deliver five scrap bundles", "Workshop / +100 on escape")
    p("Workshop bench", Vector3.new(15, 3, 5), Vector3.new(-48, 1.5, 28), C.Dark)
    local scrapPositions = { Vector3.new(-24, 1, -55), Vector3.new(24, 1, -40), Vector3.new(-28, 1, 5), Vector3.new(24, 1, 32), Vector3.new(0, 1, 64) }
    for i, pos in ipairs(scrapPositions) do
        local scrap = p("Scrap bundle " .. i, Vector3.new(2, 1.5, 2), pos, C.Orange, Enum.Material.DiamondPlate)
        interact("scrap:" .. i, scrap, "Collect scrap " .. i, "Workshop supply")
    end
    local radio = p("Dock radio", Vector3.new(3, 2, 2), Vector3.new(-15, 3, 100), C.Dark, Enum.Material.Metal)
    p("Radio table", Vector3.new(6, 2, 4), Vector3.new(-15, 1, 100), C.Concrete)
    p("Radio antenna", Vector3.new(0.2, 6, 0.2), Vector3.new(-16, 6, 100), C.Dark, Enum.Material.Metal)
    interact("radio", radio, "Send escape coordinates", "Radio side quest / +80 on escape")
    p("Dock", Vector3.new(14, 1, 35), Vector3.new(0, 0.5, 115), Color3.fromRGB(107, 91, 77), Enum.Material.WoodPlanks)
    local boat = p("Escape boat", Vector3.new(15, 2, 22), Vector3.new(0, 0, 137), C.Dark, Enum.Material.Metal)
    for _, x in ipairs({ -6.5, 6.5 }) do p("Boat rail", Vector3.new(1, 3, 22), Vector3.new(x, 2, 137), C.White) end
    p("Boat cabin", Vector3.new(9, 4, 7), Vector3.new(0, 3, 141), C.White)
    local exit = p("Boat boarding point", Vector3.new(7, 0.3, 4), Vector3.new(0, 1.2, 129), C.Mint, Enum.Material.Neon)
    label(boat, "03 / ESCAPE BOAT", C.Mint, Vector3.new(0, 8, 0)); interact("exit", exit, "Escape the island", "Complete your run")
    for _, x in ipairs({ -20, 20 }) do
        for z = -50, 70, 40 do
            p("Yard lamp post", Vector3.new(0.5, 12, 0.5), Vector3.new(x, 6, z), C.Dark, Enum.Material.Metal)
            local lamp = p("Yard lamp", Vector3.new(3, 0.5, 2), Vector3.new(x, 12, z), C.White, Enum.Material.Neon)
            local light = Instance.new("PointLight"); light.Range = 24; light.Brightness = 1.5; light.Color = C.White; light.Parent = lamp
        end
    end
    Lighting.ClockTime = 17.6; Lighting.Brightness = 2; Lighting.Ambient = Color3.fromRGB(100, 112, 135)
    Lighting.OutdoorAmbient = Color3.fromRGB(118, 133, 155)
    Lighting.FogColor = Color3.fromRGB(115, 155, 170); Lighting.FogStart = 300; Lighting.FogEnd = 1100
    return { Folder = folder, Actors = actors, Nodes = nodes, Inmates = inmates, Spawn = CFrame.new(0, 5, -70) }
end
return World
