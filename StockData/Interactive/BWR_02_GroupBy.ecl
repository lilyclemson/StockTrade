IMPORT StockData;

// Reference to the data
theData := StockData.Files.Features.ds;

/*
Find the average number of shares traded per week day.  This is equivalent to
the following SQL statement:

    SELECT trade_day_of_week, AVE(shares_traded) AS num_shares_traded
    FROM theData
    GROUP BY trade_day_of_week;
*/
aveSharesTradedPerDay := TABLE
    (
        theData,
        {
            trade_day_of_week,
            UNSIGNED6   num_shares_traded := AVE(GROUP, shares_traded)
        },
        trade_day_of_week
    );

// Make sure the result is in ascending order by day of week
sortedResult := SORT(aveSharesTradedPerDay, trade_day_of_week);

OUTPUT(sortedResult, NAMED('shares_traded_per_day'));
