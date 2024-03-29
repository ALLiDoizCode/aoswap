local bint = require('.bint')(256)
local ao = require('ao')
local token = require('token')

if not Balances then Balances = { [ao.id] = tostring(bint(10000 * 1e12)) } end
if not Allowances then Allowances = {} end

if Name ~= '' then Name = '' end

if Ticker ~= '' then Ticker = '' end

if Denomination ~= 8 then Denomination = 8 end

if not Logo then Logo = '' end

--
Handlers.add('init', Handlers.utils.hasMatchingTag('Action', 'Init'), token.Init)
Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), token.Info)
Handlers.add('balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), token.Balance)
Handlers.add('balances', Handlers.utils.hasMatchingTag('Action', 'Balances'), token.Balances)
Handlers.add('transfer', Handlers.utils.hasMatchingTag('Action', 'Transfer'), token.Transfer)
Handlers.add('mint', Handlers.utils.hasMatchingTag('Action', 'Mint'), token.Mint)
