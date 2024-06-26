function IsValid(owner, token, amount)
    if not Balances[token] then token[token] = {} end;
    if not Balances[token][owner] then Balances[token][owner] = 0 end;
    local balance = Balances[token][owner];
    return Utils.toNumber(amount) > 0 and Utils.toNumber(balance) >= Utils.toNumber(amount);
    ---return false
end

function GetEquivalentTokenAEstimate(amountB)
    return (TokenA * Utils.toNumber(amountB)) / TokenB
end

function GetEquivalentTokenBEstimate(amountA)
    return (TokenB * amountA) / TokenA
end

function GetSwapTokenAEstimate(amount)
    local tokenA = TokenA + amount;
    local tokenB = Price() / tokenA;
    local amountB = TokenB - tokenB;
    if amountB == TokenB then amountB = amountB - 1; end --To ensure that the pool is not completely depleted
end

function GetSwapTokenBEstimate(amount)
    local tokenB = TokenB + amount;
    local tokenA = Price() / tokenB;
    local amountA = TokenA - tokenA;
    if amountA == TokenA then amountA = amountA - 1; end --To ensure that the pool is not completely depleted
end

function Price()
    return TokenA * TokenB;
end

function AddBalance(owner, token, amount)
    if Balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = Balances[token][owner];
    Balances[token][owner] = Utils.toNumber(_balance) + Utils.toNumber(amount);
end

function SubstractBalance(owner, token, amount)
    if Balances[token][owner] == nil then token[token][owner] = 0 end;
    local _balance = Balances[token][owner];
    if Utils.toNumber(amount) > Utils.toNumber(_balance) then Balances[token][owner] = 0 end;
    Balances[token][owner] = Utils.toNumber(_balance) - Utils.toNumber(amount);
end

function GetLiquidity()
    if TokenA == 0 and TokenB == 0 then return 0 end;
    local _price = TokenB / TokenA;
    local amount = _price * TokenA;
    return amount + TokenB;
end

function _FeeMachine()
    --setup logic ot handle fee
end
