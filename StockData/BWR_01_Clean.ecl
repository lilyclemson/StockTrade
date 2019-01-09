IMPORT StockData;

#WORKUNIT('name', 'Stock Data: Clean Raw Data');

// Reference to original tab-delimited file; uses a record layout with
// explicit, correct datatypes for each field (HPCC automatically coerces)
reinterpretedData := DATASET
    (
        StockData.Files.Raw.PATH,
        StockData.Files.Cleaned.Layout,
        CSV(SEPARATOR('\t'), HEADING(1), QUOTE(''))
    );

// Write the result as a native Thor logical file
OUTPUT(reinterpretedData, /*RecStruct*/, StockData.Files.Cleaned.PATH, OVERWRITE, COMPRESSED);
