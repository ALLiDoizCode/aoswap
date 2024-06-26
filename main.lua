if not TokenInfo then TokenInfo = {} end;
if not Shares then Shares = {} end;
if not Balances then Balances = {} end;

TotalShares = 0;
Precision = 100000000000000000;
FeeRate = 0.01  -- Fee rate (1% in this example)
TokenA = 0;
TokenB = 0;
IsPump = true;

BondingCurve = 0;
TokenAProcess = "";
TokenBProcess = "";

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    Init(msg)
end)

Handlers.add("InitalLiquidity", Handlers.utils.hasMatchingTag('Action', "InitalLiquidity"), function(msg)
    if IsPump then
        if (TokenA == 0 and TokenB == 0) then
            InitalLiquidity(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
            return
        else
            Utils.result(msg.From, 403, "You can't add liquidty to pumps") 
        end;
        return
    end;
end);

Handlers.add("Add", Handlers.utils.hasMatchingTag('Action', "Add"), function(msg)
    Add(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
end);

Handlers.add("Remove", Handlers.utils.hasMatchingTag('Action', "Remove"), function(msg)
    Remove(msg.From, Utils.toNumber(msg.share))
end);

Handlers.add("SwapA", Handlers.utils.hasMatchingTag('Action', "SwapA"), function(msg)
    SwapA(msg.From, Utils.toNumber(msg.amount),Utils.toNumber(msg.slippage));
    local _liquidity = GetLiquidity();
    if _liquidity >= BondingCurve then IsPump = false end
end);

Handlers.add("SwapB", Handlers.utils.hasMatchingTag('Action', "SwapB"), function(msg)
    SwapB(msg.From, Utils.toNumber(msg.amount),Utils.toNumber(msg.slippage));
    local _liquidity = GetLiquidity();
    if _liquidity >= BondingCurve then IsPump = false end
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


