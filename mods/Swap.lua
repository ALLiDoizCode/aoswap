local bint = require('.bint')(256)
local ao = require('ao')

Mod = {}

-- Function to provide liquidity to the pool
function Mod.addLiquidity(amountToken1, provider)
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
function Mod.removeLiquidity(amountLiquidity, provider)
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
function Mod.swapGivenToken1(amountToken1,slippageToken1Threshold)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token2 to receive
    local expectedAmountToken2 = (amountToken1 / token1) * token2
    
    -- Calculate slippage
    local slippageToken2 = 1 - (expectedAmountToken2 / ((amountToken1 / token1) * token2))
    
    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken2) > slippageToken1Threshold then
        return nil  -- Return nil to indicate swap failure
    end

    -- Perform the swap
    -- Call TransferFrom to transfer token1
    -- Call Transfer to transfer token2
    rewardLiquidityProviders(token1Amount, "token1")
end

-- Function to swap tokens given token2 amount
function Mod.swapGivenToken2(amountToken2,slippageToken1Threshold)
    -- ex slippageThreshold of 0.02, indicates a maximum allowable slippage of 2%.

    -- Calculate expected amount of token1 to receive
    local expectedAmountToken1 = (amountToken2 / token2) * token1
    
    -- Calculate slippage
    local slippageToken1 = 1 - (expectedAmountToken1 / ((amountToken2 / token2) * token1))
    
    -- Check if slippage exceeds the threshold
    if math.abs(slippageToken1) > slippageToken1Threshold then
        return nil  -- Return nil to indicate swap failure
    end

    -- Perform the swap
    -- Call TransferFrom to transfer token2
    -- Call Transfer to transfer token1
    rewardLiquidityProviders(token2Amount, "token2")
end

-- Function to get estimate for slippage given token1
function Mod.slippageGivenToken1(amountToken1)
    -- Calculate expected amount of token1 to receive
    local expectedAmountToken2 = (amountToken1 / token1) * token2
    
    -- Calculate slippage
    local slippageToken2 = 1 - (expectedAmountToken2 / ((amountToken1 / token1) * token2))
end

-- Function to get estimate for slippage given token2
function Mod.slippageGivenToken2(amountToken2)
    -- Calculate expected amount of token1 to receive
    local expectedAmountToken1 = (amountToken2 / token2) * token1
    
    -- Calculate slippage
    local slippageToken1 = 1 - (expectedAmountToken1 / ((amountToken2 / token2) * token1))
end

-- Function to caculate liquidity reward
function Mod.liquidityFees(provider)
    local token1 = ProvidersFees[provider]["token1"]
    local token2 = ProvidersFees[provider]["token2"]
end

function Mod.liquidityRewards(provider)
    local liquidity = LiquidityProviders[provider]
end

-- Function to reward liquidity providers with fees
function Mod.rewardLiquidityProviders(tradeAmount, tradeToken)
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
function Mod.claimRewards(provider)
    local token1 = ProvidersFees[provider]["token1"]
    local token2 = ProvidersFees[provider]["token2"]
    -- Call Transfer to transfer token1
    -- Call Transfer to transfer token2
    ProvidersFees[provider]["token1"] = 0
    ProvidersFees[provider]["token2"] = 0
end

function tranfer(token,recipient,quantity)
    ao.send({
      Target = token,
      Action = "Transfer",
      Recipient = recipient,
      Quantity = tostring(quantity)
    })()
    
  end
  
  function tranferFrom(token,ownerBalance,recipient,quantity)
    ao.send({
      Target = token,
      Action = "TransferFrom",
      OwnerBalance = ownerBalance,
      Recipient = recipient,
      Quantity = tostring(quantity)
    })()
    
  end
  
  function allowance(token,target)
    ao.send({
      Target = token,
      Action = "Allowance",
      Spender = ao.id,
      Tags = {Target = target}
    })()
    
  end
  
  function balance(token,target)
    ao.send({
      Target = token,
      Action = "Balance",
      Tags = {Target = target}
    })()
    
  end

  return Mod