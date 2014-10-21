function LH = applySVM(pathToFeatures)
%% Applies the previously built SVM to the given samples.
%
%   INPUT
%       pathToFeatures -> path to the folder where are the features to
%           analyse (the file must be called featuresNoColour.mat).
%   OUTPUT
%       LH -> matrix (nxm) with likelihoods for each of the classes, where
%           n = number of samples and m = number of classes.
%
%%%%

    %% Parameters and initializations
    classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
%     pathToFeatures = 'D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_Grauman\P01_1to4001';
    
    treatMethod = 'norm'; % {'norm' = normalize || 'stand' = standardize}

    load([pathToFeatures '/featuresNoColour.mat']); % featuresNoColour
    % DELETE THIS LINE AND UNCOMMENT PREVIOUS
%     load([pathToFeatures '/featuresNoColourLQOpticalFlow.mat']); % featuresNoColour

    features = featuresNoColour;
    pathToClassifiers = 'SVM Classifier';
    load([pathToClassifiers '/classifiersTSM']); % classifiers
    if(strcmp(treatMethod, 'norm'))
        load([pathToClassifiers '/normParams']); % normParams
    elseif(strcmp(treatMethod, 'stand'))
        load([pathToClassifiers '/standParams']); % standParams
    end
    nSamples = size(features,1);
    nClasses = length(classes);
    
    %% Samples classification
    results = zeros(nSamples, nClasses*nClasses);
    for k = 1:nClasses % for each classifier
        
        if(strcmp(treatMethod, 'norm'))
            [this_features, ~, ~] = normalize(features, normParams(k).minVals, normParams(k).maxVals);
        elseif(strcmp(treatMethod, 'stand'))
            [this_features, ~, ~] = standarize(features, standParams(k).meanD, standParams(k).stdDev);
        end
        
        res = svmclassify(classifiers{k}, this_features);
        for l = 1:nSamples
            if( res(l) == 1)
                results(l, nClasses*(k-1) + k) = k;
            else
                results(l, nClasses*(k-1) + cat(2,1:k-1,k+1:nClasses)) = cat(2,1:k-1,k+1:nClasses);
            end
        end
    end
    
    %% Likelihoods calculation for each class
    LH = zeros(nSamples, nClasses);
    for i = 1:nSamples
        this_sample = results(i,results(i,:)>0);
        for j = 1:nClasses
            LH(i,j) = sum(this_sample==j) / length(this_sample);
        end
    end
    
end

