if not TokenInfo then TokenInfo = {} end;
if not Shares then Shares = {} end;
if not Balances then Balances = {} end;

TotalShares = 0;
Precision = 100000000000000000;
FeeRate = 0.01  -- Fee rate (1% in this example)
TokenA = 0;
TokenB = 0;
IsPump = true;
IsActive = true;

BondingCurve = 0;
TokenAProcess = "";
TokenBProcess = "";

Handlers.add('Init', Handlers.utils.hasMatchingTag('Action', 'Init'), function(msg)
    assert(IsActive == false,"Pool is already active")
    Init(msg)
end)

Handlers.add("InitalLiquidity", Handlers.utils.hasMatchingTag('Action', "InitalLiquidity"), function(msg)
    assert(IsActive == false,"Pool is already active")
    assert(TokenA == 0 and TokenB == 0,"Token balance is in a bad state")
    assert(IsActive == false,"Pool is already active")
    InitalLiquidity(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
    IsActive = true
end);

Handlers.add("Add", Handlers.utils.hasMatchingTag('Action', "Add"), function(msg)
    assert(IsActive,"Pool is already active")
    Add(msg.From, Utils.toNumber(msg.amountA), Utils.toNumber(msg.amountB))
end);

Handlers.add("Remove", Handlers.utils.hasMatchingTag('Action', "Remove"), function(msg)
    assert(IsActive,"Pool is already active")
    Remove(msg.From, Utils.toNumber(msg.share))
end);

Handlers.add("SwapA", Handlers.utils.hasMatchingTag('Action', "SwapA"), function(msg)
    assert(IsActive,"Pool is already active")
    SwapA(msg.From, Utils.toNumber(msg.amount),Utils.toNumber(msg.slippage));
    local _liquidity = GetLiquidity();
    if _liquidity >= BondingCurve then IsPump = false end
end);

Handlers.add("SwapB", Handlers.utils.hasMatchingTag('Action', "SwapB"), function(msg)
    assert(IsActive,"Pool is already active")
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


