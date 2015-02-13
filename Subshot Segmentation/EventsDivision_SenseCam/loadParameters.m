%% Parameters

%%% Dataset parameters
% source = 'D:\Documentos\Vicon Revue Data';
% source = '/Volumes/SHARED HD/Documentos/Vicon Revue Data';
source = '/Volumes/SHARED HD/Video Summarization Project Data Sets/R-Clustering';
global video_name;
% video_name  = '0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0';
video_name = 'Petia2';
camera = 'Narrative';
format = '.jpg';


source = [source '/' camera '/imageSets'];

%%% Feature extraction parameters
extract_features = false;

nBinsPerColor = 3; % max = 256
lenHOG = [3 3 9]; % [rows cols nGradients]
nBinsSIFTFlow = 8;
nCellsBlurriness = [3 3]; % [rows cols]


global labelsSVM;
global labels;
global weight_GC;
global classifierUsed;
global weightsClassifiers;
global distanceMeasure;
global k;
global p_value;
global doEvaluation;

%%% Evaluation Parameters
doEvaluation = true;
doPlot = false;
evaluation_type = 'fm_segments'; % 'acc_motion' or 'fm_segments'
tolerance = 5; % only used for fm_segments

%%% GC Parameters
W = 11;
min_imgs_event = 0;
weight_GC = 1;
GC_test_type = 'iterative'; % 'single' or 'iterative'
nTests = 10+1; % only for iterative

%%% Supervisied classification parameters
classifierUsed = 'KNN';
k = 21;
distanceMeasure = 'cosine'; % euclidean or cosine

%%% Feature extraction parameters
p_value = 0.001; % p-value used in the feature selection step befor training the classifier (just show purposes here)
featureSelection = false;

%%% Figures results Parameters
showResult = false;
showResult2 = false;
showResult3 = false;
showResult4 = false;
props = [100 133]; % proportions of the final summary image
n_summaryImages = 10; % number of images per cluster shown as summary

addpath('..');
addpath('../..');
addpath('GraphCuts;SupervisedClassification;FeaturesExtraction');
addpath('FeaturesPreprocessing;Evaluation;Data_Loading');

%%% Labels
labels_text = ['T'; 'S'; 'M']; % In Transit, Static, Moving Camera
