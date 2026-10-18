local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Market = game:GetService("MarketplaceService")
local Config = require(RS.Config)
local Rules = require(RS.Rules)
local Profiles = require(script.Parent.Modules.Profiles)
local World = require(script.Parent.Modules.World)
local Patrols = require(script.Parent.Modules.Patrols)
local network = Instance.new("Folder"); network.Name = "LockbreakNetwork"; network.Parent = RS
local function remote(name)
    local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = network; return r
end
local action, state, notice, board = remote("Action"), remote("State"), remote("Notice"), remote("Board")
local world = World.build(Config)
local patrols = Patrols.new(world)
local sessions, joining = {}, {}
local closing = false

local function tell(player, message, kind, result)
    if player.Parent then notice:FireClient(player, message, kind or "info", result) end
end
local function appearance(player)
    local s = sessions[player]; local character = player.Character
    if not s or not character then return end
    local color = Color3.fromRGB(table.unpack(Config.Skins[s.Profile.Skin].RGB))
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then item:Destroy() end
        if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" and item.Name ~= "Head" then item.Color = color end
    end
    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        bodyColors.TorsoColor3 = color; bodyColors.LeftArmColor3 = color; bodyColors.RightArmColor3 = color
        bodyColors.LeftLegColor3 = color; bodyColors.RightLegColor3 = color
    end
    local h = character:FindFirstChildOfClass("Humanoid")
    if h then h.DisplayName = Config.PlayerRole .. " · PARODY" .. (if s.VIP then " / VIP" else "") end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and s.VIP and not root:FindFirstChild("VIPTrail") then
        local a = Instance.new("Attachment"); a.Position = Vector3.new(-0.8,0,0); a.Parent = root
        local b = Instance.new("Attachment"); b.Position = Vector3.new(0.8,0,0); b.Parent = root
        local trail = Instance.new("Trail"); trail.Name = "VIPTrail"; trail.Attachment0 = a; trail.Attachment1 = b
        trail.Color = ColorSequence.new(Color3.fromRGB(255,208,85)); trail.Lifetime = 0.7; trail.Parent = root
    end
end
local function push(player)
    local s = sessions[player]
    if not s or not player.Parent then return end
    local d = s.Profile
    local step, title, detail, targetId = Rules.objective(s.Run)
    local node = world.Nodes[targetId]
    local stats = player:FindFirstChild("leaderstats")
    if stats then stats.Cash.Value = Rules.balance(d); stats.Escapes.Value = d.Escapes; stats.Rescues.Value = d.Rescues end
    state:FireClient(player, {
        Cash = Rules.balance(d), Escapes = d.Escapes, Rescues = d.Rescues, BestMs = d.BestMs,
        Skin = d.Skin, Owned = d.Owned, Upgrades = d.Upgrades, VIP = s.VIP,
        Objective = { Step = step, Title = title, Detail = detail, Target = node.Part.Position },
        Run = s.Run, Heat = s.Heat, Stamina = s.Stamina, MaxStamina = 100 + d.Upgrades.Stamina*20,
        Elapsed = os.clock()-s.Run.Started, Persistent = Profiles.Persistent, Frozen = s.Frozen,
        Payments = Profiles.Persistent and Profiles:Available(player), Sprinting = s.Sprinting,
    })
end
local function reset(player, reason)
    local s = sessions[player]; if not s then return end
    s.Run = Rules.newRun(os.clock()); s.Heat = 0; s.Sprinting = false
    s.Stamina = 100+s.Profile.Upgrades.Stamina*20; s.Grace = os.clock()+5; s.Frozen = false
    local character = player.Character
    if character then
        character:PivotTo(world.Spawn)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    end
    s.LastPosition = world.Spawn.Position
    if reason then tell(player, reason, "warning") end
    push(player)
end
local function alive(player)
    local c = player.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    return c and h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function canInteract(player, node)
    local s = sessions[player]; local root = alive(player)
    if not s or not root or s.Frozen or not Profiles:Available(player) then return false end
    if os.clock() - s.LastInteract < 0.45 or (root.Position-node.Part.Position).Magnitude>12 then return false end
    local params = RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={player.Character,world.Actors}
    local hit = workspace:Raycast(root.Position, node.Part.Position-root.Position, params)
    if hit and hit.Instance ~= node.Part then return false end
    s.LastInteract=os.clock()
    return true
