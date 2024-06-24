local ao = require('ao')
local json = require('json')

if not shares then shares = {} end
if not balances then balances = {} end

local totalShares = 0;
local precision = 0;
local FeeRate = 0.01 -- Fee rate (1% in this example)
local TokenA = 0;
local TokenB = 0;

local TokenAProcess = "";
local TokenBProcess = "";

Handlers.add('init', Handlers.utils.hasMatchingTag('Action', 'Init'), Init)
Handlers.add("liquidityBox", Handlers.utils.hasMatchingTag('Action', "LiquidityBox"), Liquidity);
Handlers.add("swapBox", Handlers.utils.hasMatchingTag('Action', "SwapBox"), Swap);
Handlers.add("WithdrawBox", Handlers.utils.hasMatchingTag('Action', "WithdrawBoc"), Withdraw);
Handlers.add("BalanceBox", Handlers.utils.hasMatchingTag('Action', "BalanceBox"), Balance);
Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), CreditNotice);

function Init(msg)
    ao.isTrusted(msg)
    assert(type(msg.TokenAProcess) == 'string', 'TokenAProcess is required!')
    assert(type(msg.TokenBProcess) == 'string', 'TokenBProcess is required!')
    
    TokenAProcess = msg.TokenAProcess;
    TokenBProcess = msg.TokenBProcess;
end

function Liquidity(msg)
    if msg.isAdd then
        _Add(msg.caller,msg.amountA,msg.amountB)
    else
        _Remove(msg.caller,msg.share)
    end
end

function Swap(msg)
    if msg.isTokenA then
        _SwapTokenA(msg.caller,msg.amount,msg.slippage);
    else
        _SwapTokenB(msg.caller,msg.amount,msg.slippage);
    end
end

function CreditNotice(msg)
    balances[msg.from][msg.sender] = msg.Quantity;
end

function Withdraw(msg)
    if not balances[TokenAProcess][msg.caller] then balances[TokenAProcess][msg.caller] = 0 end;
    if not balances[TokenBProcess][msg.caller] then balances[TokenBProcess][msg.caller] = 0 end;

    if msg.isTokenA then
        local _balance = balances[TokenAProcess][msg.caller];
        if _balance < msg.Quantity then return end;--[[send some error-]]--
        balances[TokenAProcess][msg.caller] = _balance - msg.Quantity;
        ao.send({
            Target = TokenAProcess,
            Tags = {
                { name = "Action", value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity", value = msg.Quantity },
            }
        });
    else
        local _balance = balances[TokenBProcess][msg.caller];
        if _balance < msg.Quantity then return end;--[[send some error-]]--
        balances[TokenBProcess][msg.caller] = _balance - msg.Quantity;
        ao.send({
            Target = TokenBProcess,
            Tags = {
                { name = "Action", value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity", value = msg.Quantity },
            }
        });
    end
end

function Balance(msg)
    if not balances[TokenAProcess][msg.caller] then balances[TokenAProcess][msg.caller] = 0 end;
    if not balances[TokenBProcess][msg.caller] then balances[TokenBProcess][msg.caller] = 0 end;
    if msg.isTokenA then
        local _balance = balances[TokenAProcess][msg.caller];
    else
        local _balance = balances[TokenBProcess][msg.caller];
    end
end

function _Add (caller,amountA,amountB)
    if not shares[caller] then shares[caller] = 0 end;
    _Share = 0;
    local isValidA = _IsValid(caller,TokenAProcess,amountA)
    local isValidB = _IsValid(caller,TokenBProcess,amountB)
    if(totalShares == 0) then _Share = 100 * precision end;
    if(TokenA <= 0 or TokenB <= 0) then return end;--[[send some error-]]-- 
    if(isValidA == false or isValidB == false) then return end;--[[send some error-]]-- 
    local estimateB = _GetEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then return end;--[[send some error-]]-- 
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then return end;--[[send some error-]]--
    _Share = shareA;
    _SubstractBalance(caller,TokenAProcess,amountA);
    _SubstractBalance(caller,TokenBProcess,amountB);
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
    local estimate = GetRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then return end;--[[send some error-]]--
    if TokenA < estimate.shareA then return end;--[[send some error-]]--
    if TokenB < estimate.shareB then return end;--[[send some error-]]--
    shares[caller] = _Share - share;
    _AddBalance(caller,TokenAProcess,estimate.shareA);
    _AddBalance(caller,TokenBProcess,estimate.shareB);
    totalShares = totalShares + share;
end

function _SwapTokenA(caller,amount,slippage)
    if totalShares <= 0 then return end;--[[send some error-]]--
    local estimate = _GetSwapTokenAEstimate(amount);
    if estimate <= slippage then return end;--[[send some error-]]--
    if TokenB <= 0 then return end;--[[send some error-]]--
    if TokenB < estimate then return end;--[[send some error-]]--
    local isValid = _IsValid(caller,TokenAProcess,amount)
    if isValid ~= false then return end;--[[send some error-]]--
    _SubstractBalance(caller,TokenAProcess,amount);
    _AddBalance(caller,TokenBProcess,estimate);
    TokenA = TokenA + amount;
    TokenB = TokenB - estimate;
    
end

function _SwapTokenB(caller,amount,slippage)
    if totalShares <= 0 then return end;--[[send some error-]]--
    local estimate = _GetSwapTokenBEstimate(amount);
    if estimate <= slippage then return end;--[[send some error-]]--
    if TokenA <= 0 then return end;--[[send some error-]]--
    if TokenA < estimate then return end;--[[send some error-]]--
    local isValid = _IsValid(caller,TokenBProcess,amount)
    if isValid ~= false then return end;--[[send some error-]]--
    _SubstractBalance(caller,TokenBProcess,amount);
    _AddBalance(caller,TokenAProcess,estimate);
    TokenB = TokenB + amount;
    TokenA = TokenA - estimate;
    
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

function FeeMachine()
    --setup logic ot handle fee
end