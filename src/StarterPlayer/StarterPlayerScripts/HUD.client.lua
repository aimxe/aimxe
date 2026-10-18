local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local Market=game:GetService("MarketplaceService")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("Config"))
local network=RS:WaitForChild("LockbreakNetwork")
local action=network:WaitForChild("Action")
local stateEvent=network:WaitForChild("State")
local notice=network:WaitForChild("Notice")
local boardEvent=network:WaitForChild("Board")
local palette={Bg=Color3.fromRGB(14,21,29),Card=Color3.fromRGB(22,32,43),Line=Color3.fromRGB(53,68,81),
    Text=Color3.fromRGB(235,241,241),Muted=Color3.fromRGB(147,167,182),Orange=Color3.fromRGB(255,177,78),
    Mint=Color3.fromRGB(89,225,188),Red=Color3.fromRGB(255,102,103)}
local gui=Instance.new("ScreenGui"); gui.Name="LockbreakHUD"; gui.ResetOnSpawn=false
-- Respect Roblox's top bar and device safe area.
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame"); root.BackgroundTransparency=1; root.AnchorPoint=Vector2.new(0.5,0.5); root.Position=UDim2.fromScale(0.5,0.5); root.Parent=gui
local scale=Instance.new("UIScale"); scale.Parent=root
local function round(item,radius)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius or 12); c.Parent=item
end
local function outline(item,color)
    local s=Instance.new("UIStroke"); s.Color=color or palette.Line; s.Thickness=1; s.Transparency=0.2; s.Parent=item
end
local function frame(parent,size,pos,color)
    local f=Instance.new("Frame"); f.Size=size; f.Position=pos or UDim2.new(); f.BackgroundColor3=color or palette.Card
    f.BorderSizePixel=0; f.Parent=parent; round(f); return f
end
local function text(parent,content,size,pos,fontSize,color,bold)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=size; t.Position=pos or UDim2.new()
    t.Text=content; t.Font=if bold then Enum.Font.GothamBold else Enum.Font.Gotham; t.TextSize=fontSize or 14
    t.TextColor3=color or palette.Text; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextYAlignment=Enum.TextYAlignment.Center
    t.TextWrapped=true; t.Parent=parent; return t
end
local function button(parent,content,size,pos,callback,color)
    local b=Instance.new("TextButton"); b.Size=size; b.Position=pos; b.Text=content; b.Font=Enum.Font.GothamBold; b.TextSize=13
    b.TextColor3=palette.Text; b.BackgroundColor3=color or palette.Card; b.AutoButtonColor=true; b.BorderSizePixel=0; b.Parent=parent
    round(b,9); outline(b); b.Activated:Connect(callback); return b
end
local function number(n)
    local value=tostring(math.floor(n or 0))
    local formatted=value:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
    return formatted
end
local function duration(seconds)
    return string.format("%02d:%02d",math.floor(seconds/60),math.floor(seconds%60))
