
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
loadParameters;

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
    load([folder_name '/labels_result']);
    GT = [labels_result.label]';
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

%% Build and calculate the MRF

% %%%%%%%%%%% TESTS
% maxTest = 10+1;
% offset = 1e-99;
% increment = 0.1;
% vec_numC = zeros(1,maxTest);
% vec_perC = zeros(1,maxTest);
% for num_i = [1:maxTest]
% %%%%%%%%%%

    tic
    disp('Applying MRF smoothing...');
    % TESTS: num_i*increment+offset
% % % %     LH_MRF = buildMRF(folder_name, LH_SVM, W, (num_i-1)*increment+offset, '', 'GraphCuts', featureSelection); 
%     LH_MRF = buildMRF(folder_name, LH_SVM, W, weight_GC, '', 'GraphCuts', featureSelection); 

%     LH_MRF = buildGraphCuts(LH_SVM, colourAndHOG, W, (num_i-1)*increment+offset, dists);
    LH_MRF = buildGraphCuts(LH_SVM, colourAndHOG, W, weight_GC, dists);
                                % (the higher the less events)
    toc                                                             

    % Save classification labels
    labels = getClassFromLH(LH_MRF);
    save([folder_name '/labels.mat'], 'labels');


    %% Final separation in events
    nFrames = fin-ini;
    event = zeros(1, nFrames); event(1) = 1;
    prev = 1;
    labels_event = [labels_text(labels(1))];
    for i = 1:nFrames
        if(labels(i) == 0)
            event(i) = 0;
        else
            if(labels(i) == labels(prev))
                event(i) = event(prev);
            else
                event(i) = event(prev)+1;
                labels_event = [labels_event; labels_text(labels(i))];
            end
            prev = i;
        end
    end
    num_clusters = max(event);

% %%%%%%%%%%% TESTS
%     vec_numC(num_i) = num_clusters;
%     vec_perC(num_i) = sum(GT==labels)/length(GT);
% end
% global fig;
% fig = figure;
% scatter([1:maxTest]-1,(vec_numC-min(vec_numC))./(max(vec_numC) - min(vec_numC)), 25, [0 0 0.8], 'filled'); % num events points
% text([1:maxTest]-1-0.05, (vec_numC-min(vec_numC))./(max(vec_numC) - min(vec_numC))+0.03, cellstr(num2str(vec_numC'))); % num events labels
% line([1:maxTest]-1, vec_perC, 'Color', 'g', 'LineWidth', 1.5) % GC accuracy
% line([1:maxTest]-1, ones(1,maxTest)*sum(GT==labelsSVM)/length(GT), 'Color', 'r', 'LineWidth', 2) % SVM accuracy
% set(gca,'XTick', [1:maxTest]-1 ); % x axis labels positions
% xticklabel_rotate([1:maxTest]-1,90,num2cell(([1:maxTest]-1).*increment+offset), 'FontSize', 16,'interpreter','none');
% % title(['Test data. FS p-value=' num2str(p_value) '.'], 'FontSize', 18);
% title(['Test data accuracy comparison.'], 'FontSize', 18);
% legend('Number Events', 'GC Accuracy', [classifierUsed ' Accuracy'], 3);
% ylabel('Accuracy', 'FontSize', 16);
% xlabel('GC tuning value.', 'FontSize', 16);
% set(gca,'FontSize',16);
% %%%%%%%%%%%

disp(' ');
if(doEvaluation)
    disp(['Accuracy after SVM: ' num2str(sum(GT==labelsSVM)/length(GT))]);
    disp(['Accuracy after MRF: ' num2str(sum(GT==labels)/length(GT))]);
end
disp(['Number of events: ' num2str(num_clusters)]);
disp(['Mean frames per event: ' num2str(length(labels)/num_clusters)]);
disp(' ');

%% Show result measures
if(doEvaluation)
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


 