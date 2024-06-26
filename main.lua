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

Handlers.add("Add", Handlers.utils.hasMatchingTag('Action', "Add"), function(msg)
    Add(msg)
end);

Handlers.add("Remove", Handlers.utils.hasMatchingTag('Action', "Remove"), function(msg)
    Remove(msg)
end);

Handlers.add("SwapA", Handlers.utils.hasMatchingTag('Action', "SwapA"), function(msg)
    SwapA(msg)
end);

Handlers.add("SwapB", Handlers.utils.hasMatchingTag('Action', "SwapB"), function(msg)
    SwapB(msg)
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


