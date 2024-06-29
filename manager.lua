local json = require('json');
local ao = require('ao');

local token_module = "Pq2Zftrqut0hdisH_MC2pDOT6S4eQFoxGsFUzR6r350";

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    ao.spawn(token_module)
end)

