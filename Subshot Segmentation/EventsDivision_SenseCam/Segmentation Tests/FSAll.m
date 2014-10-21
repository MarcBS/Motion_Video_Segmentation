
%%
%
%   FS tests
%
%%%

clear all,clc

global p_value;
global folder_data;
global video_name;

test_sets = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};

p_value = 0.001; % general p_value used for FS

featuresNum = [9 81 8 9 9];
featuresType = {'C', 'H', 'S', 'B', 'D'}; % (Colour, HOG, SIFT Flow, Blurriness, ColorDif)
featureTypeLong = {'Colour', 'HOG', 'SIFT Flow', 'Blurriness', 'Color Difference'};

% Preparation of the features row for printing the result
rowFeatures = {};
count = 1;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        rowFeatures{count} = sprintf([featuresType{i} '%2d'], j);
        count = count+1;
    end
end

counts = zeros(1, sum(featuresNum));
for i = 1:length(test_sets)
    
    % Sets test and train data.
    folder_data = {test_sets{[1:i-1 i+1:length(test_sets)]}};
    video_name =  regexp(test_sets{i}, '_', 'split');
    video_name = video_name(1);
    video_name = video_name{1};
    
    % P-value feature selection 
    disp('################');disp(['Starting features selection with p-value = ' num2str(p_value) '.']);disp('################');
    cd ../FeaturesTests
    run Pvalues_test
    
    load('featureSelection.mat'); % fs
    
    counts = counts + fs;
    
    cd '../Segmentation Tests'

end

hist(counts);
ylabel('Times Selected');
set(gca, 'XTick', 1:sum(featuresNum), 'XTickLabel', rowFeatures, 'rot', 90);
