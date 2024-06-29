local json = require('json');
local ao = require('ao');

local token_module = "SBNb1qPQ1TDwpD_mboxm2YllmMLXpWw4U8P9Ff8W9vk";

local spawnCount = 0;

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    ao.spawn(token_module,{})
    Utils.result(msg.from,200,'Success')
end)

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    spawnCount = spawnCount + 1;
end)

Handlers.add('SpawnedCount', Handlers.utils.hasMatchingTag('Action', 'SpawnedCount'), function(msg)
    Utils.result(msg.from,200,spawnCount)
end)

Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end,
    result = function(target, code, message)
        ao.send({
            Target = target,
            Data = json.encode({ code = code, message = message })
        });
    end
}

