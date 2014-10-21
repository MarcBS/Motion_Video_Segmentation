
%% 
%   This script is only used for feature statistical relevance checking.
%%%%

addpath('..');

%% Global params
global C;
global sigma;
global k;
global distMetric;
global treatMethod;
classifyMethod = 'KNN'; % SVM or KNN
C = 3;
sigma = 3;
k = 21; % 11, 21
distMetric = 'cosine'; % euclidean or cosine
treatMethod = 'stand'; % norm or stand
nFolds = 3;

%% Data params
path_data = '../../EventsDivision_SenseCam/Datasets';
% global folder_data;
folder_data = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
classesShort = {'T', 'S', 'M'};
classes = {'In Transit'; 'Static'; 'Moving Camera'}; % In Transit, Static, Moving Camera

featuresNum = [9 81 8 9 9];
featuresType = {'C', 'H', 'S', 'B', 'D'}; % (Colour, HOG, SIFT Flow, Blurriness, ColorDif)
featureTypeLong = {'Colour', 'HOG', 'SIFT Flow', 'Blurriness', 'Color Difference'};

% Preparation of the features row for printing the result
rowFeatures = '| ';
count = 2;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        rowFeatures = sprintf([rowFeatures featuresType{i} '%2d | '], j);
        count = count+1;
    end
end


%% Data retrieval
numFolders = length(folder_data);
nClasses = length(classes);
f = [];
labels = [];
for idFold = 1:numFolders
    load([path_data '/' folder_data{idFold} '/labels_result.mat']); % labels_result
    load([path_data '/' folder_data{idFold} '/features.mat']); % features
    f = [f; features];
    labels = [labels labels_result(:).label];
end
features = f;

% Logarithm on color difference
features(:,(9+81+8+9+1):end) = abs(features(:,(9+81+8+9+1):end));
for i = 1:3
    for j = (9+81+8+9+1):(9+81+8+9+9)
        features(:,j) = log(features(:,j));
        features((features(:,j)<0),j) = 0;
    end
    for j = 1:9
        features(:,j) = log(features(:,j));
        features((features(:,j)<0),j) = 0;
    end
end

%% Get only features intended for SVM/KNN
features = features(:, sum(featuresNum(1:2))+1:end);

%% Apply stratified 10-fold divison
% Balancing
count = zeros(1,nClasses);
for i = 1:nClasses
    count(i) = sum(labels==i);
end
% Getting balanced random selection
selElements = zeros(min(count)*nClasses, size(features,2));
selLabels = zeros(1,min(count)*nClasses);
for i = 1:nClasses
    selElements(((min(count)*(i-1))+1):min(count)*i , :) = features(randsample(find(labels==i), min(count)), :);
    selLabels(((min(count)*(i-1))+1):min(count)*i) = i;
end
% Creating 10-folds
tenfoldCVP = cvpartition(selLabels,'kfold',nFolds);

%% FS function
if(strcmp(classifyMethod, 'SVM'))
    classifyHandle = @classifyFS_SVM;
elseif(strcmp(classifyMethod, 'KNN'))
    classifyHandle = @classifyFS_KNN;
end

%% Apply sequential feature selection
[fs,history]  = sequentialfs(classifyHandle,selElements,selLabels','cv',tenfoldCVP, 'Nf', size(features, 2));

save(['featureSelection_' classifyMethod '.mat'], 'fs');
disp('Sequential FS Done');

