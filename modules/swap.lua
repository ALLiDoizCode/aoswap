local ao = require('ao');
local json = require('json');


function Init(msg)
    ao.isTrusted(msg)
    TokenAProcess = msg.tokenA;
    TokenBProcess = msg.tokenB;
    BondingCurve = msg.bondingCurve;
    Utils.result(msg.From, 200, 'success')
end

function Liquidity(msg)
    if IsPump then
        if (TokenA == 0 and TokenB == 0) then
            Utils.result(msg.From, 200, "Adding Inital Liquidity")
            InitalLiquidity(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
            Utils.result(msg.From, 200, "Added Inital Liquidity")
            return
        else
            Utils.result(msg.From, 403, "You can't add liquidty to pumps") 
        end;
        return
    end;
    if msg.isAdd then
        Add(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
    else
        Remove(msg.From, Utils.toNumber(msg.share))
    end
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
    TokenA = TokenA + Utils.toNumber(amountA);
    TokenB = TokenB + Utils.toNumber(amountB);
    local _share = Utils.toNumber(Shares[from]);
    Shares[from] = _share + _Share;
    TotalShares = TotalShares + _Share;
end

function Add(from, amountA, amountB)
    if not Shares[from] then Shares[from] = 0 end;
    _Share = 0;
    local isValidA = IsValid(from, TokenAProcess, amountA)
    local isValidB = IsValid(from, TokenBProcess, amountB)
    if (TotalShares == 0) then _Share = 100 * Precision end;
    Utils.result(from, 200, "BoomStick")
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
    TokenA = TokenA + amountA;
    TokenB = TokenB + amountB;
    local _share = Shares[from];
    Shares[from] = _share + _Share;
    TotalShares = TotalShares + _Share;
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
    Shares[from] = _Share - share;
    AddBalance(from, TokenAProcess, estimate.shareA);
    AddBalance(from, TokenBProcess, estimate.shareB);
    TotalShares = TotalShares + share;
end

function SwapA(msg)
    if TotalShares <= 0 then
        Utils.result(msg.From, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenAEstimate(Utils.toNumber(msg.amount));
    if estimate <= Utils.toNumber(msg.slippage) then
        Utils.result(msg.From, 403, "slippage")
        return
    end;
    if TokenB <= 0 then
        Utils.result(msg.From, 403, "No funds available")
        return
    end;
    if TokenB < estimate then
        Utils.result(msg.From, 403, "Insufficient funds available")
        return
    end;
    local isValid = IsValid(msg.From, TokenAProcess, Utils.toNumber(msg.amount))
    if isValid ~= false then
        Utils.result(msg.From, 403, "Insufficient funds")
        return
    end;
    SubstractBalance(msg.From, TokenAProcess, Utils.toNumber(msg.amount));
    AddBalance(msg.From, TokenBProcess, estimate);
    TokenA = TokenA + Utils.toNumber(msg.amount);
    TokenB = TokenB - estimate;
    local _liquidity = GetLiquidity();
    if _liquidity >= BondingCurve then IsPump = false end
end

function SwapB(msg)
    if TotalShares <= 0 then
        Utils.result(msg.From, 403, "Total Shares less then or equal to 0")
        return
    end;
    local estimate = GetSwapTokenBEstimate(Utils.toNumber(msg.amount));
    if estimate <= Utils.toNumber(msg.slippage) then
        Utils.result(msg.From, 403, "slippage")
        return
    end;
    if TokenA <= 0 then
        Utils.result(msg.From, 403, "No funds available")
        return
    end;
    if TokenA < estimate then
        Utils.result(msg.From, 403, "Insufficient funds available")
        return
    end;
    local isValid = IsValid(msg.From, TokenBProcess, Utils.toNumber(msg.amount))
    if isValid ~= false then
        Utils.result(msg.From, 403, "Insufficient funds")
        return
    end;
    SubstractBalance(msg.From, TokenBProcess, Utils.toNumber(msg.amount));
    AddBalance(msg.From, TokenAProcess, estimate);
    TokenB = TokenB + Utils.toNumber(msg.amount);
    TokenA = TokenA - estimate;
    local _liquidity = GetLiquidity();
    if _liquidity >= BondingCurve then IsPump = false end
end

function GetRemoveEstimate(share)
    local result = {};
    result.shareA = 0;
    result.shareB = 0;
    result.shareA = (share * TokenA) / TotalShares;
    result.shareB = (share * TokenB) / TotalShares;
    return result
end

function CreditNotice(msg)
    if not Balances[msg.From] then Balances[msg.From] = {} end;
    if not Balances[msg.From][msg.Sender] then Balances[msg.From][msg.Sender] = 0 end;
    local balance = Balances[msg.From][msg.Sender];
    Balances[msg.From][msg.Sender] = balance + Utils.toNumber(msg.Quantity);
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
        Balances[TokenAProcess][msg.From] = _balance - msg.Quantity;
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
        Balances[TokenBProcess][msg.From] = _balance - msg.Quantity;
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