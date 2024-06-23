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

function _add (self,caller,amountA,amountB)
    _Share = 0;
    _BalanceA = balances[TokenA][self];
    _BalanceB = balances[TokenB][self];
    local isValidA = _isValid(caller,TokenA,amountA)
    local isValidB = _isValid(caller,TokenB,amountB)
    if(totalShares == 0) then _Share = 100 * precision end;
    if(_BalanceA <= 0 or _BalanceB <= 0) then return end;--[[send some error-]]-- 
    if(isValidA == false or isValidB == false) then return end;--[[send some error-]]-- 

    ao.send({ Target = msg.From, Data = json.encode(Balances), Action = 'AddBox', Nonce = msg.Nonce, })
end

function _remove (msg)
    
end

function _swapTokenA(caller,token,amount,slippage)
    
end

function _swapTokenB(caller,token,amount,slippage)
    
end

function getShares(msg)
    
end

function _isValid(caller,token,amount)
    if not balances[token][caller] then token[TokenA][caller] = 0 end;
    local balance = balances[token][caller];
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