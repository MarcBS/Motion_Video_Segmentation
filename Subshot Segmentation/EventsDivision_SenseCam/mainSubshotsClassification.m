
%%
%   Performs the complete classification of new SenseCam samples following
%   the steps below:
%
%       1) The features of each of the images are extracted:
%           extractFeatures(). The features are stored.
%       2) The selected images are classified using the trained SVM.
%       3) The likelihoods obtained are smoothed using a MRF.
%       4) The final labels obtained are stored.
%       5) If showResult = true: a summary image with the final events is 
%           created and stored.
%%%%

%% Load parameters
% loadParameters;

tic
%% Image retrieval
fileList_aux = dir([source '/' video_name '/*' format]);
count = 1;
for k = 1:length(fileList_aux)
    if(fileList_aux(k).name(1) ~= '.')
        fileList(count).name = fileList_aux(k).name;
        count = count+1;
    end
end


ini = 1;
fin = length(fileList);
nFrames = fin-ini;

%% Features extraction
folder_name = ['Datasets/' video_name '_' num2str(ini) 'to' num2str(fin)];
if(extract_features)
    features = extractFeatures([source '/' video_name], fileList, ini, fin, nBinsPerColor, lenHOG, nBinsSIFTFlow, nCellsBlurriness);
    featuresNoColour = features(:, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+1):end);

    % Storing features
    mkdir(folder_name);
    save([folder_name '/features.mat'], 'features');
    save([folder_name '/featuresNoColour.mat'], 'featuresNoColour');
end

toc

% Load ground truth for testing
if(doEvaluation)
    if(strcmp(evaluation_type, 'acc_motion'))
        load([folder_name '/labels_result']);
        GT = [labels_result.label]';
    elseif(strcmp(evaluation_type, 'fm_segments'))
        GT_file = [source '/../GT/GT_' video_name '.xls'];
        
        [~,~,cl_limGT, ~]=analizarExcel_Narrative(GT_file, fileList);
        GT=cl_limGT';
        if GT(1) == 1, GT=GT(2:end); end
    end
end

%% Applying SVM to the new samples
if(strcmp(classifierUsed, 'SVM'))
    disp('Applying SVM classification...');
    LH_SVM = applySVM(folder_name, featureSelection);
    labelsSVM = getClassFromLH(LH_SVM);
elseif(strcmp(classifierUsed, 'KNN'))
    disp('Applying KNN classification...');
    [labelsSVM, LH_SVM] = applyKNN(folder_name, featureSelection);
elseif(strcmp(classifierUsed, 'Combined'))
    disp('Applying SVM classification...');
    LH_SVM = applySVM(folder_name, featureSelection);
    
    LH_results = zeros(size(weightsClassifiers,1), size(weightsClassifiers,2), size(LH_SVM,1));
    LH_results(1,:,:) = LH_SVM';
    
    disp('Applying KNNe classification...');
    [~, LH_KNNe] = applyKNN(folder_name, featureSelection);
    LH_results(2,:,:) = LH_KNNe';
    disp('Applying KNNc classification...');
    [~, LH_KNNc] = applyKNN(folder_name, featureSelection);
    LH_results(3,:,:) = LH_KNNc';
    
    weightedResults = zeros(size(LH_SVM,1), size(weightsClassifiers, 2));
    for i = 1:size(LH_SVM,1)
        weightedResults(i, :) = sum(LH_results(:,:,i).*weightsClassifiers);
        % Final classification result
        LH_SVM(i,:) = weightedResults(i,:)./sum(weightedResults(i,:));
    end
    labelsSVM = getClassFromLH(LH_SVM);
end

%% Get features for GraphCuts
%%%% Color hists for each image.
feat = load([folder_name '/features.mat']); % features
[colourAndHOG, ~, ~] = normalize(feat.features(:,1:(9+81)));

%% Get distances between samples
dists = pdist(colourAndHOG);
dists = squareform(dists);

