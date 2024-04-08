local bint = require('.bint')(256)
local ao = require('ao')
local token = require('token')

-- Function to provide liquidity to the pool
function addLiquidity(amountToken1,provider)
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
function removeLiquidity(amountLiquidity,provider)
    -- Calculate proportionate amounts of tokens to be withdrawn
    local token1Amount = (amountLiquidity / (token1 + token2)) * token1
    local token2Amount = (amountLiquidity / (token1 + token2)) * token2

    -- Call Transfer to Transfer token1 to provider
    -- Call Transfer to Transfer token2 to provider

    -- Update token balances
    token1 = token1 - token1Amount
    token2 = token2 - token2Amount

    -- Deduct liquidity amount for the provider
    LiquidityProviders[provider] = LiquidityProviders[provider] - amountLiquidity
end

-- Function to swap tokens given token2 amount
function swapGivenToken2(token2Amount)
    -- Calculate proportionate amount of token1 needed
    local token1Needed = calculateToken1Needed(token2Amount)

    -- Perform the swap
    -- Call TransferFrom to transfer token2
    -- Call Transfer to transfer token1
end

-- Function to swap tokens given token1 amount
function swapGivenToken1(token1Amount)
    -- Calculate proportionate amount of token2 needed
    local token2Needed = calculateToken2Needed(token1Amount)

    -- Perform the swap
    -- Call TransferFrom to transfer token1
    -- Call Transfer to transfer token2
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

-- Function to reward liquidity providers
function rewardLiquidityProviders(feeAmount)
    -- Calculate total liquidity in the pool
    local totalLiquidity = token1 + token2
    
    -- Calculate the fee per unit of liquidity
    local feePerLiquidity = feeAmount / totalLiquidity
    
    -- Distribute the fee proportionally among liquidity providers
    local token1Reward = feePerLiquidity * token1
    local token2Reward = feePerLiquidity * token2
    
    -- Update liquidity providers' balances (Assuming liquidity providers have accounts)
    -- Example: 
    -- liquidityProvider1.balance = liquidityProvider1.balance + token1Reward
    -- liquidityProvider2.balance = liquidityProvider2.balance + token2Reward
    
    -- Alternatively, you can store rewards internally in the token pool itself
    
    -- Print rewards for demonstration purposes
    print("Token1 Reward for Liquidity Providers:", token1Reward)
    print("Token2 Reward for Liquidity Providers:", token2Reward)
end

