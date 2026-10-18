local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Config)
local Rules = require(RS.Rules)
local Data = require(RS.ProfileData)
local Profiles = { Sessions = {}, Board = {}, BoardStatus = "Loading rankings" }
Profiles.Persistent = not RunService:IsStudio() or Config.StudioPersistence
local store = if Profiles.Persistent then DSS:GetDataStore(Config.StoreName) else nil
local ranking = if Profiles.Persistent then DSS:GetOrderedDataStore(Config.RankingName) else nil
local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
local names = {}

local function validProfile(d)
    if type(d) ~= "table" or type(d.Owned) ~= "table" or type(d.Upgrades) ~= "table" then return false end
    for _, key in ipairs({ "Cash", "Escapes", "Rescues", "BestMs" }) do
        if type(d[key]) ~= "number" or d[key] ~= d[key] or math.abs(d[key]) > 1e14 or d[key] % 1 ~= 0 then return false end
    end
    if d.Escapes < 0 or d.Rescues < 0 or d.BestMs < 0 or not Config.Skins[d.Skin] or not d.Owned[d.Skin] then return false end
    for name, upgrade in pairs(Config.Upgrades) do
        local n = d.Upgrades[name]
        if type(n) ~= "number" or n % 1 ~= 0 or n < 0 or n > upgrade.Max then return false end
    end
    return true
end

function Profiles:Load(player)
    if not self.Persistent then
        local s = { Data = Rules.newProfile(), LeaseUntil = math.huge, LastSave = os.clock() }
        self.Sessions[player] = s
        return s
    end
    local success, record, reason
    local sessionToken = token .. ":" .. HttpService:GenerateGUID(false)
    for attempt = 1, 3 do
        success, record = pcall(function()
            return store:UpdateAsync(tostring(player.UserId), function(old)
                if old and (not validProfile(old.Data) or type(old.Purchased) ~= "number" or old.Purchased < 0
                    or old.Purchased ~= old.Purchased or old.Purchased % 1 ~= 0 or type(old.Receipts) ~= "table") then
                    reason = "Stored profile could not be validated. Your data has been left unchanged."
                    return nil
                end
                local result, problem = Data.acquire(old, Rules.newProfile(), sessionToken, os.time(), Config.LeaseSeconds)
                reason = problem
                return result
            end)
        end)
        if success then break end
        task.wait(attempt)
    end
    if not success or not record then return nil, reason or "Profile storage unavailable. Please rejoin shortly." end
    record.Data.Purchased = record.Purchased
    local s = { Data = record.Data, Token = sessionToken, LeaseUntil = record.Lease.Expires,
        LastSave = os.clock(), CommittedEscapes = record.Data.Escapes }
    self.Sessions[player] = s
    return s
end

function Profiles:Available(player)
    local s = self.Sessions[player]
    return s ~= nil and not s.Closing and not s.Lost and os.time() < s.LeaseUntil - 10
end

function Profiles:Save(player, receipt, release)
    local s = self.Sessions[player]
    if not s or s.Lost or (s.Closing and not release) then return false end
    if release then s.Closing = true end
    local deadline = os.clock() + 20
    while s.Busy and os.clock() < deadline do task.wait(0.05) end
    if s.Busy or s.Lost then return false end
    -- A release may have started while this caller was waiting on the write lock.
    if s.Closing and not release then return false end
    if not self.Persistent then return receipt == nil end
    s.Busy = true
    local snapshot = Data.copy(s.Data)
    local reason
    local ok, result = pcall(function()
        return store:UpdateAsync(tostring(player.UserId), function(old)
            local nextRecord, problem = Data.commit(old, snapshot, s.Token, os.time(), Config.LeaseSeconds, receipt, release)
            reason = problem
            return nextRecord
        end)
    end)
    if ok and result then
        -- Never replace the live wallet: gameplay can award/spend earned funds during a write.
        -- The purchased ledger is independent and monotonic, including ambiguous previous writes.
        s.Data.Purchased = result.Purchased
        s.LastSave = os.clock()
        s.CommittedEscapes = snapshot.Escapes
        if not release then s.LeaseUntil = result.Lease.Expires end
    elseif ok and reason then
        s.Lost = true
        player:Kick("Your profile moved to another server. Please rejoin.")
    else
        warn("Lockbreak: profile write failed for user " .. player.UserId .. "; keeping data in memory.")
    end
    s.Busy = false
    return ok and result ~= nil
end

function Profiles:Release(player)
    local s = self.Sessions[player]
    if not s then return end
    if s.Releasing then
        while self.Sessions[player] == s do task.wait(0.05) end
        return
    end
    s.Releasing = true; s.Closing = true
    for attempt = 1, 3 do
        if self:Save(player, nil, true) then break end
        if s.Lost then break end
        task.wait(attempt)
    end
    self.Sessions[player] = nil
end

function Profiles:UpdateRanking(player)
    local s = self.Sessions[player]
    if not ranking or not s then return end
    local score = s.CommittedEscapes or 0
    local ok = pcall(function()
        ranking:UpdateAsync(tostring(player.UserId), function(old) return math.max(old or 0, score) end)
    end)
    if not ok then warn("Lockbreak: ranking update unavailable; profile and rewards are unaffected.") end
end

function Profiles:RefreshBoard()
    if not ranking then
        self.BoardStatus = "STUDIO SESSION · progress is temporary"
        self.Board = {}
        for p, s in pairs(self.Sessions) do table.insert(self.Board, { UserId = p.UserId, Name = p.DisplayName, Escapes = s.Data.Escapes }) end
        table.sort(self.Board, function(a, b) return a.Escapes > b.Escapes end)
        return
    end
    local ok, page = pcall(function() return ranking:GetSortedAsync(false, 10):GetCurrentPage() end)
    if not ok then self.BoardStatus = "Rankings unavailable · showing last successful update"; return end
    self.BoardStatus = "GLOBAL · updates about once a minute"
    local rows = {}
    for _, entry in ipairs(page) do
        local id = tonumber(entry.key)
        if id then
            if not names[id] then
                local player = Players:GetPlayerByUserId(id)
                if player then names[id] = player.DisplayName
                else
                    local resolved, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
                    if resolved then names[id] = name end
                end
            end
            table.insert(rows, { UserId = id, Name = names[id] or ("Player " .. entry.key), Escapes = entry.value })
        end
    end
    self.Board = rows
end
return Profiles
