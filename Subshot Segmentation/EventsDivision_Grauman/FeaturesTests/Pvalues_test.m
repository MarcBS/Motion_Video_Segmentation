
%% 
%   This script is only used for feature statistical relevance checking.
%%%%

addpath('..');

%% Data params
path_data = '../../EventsDivision_Grauman';
folder_data = 'P01_1to4001';
classesShort = {'T', 'S', 'M'};
classes = {'In Transit'; 'Static'; 'Moving Camera'}; % In Transit, Static, Moving Camera

featuresNum = [9 8 9];
featuresType = {'C', 'O', 'B'}; % (Colour, Optical Flow, Blurriness)
featureTypeLong = {'Colour', 'Optical Flow', 'Blurriness'};

% Preparation of the features row for printing the result
rowFeatures = '| ';
count = 2;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        rowFeatures = sprintf([rowFeatures featuresType{i} '%2d | '], j);
        count = count+1;
    end
end

p_value = 0.01; % The lower the p_value the more reliable the t-test results will be.


%% Data retrieval
nClasses = length(classes);
load([path_data '/' folder_data '/labels_result_' folder_data '.mat']); % labels_result
load([path_data '/' folder_data '/features.mat']); % features
labels = [labels_result.label];


%% T-Test applied over each possible classes combination
% Create .csv file
csvStr = '';
for i = 1:sum(featuresNum)
    csvStr = [csvStr '%d,'];
end
fid = fopen(['Grauman_T-Test_p-value=' num2str(p_value) '.csv'],'wt');
fprintf(fid, [strrep(rowFeatures, '|', ',') '\n']);

combos = combntns(1:nClasses, 2);
disp(['P-value applied: ' num2str(p_value)]); disp(' ');
for c = combos'
    disp(['T-Test applied on classes [ ' classes{c(1)} ' ] and [ ' classes{c(2)} ' ]']);
    rel = ttest2(features(find(labels==c(1)), :), features(find(labels==c(2)), :), p_value);
    
    % Print .csv line
    fprintf(fid, [classesShort{c(1)} 'vs' classesShort{c(2)} ',' csvStr '\n'], rel(:));
    
    % Print result nicely formatted
    relStr = '| ';
    for i = 1:length(rel)
        relStr = sprintf([relStr '%2d  | '], rel(i));
    end
    disp(rowFeatures);
    disp(relStr);
    disp(' ');
end
% Closes .csv file
fclose(fid);

%% Shows legend
lgnd = 'Legend: ';
for i = 1:length(featuresType)
    lgnd = [lgnd featuresType{i} ' = ' featureTypeLong{i} ', '];
end
disp(lgnd);




