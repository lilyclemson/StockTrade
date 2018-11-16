IMPORT StockData;
IMPORT Std;

#WORKUNIT('name', 'Stock Data: Summarize Cleaned Data');

baseData := StockData.Files.Cleaned.ds;

perSymbol := TABLE
    (
        baseData,
        {
            STRING16            symbol := StockData.Util.MakeFullSymbol(exchange_code, stock_symbol),
            Std.Date.Date_t     first_seen_date := MIN(GROUP, trade_date),
            Std.Date.Date_t     last_seen_date := MAX(GROUP, trade_date),
            UNSIGNED4           num_trading_days := COUNT(GROUP),
            DECIMAL9_2          lowest_closing_price := MIN(GROUP, closing_price),
            DECIMAL9_2          highest_closing_price := MAX(GROUP, closing_price)
        },
        StockData.Util.MakeFullSymbol(exchange_code, stock_symbol),
        MERGE
    );

OUTPUT(perSymbol, /*RecStruct*/, StockData.Files.Summarized.PATH, OVERWRITE);