end
local header=frame(root,UDim2.new(1,-40,0,76),UDim2.fromOffset(20,14),palette.Bg); outline(header)
local title=text(header,"LOCKBREAK / ISLAND",UDim2.new(0.55,0,0,32),UDim2.fromOffset(20,10),24,palette.Text,true)
local subtitle=text(header,"ESCAPE. UPGRADE. REPEAT.",UDim2.new(0.5,0,0,20),UDim2.fromOffset(21,43),10,palette.Orange,true)
local cash=text(header,"$ 0",UDim2.new(0.4,-20,0,32),UDim2.new(0.6,0,0,9),24,palette.Mint,true); cash.TextXAlignment=Enum.TextXAlignment.Right
local totals=text(header,"0 ESCAPES  /  0 RESCUES",UDim2.new(0.45,-20,0,20),UDim2.new(0.55,0,0,44),11,palette.Muted,true); totals.TextXAlignment=Enum.TextXAlignment.Right
local mission=frame(root,UDim2.fromOffset(320,168),UDim2.fromOffset(20,106),palette.Bg); outline(mission)
local missionTag=text(mission,"MAIN MISSION  /  01",UDim2.new(1,-32,0,22),UDim2.fromOffset(16,12),10,palette.Orange,true)
local missionTitle=text(mission,"CONNECTING…",UDim2.new(1,-32,0,52),UDim2.fromOffset(16,36),23,palette.Text,true)
local missionDetail=text(mission,"Loading your escape route.",UDim2.new(1,-32,0,44),UDim2.fromOffset(16,90),13,palette.Muted)
local runTime=text(mission,"RUN 00:00",UDim2.new(1,-32,0,20),UDim2.fromOffset(16,138),11,palette.Mint,true)
local quests=frame(root,UDim2.fromOffset(320,200),UDim2.fromOffset(20,287),palette.Bg); outline(quests)
text(quests,"OPTIONAL / EXTRA CASH",UDim2.new(1,-32,0,22),UDim2.fromOffset(16,12),10,palette.Orange,true)
local questText=text(quests,"",UDim2.new(1,-32,1,-50),UDim2.fromOffset(16,42),14,palette.Text)
questText.TextYAlignment=Enum.TextYAlignment.Top
local vitals=frame(root,UDim2.fromOffset(320,91),UDim2.new(0,20,1,-153),palette.Bg); outline(vitals)
local heatText=text(vitals,"POLICE / CLEAR",UDim2.new(1,-32,0,18),UDim2.fromOffset(16,9),10,palette.Muted,true)
local heatTrack=frame(vitals,UDim2.new(1,-32,0,7),UDim2.fromOffset(16,32),palette.Line)
local heatFill=frame(heatTrack,UDim2.fromScale(0,1),nil,palette.Red)
text(vitals,"STAMINA",UDim2.new(1,-32,0,16),UDim2.fromOffset(16,47),10,palette.Muted,true)
local energyTrack=frame(vitals,UDim2.new(1,-32,0,7),UDim2.fromOffset(16,69),palette.Line)
local energyFill=frame(energyTrack,UDim2.fromScale(1,1),nil,palette.Mint)
local footnote=text(root,Config.FictionNotice,UDim2.new(1,-40,0,23),UDim2.new(0,20,1,-27),10,palette.Muted)
footnote.TextXAlignment=Enum.TextXAlignment.Center
local mode=text(root,"",UDim2.new(0,410,0,26),UDim2.new(1,-430,0,101),11,palette.Muted)
mode.TextXAlignment=Enum.TextXAlignment.Right
local dock=frame(root,UDim2.fromOffset(540,50),UDim2.new(0.5,-270,1,-86),palette.Bg); outline(dock)
local latest, modalKind, shopTab, mobile = nil, nil, "Skins", false
local sprintToggle=false
local overlay=frame(root,UDim2.fromScale(1,1),nil,Color3.new(0,0,0)); overlay.BackgroundTransparency=0.3; overlay.Visible=false; overlay.ZIndex=10
local window=frame(overlay,UDim2.fromOffset(790,540),UDim2.fromScale(0.5,0.5),palette.Bg); window.AnchorPoint=Vector2.new(0.5,0.5); outline(window)
local windowTitle=text(window,"BLACK MARKET",UDim2.new(1,-80,0,40),UDim2.fromOffset(22,14),24,palette.Text,true)
local windowDetail=text(window,"Spend earned cash on your next escape.",UDim2.new(1,-44,0,32),UDim2.fromOffset(22,55),12,palette.Muted)
local content=Instance.new("ScrollingFrame"); content.Size=UDim2.new(1,-40,1,-146); content.Position=UDim2.fromOffset(20,127)
content.BackgroundTransparency=1; content.BorderSizePixel=0; content.ScrollBarThickness=4; content.ScrollBarImageColor3=palette.Muted
content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.CanvasSize=UDim2.new(); content.Parent=window
local tabs=frame(window,UDim2.new(1,-40,0,31),UDim2.fromOffset(20,89),palette.Bg)
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,9); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=content
local renderModal
local function closeModal() overlay.Visible=false; modalKind=nil end
button(window,"X",UDim2.fromOffset(34,34),UDim2.new(1,-50,0,15),closeModal)
local function openModal(kind)
    modalKind=kind; overlay.Visible=true; sprintToggle=false; action:FireServer("Sprint",false)
    if kind=="Board" then action:FireServer("Board") end
    renderModal()
