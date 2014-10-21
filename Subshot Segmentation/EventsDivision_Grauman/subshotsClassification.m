
%%
%   Performs the complete classification of new video samples following the
%   steps below:
%
%       1) The features of each of the images are extracted:
%           extractFeatures(). The features are stored.
%       2) The selected images are classified using the trained SVM.
%       3) The likelihoods obtained are smoothed using a MRF.
%       4) The final labels obtained are stored.
%       5) If showResult = true: a summary image with the final events is 
%           created and stored.
%%%%
%% Parameters
source = 'D:\Video Summarization Project\Data Sets\Grauman Data\UTE_video\';
video_name = 'P01';
format = '.mp4';
nBinsPerColor = 3; % max = 256
nBinsMotion = 8;
nCellsBlurriness = [3 3];
% bandwidth = 0.15;
W = 11;

%% Parameters show path
showResult = true;
props = [100 133]; % proportions of the final summary image
n_summaryImages = 10; % number of images per cluster shown as summary

addpath('..');

%% Labels
labels_text = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head

tic
%% Image retrieval
video = VideoReader([source video_name format]);
N = video.NumberOfFrames;

ini = 1;
fin = 4001;
% ini = 4001;
% fin = 6001;

%% Features extraction
% features = extractFeatures(video, ini, fin, nBinsPerColor, nBinsMotion, nCellsBlurriness);
% 
% featuresNoColour = features(:, (nBinsPerColor*3+1):end);
% 
% %% Storing features
folder_name = [video_name '_' num2str(ini) 'to' num2str(fin)];
% mkdir(folder_name);
% save([folder_name '/features.mat'], 'features');
% save([folder_name '/featuresNoColour.mat'], 'featuresNoColour');

toc

% Load ground truth for testing
load([folder_name '/labels_result_' folder_name '.mat']);
GT = [labels_result.label]';

%% Applying SVM to the new samples
disp('Applying SVM classification...');
LH_SVM = applySVM(folder_name);
labelsSVM = getClassFromLH(LH_SVM);
% [~, labelsSVM] = max(LH_SVM,[],2);

%% Build and calculate the MRF
% maxTest = 20;
% vec_numC = zeros(1,maxTest);
% vec_perC = zeros(1,maxTest);
% for num_i = [1:maxTest]
    tic
    disp('Applying MRF smoothing...');
    LH_MRF = buildMRF(folder_name, LH_SVM, W, 0.18, '', 'GraphCuts');      % for optimal accuracy: 2
    toc                                                                 % for optimal num events: 0.18
                                                                        % (the higher the more events)

    % Save classification labels
    labels = getClassFromLH(LH_MRF);
%     [~, labels] = max(LH_MRF,[],2);
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
    
%     vec_numC(num_i) = num_clusters;
%     vec_perC(num_i) = sum(GT==labels)/length(GT);
% end

% plot(vec_numC);
% line(1:maxTest, vec_perC*mean(vec_numC))
disp(' ');
disp(['Accuracy after SVM: ' num2str(sum(GT==labelsSVM)/length(GT))]);
disp(['Accuracy after MRF: ' num2str(sum(GT==labels)/length(GT))]);
disp(['Number of events: ' num2str(num_clusters)]);
disp(['Average frames per event: ' num2str(length(labels)/num_clusters)]);
disp(' ');

%% Create summary image
if(showResult)
    disp('Creating summary image...');
    fileList = dir([source '\*' format]);

    result_data = {};
    for i = 1:num_clusters
        result_data{i} = [];
    end
    for i = 1:nFrames
        if(event(i) ~= 0)
            result_data{event(i)} = [result_data{event(i)} i];
        end
    end

    gen_image = summaryImage(props, num_clusters, n_summaryImages, result_data, video, '', 'video', ini, labels_event);
    imwrite(gen_image, [folder_name '/Summary Events.jpg']);
end


disp(['Classification of ' folder_name ' finished.']);


 