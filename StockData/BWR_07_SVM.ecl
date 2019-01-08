IMPORT Std;
IMPORT StockData;
IMPORT ML_Core;
IMPORT ML_Core.Analysis;
IMPORT ML_Core.Types AS Types;
IMPORT SupportVectorMachines AS SVM;
IMPORT SVM.LibSVM;

#WORKUNIT('name', 'Stock Data: SVM - Multi Wi');

TRADE_START_DATE := StockData.Util.Constants.TRADE_START_DATE;
TRADE_END_DATE := StockData.Util.Constants.TRADE_END_DATE;

//SVM Example: Apple Stock (Stock_Symbol: 'AAPL', Exchange: 'O')
exchange_code := 'O';
stock_symbol := 'AAPL';
baseData := StockData.Files.Features.ds( stock_symbol = 'AAPL' AND (direction = 0 OR direction = 1));
//Define Data Range
trainstart_date := 20050101;
trainend_date := 20160101;
teststart_date := 20160101;
testend_date := 20180101;

//Convert dataset to the NumericField format used by HPCC ML algorithm
ML_Core.AppendID(baseData, id, dsID);
dsTrain := dsID(trade_date < trainend_date AND trade_date > trainstart_date);
dstest := dsID(trade_date <= testend_date AND trade_date >= teststart_date);

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

//Preproceessing
//Trainset
// Create a testing dataset by concatenating three identical datasets.
// Individual datasets are identified by a work ID column, 'wi'.
Types.NumericField IncrementWID(Types.NumericField L) := TRANSFORM
  SELF.wi := L.wi + 1;
  SELF := L;
END;
NFtrainx3 := NFtrain +
  PROJECT(NFtrain, IncrementWID(LEFT)) +
  PROJECT(PROJECT(NFtrain, IncrementWID(LEFT)), IncrementWID(LEFT));

// Split out DStrainInd_scaled and DStrainDpt ('number' identifies column, and number = 8
// corresponds to the labels).
pfield := 8;
DStrainInd := NFtrainx3(number < pfield);
DStrainInd_scaled:= StockData.Util.Scaler(dstrainind);
DStrainDpt := PROJECT(NFtrainx3(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));
//Testset
DStestInd := NFtest(number < pfield);
DStestInd_scaled := StockData.Util.Scaler(DStestInd);
DStestDpt :=  PROJECT(NFtest(number = pfield ), TRANSFORM(Types.DiscreteField, SELF.number := 1, SELF := LEFT));

//Class stats
train_DStrainDptstat := Analysis.Classification.ClassStats(DSTrainDpt);
OUTPUT(train_DStrainDptstat , NAMED('train_DStrainDptstats'));
test_DStrainDptstat := Analysis.Classification.ClassStats(DSTestDpt);
OUTPUT(test_DStrainDptstat , NAMED('test_DStrainDptstats'));

// Define a set of model parameters
svmType    := LibSVM.Types.LibSVM_Type.C_SVC;
kernelType := LibSVM.Types.LibSVM_Kernel.RBF;
gamma      := 0.05;
C          := 1.0;
degree     := 3;
coef0      := 0.0;
nu         := 0.5;
eps        := 0.001;
p          := 0.1;
shrinking  := true;
prob_est   := true;
scale      := true;
nr_weight  := 1;
lbl        := DATASET([], SVM.Types.I4Entry);
weight     := DATASET([], SVM.Types.R8Entry);

// Define model parameters
SVMSetup := SVM.SVC(
  NAMED svmType     := svmType,
  NAMED kernelType  := kernelType,
  NAMED gamma       := gamma,
  NAMED C           := C,
  NAMED degree      := degree,
  NAMED coef0       := coef0,
  NAMED eps         := eps,
  NAMED nu          := nu,
  NAMED p           := p,
  NAMED shrinking   := shrinking,
  NAMED prob_est    := prob_est,
  NAMED scale       := scale,
  NAMED nr_weight   := nr_weight,
  NAMED lbl         := lbl,
  NAMED weight      := weight
);

// Build SVM models using chosen parameters
SVMModel := SVMSetup.GetModel(
  NAMED observations    := DStrainInd_scaled,
  NAMED classifications := DStrainDpt
);

//Prediction
// Use fitted models to classify training data
classifyResults := SVMSetup.Classify(
  NAMED model             := SVMModel,
  NAMED new_observations  := DStestInd_scaled
);
OUTPUT(classifyResults, NAMED('PredictedDStrainDpt'));

//Analysis
evaluation := Analysis.Classification.AccuracyByClass(classifyResults, DSTestDpt);
OUTPUT(evaluation, NAMED('evaluation'));