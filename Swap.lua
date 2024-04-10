local bint = require('.bint')(256)
local ao = require('ao')
local swap = require('mods/swap')

if not LiquidityProviders then LiquidityProviders = {} end
if not ProvidersFees then ProvidersFees = {} end
if not Actions then Actions = {} end
if not Errors then Errors = {} end

FeeRate = 0.01 -- Fee rate (1% in this example)

Token1 = ""
Token2 = ""

Token1Balance = 0
Token2Balance = 0

Handlers.add("response", Handlers.utils.hasMatchingTag('Action', "Response"), swap.responseHandler)
Handlers.add("transfer-error", Handlers.utils.hasMatchingTag('Action', "Transfer-Error"), swap.transferError)
Handlers.add("transferFrom-error", Handlers.utils.hasMatchingTag('Action', "TransferFrom-Error"), swap.transferFromError)
Handlers.add("transferFrom-error", Handlers.utils.hasMatchingTag('Action', "TransferFrom-Error"), swap.transferFromError)
Handlers.add("errors", Handlers.utils.hasMatchingTag('Action', "Errors"), swap.errors)