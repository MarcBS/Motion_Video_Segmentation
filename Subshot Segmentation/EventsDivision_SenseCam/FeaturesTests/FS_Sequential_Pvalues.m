
%% 
%   This script is only used for feature statistical relevance checking.
%%%%

addpath('..');

%% Data params
path_data = '../../EventsDivision_SenseCam/Datasets';
% global folder_data;
folder_data = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
classesShort = {'T', 'S', 'M'};
classes = {'In Transit'; 'Static'; 'Moving Camera'}; % In Transit, Static, Moving Camera

featuresNum = [9 81 8 9 9];
featuresType = {'C', 'H', 'S', 'B', 'D'}; % (Colour, HOG, SIFT Flow, Blurriness, ColorDif)
featureTypeLong = {'Colour', 'HOG', 'SIFT Flow', 'Blurriness', 'Color Difference'};

% Preparation of the features row for printing the result
rowFeatures = '| ';
count = 2;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        rowFeatures = sprintf([rowFeatures featuresType{i} '%2d | '], j);
        count = count+1;
    end
end


%% Data retrieval
numFolders = length(folder_data);
nClasses = length(classes);
f = [];
labels = [];
for idFold = 1:numFolders
    load([path_data '/' folder_data{idFold} '/labels_result.mat']); % labels_result
    load([path_data '/' folder_data{idFold} '/features.mat']); % features
    f = [f; features];
    labels = [labels labels_result(:).label];
end
features = f;

% Logarithm on color difference
features(:,(9+81+8+9+1):end) = abs(features(:,(9+81+8+9+1):end));
for i = 1:3
    for j = (9+81+8+9+1):(9+81+8+9+9)
        features(:,j) = log(features(:,j));
        features((features(:,j)<0),j) = 0;
    end
    for j = 1:9
        features(:,j) = log(features(:,j));
        features((features(:,j)<0),j) = 0;
    end
end


%% T-Test applied over each possible classes combination

combos = combntns(1:nClasses, 2);
fsel = zeros(size(combos,1), size(features,2));
count = 1;
min_pvalue = ones(1, size(features,2));
for c = combos'
    % Curve for sequential FS
    [h,p_graph,ci,stat] = ttest2(features(find(labels==c(1)), :), features(find(labels==c(2)), :),[],[],'unequal');
    
    min_pvalue = min(min_pvalue, p_graph);
end

[vals, pos] = sort(min_pvalue);

% for c = combos'
%     disp(['T-Test applied on classes [ ' classes{c(1)} ' ] and [ ' classes{c(2)} ' ]']);
%     
%     rel = ttest2(features(find(labels==c(1)), :), features(find(labels==c(2)), :), p_value);
%     fsel(count, :) = rel;
%     
%     % Print .csv line
%     fprintf(fid, [classesShort{c(1)} 'vs' classesShort{c(2)} ',' csvStr '\n'], rel(:));
%     
%     % Print result nicely formatted
%     relStr = '| ';
%     for i = 1:length(rel)
%         relStr = sprintf([relStr '%2d  | '], rel(i));
%     end
%     disp(rowFeatures);
%     disp(relStr);
%     disp(' ');
%     count = count+1;
% end
% % Closes .csv file
% fclose(fid);
% 
% %% Shows legend
% lgnd = 'Legend: ';
% for i = 1:length(featuresType)
%     lgnd = [lgnd featuresType{i} ' = ' featureTypeLong{i} ', '];
% end
% disp(lgnd);
% 
% 
% %% Saves features selection
% fs = sum(fsel)>0;
% save('featureSelection.mat', 'fs');
% disp(['Features selected: ' num2str(sum(fs))]);




