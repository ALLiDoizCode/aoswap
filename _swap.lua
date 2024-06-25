local ao = require('ao');
local json = require('json');

if not tokenInfo then tokenInfo = {} end;
if not shares then shares = {} end;
if not balances then balances = {} end;

Handlers.add('init', Handlers.utils.hasMatchingTag('Action', 'Init'), Init(msg));

function Init(msg)
    ao.isTrusted(msg)
end