local ao = require('ao');
local json = require('json');
local crypto = require(".crypto");

if not Pools then Pools = {} end;
if not PoolRequest then PoolRequest = {} end;

local token_module = ""
local pool_module = ""

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    local uuid = UUID();
    local _request = json.decode(msg.Request)
    local request = {
        TokenB = _request.TokenB,
        Minter = msg.From,
        Name = _request.Name,
        Ticker = _request.Ticker,
        Logo = _request.Logo,
        Denomination = _request.Denomination,
        BondingCurve = _request.BondingCurve
    }
    PoolRequest[uuid] = request;
    SpawnToken(uuid, request)
end)

Handlers.add('Token-Request', Handlers.utils.hasMatchingTag('Action', 'Token-Request'), function(msg)
    local processId = msg.From;
    local request = PoolRequest[msg.UUID];
    SpawnPool(msg.UUID, processId, request.TokenB, request.BondingCurve);
end)

Handlers.add('Pool-Request', Handlers.utils.hasMatchingTag('Action', 'Swap-Request'), function(msg)
    local processId = msg.From;
    local request = PoolRequest[msg.UUID];
    local pool = {
        TokenA = msg.TokenA,
        TokenB = request.TokenB,
        Pool = processId,
        Minter = request.Minter,
        Name = request.Name,
        Ticker = request.Ticker,
        Logo = request.Logo,
        Denomination = request.Denomination,
        BondingCurve = request.BondingCurve
    }
    Pools[processId] = pool
end)

function SpawnToken(uuid, request)
    ao.spawn(token_module, {
        Action = "init",
        UUID = uuid,
        Name = request.Name,
        Ticker = request.Ticker,
        Logo = request.Logo,
        Denomination = Utils.toNumber(request.Denomination)
    })
end

function SpawnPool(uuid, tokenA, tokenB, bondingCurve)
    ao.spawn(pool_module, {
        Action = "Init",
        UUID = uuid,
        TokenA = tokenA,
        TokenB = tokenB,
        BondingCurve = bondingCurve
    })
end

function UUID()
    local random = math.random
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end
