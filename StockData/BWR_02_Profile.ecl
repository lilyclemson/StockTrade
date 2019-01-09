IMPORT StockData;
IMPORT DataPatterns;

#WORKUNIT('name', 'Stock Data: Profile Cleaned Data');

// Collect the results of the data profiling call
profileResults := DataPatterns.Profile(StockData.Files.Cleaned.ds);

// Write results as a native Thor file
OUTPUT(profileResults, /*RecStruct*/, StockData.Files.Profiled.PATH, OVERWRITE);
