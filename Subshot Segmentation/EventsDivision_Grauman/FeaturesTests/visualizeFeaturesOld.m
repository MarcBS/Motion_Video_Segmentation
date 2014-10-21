
%% 
%   This script is only used for feature visualization purposes.
%%%%

addpath('..');

%% Data params
path_data = '../../EventsDivision_Grauman';
folder_data = 'P01_1to4001';
classesShort = {'T', 'S', 'M'};
classes = {'In Transit', 'Static', 'Moving Head'}; % In Transit, Static, Moving Head
classesColour = ['r'; 'g'; 'b'];
elemsToShow = 1000;
numBars = 10;

featuresNum = [9 8 9];
featuresType = {'C', 'O', 'B'}; % (Colour, Optical Flow, Blurriness)
featuresType = {'Colour', 'Optical Flow', 'Blurriness'};

destFolder = 'Features Comparison';
mkdir(destFolder);

%% Data retrieval
nClasses = length(classes);
load([path_data '/' folder_data '/labels_result_' folder_data '.mat']); % labels_result
load([path_data '/' folder_data '/features.mat']); % features

counts = zeros(1, nClasses);
labels = [labels_result(:).label];
elems = {};
for i = 1:nClasses
    counts(i) = sum(labels==i);
    elems{i} = find((labels==i)==1);
end

% Normalize the data
[features, ~, ~] = normalize(features);


counts(:) = min(counts);

%% Gets the data to show separated into classes
numPerClass = zeros(1, nClasses);
for i = 1:nClasses
    if(counts(i) < elemsToShow)
        numPerClass(i) = counts(i);
    else
        numPerClass(i) = elemsToShow;
    end
    indices = randsample(elems{i}, numPerClass(i));
    elems{i} = features(indices, :);
end


%% Plots the values of all the chosen samples for each feature
count = 1;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        
        f=figure;
        hists = zeros(numBars, nClasses);
        for k = 1:nClasses
            hists(:,k) = hist(elems{k}(:,count), numBars);
        end
        bar((1/numBars/2):(1/numBars):(1-1/numBars/2), hists, 1, 'stack');

        % Adjust the axis limits
        axis([-0.1 1.1 0 max(sum(hists,2))]);
        
        % Sets the title and other info
        this_title = [featuresType{i} ' feature ' num2str(j) '.'];
        title(this_title);
        legend(classes{:});
        
        saveas(f, [destFolder '/' this_title '.jpg']);
        
        count = count+1;
    end
    
end
