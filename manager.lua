local ao = require('ao');
local json = require('json');
local crypto = require(".crypto");

if not Pools then Pools = {} end;
if not TokenRequest then TokenRequest = {} end;
if not PoolRequest then PoolRequest = {} end;

local token_module = ""
local swap_module = ""

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    local request = json.decode(msg.Request)
    local uuid = UUID();
    TokenRequest[uuid] = request;
    PoolRequest[uuid] = request;
    SpawnToken(msg.From, request)
end)

Handlers.add('Token-Request', Handlers.utils.hasMatchingTag('Action', 'Token-Request'), function(msg)
    local uuid = msg.UUID;
    local processId = msg.From;
    local request = TokenRequest[uuid]
    Utils.result(msg.From, 200, uuid);
end)

Handlers.add('Pool-Request', Handlers.utils.hasMatchingTag('Action', 'Swap-Request'), function(msg)
    local uuid = msg.UUID;
    local processId = msg.From;
    local request = PoolRequest[uuid]
    Utils.result(msg.From, 200, uuid)
end)

function SpawnToken(minter, uuid, request)
    ao.spawn(token_module, {
        Action = "init",
        UUID = uuid,
        Minter = minter,
        Name = request.name,
        Ticker = request.ticker,
        Logo = request.logo,
        Denomination = Utils.toNumber(request.denomination)
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