end
for id, node in pairs(world.Nodes) do
    node.Prompt.Triggered:Connect(function(player)
        if not canInteract(player,node) then return end
        local s=sessions[player]
        local ok,message,result=Rules.interact(s.Run,s.Profile,id,os.clock(),Config)
        tell(player,message,if ok then "success" else "warning",result)
        if result then
            s.Frozen=true; s.Sprinting=false
            task.spawn(function() if Profiles:Save(player) then Profiles:UpdateRanking(player) end end)
            task.delay(5,function() if sessions[player]==s then reset(player) end end)
        end
        push(player)
    end)
end
local function checkVIP(player)
    local s=sessions[player]; if not s or Config.Passes.VIP.Id<=0 then return end
    local ok,owns=pcall(Market.UserOwnsGamePassAsync,Market,player.UserId,Config.Passes.VIP.Id)
    if ok and sessions[player]==s then s.VIP=owns; appearance(player); push(player) end
end
local function spawnCharacter(player,character)
    local root=character:WaitForChild("HumanoidRootPart",10)
    if not root or not sessions[player] or player.Character~=character then return end
    reset(player); appearance(player)
end
local function join(player)
    if joining[player] or sessions[player] or closing then return end
    joining[player]=true
    local stored,problem=Profiles:Load(player)
    joining[player]=nil
    if not stored then if player.Parent then player:Kick(problem) end; return end
    if not player.Parent or closing then Profiles:Release(player); return end
    sessions[player]={Profile=stored.Data,Run=Rules.newRun(os.clock()),Heat=0,Stamina=100+stored.Data.Upgrades.Stamina*20,
        Sprinting=false,Grace=os.clock()+5,Frozen=false,VIP=false,LastInteract=0,Tokens=10,TokenTime=os.clock(),LastBoard=0}
    local stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=player
    for _,name in ipairs({"Cash","Escapes","Rescues"}) do local value=Instance.new("IntValue"); value.Name=name; value.Parent=stats end
    player.CharacterAdded:Connect(function(character) task.spawn(spawnCharacter,player,character) end)
    player.CharacterAppearanceLoaded:Connect(function() appearance(player) end)
    if player.Character then task.spawn(spawnCharacter,player,player.Character) end
    task.spawn(checkVIP,player)
    tell(player,"You play as "..Config.PlayerRole.." in an invented escape story. Find the keycard.")
    push(player)
end
Players.PlayerAdded:Connect(join)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(join,player) end
Players.PlayerRemoving:Connect(function(player)
    sessions[player]=nil
    Profiles:Release(player)
end)
local function allowRequest(s)
    local now=os.clock(); s.Tokens=math.min(10,s.Tokens+(now-s.TokenTime)*5); s.TokenTime=now
    if s.Tokens<1 then return false end
    s.Tokens-=1; return true
