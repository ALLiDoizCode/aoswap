local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json')
local crypto = require(".crypto");
Mod = {}
-- Function to provide liquidity to the pool
function Mod.addLiquidity(msg)
    -- Calculate proportionate amount of token2 needed
    local amountToken2 = calculateToken2Needed(msg.amountToken1)
    local feeAmount = (msg.amountToken1 + amountToken2) * FeeRate

    -- Build Message chain
    local _nonce = nonce()
    local nextNonce = nonce()
    local action = {
        caller = msg.caller,
        Target = Token2,
        Action = "TransferFrom",
        Recipient = ao.id,
        Quantity = tostring(amountToken2),
        Nonce = _nonce,
        NextNonce = nextNonce,
        LastNonce = nil,
    }
    Actions[_nonce] = action
    action = {
        caller = msg.caller,
        Action = "AddLiquidity",
        feeAmount = feeAmount,
        Nonce = nextNonce,
        NextNonce = nil,
        LastNonce = _nonce,
    }
    Actions[nextNonce] = action
    tranferFrom(action)
end

-- Function to remove liquidity from the pool
function Mod.removeLiquidity(msg)
    -- Calculate proportionate amounts of tokens to be withdrawn
    local token1Amount = (msg.Liquidity / (Token1Balance + Token2Balance)) * Token1Balance
    local token2Amount = (msg.Liquidity / (Token1Balance + Token2Balance)) * Token2Balance

    local _nonce = nonce()
    local nextNonce = nonce()
    local lastNonce = nonce()
    local action = {
        caller = msg.caller,
        Target = Token1,
        Action = "Transfer",
        Recipient = ao.id,
        Quantity = tostring(token1Amount),
        Nonce = _nonce,
        NextNonce = nextNonce,
        LastNonce = nil,
    }
    Actions[_nonce] = action
    local nextAction = {
        caller = msg.caller,
        Target = Token2,
        Action = "Transfer",
        Recipient = ao.id,
        Quantity = tostring(token2Amount),
        Nonce = nextNonce,
        NextNonce = nil,
        LastNonce = _nonce,
    }
    Actions[nextNonce] = nextAction
    local lastAction = {
        caller = msg.caller,
        Action = "RemoveLiquidity",
        Liquidity = msg.Liquidity,
        Nonce = lastNonce,
        NextNonce = nil,
        LastNonce = nextNonce,
    }
    Actions[lastNonce] = lastAction
    tranfer(action)
end

-- Function to swap tokens given token1 amount
function Mod.swapGivenToken1(msg)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token2 to receive
    local expectedAmountToken2 = (msg.amountToken1 / Token1Balance) * Token2Balance

    -- Calculate slippage
    local slippageToken2 = 1 - (expectedAmountToken2 / ((msg.amountToken1 / Token1Balance) * Token2Balance))

    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken2) > msg.slippageToken1Threshold then
        -- slippage to high
    else
        local _nonce = nonce()
        local nextNonce = nonce()
        local action = {
            caller = msg.caller,
            Target = Token1,
            Action = "TransferFrom",
            Recipient = ao.id,
            Quantity = tostring(msg.amountToken1),
            Nonce = _nonce,
            NextNonce = nextNonce,
            LastNonce = nil,
        }
        Actions[_nonce] = action
        local nextAction = {
            caller = msg.caller,
            Target = Token2,
            Action = "Transfer",
            Recipient = ao.id,
            Quantity = tostring(expectedAmountToken2),
            Nonce = nextNonce,
            NextNonce = nil,
            LastNonce = _nonce,
        }
        Actions[nextNonce] = nextAction
        tranferFrom(action)
        rewardLiquidityProviders(msg.amountToken1, Token1)
    end
end

-- Function to swap tokens given token2 amount
function Mod.swapGivenToken2(msg)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token1 to receive
    local expectedAmountToken1 = (msg.amountToken2 / Token2Balance) * Token1Balance

    -- Calculate slippage
    local slippageToken1 = 1 - (expectedAmountToken1 / ((msg.amountToken2 / Token2Balance) * Token1Balance))

    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken1) > msg.slippageToken1Threshold then
        -- slippage to high
    else
        local _nonce = nonce()
        local nextNonce = nonce()
        local action = {
            caller = msg.caller,
            Target = Token2,
            Action = "TransferFrom",
            Recipient = ao.id,
            Quantity = tostring(msg.amountToken2),
            Nonce = _nonce,
            NextNonce = nextNonce,
            LastNonce = nil,
        }
        Actions[_nonce] = action
        local nextAction = {
            caller = msg.caller,
            Target = Token1,
            Action = "Transfer",
            Recipient = ao.id,
            Quantity = tostring(expectedAmountToken1),
            Nonce = nextNonce,
            NextNonce = nil,
            LastNonce = _nonce,
        }
        Actions[nextNonce] = nextAction
        tranferFrom(action)
        rewardLiquidityProviders(msg.amountToken2, Token2)
    end
end

