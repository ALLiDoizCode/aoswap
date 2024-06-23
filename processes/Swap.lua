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

Handlers.add("liquidityBox", Handlers.utils.hasMatchingTag('Action', "LiquidityBox"), add)
Handlers.add("swapBox", Handlers.utils.hasMatchingTag('Action', "SwapBox"), swap)

function liquidity(msg)
    if msg.isAdd then
        _add(msg)
    else
        _remove(msg)
    end
end

function swap(msg)
    if msg.isTokenA then
        _swapTokenA(msg)
    else
        _swapTokenB(msg)
    end
    
end

function _add (caller,amountA,amountB)
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

    ao.send({ Target = msg.From, Data = json.encode(Balances), Action = 'AddBox', Nonce = msg.Nonce, })
end

function _remove (msg)
    
end

function _swapTokenA(caller,token,amount,slippage)
    
end

function _swapTokenB(caller,token,amount,slippage)
    
end

function getRemoveEstimate(share)
    local result = {}
    if shares <= 0 then return end --[[send some error]]--
    if share > totalShares then return end --[[send some error]]--
    result.shareA = (share * TokenA) / totalShares;
    result.shareB = (share * TokenB) / totalShares;
    return result
end

function _isValid(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local balance = balances[token][owner];
    return amount > 0 and balance >= amount;
end

function _getEquivalentTokenAEstimate(amountB)
    if shares <= 0 then return end --[[send some error]]--
    return (TokenA * amountB) / TokenB
end

function _getEquivalentTokenBEstimate(amountA)
    if shares <= 0 then return end --[[send some error]]--
    return (TokenB * amountA) / TokenA
end

function _getSwapTokenAEstimate(amount)
    local tokenA = TokenA + amount;
    local tokenB = _price() / tokenA;
    local amountB = TokenB - tokenB;
    if amountB == TokenB then amountB = amountB - 1; end --To ensure that the pool is not completely depleted
end

function _getSwapTokenBEstimate(amount)
    local tokenB = TokenB + amount;
    local tokenA = _price() / tokenB;
    local amountA = TokenA - tokenA;
    if amountA == TokenA then amountA = amountA - 1; end --To ensure that the pool is not completely depleted
end

function _price()
    return TokenA * TokenB;
end

function _addBalance(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local _balance =  balances[token][owner];
    balances[token][owner] = _balance + amount;
end

function _substractBalance(owner,token,amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local _balance =  balances[token][owner];
    if amount > _balance then balances[token][owner] = 0 end;
    balances[token][owner] = _balance - amount;
end