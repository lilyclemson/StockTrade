IMPORT StockData;
IMPORT Std;

#WORKUNIT('name', 'Stock Data: Enhance Cleaned Data');

baseData := StockData.Files.Cleaned.ds;

enhancedData1 := PROJECT
    (
        baseData,
        TRANSFORM
            (
                StockData.Files.Enhanced.Layout,
                SELF.symbol := StockData.Util.MakeFullSymbol(LEFT.exchange_code, LEFT.stock_symbol),
                SELF.trade_year := Std.Date.Year(LEFT.trade_date),
                SELF.trade_month := Std.Date.Month(LEFT.trade_date),
                SELF.trade_day := Std.Date.Day(LEFT.trade_date),
                SELF.trade_day_of_week := Std.Date.DayOfWeek(LEFT.trade_date),
                SELF.trade_quarter := (SELF.trade_month DIV 4) + 1,
                SELF.trade_day_of_year := Std.Date.DayOfYear(LEFT.trade_date),
                SELF.trade_day_of_quarter := Std.Date.DaysBetween
                    (
                        Std.Date.DateFromParts(SELF.trade_year, (SELF.trade_quarter - 1) * 3 + 1, 1),
                        LEFT.trade_date
                    ) + 1,
                SELF := LEFT,
                SELF := []
            )
    );

distDS := DISTRIBUTE(enhancedData1, HASH32(symbol));

groupedData := GROUP(SORT(distDS, symbol, trade_date, LOCAL), symbol, LOCAL);

withChanges := ITERATE
    (
        groupedData,
        TRANSFORM
            (
                RECORDOF(LEFT),
                SELF.opening_price_change := IF(LEFT.symbol != '', RIGHT.opening_price - LEFT.opening_price, 0),
                SELF.closing_price_change := IF(LEFT.symbol != '', RIGHT.closing_price - LEFT.closing_price, 0),
                SELF.shares_traded_change := IF(LEFT.symbol != '', RIGHT.shares_traded - LEFT.shares_traded, 0),
                SELF := RIGHT
            )
    );

// Add moving averages
withID := PROJECT
    (
        withChanges,
        TRANSFORM
            (
                {
                    INTEGER4    id,
                    RECORDOF(LEFT)
                },
                SELF.id := COUNTER,
                SELF := LEFT
            )
    );

ungroupedData := UNGROUP(withID);

withMovingAve := DENORMALIZE
    (
        ungroupedData,
        ungroupedData,
        LEFT.symbol = RIGHT.symbol
            AND RIGHT.id > 0
            AND RIGHT.id BETWEEN (LEFT.id - StockData.Util.Constants.MOVING_AVE_DAYS) AND (LEFT.id - 1),
        GROUP,
        TRANSFORM
            (
                RECORDOF(LEFT),
                SELF.moving_ave_opening_price := IF(COUNT(ROWS(RIGHT)) = StockData.Util.Constants.MOVING_AVE_DAYS, AVE(ROWS(RIGHT), opening_price), 0),
                SELF.moving_ave_high_price := IF(COUNT(ROWS(RIGHT)) = StockData.Util.Constants.MOVING_AVE_DAYS, AVE(ROWS(RIGHT), high_price), 0),
                SELF.moving_ave_low_price := IF(COUNT(ROWS(RIGHT)) = StockData.Util.Constants.MOVING_AVE_DAYS, AVE(ROWS(RIGHT), low_price), 0),
                SELF.moving_ave_closing_price := IF(COUNT(ROWS(RIGHT)) = StockData.Util.Constants.MOVING_AVE_DAYS, AVE(ROWS(RIGHT), closing_price), 0),
                SELF := LEFT
            ),
        LOCAL
    );

withoutID := PROJECT
    (
        withMovingAve,
        TRANSFORM
            (
                RECORDOF(LEFT) - [id],
                SELF := LEFT
            )
    );

OUTPUT(withoutID, /*RecStruct*/, StockData.Files.Enhanced.PATH, OVERWRITE, COMPRESSED);
