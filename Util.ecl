IMPORT Std;

EXPORT Util := MODULE

    EXPORT DescribeExchangeCode(STRING1 exchCode) := CASE
        (
            Std.Str.ToUpperCase(exchCode),
            'O' =>  'NASDAQ',
            'N' =>  'NYSE',
            'A' =>  'AMEX',
            ERROR('Unknown exchange code: "' + exchCode + '"')
        );
    
    EXPORT MakeFullSymbol(STRING1 exchCode, STRING9 symbol) := TRIM(DescribeExchangeCode(exchCode)) + ':' + symbol;

END;
