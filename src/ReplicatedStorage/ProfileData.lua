-- Pure retry-safe storage transforms. Cash excludes lifetime purchased credits.
local Data = {}
function Data.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = Data.copy(entry) end
    return result
end
function Data.acquire(old, defaults, token, now, leaseSeconds)
    local value = Data.copy(old or { Data = defaults, Purchased = 0, Receipts = {} })
    if value.Lease and value.Lease.Owner ~= token and value.Lease.Expires > now then
        return nil, "Your profile is still active on another server. Please retry shortly."
    end
    value.Lease = { Owner = token, Expires = now + leaseSeconds }
    return value
end
function Data.commit(old, snapshot, token, now, leaseSeconds, receipt, release)
    if not old or not old.Lease or old.Lease.Owner ~= token then return nil, "Session ownership changed." end
    local value = Data.copy(old)
    value.Data = Data.copy(snapshot)
    value.Data.Purchased = nil
    value.Purchased = value.Purchased or 0
    value.Receipts = value.Receipts or {}
    if receipt and not value.Receipts[receipt.Id] then
        value.Receipts[receipt.Id] = receipt.Credits
        value.Purchased += receipt.Credits
    end
    value.Lease = if release then nil else { Owner = token, Expires = now + leaseSeconds }
    return value
end
return Data
