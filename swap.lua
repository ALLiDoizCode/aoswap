local ao = require('ao');
local json = require('json');

local utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end,
    result = function(target, code, message)
        ao.send({
            Target = target,
            Data = json.encode({ code = code, message = message })
        });
    end
}
if not tokenInfo then tokenInfo = {} end;
if not shares then shares = {} end;
if not balances then balances = {} end;

local totalShares = 0;
local precision = 0;
local FeeRate = 0.01 -- Fee rate (1% in this example)
local TokenA = 0;
local TokenB = 0;
local isPump = true;

local BondingCurve = 0;
local TokenAProcess = "";
local TokenBProcess = "";

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    ao.isTrusted(msg)
    local data = json.decode(msg.data);
    local tokenA = data.tokenA;
    local tokenB = data.tokenB;
    assert(type(msg.From) == 'string', 'Minter is required!')
    assert(type(tokenA.id) == 'string', 'TokenA Process id  is required!')
    assert(type(tokenB.id) == 'string', 'TokenB Process id is required!')
    assert(type(tokenA.amount) == 'string', 'amountA is required!')
    assert(type(tokenB.amount) == 'string', 'amountB is required!')
    assert(type(data.bondingCurve) == 'string', 'bondingCurve is required!')
    assert(type(tokenA.Name) == 'string', 'bondingCurve is required!')
    assert(type(tokenA.Ticker) == 'string', 'bondingCurve is required!')
    assert(type(tokenA.Logo) == 'string', 'bondingCurve is required!')
    assert(type(tokenA.Denomination) == 'string', 'bondingCurve is required!')
    assert(type(tokenB.Name) == 'string', 'bondingCurve is required!')
    assert(type(tokenB.Ticker) == 'string', 'bondingCurve is required!')
    assert(type(tokenB.Logo) == 'string', 'bondingCurve is required!')
    assert(type(tokenB.Denomination) == 'string', 'bondingCurve is required!')

    TokenAProcess = tokenA.id;
    TokenBProcess = tokenB.id;
    BondingCurve = data.bondingCurve;

    balances[TokenAProcess] = {};
    balances[TokenBProcess] = {};

    local infoA = {
        Name = tokenA.Name,
        Ticker = tokenA.Ticker,
        Logo = tokenA.Logo,
        Denomination = tokenA.Denomination
    };
    tokenInfo[TokenAProcess] = infoA;

    local infoB = {
        Name = tokenB.Name,
        Ticker = tokenB.Ticker,
        Logo = tokenB.Logo,
        Denomination = tokenB.Denomination
    };
    tokenInfo[TokenBProcess] = infoB;
    --InitalLiquidity(msg.From, tokenA.amount, tokenB.amount)
    utils.result(msg.From, 200, json.encode(infoA))
end)

Handlers.add("Liquidity-Box", Handlers.utils.hasMatchingTag('Action', "LiquidityBox"), function(msg)
    if isPump then
        utils.result(msg.From, 403, "You can't add liquidty to pumps")
        return
    end;
    if msg.isAdd then
        _Add(msg.From, msg.amountA, msg.amountB)
    else
        _Remove(msg.From, msg.share)
    end
end);

Handlers.add("Swap-Box", Handlers.utils.hasMatchingTag('Action', "SwapBox"), function(msg)
    if msg.isTokenA then
        _SwapTokenA(msg.From, msg.amount, msg.slippage);
    else
        _SwapTokenB(msg.From, msg.amount, msg.slippage);
    end
    local _liquidity = _Liquidity();
    if _liquidity >= BondingCurve then isPump = false end
end);

