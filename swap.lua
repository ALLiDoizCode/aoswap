local ao = require('ao');
local json = require('json');

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
    assert(type(msg.Minter) == 'string', 'Minter is required!')
    assert(type(msg.TokenAProcess) == 'string', 'TokenAProcess is required!')
    assert(type(msg.TokenBProcess) == 'string', 'TokenBProcess is required!')
    assert(type(msg.amountA) == 'string', 'amountA is required!')
    assert(type(msg.amountB) == 'string', 'amountB is required!')
    assert(type(msg.BondingCurve) == 'string', 'bondingCurve is required!')
    assert(type(msg.NameA) == 'string', 'bondingCurve is required!')
    assert(type(msg.TickerA) == 'string', 'bondingCurve is required!')
    assert(type(msg.LogoA) == 'string', 'bondingCurve is required!')
    assert(type(msg.DenominationA) == 'string', 'bondingCurve is required!')
    assert(type(msg.NameB) == 'string', 'bondingCurve is required!')
    assert(type(msg.TickerB) == 'string', 'bondingCurve is required!')
    assert(type(msg.LogoB) == 'string', 'bondingCurve is required!')
    assert(type(msg.DenominationB) == 'string', 'bondingCurve is required!')


    TokenAProcess = msg.TokenAProcess;
    TokenBProcess = msg.TokenBProcess;
    BondingCurve = msg.BondingCurve;

    balances[TokenAProcess] = {};
    balances[TokenBProcess] = {};

    local infoA = {
        Name = msg.NameA,
        Ticker = msg.TickerA,
        Logo = msg.LogoA,
        Denomination = tostring(msg.DenominationA)
    };
    tokenInfo[TokenAProcess] = infoA;

    local infoB = {
        Name = msg.NameB,
        Ticker = msg.TickerB,
        Logo = msg.LogoB,
        Denomination = tostring(msg.DenominationB)
    };
    tokenInfo[TokenBProcess] = infoB;
    InitalLiquidity(msg.Minter, msg.amountA, msg.amountB)
end)

Handlers.add("Liquidity-Box", Handlers.utils.hasMatchingTag('Action', "LiquidityBox"), function(msg)
    if isPump then return end; --[[send some error-]] --
    if msg.isAdd then
        _Add(msg.from, msg.amountA, msg.amountB)
    else
        _Remove(msg.from, msg.share)
    end
end);

Handlers.add("Swap-Box", Handlers.utils.hasMatchingTag('Action', "SwapBox"), function(msg)
    if msg.isTokenA then
        _SwapTokenA(msg.from, msg.amount, msg.slippage);
    else
        _SwapTokenB(msg.from, msg.amount, msg.slippage);
    end
    local _liquidity = _Liquidity();
    if _liquidity >= BondingCurve then isPump = false end
end);

Handlers.add("Withdraw-Box", Handlers.utils.hasMatchingTag('Action', "WithdrawBox"), function(msg)
    if not balances[TokenAProcess][msg.from] then balances[TokenAProcess][msg.from] = 0 end;
    if not balances[TokenBProcess][msg.from] then balances[TokenBProcess][msg.from] = 0 end;

    if msg.isTokenA then
        local _balance = balances[TokenAProcess][msg.from];
        if _balance < msg.Quantity then return end; --[[send some error-]] --
        balances[TokenAProcess][msg.from] = _balance - msg.Quantity;
        ao.send({
            Target = TokenAProcess,
            Tags = {
                { name = "Action",    value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity",  value = msg.Quantity },
            }
        });
    else
        local _balance = balances[TokenBProcess][msg.from];
        if _balance < msg.Quantity then return end; --[[send some error-]] --
        balances[TokenBProcess][msg.from] = _balance - msg.Quantity;
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
    if not balances[TokenAProcess][msg.from] then balances[TokenAProcess][msg.from] = 0 end;
    if not balances[TokenBProcess][msg.from] then balances[TokenBProcess][msg.from] = 0 end;
    local _balanceA = balances[TokenAProcess][msg.from];
    local _balanceB = balances[TokenBProcess][msg.from];
    ao.send({
        Target = msg.From,
        Action = "Balance",
        BalanceA = _balanceA,
        BalanceB = _balanceB,
        TokenA = tokenInfo[TokenA],
        TokenB = tokenInfo[TokenB],
        Account = msg.Tags.Target or msg.From,
    })
end);

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    balances[msg.from][msg.sender] = msg.Quantity;
end);

