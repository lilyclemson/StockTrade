IMPORT StockData;
IMPORT DataPatterns;

#WORKUNIT('name', 'Stock Data: Profile Cleaned Data');

profileResults := DataPatterns.Profile(StockData.Files.Cleaned.ds);

OUTPUT(profileResults, /*RecStruct*/, StockData.Files.Profiled.PATH, OVERWRITE);
