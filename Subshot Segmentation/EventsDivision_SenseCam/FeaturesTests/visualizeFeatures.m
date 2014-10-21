
%% 
%   This script is only used for feature visualization purposes.
%%%%

addpath('..');
addpath('../..')

%% Data params
path_data = '../../EventsDivision_SenseCam/Datasets';
folder_data = '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233';
classesShort = {'T', 'S', 'M'};
classes = {'In Transit', 'Static', 'Moving Camera'}; % In Transit, Static, Moving Camera
classesColour = ['r'; 'g'; 'b'];
elemsToShow = 10000;
numBars = 10;

featuresNum = [9 81 8 9];
featuresType = {'C', 'H', 'S', 'B'}; % (Colour, HOG, SIFT Flow, Blurriness)
featuresTypeLong = {'Colour', 'HOG', 'SIFT Flow', 'Blurriness'};

% Preparation of the features row for printing the result
rowFeatures = '|  ';
count = 2;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        rowFeatures = sprintf([rowFeatures featuresType{i} '%2d |  '], j);
        count = count+1;
    end
end

destFolder = 'Features Comparison';
mkdir(destFolder);


%% Data retrieval
load([path_data '/' folder_data '/labels_result.mat']); % labels_result
load([path_data '/' folder_data '/features.mat']); % features

nClasses = length(classes);
counts = zeros(1, nClasses);
labels = [labels_result(:).label];
elems = {};
for i = 1:nClasses
    counts(i) = sum(labels==i);
    elems{i} = find((labels==i)==1);
end

% Normalize the data
[features, ~, ~] = normalize(features);


% counts(:) = min(counts);

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
combos = combntns(1:nClasses, 2)';
chisqMat = zeros(size(combos,2),sum(featuresNum));
count = 1;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        
        f=figure;
        hists = zeros(numBars, nClasses);
        for k = 1:nClasses
            hists(:,k) = hist(elems{k}(:,count), numBars);
        end
        
        [hists, ~, ~] = normalize(hists);
        
        % Chi Square calculations
        countC = 1;
        for c = combos
            chisqMat(countC, count) = pdist2(hists(:,c(1))', hists(:,c(2))', 'chisq');
            countC = countC+1;
        end
        
        % Plots lines
        for k = 1:nClasses
            plot((1/numBars/2):(1/numBars):(1-1/numBars/2), hists(:,k), 'Color', classesColour(k));
            hold on
        end
        hold off
%         bar((1/numBars/2):(1/numBars):(1-1/numBars/2), hists, 1, 'stack');

        % Adjust the axis limits
        axis([0 1 0 max(max(hists))*1.1]);
%         axis([-0.1 1.1 0 max(sum(hists, 2))]);
        
        % Sets the title and other info
        this_title = [featuresTypeLong{i} ' feature ' num2str(j)];
        title(this_title);
        legend(classes{:});

        saveas(f, [destFolder '/' this_title '.jpg']);
        
        count = count+1;
    end
    
end

%% Format output matrix of chi square distances
disp(['     ' rowFeatures]);
count = 1;
for c = combos
    colCell{count} = [classesShort{c(1)} 'vs' classesShort{c(2)}];
    row = [classesShort{c(1)} 'vs' classesShort{c(2)} ' | '];
    for i = 1:sum(featuresNum)
        row = sprintf([row '%1.2f | '], chisqMat(count, i));
    end
    disp(row);
    count = count+1;
end

%% Shows legend
lgnd = 'Legend: ';
for i = 1:length(featuresType)
    lgnd = [lgnd featuresType{i} ' = ' featuresTypeLong{i} ', '];
end
disp(' ');disp(lgnd);


%% Create .csv file
csvStr = '';
for i = 1:sum(featuresNum)
    csvStr = [csvStr '%f,'];
end

fid = fopen('SenseCam_ChiSq_Distances.csv','wt');
fprintf(fid, [strrep(rowFeatures, '|', ',') '\n']);
for i=1:length(combos)
    fprintf(fid, [colCell{i} ',' csvStr '\n'], chisqMat(i, :));
end
fclose(fid);


