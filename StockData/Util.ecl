IMPORT Std;
IMPORT ML_Core;
IMPORT ML_Core.Types AS Types;
IMPORT StockData;

EXPORT Util := MODULE

    EXPORT Constants := MODULE

        EXPORT MOVING_AVE_DAYS := 5;
        EXPORT TRADE_START_DATE := 20030101;
        EXPORT TRADE_END_DATE := 20181101;
        EXPORT TRADE_START_YEAR := STD.Date.Year(TRADE_START_DATE);
        EXPORT TRADE_END_YEAR := STD.Date.Year(TRADE_END_DATE);
    END;

    EXPORT DescribeExchangeCode(STRING1 exchCode) := CASE
        (
            Std.Str.ToUpperCase(exchCode),
            'O' =>  'NASDAQ',
            'N' =>  'NYSE',
            'A' =>  'AMEX',
            ERROR('Unknown exchange code: "' + exchCode + '"')
        );
    
    EXPORT MakeFullSymbol(STRING1 exchCode, STRING9 symbol) := TRIM(DescribeExchangeCode(exchCode)) + ':' + symbol;

    //Scaler
    EXPORT Scaler(DATASET(Types.NumericField) ds) := FUNCTION
        scale:= ML_Core.FieldAggregates(ds).simple;
        rst := JOIN(ds, scale, LEFT.wi = RIGHT.wi AND LEFT.number = RIGHT.number,  TRANSFORM(Types.NumericField,
                    SELF.value := (LEFT.value - RIGHT.minval)/(RIGHT.maxval- RIGHT.minval), SELF := LEFT), LOOKUP);
        RETURN rst;
    END;


    //Returen Stock Data based on the exchange code, ticket symbol and provided year
    EXPORT GetDataByYear(STRING4 code = 'O', STRING4 ticket = 'AAPL',
                        UNSIGNED4 start_year = Constants.TRADE_START_YEAR,
                            UNSIGNED4 end_year = Constants.TRADE_END_YEAR) := MODULE
        SHARED fullSymbol := MakeFullSymbol(code, ticket);
        SHARED baseData := StockData.Files.Features.ds(symbol = fullSymbol);
        //Valid Trading Dates
        SHARED ByYear( UNSIGNED4 s = start_year , UNSIGNED4 e = end_year) := FUNCTION
            tradeperiod := StockData.Files.Summarized.ds(symbol = fullSymbol);
            first_seen_year := STD.Date.Year(tradeperiod[1].first_seen_date); // 20020101
            last_seen_year := STD.Date.Year(tradeperiod[1].last_seen_date); // 20181101
            syear := MAP(e < s => ERROR('INVALID INPUTS'),
                        START_YEAR > END_YEAR => ERROR('INVALID TRADE DATE'),
                        first_seen_year < START_YEAR => MAX(Constants.TRADE_START_YEAR,s),
                        MAX(first_seen_year,s));
            eyear := MAP(e < s => ERROR('INVALID INPUTS'),
                    START_YEAR > END_YEAR => ERROR('INVALID TRADE DATE'),
                    last_seen_year > END_YEAR => MIN(Constants.TRADE_END_YEAR,e),
                    MIN(last_seen_year,e));
            ds := baseData(STD.Date.Year(trade_date) >= syear AND
                                    STD.Date.Year(trade_date) <= eyear);
            RETURN ds;
        END;
        SHARED rst := ByYear();
        EXPORT ds := PROJECT(rst, TRANSFORM(StockData.Files.Preprocessing.Layout, SELF.id := COUNTER,SELF := LEFT));
    END;
END;
