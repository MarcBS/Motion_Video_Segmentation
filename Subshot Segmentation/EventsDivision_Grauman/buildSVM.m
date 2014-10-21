
%% 
%   This script builds the SVM for classifying In Transit, Static and 
%   Moving Head images.
%%%%

% addpath('../../svm');

%% Data params
path_data = '../EventsDivision_Grauman';
folder_data = 'P01_1to4001';
classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
max_iter = 50000;
sigma = 1;

treatMethod = 'norm'; % {'norm' = normalize || 'stand' = standardize}

% Structure for saving the normalization params for each of the
% classifiers.
normParams = struct('maxVals', {}, 'minVals', {});
% Structure for saving the standardization params for each of the
% classifiers.
standParams = struct('meanD', {}, 'stdDev', {});

balanced = true;

%% Data retrieval
nClasses = length(classes);
load([path_data '/' folder_data '/labels_result_' folder_data '.mat']); % labels_result
load([path_data '/' folder_data '/featuresNoColour.mat']); % featuresNoColour
features = featuresNoColour;

counts = zeros(1, nClasses);
labels = [labels_result(:).label];
elems = {};

for i = 1:nClasses
    counts(i) = sum(labels==i);
    elems{i} = find((labels==i)==1);
end

%% Balances the data
if(balanced)
    counts(:) = min(counts);
end

%% Gets the data separated into classes
for i = 1:nClasses
    indices = randsample(elems{i}, counts(i));
    elems{i} = features(indices, :);
end


%% Trains the classifiers [ ONE vs ALL ]
classifiers = {};
options = statset('MaxIter', max_iter);
for i = 1:nClasses
    c1 = i; c2 = cat(2, 1:(i-1), (i+1):nClasses);
    e1 = [elems{c1}]; % elements
    e2 = [];
    % Gets elements from the rest of the classes (ALL)
    for j = 1:(nClasses-1)
        e2 = [e2; elems{c2(j)}];
    end
    % Balances them
    indices = randsample(1:counts(i), counts(c1));
    e = [e1; e2(indices, :)];
    c = [ones(counts(c1),1);ones(counts(c1),1)*-1];
    
    if(strcmp(treatMethod, 'norm'))
        % Normalizes the data
        [ e, minVals, maxVals ] = normalize( e );
        normParams(i).maxVals = maxVals;
        normParams(i).minVals = minVals;
    elseif(strcmp(treatMethod, 'stand'))
        [ e, meanD, stdDev ] = standarize( e );
        standParams(i).meanD = meanD;
        standParams(i).stdDev = stdDev;
    end
    
    % Builds the classifier
    classifiers{c1} = svmtrain(e, c, 'kernel_function', 'rbf', 'rbf_sigma', sigma, 'options', options);
    disp(['Classifier ' num2str(i) ' out of ' num2str(nClasses) ' trained.']);
end

save('SVM Classifier/classifiersTSM', 'classifiers');

if(strcmp(treatMethod, 'norm'))
    save('SVM Classifier/normParams', 'normParams');
elseif(strcmp(treatMethod, 'stand'))
    save('SVM Classifier/standParams', 'standParams');
end


disp('SVM classifier built.');