IMPORT StockData;
IMPORT DataPatterns;

#WORKUNIT('name', 'Stock Data: Profile Final Data');

// Collect the results of the data profiling call
profileResults := DataPatterns.Profile
    (
        StockData.Files.Features.ds,
        features := 'fill_rate,best_ecl_types,cardinality,modes,lengths,patterns,min_max,mean,std_dev,quartiles'
    );

// Write results as a native Thor file
OUTPUT(profileResults, /*RecStruct*/, StockData.Files.PATH_PREFIX + '::final_profile', OVERWRITE);
