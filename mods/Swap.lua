local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json')
local crypto = require(".crypto");
Mod = {}
-- Function to provide liquidity to the pool
function Mod.addLiquidity(amountToken1, provider)
    -- Calculate proportionate amount of token2 needed
    local amountToken2 = calculateToken2Needed(amountToken1)
    local feeAmount = (amountToken1 + amountToken2) * FeeRate

    -- Build Message chain
    local _nonce = nonce()
    local nextNonce = nonce()
    local data = {
        caller = provider,
        Target = Token2,
        Action = "TransferFrom",
        Recipient = ao.id,
        Quantity = tostring(amountToken2),
        AmountToken1 = tostring(amountToken1),
        Nonce = nextNonce,
    }
    Data[_nonce] = data
    data = {
        caller = provider,
        Action = "AddLiquidity",
        Provider = provider,
        feeAmount = feeAmount,
        Nonce = nil,
    }
    Data[nextNonce] = data
    tranferFrom(Token1, provider, ao.id, amountToken1, _nonce)
end

-- Function to remove liquidity from the pool
function Mod.removeLiquidity(amountLiquidity, provider)
    -- Calculate proportionate amounts of tokens to be withdrawn
    local token1Amount = (amountLiquidity / (Token1Balance + Token2Balance)) * Token1Balance
    local token2Amount = (amountLiquidity / (Token1Balance + Token2Balance)) * Token2Balance

    tranfer(Token1, provider, token1Amount)
    tranfer(Token2, provider, token2Amount)

    -- Deduct liquidity amount for the provider
    LiquidityProviders[provider] = LiquidityProviders[provider] - amountLiquidity
end

-- Function to swap tokens given token1 amount
function Mod.swapGivenToken1(amountToken1, slippageToken1Threshold, caller)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token2 to receive
    local expectedAmountToken2 = (amountToken1 / Token1Balance) * Token2Balance

    -- Calculate slippage
    local slippageToken2 = 1 - (expectedAmountToken2 / ((amountToken1 / Token1Balance) * Token2Balance))

    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken2) > slippageToken1Threshold then
        return nil -- Return nil to indicate swap failure
    end

    local _nonce = nonce()
    local data = {
        caller = caller,
        Target = Token2,
        Action = "Transfer",
        Recipient = ao.id,
        Quantity = tostring(expectedAmountToken2),
        AmountToken1 = tostring(amountToken1),
        Nonce = _nonce,
    }
    Data[_nonce] = data
    tranferFrom(Token1, caller, ao.id, amountToken1, _nonce)
    -- Perform the swap
    -- Call TransferFrom to transfer token1
    -- Call Transfer to transfer token2
    rewardLiquidityProviders(amountToken1, Token1)
end

-- Function to swap tokens given token2 amount
function Mod.swapGivenToken2(amountToken2, slippageToken1Threshold)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token1 to receive
    local expectedAmountToken1 = (amountToken2 / Token2Balance) * Token1Balance

    -- Calculate slippage
    local slippageToken1 = 1 - (expectedAmountToken1 / ((amountToken2 / Token2Balance) * Token1Balance))

    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken1) > slippageToken1Threshold then
        return nil -- Return nil to indicate swap failure
    end

    -- Perform the swap
    -- Call TransferFrom to transfer token2
    -- Call Transfer to transfer token1
    rewardLiquidityProviders(token2Amount, Token2)
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

function Mod.responseHandler(msg)
    if msg.Error then
        ErrorResponse(msg)
    elseif msg.Balance then
        BalanceResponse(msg)
    else
        if msg.Nonce then
            local data = Data[msg.Nonce]
            dataHandler(data, msg)
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

--[[ function Mod.responseHandler(msg)
    if msg.Error and not msg.Nonce then
        -- Handle Errors
    elseif msg.Balance then
        if msg.from == Token1 then
            Token1Balance = msg.Balance
        end
        if msg.from == Token2 then
            Token2Balance = msg.Balance
        end
    else
        if Data[msg.Nonce] then
            local data = Data[msg.Nonce]
            if msg.Error then
                if msg.from == Token2 then
                    --transfer back token1 amount
                    tranfer(Token1, data.caller, data.AmountToken1)
                elseif msg.from == Token2 then
                end
                ao.send({
                    Target = data.caller,
                    Action = 'Response',
                    ['Message-Id'] = msg.Id,
                    Error = msg.Error,
                    Nonce = nil,
                })
            else
                -- handle data
                dataHandler(data, msg)
            end
        end
    end
end ]]
--

function dataHandler(data, msg)
    if data.Action == "TransferFrom" then
        tranferFrom(data.Target, data.caller, data.Recipient, data.Quantity, data.Nonce)
    end
    if data.Action == "Transfer" then
        tranfer(data.Target, data.Recipient, data.Quantity)
        balance(data.Target)
    end
    if data.Action == "AddLiquidity" then
        -- get updated balances for Token1 and Token2
        balance(Token1)
        balance(Token2)
        -- Store liquidity amount for the provider
        if not LiquidityProviders[data.Provider] then
            LiquidityProviders[data.Provider] = 0
        end
        LiquidityProviders[data.Provider] = LiquidityProviders[data.Provider] + data.FeeAmount
        -- handle success
    end
end

function tranfer(token, recipient, quantity, nonce)
    ao.send({
        Target = token,
        Action = "Transfer",
        Recipient = recipient,
        Quantity = tostring(quantity),
        Nonce = nonce,
    })()
end

function tranferFrom(token, ownerBalance, recipient, quantity, nonce)
    ao.send({
        Target = token,
        Action = "TransferFrom",
        OwnerBalance = ownerBalance,
        Recipient = recipient,
        Quantity = tostring(quantity),
        Nonce = nonce,
    })()
end

function allowance(token, target)
    local _nonce = nonce()
    ao.send({
        Target = token,
        Action = "Allowance",
        Spender = ao.id,
        Tags = { Target = target },
        Nonce = _nonce,
    })()
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
