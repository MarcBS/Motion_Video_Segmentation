function LH = applySVM(pathToFeatures, featureSelection)
%% Applies the previously built SVM to the given samples.
%
%   INPUT
%       pathToFeatures -> path to the folder where are the features to
%           analyse (the file must be called featuresNoColour.mat).
%       featureSelection -> indicates if we want to perform a feature
%           selection.
%   OUTPUT
%       LH -> matrix (nxm) with likelihoods for each of the classes, where
%           n = number of samples and m = number of classes.
%
%%%%

    %% Parameters and initializations
    classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
%     pathToFeatures = 'D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_Grauman\P01_1to4001';
    
    treatMethod = 'stand'; % {'norm' = normalize || 'stand' = standardize}

%     load([pathToFeatures '/featuresNoColour.mat']); % featuresNoColour
%     features = featuresNoColour;
    load([pathToFeatures '/features.mat']);
    
    if(featureSelection)
        features = applyFeatureSelection(features, 'SVM');
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
    margins = zeros(nSamples, nClasses*nClasses);
    for k = 1:nClasses % for each classifier
        
        if(strcmp(treatMethod, 'norm'))
            [this_features, ~, ~] = normalize(features, normParams(k).minVals, normParams(k).maxVals);
        elseif(strcmp(treatMethod, 'stand'))
            [this_features, ~, ~] = standarize(features, standParams(k).meanD, standParams(k).stdDev);
        end
        
        [res margin] = svmclassify2(classifiers{k}, this_features);
        margin = abs(margin);
        for l = 1:nSamples
            if( res(l) == 1)
                results(l, nClasses*(k-1) + k) = k;
                margins(l, nClasses*(k-1) + k) = margin(l);
            else
                results(l, nClasses*(k-1) + cat(2,1:k-1,k+1:nClasses)) = cat(2,1:k-1,k+1:nClasses);
                margins(l, nClasses*(k-1) + cat(2,1:k-1,k+1:nClasses)) = margin(l);
            end
        end
    end
    
    %% Likelihoods calculation for each class
    LH = zeros(nSamples, nClasses);
    for i = 1:nSamples
        this_sample = results(i,results(i,:)>0);
        this_margins = margins(i,results(i,:)>0);
        for j = 1:nClasses
%             LH(i,j) = sum(this_sample==j) / length(this_sample);
            LH(i,j) = sum(this_margins(this_sample==j));
        end
        LH_aux = zeros(1, nClasses);
        for j = 1:nClasses
            LH_aux(j) = LH(i,j)/sum(LH(i,:));
        end
        LH(i,:) = LH_aux;
    end
    
end

