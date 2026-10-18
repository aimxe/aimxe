-- Pure game rules: the server owns state; tests can run without the Roblox engine.
local Rules = {}
function Rules.newProfile()
    return { Cash = 0, Purchased = 0, Escapes = 0, Rescues = 0, BestMs = 0,
        Skin = "Intake", Owned = { Intake = true }, Upgrades = { Sprint = 0, Stamina = 0, Stealth = 0 } }
end
function Rules.balance(profile) return profile.Cash + profile.Purchased end
function Rules.newRun(now)
    return { Started = now, Key = false, Power = false, Rescued = {}, Scrap = {},
        ScrapDone = false, RadioDone = false, Finished = false }
end
function Rules.count(items)
    local n = 0
    for _, value in pairs(items) do if value then n += 1 end end
    return n
end
function Rules.objective(run)
    if not run.Key then return "01", "STEAL A KEYCARD", "Find the guard office in the west wing.", "key" end
    if not run.Power then return "02", "CUT THE POWER", "Reach the generator in the east utility yard.", "power" end
    return "03", "REACH THE ESCAPE BOAT", "Rescue the optional inmates, then head north to the dock.", "exit"
end
function Rules.interact(run, profile, id, now, config)
    if run.Finished then return false, "Your next run is starting." end
    if id == "key" then
        if run.Key then return false, "You already have the keycard." end
        run.Key = true
        return true, "Keycard acquired. Police can now spot you. Find the generator."
    elseif id == "power" then
        if not run.Key then return false, "You need the guard's keycard." end
        if run.Power then return false, "Security is already disabled for this run." end
        run.Power = true
        return true, "Security disabled. Rescue the inmates or head to the escape boat."
    elseif id == "foreman" then
        if run.ScrapDone then return false, "Workshop quest already completed this run." end
        if Rules.count(run.Scrap) < 5 then return false, "Find all five scrap bundles first." end
        run.ScrapDone = true
        return true, "Workshop quest complete. +100 cash when you escape."
    elseif id == "radio" then
        if not run.Power then return false, "Disable security before sending the radio message." end
        if run.RadioDone then return false, "Radio quest already completed this run." end
        run.RadioDone = true
        return true, "Escape coordinates sent. +80 cash when you escape."
    elseif id == "exit" then
        if not run.Key or not run.Power then return false, "Steal the keycard and cut the power first." end
        local rescued = Rules.count(run.Rescued)
        local reward = config.BaseReward + rescued * config.RescueReward
            + (if run.ScrapDone then config.ScrapReward else 0)
            + (if run.RadioDone then config.RadioReward else 0)
        local ms = math.max(1, math.floor((now - run.Started) * 1000))
        profile.Cash += reward; profile.Escapes += 1; profile.Rescues += rescued
        if profile.BestMs == 0 or ms < profile.BestMs then profile.BestMs = ms end
        run.Finished = true
        return true, "ESCAPED! +" .. reward .. " cash", { Reward = reward, Rescues = rescued, TimeMs = ms }
    end
    local kind, value = string.match(id, "^(%w+):(.+)$")
    if kind == "scrap" then
        local index = tonumber(value)
        if not index or index % 1 ~= 0 or index < 1 or index > 5 or tostring(index) ~= value then return false, "Unknown scrap bundle." end
        if run.Scrap[value] then return false, "You already collected this bundle." end
        run.Scrap[value] = true
        return true, "Scrap " .. Rules.count(run.Scrap) .. "/5. Bring all five to the workshop foreman."
    elseif kind == "rescue" then
        local cast
        for _, inmate in ipairs(config.Cast) do if inmate.Id == value then cast = inmate end end
        if not cast then return false, "Unknown inmate." end
        if not run.Power then return false, "Cut the power to release the cell locks." end
        if run.Rescued[value] then return false, "This inmate is already following you." end
        run.Rescued[value] = true
        return true, cast.Name .. " is following you. Get to the boat for the rescue bonus."
    end
    return false, "Unknown interaction."
end
function Rules.buy(profile, category, id, config)
    if category == "Skin" then
        local skin = config.Skins[id]
        if not skin then return false, "Unknown skin." end
        if not profile.Owned[id] then
            if Rules.balance(profile) < skin.Price then return false, "Not enough cash." end
            profile.Cash -= skin.Price; profile.Owned[id] = true
        end
        profile.Skin = id
        return true, skin.Name .. " equipped."
    elseif category == "Upgrade" then
        local upgrade = config.Upgrades[id]
        if not upgrade then return false, "Unknown upgrade." end
        local level = profile.Upgrades[id]
        if level >= upgrade.Max then return false, "Already fully upgraded." end
        local price = upgrade.Prices[level + 1]
        if Rules.balance(profile) < price then return false, "You need " .. price .. " cash." end
        profile.Cash -= price; profile.Upgrades[id] += 1
        return true, upgrade.Name .. " upgraded to level " .. profile.Upgrades[id] .. "."
    end
    return false, "Unknown purchase."
end
return Rules
