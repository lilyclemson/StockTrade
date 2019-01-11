IMPORT StockData;
IMPORT ML_Core;
IMPORT ML_Core.Types AS Types;
IMPORT ML_Core.Analysis;
IMPORT LogisticRegression AS LR;
IMPORT Std;

#WORKUNIT('name', 'Stock Data: Logistic Regression - Singel Wi');

TRADE_START_DATE := 20020108;
TRADE_END_DATE := 20181101;

//Select Apple Stock (Stock_Symbol: 'AAPL', Exchange: 'O') to run regression.
exchange_code := 'O';
stock_symbol := 'AAPL';
full_symbol := StockData.Util.MakeFullSymbol(exchange_code, stock_symbol);

baseData := StockData.Files.Features.ds( symbol = full_symbol AND (direction = 0 OR direction = 1));
//Valid Trading Dates
tradeperiod := StockData.Files.Summarized.ds(symbol = full_symbol);
first_seen := tradeperiod[1].first_seen_date; // 20020101
last_seen := tradeperiod[1].last_seen_date; // 20181101
trainstart_date := IF(first_seen <= TRADE_START_DATE, TRADE_START_DATE, first_seen); //20020108
trainend_date := 20180101;
teststart_date := MAX(trainend_date, TRADE_START_DATE);
end_date := 20180601;
testend_date := MIN(end_date, TRADE_END_DATE);

//Transform baseData to NF format.
ML_Core.AppendID(baseData, id, dsID);
dsTrain := dsID(trade_date < trainend_date AND trade_date > trainstart_date);
dstest := dsID(trade_date <= testend_date AND trade_date >= teststart_date);
ML_Core.ToField(dstrain, NFtrain, id,, ,'opening_price_change,closing_price_change,shares_traded_change_rate, direction');
ML_Core.ToField(dstest, NFtest, id,, ,'opening_price_change,closing_price_change,shares_traded_change_rate, direction');
//Helper: Scaler
Scaler(DATASET(Types.NumericField) ds) := FUNCTION
  scale:= ML_Core.FieldAggregates(ds).simple;
  rst := JOIN(ds, scale, LEFT.wi = RIGHT.wi AND LEFT.number = RIGHT.number,  TRANSFORM(Types.NumericField, 
              SELF.value := (LEFT.value - RIGHT.minval)/(RIGHT.maxval- RIGHT.minval), SELF := LEFT), LOOKUP);
RETURN rst;
END;
//Preproceessing
pfield := 4;
//Trainset
DStrainInd := NFtrain(number < pfield);
DStrainInd_scaled:= scaler(dstrainind);
DStrainDpt := PROJECT(NFtrain(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));
//Testset
DStestInd := NFtest(number < pfield);
DStestInd_scaled := scaler(DStestInd);
DStestDpt :=  PROJECT(NFtest(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));
//LogisticRegression
mod_bi := LR.BinomialLogisticRegression(100, 0.0000001).getModel(DStrainInd_scaled, DStrainDpt);
//Prediction
classesstat := Analysis.Classification.ClassStats(DSTrainDpt);
OUTPUT(classesstat , NAMED('classesstats'));
prediction  := LR.BinomialLogisticRegression(100, 0.0000001).Classify(mod_bi,DStestInd_scaled);
OUTPUT(prediction   , NAMED('prediction'));
//Analysis
evaluation := Analysis.Classification.AccuracyByClass(prediction, DSTestDpt);
OUTPUT(evaluation, NAMED('evaluation'));