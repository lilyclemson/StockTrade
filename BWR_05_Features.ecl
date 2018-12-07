IMPORT StockData;
IMPORT Std;

#WORKUNIT('name', 'Stock Data: Enhance Cleaned Data W Full Features');

baseData := StockData.Files.Enhanced.ds;

enhancedData1 := PROJECT
    (
        baseData,
        TRANSFORM
            (
                StockData.Files.Features.Layout,
                SELF := LEFT,
                SELF := []
            )
    );

groupedData := GROUP(SORT(enhancedData1, symbol, trade_date), symbol);

withChanges := ITERATE
    (
        groupedData,
        TRANSFORM
            (
                RECORDOF(LEFT),
                SELF.shares_traded_change_rate := RIGHT.shares_traded_change / LEFT.shares_traded,
                SELF.direction := MAP(
                                        RIGHT.closing_price_change < 0 =>0,
                                        RIGHT.closing_price_change > 0 => 1, 2), 
                SELF := RIGHT)
    );

ungroupedData := UNGROUP(withChanges);

OUTPUT(ungroupedData, /*RecStruct*/, StockData.Files.Features.PATH, OVERWRITE, COMPRESSED);

working_data := PROJECT(ungroupedData, TRANSFORM(StockData.Files.Preprocessing.Layout,
                                                SELF := LEFT));
