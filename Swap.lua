local bint = require('.bint')(256)
local ao = require('ao')
local swap = require('mods/swap')

if not LiquidityProviders then LiquidityProviders = {} end
if not ProvidersFees then ProvidersFees = {} end
if not Data then Data = {} end

FeeRate = 0.01 -- Fee rate (1% in this example)

Token1 = ""
Token2 = ""

Handlers.add("response", Handlers.utils.hasMatchingTag('Action', "Response"), swap.responseHandler)