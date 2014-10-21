
%% 
%   This script builds the KNN classifier for classifying In Transit, Static and 
%   Moving Head images.
%%%%

%% Data params
path_data = '../EventsDivision_SenseCam/Datasets';
global folder_data;
% folder_data = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
%     '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
%     '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
%     '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
%     'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
global k;
global distanceMeasure;
% k = 15; % k number of nearest neighbours

treatMethod = 'stand'; % {'norm' = normalize || 'stand' = standardize}

% Structure for saving the normalization params for each of the
% classifiers.
normParams = struct('maxVals', {}, 'minVals', {});
% Structure for saving the standardization params for each of the
% classifiers.
standParams = struct('meanD', {}, 'stdDev', {});

balanced = true;
featureSelection = false;

%% Data retrieval
numFolders = length(folder_data);
nClasses = length(classes);
features_aux = [];
labels = [];
for idFold = 1:numFolders
    load([path_data '/' folder_data{idFold} '/labels_result.mat']); % labels_result
    load([path_data '/' folder_data{idFold} '/featuresNoColour.mat']); % featuresNoColour
    features_aux = [features_aux; featuresNoColour];
%     load([path_data '/' folder_data{idFold} '/features.mat']); % features
%     features_aux = [features_aux; features];
    labels = [labels labels_result(:).label];
end
features = features_aux;

if(featureSelection)
    features = applyFeatureSelection(features, ['KNN' distanceMeasure(1)]);
end

% %%%%%%% Caution! Features outliers correction with log
% colLength = 3;
% HOGLength = [3 3 9];
% load('D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_SenseCam\FeaturesTests\featureSelection.mat');
% 
% not0 = fs((colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)+1):end)==1;
% 
% features(:,find(not0==1)>(9+8)) = abs(features(:,find(not0==1)>(9+8)));
% for i = 1:3
%     for j = find(find(not0==1)>(9+8))
%         features(:,j) = log10(features(:,j));
%         if(i~=3)
%             features((features(:,j)<0),j) = 0;
%         else
%             features((features(:,j)==-Inf),j) = min(features(~(features(:,j)==-Inf),j));
%         end
%     end
% end
% %%%%%%%%

counts = zeros(1, nClasses);
elems = {};

for i = 1:nClasses
    counts(i) = sum(labels==i);
    elems{i} = find((labels==i)==1);
end

%% Balances the data
if(balanced)
    counts(:) = min(counts);
end

%% Gets the data separated into classes
for i = 1:nClasses
    indices = randsample(elems{i}, counts(i));
    elems{i} = features(indices, :);
end


%% Trains the classifier
% Gets elements "e" and classes "c"
e = [];
c = [];
for i = 1:nClasses
    e = [e; elems{i}];
    c = [c; ones(counts(i),1)*i];
end

if(strcmp(treatMethod, 'norm'))
    % Normalizes the data
    [ e, minVals, maxVals ] = normalize( e );
    normParams(1).maxVals = maxVals;
    normParams(1).minVals = minVals;
elseif(strcmp(treatMethod, 'stand'))
    [ e, meanD, stdDev ] = standarize( e );
    standParams(1).meanD = meanD;
    standParams(1).stdDev = stdDev;
end

% Builds the classifier
classifier = ClassificationKNN.fit(e, c, 'NumNeighbors', k, 'Distance', distanceMeasure);
disp(['Classifier trained.']);

%% Saves the result
save(['KNN' distanceMeasure(1) ' Classifier/classifierKNN'], 'classifier');

if(strcmp(treatMethod, 'norm'))
    save(['KNN' distanceMeasure(1) ' Classifier/normParams'], 'normParams');
elseif(strcmp(treatMethod, 'stand'))
    save(['KNN' distanceMeasure(1) ' Classifier/standParams'], 'standParams');
end


disp('KNN classifier built.');