end
action.OnServerEvent:Connect(function(player,verb,arg)
    local s=sessions[player]
    if not s or type(verb)~="string" or #verb>30 then return end
    if verb=="Sprint" and arg==false then s.Sprinting=false; return end
    if not allowRequest(s) then return end
    if verb=="Ready" then push(player); return end
    if verb=="Board" then
        if os.clock()-s.LastBoard<3 then return end
        s.LastBoard=os.clock()
        if not Profiles.Persistent then Profiles:RefreshBoard() end
        board:FireClient(player,Profiles.Board,Profiles.BoardStatus); return
    end
    if not Profiles:Available(player) or s.Frozen then return end
    if verb=="Sprint" and type(arg)=="boolean" then s.Sprinting=arg and s.Stamina>10; return end
    if type(arg)~="string" or #arg>40 then return end
    if verb=="Skin" or verb=="Upgrade" then
        local ok,message=Rules.buy(s.Profile,verb,arg,Config)
        if ok then appearance(player) end
        tell(player,message,if ok then "success" else "warning"); push(player)
    elseif verb=="Product" or verb=="Pass" then
        local item=if verb=="Product" then Config.Products[arg] else Config.Passes[arg]
        if not item or item.Id<=0 then tell(player,"This item isn't available yet.","warning"); return end
        if not Profiles.Persistent then tell(player,"Purchases are disabled in the Studio practice session.","warning"); return end
        if verb=="Pass" and s.VIP then tell(player,"You already own VIP."); return end
        local ok=pcall(function()
            if verb=="Product" then Market:PromptProductPurchase(player,item.Id)
            else Market:PromptGamePassPurchase(player,item.Id) end
        end)
        if not ok then tell(player,"Roblox couldn't open the purchase window. Try again later.","warning") end
    end
end)
Market.ProcessReceipt=function(receipt)
    local pending=Enum.ProductPurchaseDecision.NotProcessedYet
    local player=Players:GetPlayerByUserId(receipt.PlayerId)
    if not player or not Profiles.Persistent or not Profiles:Available(player) then return pending end
    local product
    for _,item in pairs(Config.Products) do if item.Id>0 and item.Id==receipt.ProductId then product=item; break end end
    if not product then return pending end
    local ok=Profiles:Save(player,{Id=receipt.PurchaseId,Credits=product.Credits})
    if not ok then return pending end
    push(player)
    tell(player,"Purchase confirmed. Your cash balance is up to date.","success")
    return Enum.ProductPurchaseDecision.PurchaseGranted
end
Market.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
    if id==Config.Passes.VIP.Id and purchased then
        local s=sessions[player]
        if s then s.VIP=true; appearance(player); push(player) end
    end
end)
local timer,uiTimer=0,0
RunService.Heartbeat:Connect(function(dt)
    timer+=dt; uiTimer+=dt
    if timer<0.1 then return end
    local step=math.min(timer,0.3); timer=0
    for player,s in pairs(sessions) do
        local root=alive(player)
        local h=root and player.Character:FindFirstChildOfClass("Humanoid")
        if h then
            local available=Profiles:Available(player)
            local moving=h.MoveDirection.Magnitude>0.1
            local sprint=s.Sprinting and s.Stamina>0 and moving and available and not s.Frozen
            local maxStamina=100+s.Profile.Upgrades.Stamina*20
            s.Stamina=math.clamp(s.Stamina+step*(if sprint then -24 else 18),0,maxStamina)
            if s.Stamina<=0 then s.Sprinting=false end
            h.WalkSpeed=if s.Frozen or not available then 0 elseif sprint then 25+s.Profile.Upgrades.Sprint*2 else 16
            if root.Position.Y< -10 or math.abs(root.Position.X)>130 or math.abs(root.Position.Z)>180 then
                reset(player,"Back at intake. Your saved cash and upgrades are safe.")
            elseif s.LastPosition and os.clock()>s.Grace and (root.Position-s.LastPosition).Magnitude>math.max(40,step*h.WalkSpeed*4) then
                reset(player,"Movement reset. Start a fresh escape run.")
            end
            s.LastPosition=root.Position
        end
    end
    patrols:Step(step,sessions,function(player) reset(player,"Caught by patrol! Run rewards reset; your cash and upgrades are safe.") end)
    if uiTimer>=0.3 then uiTimer=0; for player in pairs(sessions) do push(player) end end
end)
task.spawn(function()
    while not closing do
        task.wait(Config.SaveInterval)
        for player in pairs(sessions) do
            task.spawn(function()
                local ok=Profiles:Save(player)
                if ok then Profiles:UpdateRanking(player); push(player)
                else
                    local stored=Profiles.Sessions[player]
                    if stored and os.time()>=stored.LeaseUntil-10 then player:Kick("Storage connection lost. Please rejoin to protect your progress.") end
                end
            end)
        end
    end
end)
task.spawn(function()
    while not closing do Profiles:RefreshBoard(); task.wait(60) end
end)
game:BindToClose(function()
    closing=true
    for player in pairs(Profiles.Sessions) do task.spawn(function() Profiles:Release(player) end) end
    local deadline=os.clock()+27
    repeat task.wait(0.1) until (not next(Profiles.Sessions) and not next(joining)) or os.clock()>deadline
end)
