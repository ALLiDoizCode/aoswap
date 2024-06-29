local ao = require('ao');
local json = require('json');

if not TokenInfo then TokenInfo = {} end;
if not Shares then Shares = {} end;
if not Balances then Balances = {} end;

ManagerProcess = "HNIsIdCJzUINPhAsnTOY-7XgYW2ZKEXqzKR9lNg7rG4";

TotalShares = 0;
Precision = 100000000000000000;
FeeRate = 0.01  -- Fee rate (1% in this example)
TokenA = 0;
TokenB = 0;
IsPump = true;
IsActive = false;

BondingCurve = 0;
TokenAProcess = "";
TokenBProcess = "";

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    ao.isTrusted(msg)
    assert(IsActive == false,"Pool is already active")
    Init(msg.from,msg.TokenA,msg.TokenB,msg.BondingCurve)
end)

Handlers.add("InitalLiquidity", Handlers.utils.hasMatchingTag('Action', "InitalLiquidity"), function(msg)
    assert(IsActive == false,"Pool is already active")
    assert(TokenA == 0 and TokenB == 0,"Token balance is in a bad state")
    assert(IsActive == false,"Pool is already active")
    InitalLiquidity(msg.From, msg.amountA, msg.amountB)
    IsActive = true
end);

Handlers.add("Add", Handlers.utils.hasMatchingTag('Action', "Add"), function(msg)
    assert(IsPump == false,"You can't added liquidity to pumps")
    assert(IsActive,"Pool must be active")
    Add(msg.From, msg.amountA, msg.amountB)
end);

Handlers.add("Remove", Handlers.utils.hasMatchingTag('Action', "Remove"), function(msg)
    assert(IsPump == false,"You can't remove liquidity from pumps")
    assert(IsActive,"Pool must be active")
    Remove(msg.From, msg.share)
end);

Handlers.add("SwapA", Handlers.utils.hasMatchingTag('Action', "SwapA"), function(msg)
    assert(IsActive,"Pool must be active")
    SwapA(msg.From, msg.amount,msg.slippage);
end);

Handlers.add("SwapB", Handlers.utils.hasMatchingTag('Action', "SwapB"), function(msg)
    assert(IsActive,"Pool must be active")
    SwapB(msg.From, msg.amount,msg.slippage);
end)

Handlers.add('Balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
    Balance(msg)
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag('Action', "Credit-Notice"), function(msg)
    CreditNotice(msg)
end);

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    Info(msg)
end)

function Init(from,tokenA, tokenB, bondingCurve)
    TokenAProcess = tokenA;
    TokenBProcess = tokenB;
    BondingCurve = Utils.toNumber(bondingCurve);
    Balances[TokenAProcess] = {};
    Balances[TokenBProcess] = {};
    ao.send({
        Target = from,
        Action = "Pool-Request",
        BondingCurve = BondingCurve,
        TokenA = TokenAProcess,
        TokenB = TokenBProcess
    });
end

function InitalLiquidity(from, amountA, amountB)
    if Shares[from] == nil then Shares[from] = 0 end;
    _Share = 0;
    local isValidA = IsValid(from, TokenAProcess, amountA)
    local isValidB = IsValid(from, TokenBProcess, amountB)
    if (TotalShares == 0) then _Share = 100 * Precision end;
    if (isValidA == false or isValidB == false) then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    SubstractBalance(from, TokenAProcess, amountA);
    SubstractBalance(from, TokenBProcess, amountB);
    TokenA = Utils.toNumber(Utils.add(TokenA,amountA));
    TokenB = Utils.toNumber(Utils.add(TokenB,amountB));
    local _share = Shares[from];
    Shares[from] = Utils.toNumber(Utils.add(_share, _Share));
    TotalShares = Utils.toNumber(Utils.add(TotalShares, _Share));
end

