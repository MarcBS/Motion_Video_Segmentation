
%%
%
%   Calculates the Accuracy per class, Total Accuracy, Recall, Precision
%   and F-measure on both, SVM and GC with FS.
%
%%%%
% clear all,clc

global p_value;
global folder_data;
global video_name; 
global weight_GC;
global labelsSVM;
global labels;
global fig;
global classifierUsed; % SVM or KNN
global k;
global distanceMeasure;
global weightsClassifiers;

test_sets = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};

weightsClassifiers = [  0.48 0.2 0.4;... % SVM
                        0.2 0.48 0.2;... % KNNe
                        0.32 0.32 0.4];  % KNNc

classifierUsed = 'KNN'; 
k = 21;
distanceMeasure = 'cosine'; % euclidean or cosine

p_value = '0.001'; % general p_value used for FS

% BEST FOR KNN
% w_GC = [2.4 2.7 3.45 2.25 1.95 3 2.55 2.1 2.7 1.8]; % (euclidean)
% w_GC = [2.4 2.7 2.25 2.7 2.25 3.75 3.45 2.4 3 2.4]; % (cosine)
% w_GC = [4.25 4.05 3 3.15 1.95 4.35 4.4 3.6 3.6 2.7]; % (cosine) new FS (all features)
w_GC = [2.25 2.25 2.4 2.4 1.95 3.15 2.85 2.1 2.85 2.25]; % (cosine) NO FS
% BEST FOR COMBINED
% w_GC = [1.95 2.55 1.65 3 1.95 3.45 3.3 2.25 3.15 1.95]; % (COMBINED)
% BEST FOR SVM
% w_GC = [2.7 3.3 3.3 3.45 2.1 3.75 3.45 2.55 3.3 2.25]; % GC weighting term for each test dataset 
% w_GC = [3.15 2.4 2.25 2.7 2.25 3.75 3.9 2.85 2.85 2.7]; % New FS

classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
nClasses = length(classes);

resultsSVM = zeros(length(test_sets)+1, 4); % last row for means
resultsGC = zeros(length(test_sets)+1, 4); % last row for means
labelsAcc = zeros(length(test_sets)+1, 4);
for i_test = 1:length(test_sets)
    % DELETE THIS LINE
    i_test = 10;
    % Sets test and train data.
    folder_data = {test_sets{[1:i_test-1 i_test+1:length(test_sets)]}};
    video_name =  regexp(test_sets{i_test}, '_', 'split');
    video_name = video_name(1);
    video_name = video_name{1};
    weight_GC = w_GC(i_test);
    
    
    % P-value feature selection 
%     disp('################');disp(['Starting features selection with p-value = ' num2str(p_value) '.']);disp('################');
%     cd ../FeaturesTests
%     run Pvalues_test

    % Build Classifier
    disp('################');disp(['Start Building Classifier.']);disp('################');
    cd ..
    if(strcmp(classifierUsed, 'SVM'))
        run buildSVM
    elseif(strcmp(classifierUsed, 'KNN'))
        run buildKNN
    elseif(strcmp(classifierUsed, 'Combined'))
        run buildSVM
        k = 11;
        distanceMeasure = 'euclidean';
        run buildKNN
        k = 21;
        distanceMeasure = 'cosine';
        run buildKNN
    end
    
    % Perform segmentation
    disp('################');disp(['Start Segmentation tests.']);disp('################');
    run subshotsClassificationSenseCam
    
    cd 'Segmentation Tests'
    
    % SVM Measures
    tmp_labels_SVM = {};
    for j = 1:nClasses
        tmp_labels_SVM{j} = labelsSVM(GT==j);
        labelsAcc(i_test, j) = sum(GT==j);
        labelsAcc(i_test, end) = labelsAcc(i_test, end)+sum(GT==j);
    end
    [ acc_Class, acc_Total ] = resultMeasuresFinalTest(tmp_labels_SVM);
    resultsSVM(i_test, :) = [acc_Class acc_Total];
    
    % GC Measures
    tmp_labels_GC = {};
    for j = 1:nClasses
        tmp_labels_GC{j} = labels(GT==j);
    end
    [ acc_Class, acc_Total ] = resultMeasuresFinalTest(tmp_labels_GC);
    resultsGC(i_test, :) = [acc_Class acc_Total];
    
    % Save result figure
    saveas(fig, ['Test dataset ' num2str(i_test) '. Accuracy comparison.jpg']);
    delete(fig);
    
end

for j = 1:nClasses+1
    labelsAcc(length(test_sets)+1,j) = sum(labelsAcc(:,j));
end
% Calculate Means SVM
for j = 1:nClasses
    count = 0;
    for i = 1:length(test_sets)
        count = count + resultsSVM(i,j)*labelsAcc(i, j);
    end
    resultsSVM(length(test_sets)+1,j) = count/labelsAcc(length(test_sets)+1,j);
end
count = 0;
for j = 1:nClasses
    count = count + resultsSVM(length(test_sets)+1,j)*labelsAcc(length(test_sets)+1,j);
end
resultsSVM(length(test_sets)+1,nClasses+1) = count/sum(labelsAcc(length(test_sets)+1,nClasses+1));

% Calculate Means GC
for j = 1:nClasses
    count = 0;
    for i = 1:length(test_sets)
        count = count + resultsGC(i,j)*labelsAcc(i, j);
    end
    resultsGC(length(test_sets)+1,j) = count/labelsAcc(length(test_sets)+1,j);
end
count = 0;
for j = 1:nClasses
    count = count + resultsGC(length(test_sets)+1,j)*labelsAcc(length(test_sets)+1,j);
end
resultsGC(length(test_sets)+1,nClasses+1) = count/sum(labelsAcc(length(test_sets)+1,nClasses+1));

%% Save results
% save(['Accuracy Tests ' classifierUsed '/Final_Tests_SVM.mat'], 'resultsSVM');
% save(['Accuracy Tests ' classifierUsed '/Final_Tests_GC.mat'], 'resultsGC');
disp('Results Saved!');