%% Build and calculate the GraphCut
tic
disp('Applying GC smoothing...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SINGLE TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(strcmp(GC_test_type, 'single'))
    LH_GC = buildGraphCuts(LH_SVM, colourAndHOG, W, weight_GC, dists);
    % Save classification labels
    labels = getClassFromLH(LH_GC);
    save([folder_name '/labels.mat'], 'labels');
    % Final separation in events
    [ event, labels_event, num_clusters ] = getEventsFromLH(LH_GC);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% ITERATIVE TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif(strcmp(GC_test_type, 'iterative'))
    w_values = linspace(0, 1, nTests);
    w_values(1) = 1e-99;
    vec_numC = zeros(1,nTests);
    vec_perC = zeros(1,nTests);
    for num_i = [1:nTests]
        LH_GC = buildGraphCuts(LH_SVM, colourAndHOG, W, w_values(num_i), dists);
        % Final separation in events
        [ event, labels_event, num_clusters ] = getEventsFromLH(LH_GC);
        % Evaluation
        vec_numC(num_i) = num_clusters;
        if(strcmp(evaluation_type, 'acc_motion'))
            vec_perC(num_i) = sum(GT==labels)/length(GT);
        elseif(strcmp(evaluation_type, 'fm_segments'))
            [~, ~, ~, fMeasureGC]=Rec_Pre_Acc_Evaluation(GT,labels_event,length(fileList),tolerance);
            vec_perC(num_i) = fMeasureGC;
        end
    end
    if(strcmp(evaluation_type, 'acc_motion'))
        evalSupervised = sum(GT==labelsSVM)/length(GT);
        measure = 'Accuracy';
    elseif(strcmp(evaluation_type, 'fm_segments'))
        [ ~, labels_event_SVM, ~ ] = getEventsFromLH(LH_SVM);
        [~, ~, ~, evalSupervised]=Rec_Pre_Acc_Evaluation(GT,labels_event_SVM,length(fileList),tolerance);
        measure = 'F-Measure';
    end
    
    if(doPlot)
        global fig;
        fig = figure;
        scatter(w_values,(vec_numC-min(vec_numC))./(max(vec_numC) - min(vec_numC)), 25, [0 0 0.8], 'filled'); % num events points
        text(w_values, (vec_numC-min(vec_numC))./(max(vec_numC) - min(vec_numC))+0.03, cellstr(num2str(vec_numC'))); % num events labels
        line(w_values, vec_perC, 'Color', 'g', 'LineWidth', 1.5) % GC accuracy
        line(w_values, ones(1,nTests)*evalSupervised, 'Color', 'r', 'LineWidth', 2) % SVM accuracy
    %     set(gca,'XTick', [1:nTests]-1 ); % x axis labels positions
    %     xticklabel_rotate([1:nTests]-1,90,w_values, 'FontSize', 16,'interpreter','none');
        % title(['Test data. FS p-value=' num2str(p_value) '.'], 'FontSize', 18);
        title(['Test data comparison.'], 'FontSize', 18);
        legend('Number Events', 'GC Accuracy', [classifierUsed ' ' measure], 1);
        ylabel(measure, 'FontSize', 16);
        xlabel('GC tuning value.', 'FontSize', 16);
        set(gca,'FontSize',16);
    end
end
toc


disp(' ');
if(doEvaluation)
    if(strcmp(evaluation_type, 'acc_motion'))
        disp(['Accuracy after SVM: ' num2str(sum(GT==labelsSVM)/length(GT))]);
        disp(['Accuracy after GC: ' num2str(sum(GT==labels)/length(GT))]);
    elseif(strcmp(evaluation_type, 'fm_segments'))
        [~, ~, ~, fMeasureGC]=Rec_Pre_Acc_Evaluation(GT,labels_event,length(fileList),tolerance);
        disp(['F-Measure after GC: ' num2str(fMeasureGC)]);
    end
end
disp(['Number of events: ' num2str(num_clusters)]);
disp(['Mean frames per event: ' num2str(length(labels)/num_clusters)]);
disp(' ');

%% Show result measures
if(doEvaluation && strcmp(evaluation_type, 'acc_motion'))
    tmp_labels = {};
    for i = 1:nClasses
        tmp_labels{i} = labels(GT==i);
    end
    resultMeasures(tmp_labels);
    disp(' ');
end
disp(['Labels ordered by indices: ' labels_text']);

%% Create summary image
if(showResult)
    disp('Creating summary image...');

    result_data = {};
    for i = 1:num_clusters
        result_data{i} = [];
    end
    for i = 1:nFrames
        if(event(i) ~= 0)
            result_data{event(i)} = [result_data{event(i)} i];
        end
    end
    
    % Deletes events with less than min_imgs_event images
    res_dat = {};
    lab_event = [];
    count = 1;
    for i = 1:length(result_data)
        if(length(result_data{i}) >= min_imgs_event)
            res_dat{count} = result_data{i};
            lab_event = [lab_event; labels_event(i)];
            count = count+1;
        end
    end
    num_clus = length(res_dat);

    gen_image = summaryImage(props, num_clus, n_summaryImages, res_dat, fileList, [source '/' video_name], 'images', ini, lab_event);
    imwrite(gen_image, [folder_name '/Summary Events.jpg']);
end

%% Create summary image of complete final event segmentation (using small colored squares)
if(showResult2)
   
    disp('Creating summary image 2...');

    result_data = {};
    for i = 1:num_clusters
        result_data{i} = [];
    end
    for i = 1:nFrames
        if(event(i) ~= 0)
            result_data{event(i)} = [result_data{event(i)} i];
        end
    end
    
    res_dat = {};
    lab_event = [];
    count = 1;
    for i = 1:length(result_data)
        res_dat{count} = result_data{i};
        lab_event = [lab_event; labels_event(i)];
        count = count+1;
    end
    num_clus = length(res_dat);
    
    gen_image = summaryImage2([4 4], num_clus, n_summaryImages, res_dat, fileList, [source '/' video_name], 'images', ini, lab_event);
    imwrite(gen_image, [folder_name '/Summary Events2.jpg']);
    
end


%% Create summary image splitting the events of each class (also for the GT)
if(showResult3)
    disp('Creating summary image 3...');

    %% TEST
    
    result_data = {};
    for i = 1:num_clusters
        result_data{i} = [];
    end
    for i = 1:nFrames
        if(event(i) ~= 0)
            result_data{event(i)} = [result_data{event(i)} i];
        end
    end
    
    % Deletes events with less than min_imgs_event images
    res_dat = {};
    lab_event = [];
    count = 1;
    for i = 1:length(result_data)
        if(length(result_data{i}) >= min_imgs_event)
            res_dat{count} = result_data{i};
            lab_event = [lab_event; labels_event(i)];
            count = count+1;
        end
    end
    num_clus = length(res_dat);

    labs = unique(lab_event);
    gen_image = summaryImage3(props, num_clus, n_summaryImages, res_dat, fileList, [source '/' video_name], 'images', ini, lab_event);
    for i = 1:length(labs)
        imwrite(gen_image{i}, [folder_name '/Summary Events 3 Test_' labs(i) '.jpg']);
    end
    
    %% GT
    
    if(doEvaluation)
        % Final separation in events for the GT
        nFrames = fin-ini;
        eventGT = zeros(1, nFrames); eventGT(1) = 1;
        prev = 1;
        labels_event = [labels_text(GT(1))];
        for i = 1:nFrames
            if(GT(i) == 0)
                eventGT(i) = 0;
            else
                if(GT(i) == GT(prev))
                    eventGT(i) = eventGT(prev);
                else
                    eventGT(i) = eventGT(prev)+1;
                    labels_event = [labels_event; labels_text(GT(i))];
                end
                prev = i;
            end
        end
        num_clus = max(eventGT);


        result_data = {};
        for i = 1:num_clus
            result_data{i} = [];
        end
        for i = 1:nFrames
            if(eventGT(i) ~= 0)
                result_data{eventGT(i)} = [result_data{eventGT(i)} i];
            end
        end

        % Deletes events with less than min_imgs_event images
        res_dat = {};
        lab_event = [];
        count = 1;
        for i = 1:length(result_data)
            if(length(result_data{i}) >= min_imgs_event)
                res_dat{count} = result_data{i};
                lab_event = [lab_event; labels_event(i)];
                count = count+1;
            end
        end
        num_clus = length(res_dat);

        labs = unique(lab_event);
        gen_image = summaryImage3(props, num_clus, n_summaryImages, res_dat, fileList, [source '/' video_name], 'images', ini, lab_event);
        for i = 1:length(labs)
            imwrite(gen_image{i}, [folder_name '/Summary Events 3 GT_' labs(i) '.jpg']);
        end
    end
        
end


%% Create summary image simply with all the images of the dataset in cronological order
if(showResult4)
   
    disp('Creating summary image 4...');
    
    gen_image = summaryImage4([20 27], fileList, [source '/' video_name] );
    imwrite(gen_image, [folder_name '/Summary Events4.jpg']);
    
end


disp(['Classification of ' folder_name ' finished.']);


 