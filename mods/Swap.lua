local bint = require('.bint')(256)
local ao = require('ao')

-- Function to provide liquidity to the pool
function addLiquidity(amountToken1, provider)
    -- Calculate proportionate amount of token2 needed
    local amountToken2 = calculateToken2Needed(amountToken1)
    local feeAmount = (amountToken1 + amountToken2) * FeeRate

    -- Check Balances and Allowance for token1 and token2
    -- Call TransferFrom to Transfer token1 to swap
    -- Call TransferFrom to Transfer token2 to swap

    -- Store liquidity amount for the provider
    if not LiquidityProviders[provider] then
        LiquidityProviders[provider] = 0
    end
    LiquidityProviders[provider] = LiquidityProviders[provider] + feeAmount
end

-- Function to remove liquidity from the pool
function removeLiquidity(amountLiquidity, provider)
    -- Calculate proportionate amounts of tokens to be withdrawn
    local token1Amount = (amountLiquidity / (token1 + token2)) * token1
    local token2Amount = (amountLiquidity / (token1 + token2)) * token2

    -- Call Transfer to Transfer token1 to provider
    -- Call Transfer to Transfer token2 to provider

    -- Update token balances
    local token1 = token1 - token1Amount
    local token2 = token2 - token2Amount

    -- Deduct liquidity amount for the provider
    LiquidityProviders[provider] = LiquidityProviders[provider] - amountLiquidity
end

-- Function to swap tokens given token1 amount
function swapGivenToken1(token1Amount)
    -- Calculate proportionate amount of token2 needed
    local token2Needed = calculateToken2Needed(token1Amount)

    -- Perform the swap
    -- Call TransferFrom to transfer token1
    -- Call Transfer to transfer token2
    rewardLiquidityProviders(token1Amount, "token1")
end

-- Function to swap tokens given token2 amount
function swapGivenToken2(token2Amount)
    -- Calculate proportionate amount of token1 needed
    local token1Needed = calculateToken1Needed(token2Amount)

    -- Perform the swap
    -- Call TransferFrom to transfer token2
    -- Call Transfer to transfer token1
    rewardLiquidityProviders(token2Amount, "token2")
end

-- Function to calculate proportionate amount of token1 needed given token2
function calculateToken1Needed(token2Amount)
    local currentRatio = token1 / token2
    local token1Needed = (token2Amount * currentRatio) / (1 + currentRatio)
    return token1Needed
end

-- Function to calculate proportionate amount of token2 needed given token1
function calculateToken2Needed(token1Amount)
    local currentRatio = token1 / token2
    local token2Needed = token1Amount / currentRatio
    return token2Needed
end

-- Function to caculate liquidity reward
function liquidityFees(provider)
    local token1 = ProvidersFees[provider]["token1"]
    local token2 = ProvidersFees[provider]["token2"]
end

function liquidityRewards(provider)
    local liquidity = LiquidityProviders[provider]
end

-- Function to reward liquidity providers with fees
function rewardLiquidityProviders(tradeAmount, tradeToken)
    -- Calculate fee amount for the trade
    local feeAmount = tradeAmount * FeeRate

    -- Calculate the total liquidity pool value
    local totalPoolValue = token1 + token2

    -- Iterate through each liquidity provider
    for provider, liquidityAmount in pairs(LiquidityProviders) do
        -- Calculate the liquidity provider's share of the fees based on their liquidity contribution
        local providerReward = feeAmount * liquidityAmount / totalPoolValue
        -- Check the direction of the trade and distribute fees accordingly
        if tradeToken == "token1" then
            -- Reward liquidity provider with fees from trade of token1
            ProvidersFees[provider]["token1"] = ProvidersFees[provider]["token1"] + providerReward
        elseif tradeToken == "token2" then
            -- Reward liquidity provider with fees from trade of token2
            ProvidersFees[provider]["token2"] = ProvidersFees[provider]["token2"] + providerReward
        end
    end
end

-- Function for liquidity providers to claim their rewards
function claimRewards(provider)
    local token1 = ProvidersFees[provider]["token1"]
    local token2 = ProvidersFees[provider]["token2"]
    -- Call Transfer to transfer token1
    -- Call Transfer to transfer token2
    ProvidersFees[provider]["token1"] = 0
    ProvidersFees[provider]["token2"] = 0
end
