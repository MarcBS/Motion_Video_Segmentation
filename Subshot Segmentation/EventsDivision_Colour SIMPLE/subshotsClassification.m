
global nBinsPerColor;
global thres_penal;
global W;
global C_min;
global min_dif_row;
global thres_join;
global thres_split;

%% Parameters
source = 'D:\Documentos\Vicon Revue Data\0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0';
format = '.jpg';
nBinsGIST = 10; %optimum 10
nBinsPerColor = 5; % max = 256 % optimum = 5
importancePosition = 5; % optimum = 5
bandwidth = 0.15; % optimum = 20
W = 10; % optimum 10/11
thres_penal = 0.5; % Penalization between consecutive images with dif. labels % optimum 0.7 > x < 0.9
% similar color but different label. Similarity -> pdist2(i1, i2) < thres_penal
max_group = 5000;
C_min = 16; % Minimum number of images allowed in a cluster
min_dif_row = 4; % Minimum number of images in a row with high distance to their neighbours

W2 = 6; % Length of sliding window used to split the events by their mean 
thres_split = 0.3;

thres_join = 0.65;

num_smooths = 1; % Number of consecutive smooths applied to the set
 
%% Parameters show path
showResult = true;
dirname = 'Result Clustering';
n_summaryImages = 10; % number of images per cluster shown as summary
props = [100 133];

addpath('..');
addpath('../../LabelMeToolbox');
addpath('../../MeanShift');

% GIST Parameters:
% param.imageSize = 128;
nb = 4; % 4
ops = 8;
param.imageSize = 128; % 128
param.orientationsPerScale = [ops ops ops ops];
param.numberBlocks = nb;
param.fc_prefilt = 4;

tic
%% Image retrieval
fileList = dir([source '\*' format]);
N_total = length(fileList);

iters = ceil(N_total/max_group);

%% DELETE LINES
% N = 1000;
% fileList = fileList(1000:2000);

%% Get features
% Gets Color Histogram and GIST features
% features = zeros(N, nBinsPerColor*3 + (nb*nb*32) + importancePosition);
for g = 1:iters
    
    n = (g-1)*max_group + 1;
    N = g*max_group;
    if(N_total < N)
        N = N_total;
    end
    
%     %%%%%%%%%%%%%%
%     
% %     features = zeros(N, nBinsPerColor*3 + nBinsGIST + importancePosition);
%     features = zeros(N, nBinsPerColor*3 + importancePosition);
% 
%     hists = zeros(N, nBinsPerColor*3);
%     for i = n:N
%         im = imread([source '/' fileList(i).name]);
% %         [gist, param] = LMgist(im, '', param); % GIST features
% %         gist = hist(gist, nBinsGIST);
%         hists(i,:) = [imhist(im(:,:,1), nBinsPerColor)' imhist(im(:,:,2), nBinsPerColor)' imhist(im(:,:,3), nBinsPerColor)']; % RGB Histogram features
% %         features(i,nBinsPerColor*3+1:end) = [gist ones(1, importancePosition)*i/N];
%         features(i,nBinsPerColor*3+1:end) = [ones(1, importancePosition)*i/N];
%         if(mod(i,100)==0 && i ~= N)
%             disp(['Features extraction progress: ' num2str(i) '/' num2str(N)]);
%         end
%     end
%     disp(['Features extraction complete! ' num2str(i) '/' num2str(N)]);
% 
%     % features(1:N, 1:nBinsPerColor*3) = hists/norm(hists);
%     features(1:N, 1:nBinsPerColor*3) = normalize(hists, 1, 0, max(max(hists)), min(min(hists)));
% 
%     %%%%%%%%%%%%%%
    
%     save('features.mat', 'features');
    load('features.mat');
%     features = features(1000:2000,:);

    [clustCent,data2cluster,cluster2dataCell] = MeanShiftCluster(features', bandwidth);

    for i = n:N
        data2cluster(i) = i;
    end

    for r = 1:num_smooths
        %% Penalization between consecutive similar images with different labels
        data2cluster = penalizeConsecutiveImages(data2cluster, n, N, features);

        %% Smoothing clusters using sliding window W
        data2cluster = smoothSlidingW(data2cluster, n, N);
        
        %% Splits the events using two windows on length W2 and the mean of the features
        data2cluster = splitEventsMean(data2cluster, n, N, features, W2);
        
        %% Joins different events whose means are very similar
        data2cluster = joinEventsMean(data2cluster, n, N, features);
        
        %% Delete events with less than C_min images
        % Sets to 0 the data2cluster id of all the deleted images
        data2cluster = deleteShortEvents(data2cluster, n, N);
        
    end

    
    %% Final separation in events
    event = zeros(1,N); event(1) = 1;
    prev = 1;
    for i = (n+1):N
        if(data2cluster(i) == 0)
            event(i) = 0;
        else
            if(data2cluster(i) == data2cluster(prev))
                event(i) = event(prev);
            else
                event(i) = event(prev)+1;
            end
            prev = i;
        end
    end
    data2cluster = event;
    num_clusters = max(data2cluster);
    

    %% Showing results clustering
    if(showResult)
        if(isdir([dirname num2str(g)]))
            rmdir([dirname num2str(g)], 's');
        end
        mkdir([dirname num2str(g)]);
        u = unique(data2cluster);
        for c = u
            mkdir([[dirname num2str(g)] '/cluster_' num2str(c)]);
        end
        result_data = {};
        for i = 1:num_clusters
            result_data{i} = [];
        end
        for i = n:N
            if(data2cluster(i) ~= 0)
                result_data{data2cluster(i)} = [result_data{data2cluster(i)} i];
            end
            copyfile([source '/' fileList(i).name], [dirname num2str(g) '/cluster_' num2str(data2cluster(i))]);
        end
    end
    
    
    %% Create summary image
    if(showResult)
        gen_image = summaryImage(props, num_clusters, n_summaryImages, result_data, fileList, source, 'images', 0, []);
        imwrite(gen_image, [dirname num2str(g) '/Summary Events.jpg']);
    end
    
    
end

disp('Done');
toc