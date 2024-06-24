local ao = require('ao')
local json = require('json')

if not shares then shares = {} end
if not balances then balances = {} end

local totalShares = 0;
local precision = 0;
local FeeRate = 0.011 -- Fee rate (1% in this example)
local TokenA = 0;
local TokenB = 0;

local TokenAProcess = "";
local TokenBProcess = "";

Handlers.add("liquidityBox", Handlers.utils.hasMatchingTag('Action', "LiquidityBox"), Liquidity)
Handlers.add("swapBox", Handlers.utils.hasMatchingTag('Action', "SwapBox"), Swap)

function Liquidity(msg)
    if msg.isAdd then
        _Add(msg.caller,msg.amountA,msg.amountB)
    else
        _Remove(msg.caller,msg.share)
    end
end

function Swap(msg)
    if msg.isTokenA then
        _SwapTokenA(msg)
    else
        _SwapTokenB(msg)
    end
    
end

function _Add (caller,amountA,amountB)
    if not shares[caller] then shares[caller] = 0 end;
    _Share = 0;
    local isValidA = _isValid(caller,TokenAProcess,amountA)
    local isValidB = _isValid(caller,TokenBProcess,amountB)
    if(totalShares == 0) then _Share = 100 * precision end;
    if(TokenA <= 0 or TokenB <= 0) then return end;--[[send some error-]]-- 
    if(isValidA == false or isValidB == false) then return end;--[[send some error-]]-- 
    local estimateB = _getEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then return end;--[[send some error-]]-- 
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then return end;--[[send some error-]]--
    _Share = shareA;
    _substractBalance(caller,TokenAProcess,amountA);
    _substractBalance(caller,TokenBProcess,amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = shares[caller];
    shares[caller] = _share + _Share;
    totalShares = totalShares + _Share;
    --[[figure out some message design pattern]]-- 
    --ao.send({ Target = msg.From, Data = json.encode(Balances), Action = 'AddBox', Nonce = msg.Nonce, })
end

function _Remove (caller,share)
    if not shares[caller] then shares[caller] = 0 end;
    if totalShares <= 0 then return end;--[[send some error-]]--
    _Share = shares[caller];
    if _Share < share then return end;--[[send some error-]]--
    local estimate = getRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then return end;--[[send some error-]]--
    if TokenA < estimate.shareA then return end;--[[send some error-]]--
    if TokenB < estimate.shareB then return end;--[[send some error-]]--
    shares[caller] = _Share - share;
    _addBalance(caller,TokenAProcess,estimate.shareA);
    _addBalance(caller,TokenBProcess,estimate.shareB);
    totalShares = totalShares + share;
end

function _SwapTokenA(caller,token,amount,slippage)
    
end

function _SwapTokenB(caller,token,amount,slippage)
    
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    if shares <= 0 then return end --[[send some error]]--
    if share > totalShares then return end --[[send some error]]--
    result.shareA = (share * TokenA) / totalShares;
    result.shareB = (share * TokenB) / totalShares;
    return result
end

function _IsValid(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local balance = balances[token][owner];
    return amount > 0 and balance >= amount;
end

function _GetEquivalentTokenAEstimate(amountB)
    if shares <= 0 then return end --[[send some error]]--
    return (TokenA * amountB) / TokenB
end

function _getEquivalentTokenBEstimate(amountA)
    if shares <= 0 then return end --[[send some error]]--
    return (TokenB * amountA) / TokenA
end

function _GetSwapTokenAEstimate(amount)
    local tokenA = TokenA + amount;
    local tokenB = _price() / tokenA;
    local amountB = TokenB - tokenB;
    if amountB == TokenB then amountB = amountB - 1; end --To ensure that the pool is not completely depleted
end

function _GetSwapTokenBEstimate(amount)
    local tokenB = TokenB + amount;
    local tokenA = _price() / tokenB;
    local amountA = TokenA - tokenA;
    if amountA == TokenA then amountA = amountA - 1; end --To ensure that the pool is not completely depleted
end

function _Price()
    return TokenA * TokenB;
end

function _AddBalance(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local _balance =  balances[token][owner];
    balances[token][owner] = _balance + amount;
end

function _SubstractBalance(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local _balance =  balances[token][owner];
    if amount > _balance then balances[token][owner] = 0 end;
    balances[token][owner] = _balance - amount;
end