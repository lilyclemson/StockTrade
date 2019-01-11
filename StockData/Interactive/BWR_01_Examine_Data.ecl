IMPORT StockData;

// Reference to the data
theData := StockData.Files.Features.ds;

// Show the first 100 records in the file
OUTPUT(theData, NAMED('data_sample'));

// Show the number of records in the file
recordCount := COUNT(theData);
OUTPUT(recordCount, NAMED('number_of_records'));

// Show the maximum number of shares traded in any single day
maxShares := MAX(theData, shares_traded);
OUTPUT(maxShares, NAMED('max_shares_traded'));

// Show the minimum number of shares (above zero) traded in any single day
minShares := MIN(theData(shares_traded > 0), shares_traded);
OUTPUT(minShares, NAMED('min_shares_traded'));