Handlers.add("Withdraw-Box", Handlers.utils.hasMatchingTag('Action', "WithdrawBox"), function(msg)
    if not balances[TokenAProcess][msg.From] then balances[TokenAProcess][msg.From] = 0 end;
    if not balances[TokenBProcess][msg.From] then balances[TokenBProcess][msg.From] = 0 end;

    if msg.isTokenA then
        local _balance = balances[TokenAProcess][msg.From];
        if _balance < msg.Quantity then
            utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        balances[TokenAProcess][msg.From] = _balance - msg.Quantity;
        ao.send({
            Target = TokenAProcess,
            Tags = {
                { name = "Action",    value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity",  value = msg.Quantity },
            }
        });
    else
        local _balance = balances[TokenBProcess][msg.From];
        if _balance < msg.Quantity then
            utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        balances[TokenBProcess][msg.From] = _balance - msg.Quantity;
        ao.send({
            Target = TokenBProcess,
            Tags = {
                { name = "Action",    value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity",  value = msg.Quantity },
            }
        });
    end
end);

Handlers.add("Balance-Box", Handlers.utils.hasMatchingTag('Action', "BalanceBox"), function(msg)
    if not balances[TokenAProcess][msg.From] then balances[TokenAProcess][msg.From] = 0 end;
    if not balances[TokenBProcess][msg.From] then balances[TokenBProcess][msg.From] = 0 end;
    local _balanceA = balances[TokenAProcess][msg.From];
    local _balanceB = balances[TokenBProcess][msg.From];
    ao.send({
        Target = msg.From,
        Action = "Balance",
        BalanceA = _balanceA,
        BalanceB = _balanceB,
        TokenA = json.encode(tokenInfo[TokenAProcess]),
        TokenB = json.encode(tokenInfo[TokenBProcess]),
        Account = msg.Tags.Target or msg.From,
    })
end);

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    balances[msg.From][msg.Sender] = msg.Quantity;
end);

function InitalLiquidity(from, amountA, amountB)
    if shares[from] == nil then shares[from] = 0 end;
    _Share = 0;
    local isValidA = _IsValid(from, TokenAProcess, amountA)
    local isValidB = _IsValid(from, TokenBProcess, amountB)
    if (totalShares == 0) then _Share = 100 * precision end;
    if (TokenA > 0 or TokenB > 0) then
        utils.result(from, 403, "Inital liquidity exist")
        return
    end;
    if (isValidA == false or isValidB == false) then
        utils.result(from, 403, "Invalid Amount")
        return
    end;
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then
        utils.result(from, 403, "Invalid Share Amount")
        return
    end;
    _Share = shareA;
    _SubstractBalance(from, TokenAProcess, amountA);
    _SubstractBalance(from, TokenBProcess, amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = shares[from];
    shares[from] = _share + _Share;
    totalShares = totalShares + _Share;
end

function _Add(from, amountA, amountB)
    if not shares[from] then shares[from] = 0 end;
    _Share = 0;
    local isValidA = _IsValid(from, TokenAProcess, amountA)
    local isValidB = _IsValid(from, TokenBProcess, amountB)
    if (totalShares == 0) then _Share = 100 * precision end;
    if (TokenA <= 0 or TokenB <= 0) then
        utils.result(from, 403, "Pool as a zero balance of one or more tokens")
        return
    end;
    if (isValidA == false or isValidB == false) then
        utils.result(from, 403, "Invalid Amount")
        return
    end;
    local estimateB = _GetEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then
        utils.result(from, 403, "Invalid Amount")
        return
    end;
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then
        utils.result(from, 403, "Invalid Shares")
        return
    end;
    _Share = shareA;
    _SubstractBalance(from, TokenAProcess, amountA);
    _SubstractBalance(from, TokenBProcess, amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = shares[from];
    shares[from] = _share + _Share;
    totalShares = totalShares + _Share;
end

function _Remove(from, share)
    if not shares[from] then shares[from] = 0 end;
    if totalShares <= 0 then
        utils.result(from, 403, "Totals shares less then or equal to 0")
        return
    end;
    if totalShares < share then
        utils.result(from, 403, "Total shares less then requested amount")
        return
    end;
    local estimate = GetRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then
        utils.result(from, 403, "No shares available")
        return
    end;
    if TokenA < estimate.shareA then
        utils.result(from, 403, "Invalid Amount in reserve A")
        return
    end;
    if TokenB < estimate.shareB then
        utils.result(from, 403, "Invalid Amount in reserve B")
        return
    end;
    shares[from] = _Share - share;
    _AddBalance(from, TokenAProcess, estimate.shareA);
    _AddBalance(from, TokenBProcess, estimate.shareB);
    totalShares = totalShares + share;
end

function _SwapTokenA(from, amount, slippage)
    if totalShares <= 0 then
        utils.result(from, 403, "Total shares less then or equal to 0")
        return
    end;
    local estimate = _GetSwapTokenAEstimate(amount);
    if estimate <= slippage then
        utils.result(from, 403, "slippage")
        return
    end;
    if TokenB <= 0 then
        utils.result(from, 403, "No funds available")
        return
    end;
    if TokenB < estimate then
        utils.result(from, 403, "Insufficient funds available")
        return
    end;
    local isValid = _IsValid(from, TokenAProcess, amount)
    if isValid ~= false then
        utils.result(from, 403, "Insufficient funds")
        return
    end;
    _SubstractBalance(from, TokenAProcess, amount);
    _AddBalance(from, TokenBProcess, estimate);
    TokenA = TokenA + amount;
    TokenB = TokenB - estimate;
end

function _SwapTokenB(from, amount, slippage)
    if totalShares <= 0 then
        utils.result(from, 403, "Total shares less then or equal to 0")
        return
    end;
    local estimate = _GetSwapTokenBEstimate(amount);
    if estimate <= slippage then
        utils.result(from, 403, "slippage")
        return
    end;
    if TokenA <= 0 then
        utils.result(from, 403, "No funds available")
        return
    end;
    if TokenA < estimate then
        utils.result(from, 403, "Insufficient funds available")
        return
    end;
    local isValid = _IsValid(from, TokenBProcess, amount)
    if isValid ~= false then
        utils.result(from, 403, "Insufficient funds")
        return
    end;
    _SubstractBalance(from, TokenBProcess, amount);
    _AddBalance(from, TokenAProcess, estimate);
    TokenB = TokenB + amount;
    TokenA = TokenA - estimate;
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    result.shareA = (share * TokenA) / totalShares;
    result.shareB = (share * TokenB) / totalShares;
    return result
end

function _IsValid(owner, token, amount)
    if balances[token] == nil then token[token] = {} end;
    utils.result(owner, 403, token)
    if balances[token][owner] == nil then balances[token][owner] = 0 end;
    local balance = balances[token][owner];
    return utils.toNumber(amount) > 0 and balance >= utils.toNumber(amount);
    ---return false
end

function _GetEquivalentTokenAEstimate(amountB)
    return (TokenA * amountB) / TokenB
end

function _GetEquivalentTokenBEstimate(amountA)
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

function _AddBalance(owner, token, amount)
    if balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = balances[token][owner];
    balances[token][owner] = _balance + amount;
end

function _SubstractBalance(owner, token, amount)
    if balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = balances[token][owner];
    if amount > _balance then balances[token][owner] = 0 end;
    balances[token][owner] = _balance - amount;
end

function _Liquidity()
    if TokenA == 0 and TokenB == 0 then return 0 end;
    local _price = TokenB / TokenA;
    local amount = _price * TokenA;
    return amount + TokenB;
end

function FeeMachine()
    --setup logic ot handle fee
end
