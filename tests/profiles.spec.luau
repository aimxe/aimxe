-- Executes the actual Profiles module with a deterministic DataStore double.
-- This tests storage orchestration; it is not a live Roblox service test.
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local Data=require('../src/ReplicatedStorage/ProfileData')
local Rules=require('../src/ReplicatedStorage/Rules')
local BaseConfig=require('../src/ReplicatedStorage/Config')
local source=fs.readFile('src/ServerScriptService/Modules/Profiles.lua')
local passed,failed=0,0
local function equal(actual,expected) assert(actual==expected,'expected '..tostring(expected)..', got '..tostring(actual)) end
local function test(name,fn)
    local ok,err=pcall(fn)
    if ok then passed+=1; print('PASS '..name) else failed+=1; print('FAIL '..name..': '..tostring(err)) end
end
local function fixture(studio)
    local config=Data.copy(BaseConfig)
    local store={Records={},Calls=0,FailBefore=0,FailAfter=false,YieldAfter=false}
    function store:UpdateAsync(key,transform)
        self.Calls+=1
        if self.FailBefore>0 then self.FailBefore-=1; error('simulated outage') end
        local result=transform(Data.copy(self.Records[key]))
        if result==nil then return nil end
        self.Records[key]=Data.copy(result)
        if self.YieldAfter then self.YieldAfter=false; coroutine.yield('committed') end
        if self.FailAfter then self.FailAfter=false; error('simulated response loss after commit') end
        return Data.copy(result)
    end
    local guid=0
    local rank={UpdateAsync=function(_,_,transform) transform(0) end}
    local services={
        DataStoreService={GetDataStore=function() return store end,GetOrderedDataStore=function() return rank end},
        RunService={IsStudio=function() return studio end},
        HttpService={GenerateGUID=function() guid+=1; return tostring(guid) end},
        ReplicatedStorage={Config=config,Rules=Rules,ProfileData=Data},
        Players={GetPlayerByUserId=function() return nil end,GetNameFromUserIdAsync=function(_,id) return 'User'..id end},
    }
    local game={JobId='test-server',GetService=function(_,name) return assert(services[name],name) end}
    local module=luau.load(source,{environment={game=game,require=function(value) return value end,
        warn=function() end,task={wait=function() coroutine.yield('waiting') end}},injectGlobals=true})()
    local function player(id)
        return {UserId=id or 1,DisplayName='Tester',Parent=true,Kick=function(self,message) self.Kicked=message end}
    end
    return module,store,player
end
local function finish(thread)
    local result
    for _=1,30 do
        local ok,value=coroutine.resume(thread); assert(ok,value); result=value
        if coroutine.status(thread)=='dead' then return result end
    end
    error('Coroutine failed to finish')
end

test('Studio practice does not contact DataStores',function()
    local service,store,player=fixture(true); local p=player(); local s=service:Load(p)
    equal(store.Calls,0); equal(service.Persistent,false); equal(service:Available(p),true)
    s.Data.Cash=250; equal(service:Save(p),true); equal(store.Calls,0)
end)
test('live load takes a lease and restores an independent purchased balance',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    assert(s.Token); equal(store.Records['1'].Lease.Owner,s.Token); equal(service:Available(p),true)
end)
test('rapid same-server rejoin cannot reuse an unreleased session token',function()
    local service,_,player=fixture(false); local first=player(); service:Load(first)
    local duplicate,reason=service:Load(player()); equal(duplicate,nil); assert(reason:find('another server'))
end)
test('failed loads do not replace existing records with blank profiles',function()
    local service,store,player=fixture(false); store.FailBefore=3
    local p=player(); local thread=coroutine.create(function()
        local session,reason=service:Load(p); equal(session,nil); assert(reason); equal(service.Sessions[p],nil)
    end)
    finish(thread); equal(store.Records['1'],nil)
end)
test('invalid stored schema is preserved and rejected',function()
    local service,store,player=fixture(false); store.Records['1']={Data={Cash=700},Purchased=0,Receipts={}}
    local session,reason=service:Load(player()); equal(session,nil); assert(reason:find('validated'))
    equal(store.Records['1'].Data.Cash,700)
end)
test('save completion does not overwrite concurrent gameplay rewards',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    s.Data.Cash=100; store.YieldAfter=true
    local thread=coroutine.create(function() assert(service:Save(p,{Id='one',Credits=500})) end)
    local ok,marker=coroutine.resume(thread); assert(ok); equal(marker,'committed')
    s.Data.Cash+=150; finish(thread)
    equal(s.Data.Cash,250); equal(s.Data.Purchased,500); equal(Rules.balance(s.Data),750)
    assert(service:Save(p)); equal(store.Records['1'].Data.Cash,250)
end)
test('lost receipt response is reconciled by autosave and not granted twice',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    store.FailAfter=true
    equal(service:Save(p,{Id='one',Credits=500}),false); equal(s.Data.Purchased,0)
    s.Data.Cash=150; assert(service:Save(p)); equal(s.Data.Purchased,500)
    assert(service:Save(p,{Id='one',Credits=500})); equal(Rules.balance(s.Data),650)
end)
test('concurrent save and receipt are serialized before snapshot creation',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    store.YieldAfter=true
    local first=coroutine.create(function() assert(service:Save(p)) end)
    local second=coroutine.create(function() assert(service:Save(p,{Id='one',Credits=500})) end)
    assert(coroutine.resume(first)); local ok,marker=coroutine.resume(second); assert(ok); equal(marker,'waiting')
    s.Data.Cash=200; finish(first); finish(second)
    equal(store.Records['1'].Data.Cash,200); equal(s.Data.Purchased,500)
end)
test('lease loss prevents further writes and removes the player',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    store.Records['1'].Lease.Owner='another-server'
    equal(service:Save(p),false); equal(s.Lost,true); assert(p.Kicked); equal(service:Available(p),false)
end)
test('release waits for an in-flight receipt and saves final progress',function()
    local service,store,player=fixture(false); local p=player(); local s=service:Load(p)
    store.YieldAfter=true
    local receipt=coroutine.create(function() assert(service:Save(p,{Id='one',Credits=500})) end)
    assert(coroutine.resume(receipt)); s.Data.Cash=200
    local release=coroutine.create(function() service:Release(p) end)
    local ok,marker=coroutine.resume(release); assert(ok); equal(marker,'waiting'); equal(service:Available(p),false)
    finish(receipt); finish(release)
    equal(service.Sessions[p],nil); equal(store.Records['1'].Lease,nil)
    equal(store.Records['1'].Data.Cash,200); equal(store.Records['1'].Purchased,500)
    local restored=service:Load(player()); equal(Rules.balance(restored.Data),700)
end)
print(string.format('\n%d passed; %d failed',passed,failed))
assert(failed==0,'Storage orchestration tests failed')