function Add(from, amountA, amountB)
    if not Shares[from] then Shares[from] = 0 end;
    _Share = 0;
    local isValidA = IsValid(from, TokenAProcess, amountA)
    local isValidB = IsValid(from, TokenBProcess, amountB)
    if (TotalShares == 0) then _Share = 100 * Precision end;
    if (TokenA <= 0 or TokenB <= 0) then
        Utils.result(from, 403, "Pool as a zero balance of one or more tokens")
        return
    end;
    if (isValidA == false or isValidB == false) then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    local estimateB = GetEquivalentTokenAEstimate(amountB);
    if amountB ~= estimateB then
        Utils.result(from, 403, "Invalid Amount")
        return
    end;
    local shareA = (TotalShares * amountA) / TokenA;
    local shareB = (TotalShares * amountB) / TokenB;
    if shareA ~= shareB then
        Utils.result(from, 403, "Invalid Shares")
        return
    end;
    _Share = shareA;
    SubstractBalance(from, TokenAProcess, amountA);
    SubstractBalance(from, TokenBProcess, amountB);
    TokenA = Utils.add(TokenA, amountA);
    TokenB = Utils.add(TokenB, amountB);
    local _share = Shares[from];
    Shares[from] = Utils.add(_share, _Share);
    TotalShares = Utils.add( TotalShares, _Share);
end

function Remove(from, share)
    if not Shares[from] then Shares[from] = 0 end;
    if TotalShares <= 0 then
        Utils.result(from, 403, "Totals Shares less then or equal to 0")
        return
    end;
    if TotalShares < share then
        Utils.result(from, 403, "Total Shares less then requested amount")
        return
    end;
    local estimate = GetRemoveEstimate(share);
    if estimate.shareA <= 0 and estimate.shareB <= 0 then
        Utils.result(from, 403, "No Shares available")
        return
    end;
    if TokenA < estimate.shareA then
        Utils.result(from, 403, "Invalid Amount in reserve A")
        return
    end;
    if TokenB < estimate.shareB then
        Utils.result(from, 403, "Invalid Amount in reserve B")
        return
    end;
    Shares[from] = Utils.subtract(_Share, share);
    AddBalance(from, TokenAProcess, estimate.shareA);
    AddBalance(from, TokenBProcess, estimate.shareB);
    TotalShares = Utils.add(TotalShares, share);
end