-- Function to get estimate for slippage given token1
function Mod.slippageGivenToken1(amountToken1)
    -- Calculate expected amount of token1 to receive
    local expectedAmountToken2 = (amountToken1 / Token1Balance) * Token2Balance

    -- Calculate slippage
    local slippageToken2 = 1 - (expectedAmountToken2 / ((amountToken1 / Token1Balance) * Token2Balance))
end

-- Function to get estimate for slippage given token2
function Mod.slippageGivenToken2(amountToken2)
    -- Calculate expected amount of token1 to receive
    local expectedAmountToken1 = (amountToken2 / Token2Balance) * Token1Balance

    -- Calculate slippage
    local slippageToken1 = 1 - (expectedAmountToken1 / ((amountToken2 / Token2Balance) * Token1Balance))
end

-- Function to caculate liquidity reward
function Mod.liquidityFees(provider)
    local token1 = ProvidersFees[provider][Token1]
    local token2 = ProvidersFees[provider][Token2]
end

function Mod.liquidityRewards(provider)
    local liquidity = LiquidityProviders[provider]
end

-- Function to reward liquidity providers with fees
function Mod.rewardLiquidityProviders(tradeAmount, tradeToken)
    -- Calculate fee amount for the trade
    local feeAmount = tradeAmount * FeeRate

    -- Calculate the total liquidity pool value
    local totalPoolValue = Token1Balance + Token2Balance

    -- Iterate through each liquidity provider
    for provider, liquidityAmount in pairs(LiquidityProviders) do
        -- Calculate the liquidity provider's share of the fees based on their liquidity contribution
        local providerReward = feeAmount * liquidityAmount / totalPoolValue
        -- Check the direction of the trade and distribute fees accordingly
        if tradeToken == Token1 then
            -- Reward liquidity provider with fees from trade of token1
            ProvidersFees[provider][Token1] = ProvidersFees[provider][Token1] + providerReward
        elseif tradeToken == Token2 then
            -- Reward liquidity provider with fees from trade of token2
            ProvidersFees[provider][Token2] = ProvidersFees[provider][Token2] + providerReward
        end
    end
end

-- Function for liquidity providers to claim their rewards
function Mod.claimRewards(provider)
    local token1 = ProvidersFees[provider][Token1]
    local token2 = ProvidersFees[provider][Token2]
    -- Call Transfer to transfer token1
    -- Call Transfer to transfer token2
    ProvidersFees[provider][Token1] = 0
    ProvidersFees[provider][Token2] = 0
end

function Mod.errors(msg)
    ao.send({ Target = msg.From, Errors = json.encode(Errors) })
end

function Mod.transferError(msg)
    if Actions[msg.Nonce] then
        local action = Actions[msg.Nonce]
        if Actions[action.LastNonce] then
            local lastAction = Actions[msg.LastNonce]
            if lastAction.Action == "TransferFrom" then
                --transfer back tokens
                lastAction.Recipient = action.caller
                lastAction.Action = "Transfer"
                lastAction.Nonce = nil
                tranfer(lastAction)
            end
        end
    end
end

function Mod.transferFromError(msg)
    if Actions[msg.Nonce] then
        local action = Actions[msg.Nonce]
        if Actions[action.LastNonce] then
            local lastAction = Actions[msg.LastNonce]
            if lastAction.Action == "TransferFrom" then
                --transfer back tokens
                lastAction.Recipient = action.caller
                lastAction.Action = "Transfer"
                lastAction.Nonce = nil
                tranfer(lastAction)
            end
        end
    end
end

function Mod.responseHandler(msg)
    if msg.Balance then
        BalanceResponse(msg)
    else
        if msg.Nonce then
            local action = Actions[msg.Nonce]
            actionHandler(action)
        end
    end
end

function ErrorResponse(msg)
    if not msg.Target == ao.id then
        ao.send({
            Target = msg.Target,
            Error = msg.Error,
            ['Message-Id'] = msg['Message-Id'],
        })()
    end
    Errors[msg.id] = msg
end

function BalanceResponse(msg)
    if msg.from == Token1 then
        Token1Balance = msg.Balance
    end
    if msg.from == Token2 then
        Token2Balance = msg.Balance
    end
end


function actionHandler(action)
    if action.Action == "TransferFrom" then
        tranferFrom(action)
        balance(action.Target)
    end
    if action.Action == "Transfer" then
        tranfer(action)
        balance(action.Target)
    end
    if action.Action == "AddLiquidity" then
        -- Store liquidity amount for the provider
        if not LiquidityProviders[action.Provider] then
            LiquidityProviders[action.Provider] = 0
        end
        LiquidityProviders[action.Provider] = LiquidityProviders[action.Provider] + action.FeeAmount
        -- handle success
    end
    if action.Action == "RemoveLiquidity" then
        -- Deduct liquidity amount for the provider
        LiquidityProviders[action.caller] = LiquidityProviders[action.caller] - action.Liquidity
        -- handle success
    end
end

function tranfer(action)
    ao.send(action)()
end

function tranferFrom(action)
    ao.send(action)()
end

function balance(token)
    ao.send({
        Target = token,
        Action = "Balance",
        Tags = { Target = ao.id },
    })()
end

function nonce()
    local v = tostring(math.random()):sub(-13)
    return tostring(v)
end

return Mod
