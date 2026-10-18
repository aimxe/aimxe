local Pathfinding = game:GetService("PathfindingService")
local World = require(script.Parent.World)
local Patrols = {}
Patrols.__index = Patrols
function Patrols.new(world)
    local self = setmetatable({ World = world, Guards = {} }, Patrols)
    local routes = {
        { Vector3.new(-14,3.3,-40), Vector3.new(-14,3.3,35), Vector3.new(14,3.3,35), Vector3.new(14,3.3,-40) },
        { Vector3.new(14,3.3,-10), Vector3.new(14,3.3,62), Vector3.new(-14,3.3,62), Vector3.new(-14,3.3,-10) },
        { Vector3.new(-10,3.3,70), Vector3.new(10,3.3,70), Vector3.new(10,3.3,15), Vector3.new(-10,3.3,15) },
    }
    for i, route in ipairs(routes) do
        local model = World.figure(world.Actors, "GUARD " .. string.format("%02d",i), route[1], Color3.fromRGB(40,91,153), true)
        table.insert(self.Guards, { Model = model, Route = route, Index = 2, Replan = 0, LastSeen = 0, PathIndex = 1 })
    end
    return self
end
function Patrols:Step(dt, sessions, caught)
    local now = os.clock()
    local ignore = { self.World.Actors }
    for player in pairs(sessions) do if player.Character then table.insert(ignore, player.Character) end end
    local rays = RaycastParams.new(); rays.FilterType = Enum.RaycastFilterType.Exclude; rays.FilterDescendantsInstances = ignore
    local spotted = {}
    for _, guard in ipairs(self.Guards) do
        local position = guard.Model:GetPivot().Position
        local nearest, nearestDist = nil, math.huge
        for player, s in pairs(sessions) do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 and not s.Frozen and s.Run.Key and now > s.Grace then
                local delta = root.Position - position
                local distance = delta.Magnitude
                local facing = distance < 8 or (distance > 0 and guard.Model:GetPivot().LookVector:Dot(delta.Unit) > 0.15)
                if distance < 36 and facing and not workspace:Raycast(position, delta, rays) then
                    spotted[player] = true
                    if distance < nearestDist then nearest = player; nearestDist = distance end
                    if s.Heat >= 0.65 and distance < 5 then caught(player) end
                end
            end
        end
        if nearest then guard.Target = nearest; guard.LastSeen = now end
        if now - guard.LastSeen > 4 or (guard.Target and not sessions[guard.Target]) then guard.Target = nil end
        local targetState = guard.Target and sessions[guard.Target]
        local root = guard.Target and guard.Target.Character and guard.Target.Character:FindFirstChild("HumanoidRootPart")
        local chasing = root and targetState and targetState.Run.Key and not targetState.Frozen and targetState.Heat >= 0.3
        local goal = if chasing then root.Position else guard.Route[guard.Index]
        goal = Vector3.new(goal.X, 3.3, goal.Z)
        if not chasing and (goal-position).Magnitude < 2 then
            guard.Index = guard.Index % #guard.Route + 1; goal = guard.Route[guard.Index]
        end
        local destination = goal
        if workspace:Raycast(position, goal-position, rays) then
            if now > guard.Replan and not guard.Computing then
                guard.Replan = now + 1; guard.Computing = true
                local from, to = position - Vector3.new(0,2.8,0), goal - Vector3.new(0,2.8,0)
                task.spawn(function()
                    local path = Pathfinding:CreatePath({ AgentRadius = 2, AgentHeight = 6, AgentCanJump = false, WaypointSpacing = 4 })
                    local ok = pcall(function() path:ComputeAsync(from, to) end)
                    guard.Path = if ok and path.Status == Enum.PathStatus.Success then path:GetWaypoints() else nil
                    guard.PathIndex = 2; guard.Computing = false
                end)
            end
            local waypoint = guard.Path and guard.Path[guard.PathIndex]
            if waypoint then
                destination = Vector3.new(waypoint.Position.X, 3.3, waypoint.Position.Z)
                if (destination-position).Magnitude < 2 then guard.PathIndex += 1 end
            else destination = position end
        else guard.Path = nil end
        local delta = destination-position
        if delta.Magnitude > 0.1 then
            local step = delta.Unit * math.min(delta.Magnitude, dt * (if chasing then 19 else 9))
            -- Check each step as well so stale paths cannot cut through a closed wall.
            if not workspace:Raycast(position, step, rays) then
                guard.Model:PivotTo(CFrame.lookAt(position+step, position+step+delta.Unit))
            end
        end
    end
    for player, s in pairs(sessions) do
        local rate = if spotted[player] then 0.65 / (1 + s.Profile.Upgrades.Stealth * 0.25) else -0.28
        s.Heat = math.clamp(s.Heat + rate * dt, 0, 1)
    end
end
return Patrols