function SwapA(from, amount, slippage)
    if TotalShares <= 0 and IsPump == false then
        Utils.result(from, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenAEstimate(amount);
    if estimate <= slippage then
        Utils.result(from, 403, "slippage")
        return
    end;
    if TokenB <= 0 then
        Utils.result(from, 403, "No funds available")
        return
    end;
    if TokenB < estimate then
        Utils.result(from, 403, "Insufficient funds available")
        return
    end;
    local isValid = IsValid(from, TokenAProcess, amount)
    if isValid ~= true then
        Utils.result(from, 403, "Insufficient funds")
        return
    end;
    SubstractBalance(from, TokenAProcess, amount);
    AddBalance(from, TokenBProcess, estimate);
    TokenA = Utils.add(TokenA, amount);
    TokenB = Utils.subtract(TokenB, estimate);
    local liquidity = GetLiquidity();
    if liquidity >= BondingCurve then
        IsPump = false;
        ao.send({
            Target = ManagerProcess,
            Action = "Bonded"
        });
    end
end

function SwapB(from, amount, slippage)
    if TotalShares <= 0 and IsPump == false then
        Utils.result(from, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenBEstimate(amount);
    if estimate <= slippage then
        Utils.result(from, 403, "slippage")
        return
    end;
    if TokenA <= 0 then
        Utils.result(from, 403, "No funds available")
        return
    end;
    if TokenA < estimate then
        Utils.result(from, 403, "Insufficient funds available")
        return
    end;
    local isValid = IsValid(from, TokenBProcess, amount)
    if isValid ~= true then
        Utils.result(from, 403, "Insufficient funds")
        return
    end;
    SubstractBalance(from, TokenBProcess, amount);
    AddBalance(from, TokenAProcess, estimate);
    TokenB = Utils.add(TokenB, amount);
    TokenA = Utils.subtract(TokenA, estimate);
    local liquidity = GetLiquidity();
    if liquidity >= BondingCurve then
        IsPump = false;
        ao.send({
            Target = ManagerProcess,
            Action = "Bonded"
        });
    end
end

function CreditNotice(msg)
    if not Balances[msg.From] then Balances[msg.From] = {} end;
    if not Balances[msg.From][msg.Sender] then Balances[msg.From][msg.Sender] = 0 end;
    local balance = Balances[msg.From][msg.Sender];
    Balances[msg.From][msg.Sender] = Utils.add(balance,msg.Quantity);
end

function Info(msg)
    local info = {
        Name = msg.Name,
        Ticker = msg.Ticker,
        Logo = msg.Logo,
        Denomination = msg.Denomination
    };
    TokenInfo[msg.From] = info;
end

function Balance(msg)
    if not Balances[TokenAProcess][msg.From] then Balances[TokenAProcess][msg.From] = 0 end;
    if not Balances[TokenBProcess][msg.From] then Balances[TokenBProcess][msg.From] = 0 end;
    local _balanceA = Balances[TokenAProcess][msg.From];
    local _balanceB = Balances[TokenBProcess][msg.From];
    ao.send({
        Target = msg.From,
        Action = "Balance",
        BalanceA = _balanceA,
        BalanceB = _balanceB,
        TokenA = json.encode(TokenInfo[TokenAProcess]),
        TokenB = json.encode(TokenInfo[TokenBProcess]),
        Account = msg.Tags.Target or msg.From,
    })
end

function Withdraw(msg)
    if not Balances[TokenAProcess][msg.From] then Balances[TokenAProcess][msg.From] = 0 end;
    if not Balances[TokenBProcess][msg.From] then Balances[TokenBProcess][msg.From] = 0 end;

    if msg.isTokenA then
        local _balance = Balances[TokenAProcess][msg.From];
        if _balance < msg.Quantity then
            Utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        Balances[TokenAProcess][msg.From] = Utils.subtract(_balance,msg.Quantity);
        ao.send({
            Target = TokenAProcess,
            Tags = {
                { name = "Action",    value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity",  value = msg.Quantity },
            }
        });
    else
        local _balance = Balances[TokenBProcess][msg.From];
        if _balance < msg.Quantity then
            Utils.result(msg.From, 403, "Insufficient Funds")
            return
        end;
        Balances[TokenBProcess][msg.From] = Utils.subtract(_balance,msg.Quantity);
        ao.send({
            Target = TokenBProcess,
            Tags = {
                { name = "Action",    value = "Transfer" },
                { name = "Recipient", value = msg.Recipient },
                { name = "Quantity",  value = msg.Quantity },
            }
        });
    end
end

function IsValid(owner, token, amount)
    if not Balances[token] then token[token] = {} end;
    if not Balances[token][owner] then Balances[token][owner] = 0 end;
    local balance = Balances[token][owner];
    return Utils.toNumber(amount) > 0 and Utils.toNumber(balance) >= Utils.toNumber(amount);
    ---return false
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    result.shareA = Utils.div( Utils.mul(share, TokenA), TotalShares);
    result.shareB = Utils.div(Utils.mul(share, TokenB), TotalShares);
    return result
end

function GetEquivalentTokenAEstimate(amountB)
    return Utils.div(Utils.mul(TokenA, amountB), TokenB)
end

function GetEquivalentTokenBEstimate(amountA)
    return Utils.div(Utils.mul(TokenB, amountA),TokenA)
end

function GetSwapTokenAEstimate(amount)
    local tokenA = Utils.add(TokenA, amount);
    local tokenB = Utils.div(Price(), tokenA);
    local amountB = Utils.subtract(TokenB, tokenB);
    if amountB == TokenB then amountB = Utils.subtract(amountB, 1); end --To ensure that the pool is not completely depleted
    return amountB
end

function GetSwapTokenBEstimate(amount)
    local tokenB = Utils.add(TokenB, amount);
    local tokenA = Utils.div(Price(), tokenB);
    local amountA = Utils.subtract(TokenA, tokenA);
    if amountA == TokenA then amountA = Utils.subtract(amountA, 1); end --To ensure that the pool is not completely depleted
    return amountA
end

function Price()
    return Utils.mul(TokenA, TokenB);
end

function AddBalance(owner, token, amount)
    if Balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = Balances[token][owner];
    Balances[token][owner] = Utils.add(_balance,amount);
end

function SubstractBalance(owner, token, amount)
    if Balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = Balances[token][owner];
    if Utils.toNumber(amount) > Utils.toNumber(_balance) then Balances[token][owner] = 0 end;
    Balances[token][owner] = Utils.subtract(_balance,amount);
end

function GetLiquidity()
    if TokenA == 0 and TokenB == 0 then return 0 end;
    local _price = Utils.div(TokenB, TokenA);
    local amount = Utils.mul(_price, TokenA);
    return Utils.add(amount, TokenB);
end

function _FeeMachine()
    --setup logic ot handle fee
end

Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    mul = function(a, b)
        return tostring(bint(a) * bint(b))
    end,
    div = function(a, b)
        return tostring(bint(a) / bint(b))
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

