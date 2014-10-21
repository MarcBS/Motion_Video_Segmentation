
%% 
%   Test script for doing K-fold validations over the Support Vector 
%   Machine classifier
%%%%

addpath('..');

%% Params
path_data = '../../EventsDivision_Grauman';
folder_data = 'P01_1to4001';
classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
X_fold = 10; % number of cross validations performed
max_iter = 500000;
M = 10; % Number of iterations though the cross validation process

treatMethod = 'norm'; % {'norm' = normalize || 'stand' = standardize}

%% Data retrieval
load([path_data '/' folder_data '/labels_result_' folder_data '.mat']); % labels_result
load([path_data '/' folder_data '/featuresNoColour.mat']); % featuresNoColour
features = featuresNoColour;
nClasses = length(classes);

% F = standarizer(F); % Standarizes data

counts = zeros(1, nClasses);
labels = [labels_result(:).label];
elems = {};

for i = 1:nClasses
    counts(i) = sum(labels==i);
    elems{i} = find((labels==i)==1);
end

%% Balances the data
countsB = min(counts);
nPerGroup = floor(countsB / X_fold);
% countsB = nPerGroup*X_fold;

%% Gets the data separated into X_fold + 1 groups
X_fold_groups = {};
for i = 1:nClasses
    rand_indices = randsample(elems{i}, counts(i));
    X_fold_groups{i} = {};
    for j = 1:X_fold
        ini = (j-1)*nPerGroup +1;
        fin = j*nPerGroup;
        X_fold_groups{i}{j} = features(rand_indices(ini:fin), :);
    end
    X_fold_groups{i}{X_fold+1} = features(rand_indices((X_fold*nPerGroup+1):end), :);
end


%% Performs the cross fold validation using ONE vs ALL classifiers
options = statset('MaxIter', max_iter);
tic
results = {};
for i = 1:nClasses
    results{i} = zeros(counts(i), nClasses*nClasses);
end

%% We apply M times K-fold cross validation
all_errors = zeros(1,M);
for iter = 1:M

    disp(['Starting iteration ' num2str(iter) '/' num2str(M) '...']);
    disp(' ');
    
    %% X-Fold Cross-Validation
    for j = 1:X_fold

        disp(['Starting ' num2str(j) ' out of ' num2str(X_fold) ' fold cross-validations.']);

        xTrain = {}; xTest = {};
        for i = 1:nClasses % for each class
            xTrain{i} = []; xTest{i} = [];
            xTrain{i} = cat(1, X_fold_groups{i}{cat(2, 1:j-1, j+1:X_fold)});
            xTest{i} = [X_fold_groups{i}{j}];
            if(j==X_fold)
                xTest{i} = [xTest{i}; X_fold_groups{i}{X_fold+1}];
            end
        end


        for i = 1:nClasses % for each classifier

            % Balances the elements
            indices = randsample(1:(size(xTrain{i},1) * 2), size(xTrain{i},1));
            e = cat(1,xTrain{cat(2,1:i-1,i+1:nClasses)});
            e = [xTrain{i}; e(indices, :)];
            c = [ones(size(xTrain{i},1),1);ones(size(xTrain{i},1),1)*-1];
            
            if(strcmp(treatMethod, 'norm'))
                % Normalizes the data
                [ e, minVals, maxVals ] = normalize( e );
            elseif(strcmp(treatMethod, 'stand'))
                [ e, meanD, stdDev ] = standarize( e );
            end
            
            % Builds the classifier
            disp(['    Building classifier ' num2str(i) '/' num2str(nClasses)]);
            classifier =  svmtrain(e, c, 'kernel_function', 'rbf', 'rbf_sigma', 1, 'options', options);
%             classifier =  svmtrain(e, c, 'kernel_function', 'mlp', 'options', options);

            for k = 1:nClasses % for each class

                if(strcmp(treatMethod, 'norm'))
                    % Normalizes the data
                    [ this_xTest, ~, ~ ] = normalize( xTest{k}, minVals, maxVals );
                elseif(strcmp(treatMethod, 'stand'))
                    [ this_xTest, ~, ~ ] = standarize( xTest{k}, meanD, stdDev );
                end
                
                res = svmclassify(classifier, this_xTest);
                nSamples = size(this_xTest,1);
                for l = 1:nSamples
                    if( res(l) == 1)
                        results{k}((j-1)*nPerGroup + l, nClasses*(i-1) + i) = i;
                    else
                        results{k}((j-1)*nPerGroup + l, nClasses*(i-1) + cat(2,1:i-1,i+1:nClasses)) = cat(2,1:i-1,i+1:nClasses);
                    end
                end

            end 

        end

    end

    disp(' ');

    %% Error check
    resCounts = zeros(nClasses, nClasses); % true_value x assigned_value
    for i = 1:nClasses
        for j = 1:counts(i)
            maxClass = 0;
            maxValue = -1;
            for k = 1:nClasses
                this_ocurrences = sum(results{i}(j,:)==k);
                if(this_ocurrences > maxValue)
                    maxValue = this_ocurrences;
                    maxClass = k;
                end
            end
            resCounts(i, maxClass) = resCounts(i, maxClass)+1;
        end


        disp(['Error class ' num2str(i) ': ' num2str((counts(i)-resCounts(i,i)) / counts(i))]);
    end

    disp(' ');
    disp('Confusion matrix:');

    topLine = '    ';
    bottom = {};
    for i = 1:nClasses
        topLine = [topLine num2str(i) '    '];
        bottom{i} = [num2str(i) '  ' num2str(resCounts(i,:))];
    end
    disp(topLine);
    for i = 1:nClasses
        disp(bottom{i});
    end

    tot_error = 1 - (sum(diag(resCounts)) / sum(sum(resCounts)));
    disp(' ');
    disp(['Total error: ' num2str(tot_error)]);
    disp(' ');
    
    all_errors(iter) = tot_error;
end

toc

disp(' ');
disp('All errors: ');
disp(all_errors);
disp(['Mean error: ' num2str(mean(all_errors))]);
disp(['Std deviation: +-' num2str(std(all_errors))]);