end
button(dock,"SHOP",UDim2.new(0.25,-9,1,-12),UDim2.fromOffset(6,6),function() openModal("Shop") end)
button(dock,"RANKINGS",UDim2.new(0.25,-9,1,-12),UDim2.new(0.25,3,0,6),function() openModal("Board") end)
button(dock,"QUESTS",UDim2.new(0.25,-9,1,-12),UDim2.new(0.5,0,0,6),function() openModal("Quests") end)
local sprintButton=button(dock,"SPRINT / SHIFT",UDim2.new(0.25,-9,1,-12),UDim2.new(0.75,-3,0,6),function()
    sprintToggle=not sprintToggle; action:FireServer("Sprint",sprintToggle)
end)
local toast=frame(root,UDim2.fromOffset(550,68),UDim2.new(0.5,-275,0,105),palette.Card); toast.Visible=false; toast.ZIndex=20; outline(toast)
local toastText=text(toast,"",UDim2.new(1,-32,1,-16),UDim2.fromOffset(16,8),15,palette.Text,true)
local resultCard=frame(root,UDim2.fromOffset(430,230),UDim2.fromScale(0.5,0.45),palette.Bg)
resultCard.AnchorPoint=Vector2.new(0.5,0.5); resultCard.Visible=false; resultCard.ZIndex=30; outline(resultCard,palette.Mint)
text(resultCard,"EXTRACTION COMPLETE",UDim2.new(1,-40,0,30),UDim2.fromOffset(20,22),12,palette.Mint,true)
local resultAmount=text(resultCard,"+$150",UDim2.new(1,-40,0,68),UDim2.fromOffset(20,58),46,palette.Text,true)
local resultDetail=text(resultCard,"",UDim2.new(1,-40,0,76),UDim2.fromOffset(20,135),15,palette.Muted)
local productPrices={}
local boardRows,boardStatus={},"Fetching rankings…"
local function clearContent()
    for _,child in ipairs(content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    for _,child in ipairs(tabs:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
local function row(name,description,caption,color,callback)
    local r=frame(content,UDim2.new(1,-8,0,99),nil,palette.Card)
    frame(r,UDim2.fromOffset(5,64),UDim2.fromOffset(12,17),color or palette.Mint)
    text(r,name,UDim2.new(1,-155,0,30),UDim2.fromOffset(28,13),15,palette.Text,true)
    text(r,description,UDim2.new(1,-165,0,43),UDim2.fromOffset(28,44),12,palette.Muted)
    local b=button(r,caption,UDim2.fromOffset(112,49),UDim2.new(1,-124,0.5,-24),callback or function() end)
    if not callback then b.AutoButtonColor=false; b.TextColor3=palette.Muted end
    return r
end
local function priceLabel(kind,id)
    if id<=0 then return "UNAVAILABLE" end
    local price=productPrices[kind..id]
    return if price then "R$ "..number(price) else "VIEW PRICE"
end
renderModal=function()
    if not modalKind then return end
    clearContent()
    if modalKind=="Shop" then
        windowTitle.Text="BLACK MARKET"
        windowDetail.Text=if latest then "$ "..number(latest.Cash).." available  ·  Skins and upgrades use cash." else "Loading wallet…"
        for i,name in ipairs({"Skins","Upgrades","Robux"}) do
            local b=button(tabs,name,UDim2.new(1/3,-7,1,0),UDim2.new((i-1)/3,0,0,0),function() shopTab=name; renderModal() end)
            if name==shopTab then b.BackgroundColor3=Color3.fromRGB(53,73,82); b.TextColor3=palette.Mint end
        end
        if not latest then return end
        if shopTab=="Skins" then
            for _,id in ipairs(Config.SkinOrder) do
                local item=Config.Skins[id]
                local caption=if latest.Skin==id then "EQUIPPED" elseif latest.Owned[id] then "EQUIP" else "$ "..number(item.Price)
                row(item.Name,"Permanent outfit · no stat bonus",caption,Color3.fromRGB(table.unpack(item.RGB)),function() action:FireServer("Skin",id) end)
            end
        elseif shopTab=="Upgrades" then
            for _,id in ipairs(Config.UpgradeOrder) do
                local item=Config.Upgrades[id]; local level=latest.Upgrades[id]
                row(item.Name.."  "..level.."/"..item.Max,item.Description,
                    if level>=item.Max then "MAXED" else "$ "..number(item.Prices[level+1]),palette.Mint,
                    if level<item.Max then function() action:FireServer("Upgrade",id) end else nil)
            end
        else
            windowDetail.Text="Optional purchases. Roblox shows the final price and asks you to confirm."
            local pass=Config.Passes.VIP
            local enabled=latest.Payments and pass.Id>0 and not latest.VIP
            row(pass.Name,pass.Description,if latest.VIP then "OWNED" elseif not latest.Payments then "PRACTICE" else priceLabel("pass",pass.Id),palette.Orange,
                if enabled then function() action:FireServer("Pass","VIP") end else nil)
            for _,id in ipairs({"Cash500","Cash1500"}) do
                local item=Config.Products[id]; local enabledProduct=latest.Payments and item.Id>0
                row(item.Name,"Use cash for any skin or upgrade",if not latest.Payments then "PRACTICE" else priceLabel("product",item.Id),palette.Mint,
                    if enabledProduct then function() action:FireServer("Product",id) end else nil)
            end
        end
    elseif modalKind=="Board" then
        windowTitle.Text="ESCAPE LEADERBOARD"; windowDetail.Text=boardStatus
        if #boardRows==0 then row("No escapes recorded yet","Make the first successful escape.","—",palette.Muted) end
        for i,entry in ipairs(boardRows) do
            row(string.format("%02d / %s",i,entry.Name),"Total successful escapes",number(entry.Escapes),if i==1 then palette.Orange else palette.Mint)
        end
    elseif modalKind=="Quests" then
        windowTitle.Text="THE ESCAPE PLAN"; windowDetail.Text="Bonus rewards are paid when you reach the boat. Getting caught resets the run."
        if not latest then return end
        for _,cast in ipairs(Config.Cast) do
            row("Rescue "..cast.Name,"Cell "..cast.Cell.." · disable security first",if latest.Run.Rescued[cast.Id] then "FOLLOWING" else "+$75",palette.Orange)
        end
        local count=0; for _ in pairs(latest.Run.Scrap) do count+=1 end
        row("Workshop delivery",count.."/5 bundles · take them to the foreman",if latest.Run.ScrapDone then "COMPLETE" else "+$100",palette.Mint)
        row("Radio the escape boat","Send coordinates from the dock radio",if latest.Run.RadioDone then "COMPLETE" else "+$80",palette.Mint)
        row("Your best escape",if latest.BestMs>0 then duration(latest.BestMs/1000) else "Complete a run to set your best time.","PERSONAL",palette.Muted)
    end
end
local function resize()
    local camera=workspace.CurrentCamera; if not camera then return end
    local viewport=camera.ViewportSize; mobile=viewport.X<700
    local factor=if mobile then math.clamp(viewport.X/450,0.65,1) else math.clamp(math.min(viewport.X/1280,viewport.Y/800),0.65,1.15)
    scale.Scale=factor
    local w,h=viewport.X/factor,math.max(500,(viewport.Y-50)/factor)
    root.Size=UDim2.fromOffset(w,h)
    header.Position=UDim2.fromOffset(16,10); header.Size=UDim2.new(1,-32,0,76)
    title.TextSize=if mobile then 17 else 24; title.Size=UDim2.new(0.62,0,0,32)
    subtitle.TextSize=if mobile then 8 else 10
    cash.TextSize=if mobile then 19 else 24; totals.TextSize=if mobile then 8 else 11
    mission.Position=UDim2.fromOffset(16,100); mission.Size=UDim2.fromOffset(if mobile then w-32 else 320,168)
    quests.Visible=not mobile
    vitals.Position=if mobile then UDim2.fromOffset(16,280) else UDim2.new(0,20,1,-155)
    vitals.Size=UDim2.fromOffset(if mobile then w-32 else 320,91)
    mode.Visible=not mobile
    dock.Size=UDim2.fromOffset(if mobile then w-32 else 540,50)
    dock.Position=UDim2.new(0.5,-(if mobile then w-32 else 540)/2,1,if mobile then -175 else -86)
    sprintButton.Text=if mobile then "SPRINT" else "SPRINT / SHIFT"
    footnote.Size=UDim2.new(1,-32,0,35); footnote.Position=UDim2.new(0,16,1,if mobile then -218 else -34)
    window.Size=UDim2.fromOffset(math.min(w-28,790),math.min(h-90,560))
    windowTitle.TextSize=if mobile then 19 else 24
    toast.Size=UDim2.fromOffset(math.min(w-32,550),72); toast.Position=UDim2.new(0.5,-math.min(w-32,550)/2,0,if mobile then 385 else 106)
    resultCard.Size=UDim2.fromOffset(math.min(w-32,430),230)
end
local cameraConnection
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera); bindCamera()
local function sprintAction(_,inputState)
    if inputState==Enum.UserInputState.Begin then
        if not overlay.Visible then action:FireServer("Sprint",true) end
    elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then
        sprintToggle=false; action:FireServer("Sprint",false)
    end
    return Enum.ContextActionResult.Pass
end
CAS:BindAction("LockbreakSprint",sprintAction,false,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
UIS.WindowFocusReleased:Connect(function() sprintToggle=false; action:FireServer("Sprint",false) end)
UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.B then if overlay.Visible then closeModal() else openModal("Shop") end end
    if input.KeyCode==Enum.KeyCode.Escape then closeModal() end
end)
local toastVersion=0
notice.OnClientEvent:Connect(function(message,kind,result)
    toastVersion+=1; local current=toastVersion
    toastText.Text=message; toastText.TextColor3=if kind=="warning" then palette.Orange else palette.Text
    toast.Visible=true
    task.delay(5,function() if toastVersion==current then toast.Visible=false end end)
    if result then
        resultAmount.Text="+$"..number(result.Reward)
        resultDetail.Text=duration(result.TimeMs/1000).."  /  "..result.Rescues.." inmates rescued\nA new run starts in 5 seconds."
        resultCard.Visible=true
        task.delay(4.8,function() resultCard.Visible=false end)
    end
end)
local marker=Instance.new("Part"); marker.Name="LocalObjectiveMarker"; marker.Size=Vector3.one; marker.Anchored=true
marker.CanCollide=false; marker.CanTouch=false; marker.CanQuery=false; marker.Transparency=1; marker.Parent=workspace
local markerGui=Instance.new("BillboardGui"); markerGui.Size=UDim2.fromOffset(120,50); markerGui.AlwaysOnTop=true
markerGui.StudsOffset=Vector3.new(0,5,0); markerGui.Parent=marker
local markerText=text(markerGui,"MISSION",UDim2.fromScale(1,1),nil,14,palette.Orange,true); markerText.TextXAlignment=Enum.TextXAlignment.Center
local escorts=Instance.new("Folder"); escorts.Name="LocalEscorts"; escorts.Parent=workspace
local followers={}
local function updateWorldVisuals()
    if not latest then return end
    local world=workspace:FindFirstChild("LockbreakWorld"); if not world then return end
    local actors=world:FindFirstChild("Actors"); if not actors then return end
    for _,actor in ipairs(actors:GetChildren()) do
        local id=actor:GetAttribute("InmateId")
        if id then
            local freed=latest.Run.Rescued[id]==true
            for _,item in ipairs(actor:GetDescendants()) do
                if item:IsA("BasePart") then item.LocalTransparencyModifier=if freed then 1 else 0 end
                if item:IsA("BillboardGui") then item.Enabled=not freed end
            end
            if freed and not followers[id] then
                local clone=actor:Clone(); clone.Name="Following "..actor.Name; clone.Parent=escorts
                for _,item in ipairs(clone:GetDescendants()) do
                    if item:IsA("BasePart") then item.LocalTransparencyModifier=0 end
                    if item:IsA("BillboardGui") then item.Enabled=true end
                end
                followers[id]=clone
            elseif not freed and followers[id] then followers[id]:Destroy(); followers[id]=nil end
        end
    end
    for _,item in ipairs(world:GetChildren()) do
        if item:IsA("BasePart") then
            local id=item:GetAttribute("InteractionId"); local prompt=item:FindFirstChildOfClass("ProximityPrompt")
            if id and prompt then
                local done=(id=="key" and latest.Run.Key) or (id=="power" and latest.Run.Power)
                    or (id=="radio" and latest.Run.RadioDone) or (id=="foreman" and latest.Run.ScrapDone)
                local scrap=string.match(id,"^scrap:(%d+)$"); local rescue=string.match(id,"^rescue:(.+)$")
                if scrap then done=latest.Run.Scrap[scrap]==true; item.LocalTransparencyModifier=if done then 0.8 else 0 end
                if rescue then done=latest.Run.Rescued[rescue]==true end
                prompt.Enabled=not done and not latest.Frozen
            end
        end
    end
end
local modalFingerprint=""
stateEvent.OnClientEvent:Connect(function(data)
    latest=data
    cash.Text="$ "..number(data.Cash)
    totals.Text=data.Escapes.." ESCAPES  /  "..data.Rescues.." RESCUES"
    missionTag.Text="MAIN MISSION  /  "..data.Objective.Step
    missionTitle.Text=data.Objective.Title; missionDetail.Text=data.Objective.Detail
    runTime.Text="RUN "..duration(data.Elapsed).."   /   ROLE: "..string.upper(Config.PlayerRole)
    heatText.Text=if data.Heat>0.65 then "POLICE / PURSUIT" elseif data.Heat>0.1 then "POLICE / SUSPICIOUS" else "POLICE / CLEAR"
    heatText.TextColor3=if data.Heat>0.65 then palette.Red else palette.Muted
    heatFill.Size=UDim2.fromScale(data.Heat,1); energyFill.Size=UDim2.fromScale(data.Stamina/data.MaxStamina,1)
    mode.Text=if data.Persistent then "CLOUD PROFILE  /  B TO OPEN SHOP" else "STUDIO PRACTICE  /  TEMPORARY PROGRESS"
    if not data.Sprinting then sprintToggle=false end
    sprintButton.TextColor3=if data.Sprinting then palette.Mint else palette.Text
    local lines={}
    for _,cast in ipairs(Config.Cast) do table.insert(lines,(if data.Run.Rescued[cast.Id] then "✓ " else "○ ")..cast.Name.."   +$75") end
    local count=0; for _ in pairs(data.Run.Scrap) do count+=1 end
    table.insert(lines,(if data.Run.ScrapDone then "✓ " else "○ ").."Workshop  "..count.."/5   +$100")
    table.insert(lines,(if data.Run.RadioDone then "✓ " else "○ ").."Dock radio   +$80")
    questText.Text=table.concat(lines,"\n\n")
    marker.Position=data.Objective.Target; markerGui.Enabled=not data.Frozen
    updateWorldVisuals()
    local fingerprint=data.Cash..data.Skin..tostring(data.VIP)..data.Upgrades.Sprint..data.Upgrades.Stamina..data.Upgrades.Stealth..table.concat(lines)
    if fingerprint~=modalFingerprint then modalFingerprint=fingerprint; if modalKind=="Shop" or modalKind=="Quests" then renderModal() end end
end)
boardEvent.OnClientEvent:Connect(function(rows,status)
    boardRows=rows; boardStatus=status
    if modalKind=="Board" then renderModal() end
end)
RunService.RenderStepped:Connect(function(dt)
    local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not latest then return end
    markerText.Text="▼ MISSION\n"..math.floor((marker.Position-hrp.Position).Magnitude).." studs"
    local index=0
    for _,cast in ipairs(Config.Cast) do
        local follower=followers[cast.Id]
        if follower then
            index+=1
            local position=(hrp.CFrame*CFrame.new((index-1.5)*3,0,5+index*2)).Position
            local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
            ray.FilterDescendantsInstances={char,escorts,workspace.LockbreakWorld.Actors}
            local ground=workspace:Raycast(position+Vector3.new(0,6,0),Vector3.new(0,-25,0),ray)
            local y=if ground then ground.Position.Y+3.3 else position.Y
            local target=CFrame.new(position.X,y,position.Z)*hrp.CFrame.Rotation
            follower:PivotTo(follower:GetPivot():Lerp(target,math.min(1,dt*6)))
        end
    end
end)
task.spawn(function()
    for _,kind in ipairs({"pass","product"}) do
        local items=if kind=="pass" then Config.Passes else Config.Products
        for _,item in pairs(items) do
            if item.Id>0 then
                local ok,info=pcall(Market.GetProductInfo,Market,item.Id,if kind=="pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
                if ok and info and info.IsForSale and info.PriceInRobux then productPrices[kind..item.Id]=info.PriceInRobux end
            end
        end
    end
    if modalKind=="Shop" then renderModal() end
end)
action:FireServer("Ready")
