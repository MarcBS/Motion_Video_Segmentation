function [labels, likelihood] = applyKNN(pathToFeatures, featureSelection)
%% Applies the KNN algorithm to the given samples.
%
%   INPUT
%       pathToFeatures -> path to the folder where are the features to
%           analyse (the file must be called featuresNoColour.mat).
%       featureSelection -> indicates if we want to perform a feature
%           selection.
%       k -> number of nearest neighbours considered in the decision.
%
%   OUTPUT
%       labels -> the most probable label for each sample.
%       likelihood -> matrix (nxm) with likelihoods for each of the classes, where
%           n = number of samples and m = number of classes.
%
%%%%

    global distanceMeasure;

    %% Parameters and initializations
    classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
%     pathToFeatures = 'D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_Grauman\P01_1to4001';
    
    treatMethod = 'stand'; % {'norm' = normalize || 'stand' = standardize}

    load([pathToFeatures '/featuresNoColour.mat']); % featuresNoColour
    features = featuresNoColour;
%     load([pathToFeatures '/features.mat']);
    
    if(featureSelection)
        features = applyFeatureSelection(features, ['KNN' distanceMeasure(1)]);
    end
    
%     %%%%%%% Caution! Features outliers correction with log
%     colLength = 3;
%     HOGLength = [3 3 9];
%     load('D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_SenseCam\FeaturesTests\featureSelection.mat');
% 
%     not0 = fs((colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)+1):end)==1;
% 
%     features(:,find(not0==1)>(9+8)) = abs(features(:,find(not0==1)>(9+8)));
%     for i = 1:3
%         for j = find(find(not0==1)>(9+8))
%             features(:,j) = log10(features(:,j));
%             if(i~=3)
%                 features((features(:,j)<0),j) = 0;
%             else
%                 features((features(:,j)==-Inf),j) = min(features(~(features(:,j)==-Inf),j));
%             end
%         end
%     end
%     %%%%%%%%
    
    pathToClassifiers = ['KNN' distanceMeasure(1) ' Classifier'];
    load([pathToClassifiers '/classifierKNN']); % classifier
    if(strcmp(treatMethod, 'norm'))
        load([pathToClassifiers '/normParams']); % normParams
    elseif(strcmp(treatMethod, 'stand'))
        load([pathToClassifiers '/standParams']); % standParams
    end
    
    %% Samples classification        
    if(strcmp(treatMethod, 'norm'))
        [this_features, ~, ~] = normalize(features, normParams.minVals, normParams.maxVals);
    elseif(strcmp(treatMethod, 'stand'))
        [this_features, ~, ~] = standarize(features, standParams.meanD, standParams.stdDev);
    end

    [labels likelihood] = predict(classifier, this_features);
    
end

