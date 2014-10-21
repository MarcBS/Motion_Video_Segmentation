%%
%
% Performs a set of tests for feature selection and GC over each test set.
%
%%%%

clear all,clc

test_sets = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
p_values = [1e-30 0.001 0.1 0.9999];

global p_value;
global folder_data;
global video_name;
global fig;

for i = 10:length(test_sets)
    
    % Sets test and train data.
    folder_data = {test_sets{[1:i-1 i+1:length(test_sets)]}};
    video_name =  regexp(test_sets{i}, '_', 'split');
    video_name = video_name(1);
    video_name = video_name{1};
    
    % Builds dir to store the results
    folder = ['Test ' num2str(i)];
    mkdir(folder);
    
    % For each p-value
    for p = p_values
    
        p_value = p;

        % P-value feature selection 
        disp('################');disp(['Starting features selection with p-value = ' num2str(p) '.']);disp('################');
        cd ../FeaturesTests
        run Pvalues_test
        % Build SVM
        disp('################');disp(['Start Building SVM.']);disp('################');
        cd ..
        run buildSVM
        % Perform segmentation
        disp('################');disp(['Start Segmentation tests.']);disp('################');
        run subshotsClassificationSenseCam
        
        % Save result figure
        cd 'Segmentation Tests'
        saveas(fig, [folder '/Test data. FS  p-value=' num2str(p_value) '.jpg']);
        delete(fig);
        
    end
    
end