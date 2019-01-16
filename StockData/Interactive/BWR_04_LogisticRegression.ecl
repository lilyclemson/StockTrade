IMPORT StockData;
IMPORT ML_Core;
IMPORT ML_Core.Types AS Types;
IMPORT ML_Core.Analysis;
IMPORT LogisticRegression AS LR;
IMPORT Std;

#WORKUNIT('name', 'Stock Data: Logistic Regression: Singel-Wi');

TRADE_START_DATE := StockData.Util.Constants.TRADE_START_DATE;
TRADE_END_DATE := StockData.Util.Constants.TRADE_END_DATE;

//Select Apple Stock (Stock_Symbol: 'AAPL', Exchange: 'O') to run regression.
exchange_code := 'O';
stock_symbol := 'AAPL';
baseData := StockData.Files.Features.ds( stock_symbol = 'AAPL' AND (direction = 0 OR direction = 1));

//Step 1: Preprocessing
//Hold your data in ML format
//---Continuous Field: ML_Core.Types.NumericField
//---Discrete Field: ML_Core.Types.DiscreteField
//TRRANSFORM the datasets to ML_Core.Types.NumericField format
//Append ID to each record
ML_Core.AppendID(baseData, id, dsID);
//Filter the data we need from basedata
//Define filter criteria based on the Date (YYYYMMDD)
//Define filter criteria for Traing set based on the Date
trainstart_date := 20050101;
trainend_date := 20160101;
//Define filter criteria for Test set based on the Date
teststart_date := 20160101;
testend_date := 20180101;
//Action: get the desired datasets
dsTrain := dsID(trade_date < trainend_date AND trade_date > trainstart_date);
dstest := dsID(trade_date <= testend_date AND trade_date >= teststart_date);

//Convert dataset to the NumericField format used by HPCC ML algorithm
//ML_Core.ToField is a powerful tool to TRANSFORM your data to NumericField format.
ML_Core.ToField(dstrain, NFtrain, id,,,'opening_price_change,' +
                                        'closing_price_change,' +
                                        'shares_traded_change_rate,' +
                                        'moving_ave_opening_price,' +
                                        'moving_ave_high_price,' +
                                        'moving_ave_low_price,' +
                                        'moving_ave_closing_price,' +
                                        'direction');
ML_Core.ToField(dstest, NFtest, id,,,  'opening_price_change,' +
                                        'closing_price_change,' +
                                        'shares_traded_change_rate,' +
                                        'moving_ave_opening_price,' +
                                        'moving_ave_high_price,' +
                                        'moving_ave_low_price,' +
                                        'moving_ave_closing_price,' +
                                        'direction');

//Define the Dependence data and the Independence data for our model
//As shown in the NFtrain dataset, the classes are defined at Field 8
pfield := 8;
//Trainset
//Independence dataset for training
DStrainInd := NFtrain(number < pfield);
DStrainInd_scaled:= StockData.Util.Scaler(dstrainind);
//dependence dataset for training
DStrainDpt := PROJECT(NFtrain(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));
//Testset
//Independence dataset for test
DStestInd := NFtest(number < pfield);
DStestInd_scaled := StockData.Util.Scaler(DStestInd);
//dependence dataset for test
DStestDpt :=  PROJECT(NFtest(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));
//Take a look of your data before training models
//Class stats
train_classesstat := Analysis.Classification.ClassStats(DSTrainDpt);
OUTPUT(train_classesstat , NAMED('train_classstats'));
test_classesstat := Analysis.Classification.ClassStats(DSTestDpt);
OUTPUT(test_classesstat , NAMED('test_classstats'));

//Step 2: Train ML model
//LogisticRegression
//Define the max number of iterations
MaxItr := 100;
//Define the converge threshold
e :=  0.0000001;
mod_bi := LR.BinomialLogisticRegression(MaxItr, e).getModel(DStrainInd_scaled, DStrainDpt);

//Step 3: Prediction
prediction  := LR.BinomialLogisticRegression(100, 0.0000001).Classify(mod_bi,DStestInd_scaled);
OUTPUT(prediction , NAMED('prediction'));

//Step 4: Evaluation
evaluation := Analysis.Classification.AccuracyByClass(prediction, DSTestDpt);
OUTPUT(evaluation, NAMED('evaluation'));
