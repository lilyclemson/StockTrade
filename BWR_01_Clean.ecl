IMPORT StockData;

#WORKUNIT('name', 'Stock Data: Clean Raw Data');

reinterpretedData := DATASET
    (
        StockData.Files.Raw.PATH,
        StockData.Files.Cleaned.Layout,
        CSV(SEPARATOR('\t'), HEADING(1), QUOTE(''))
    );

OUTPUT(reinterpretedData, /*RecStruct*/, StockData.Files.Cleaned.PATH, OVERWRITE, COMPRESSED);