function InitalLiquidity(from, amountA, amountB)
    if not shares[from] then shares[from] = 0 end;
    _Share = 0;
    local isValidA = _IsValid(from, TokenAProcess, amountA)
    local isValidB = _IsValid(from, TokenBProcess, amountB)
    if (totalShares == 0) then _Share = 100 * precision end;
    if (TokenA > 0 or TokenB > 0) then return end; --[[send some error-]]               --
    if (isValidA == false or isValidB == false) then return end; --[[send some error-]] --
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then return end; --[[send some error-]] --
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
    if (TokenA <= 0 or TokenB <= 0) then return end; --[[send some error-]]             --
    if (isValidA == false or isValidB == false) then return end; --[[send some error-]] --
    local estimateB = _GetEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then return end; --[[send some error-]]                     --
    local shareA = (totalShares * amountA) / TokenA;
    local shareB = (totalShares * amountB) / TokenB;
    if shareA ~= shareB then return end; --[[send some error-]] --
    _Share = shareA;
    _SubstractBalance(from, TokenAProcess, amountA);
    _SubstractBalance(from, TokenBProcess, amountB);
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = shares[from];
    shares[from] = _share + _Share;
    totalShares = totalShares + _Share;
    --[[figure out some message design pattern]] --
    --ao.send({ Target = msg.From, Data = json.encode(Balances), Action = 'AddBox', Nonce = msg.Nonce, })
end

function _Remove(from, share)
    if not shares[from] then shares[from] = 0 end;
    if totalShares <= 0 then return end; --[[send some error-]]                              --
    _Share = shares[from];
    if _Share < share then return end; --[[send some error-]]                                --
    local estimate = GetRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then return end; --[[send some error-]] --
    if TokenA < estimate.shareA then return end; --[[send some error-]]                      --
    if TokenB < estimate.shareB then return end; --[[send some error-]]                      --
    shares[from] = _Share - share;
    _AddBalance(from, TokenAProcess, estimate.shareA);
    _AddBalance(from, TokenBProcess, estimate.shareB);
    totalShares = totalShares + share;
end

function _SwapTokenA(from, amount, slippage)
    if totalShares <= 0 then return end; --[[send some error-]]     --
    local estimate = _GetSwapTokenAEstimate(amount);
    if estimate <= slippage then return end; --[[send some error-]] --
    if TokenB <= 0 then return end; --[[send some error-]]          --
    if TokenB < estimate then return end; --[[send some error-]]    --
    local isValid = _IsValid(from, TokenAProcess, amount)
    if isValid ~= false then return end; --[[send some error-]]     --
    _SubstractBalance(from, TokenAProcess, amount);
    _AddBalance(from, TokenBProcess, estimate);
    TokenA = TokenA + amount;
    TokenB = TokenB - estimate;
end

function _SwapTokenB(from, amount, slippage)
    if totalShares <= 0 then return end; --[[send some error-]]     --
    local estimate = _GetSwapTokenBEstimate(amount);
    if estimate <= slippage then return end; --[[send some error-]] --
    if TokenA <= 0 then return end; --[[send some error-]]          --
    if TokenA < estimate then return end; --[[send some error-]]    --
    local isValid = _IsValid(from, TokenBProcess, amount)
    if isValid ~= false then return end; --[[send some error-]]     --
    _SubstractBalance(from, TokenBProcess, amount);
    _AddBalance(from, TokenAProcess, estimate);
    TokenB = TokenB + amount;
    TokenA = TokenA - estimate;
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    if shares <= 0 then return end --[[send some error]]         --
    if share > totalShares then return end --[[send some error]] --
    result.shareA = (share * TokenA) / totalShares;
    result.shareB = (share * TokenB) / totalShares;
    return result
end

function _IsValid(owner, token, amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
    local balance = balances[token][owner];
    return amount > 0 and balance >= amount;
end

function _GetEquivalentTokenAEstimate(amountB)
    if shares <= 0 then return end --[[send some error]] --
    return (TokenA * amountB) / TokenB
end

function _getEquivalentTokenBEstimate(amountA)
    if shares <= 0 then return end --[[send some error]] --
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
    if not balances[token][owner] then token[token][owner] = 0 end;
    local _balance = balances[token][owner];
    balances[token][owner] = _balance + amount;
end

function _SubstractBalance(owner, token, amount)
    if not balances[token][owner] then token[token][owner] = 0 end;
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
