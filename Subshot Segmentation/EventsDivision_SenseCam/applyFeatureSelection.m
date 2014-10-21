function [ features ] = applyFeatureSelection( features, method )

    colLength = 3;
    HOGLength = [3 3 9];

    fs = 0;
    % load('D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_SenseCam\FeaturesTests\featureSelection.mat');
    load('/Volumes/SHARED HD/Video Summarization Project/Code/Subshot Segmentation/EventsDivision_SenseCam/FeaturesTests/featureSelection.mat');
    % fs with 0s and 1s
    
    if(strcmp(method, 'SVM'))
        features = features(:, fs);
%         features = features(:, fs((colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)+1):end)==1 );
    elseif(strcmp(method, 'KNNe'))
        features = features(:, fs((colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)+1):end)==1 );
    elseif(strcmp(method, 'KNNc'))
%         features = features(:, fs);
        features = features(:, fs((colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)+1):end)==1 );
    elseif(strcmp(method, 'MRF'))
        features = features(:, fs(1:(colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)))==1 );
    end

end

