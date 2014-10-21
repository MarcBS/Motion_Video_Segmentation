
%% 
%   Test script for doing K-fold nested (training, validation and test) 
%   cross-validations over the Support Vector Machine classifier
%%%%

addpath('..');
addpath('../..');

%% Params
path_data = '../../EventsDivision_SenseCam/Datasets';
folder_data = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
classes = ['T'; 'S'; 'M']; % In Transit, Static, Moving Head
X_fold = 3; % number of cross validations performed
M = 1; % Number of iterations through the cross validation process
balance = true;
treatMethod = 'stand'; % {'norm' = normalize || 'stand' = standardize}
distanceMeasure = 'cosine'; % euclidean or cosine

%% Prepare different parameters for classification comparison
params_grid = [5 7 11 15 19 21 31 51 81 101 151]; % Ks
numParams = length(params_grid);

numTests = length(folder_data); % number of folders to test
nClasses = length(classes); % number of classes

%% Open file to write the result
fid = fopen('testResult.txt', 'w');
writeToFile(fid, 'Test Results using: ', true);
writeToFile(fid, ' ', true);
writeToFile(fid, [num2str(X_fold) '-fold BALANCED validations.'], true);
writeToFile(fid, ' ', true);
writeToFile(fid, 'K values: ', true);
writeToFile(fid, params_grid, true);
writeToFile(fid, ['With ' num2str(M) ' iterations per parameter value.'], true);

%%%%%%%%%%%%%%%%%%%%%%%
%
%% We apply M times K-fold cross validation for each parameter and for each test set
%
%%%%%%%%%%%%%%%%%%%%%%%
best_Ks = zeros(1, numTests);
errorsTest = zeros(1, numTests);
for idTest = 1:numTests
    writeToFile(fid, ' ', true);
    writeToFile(fid, '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////', true);
    writeToFile(fid, '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////', true);
    writeToFile(fid, ' ', true);
    writeToFile(fid, ['Starting test ' num2str(idTest) '/' num2str(numTests)], true);
    writeToFile(fid, ['Folder name: ' folder_data{idTest}], true);
    writeToFile(fid, ' ', true);
    writeToFile(fid, '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////', true);
    writeToFile(fid, '//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////', true);
    writeToFile(fid, ' ', true);
    
    %% Data retrieval for each training set
    features = [];
    counts = zeros(1, nClasses);
    countsTest = zeros(1, nClasses);
    labels = [];
    labelsTest = [];
    elems = {};
    elemsTest = {};
    for idTrain = 1:numTests
        if(idTrain ~= idTest) % training + validation samples
            load([path_data '/' folder_data{idTrain} '/labels_result.mat']); % labels_result
            load([path_data '/' folder_data{idTrain} '/featuresNoColour.mat']); % featuresNoColour
            features = [features; featuresNoColour];
            labels = [labels labels_result(:).label];
        else % test samples
            load([path_data '/' folder_data{idTest} '/labels_result.mat']); % labels_result
            load([path_data '/' folder_data{idTest} '/featuresNoColour.mat']); % featuresNoColour
            featuresTest = featuresNoColour;
            labelsTest = [labels_result(:).label];
        end
    end

    %% Gets all labels
    for i = 1:nClasses
        counts(i) = counts(i) + sum(labels==i);
        elems{i} = find((labels==i)==1);
        countsTest(i) = sum(labelsTest==i);
        elemsTest{i} = find((labelsTest==i)==1);
    end
    
    %% Balances the data
    countsB = zeros(1, length(counts));
    if(balance)
        countsB(:) = min(counts);
    else
        countsB = counts;
    end
    nPerGroup = floor(countsB ./ X_fold);
    
    tic
    results = {};
    for i = 1:nClasses
        results{i} = zeros(counts(i), 1);
    end

    %% Gets the data separated into X_fold + 1 groups
    X_fold_groups = {};
    for i = 1:nClasses
        rand_indices = randsample(elems{i}, counts(i));
        X_fold_groups{i} = {};
        for j = 1:X_fold
            ini = (j-1)*nPerGroup(i) +1;
            fin = j*nPerGroup(i);
            X_fold_groups{i}{j} = features(rand_indices(ini:fin), :);
        end
        X_fold_groups{i}{X_fold+1} = features(rand_indices((X_fold*nPerGroup(i)+1):end), :);
    end
    
    %% Selects parameter K
    all_errors = zeros(numParams,M);
    all_errors_weighted = zeros(numParams,M, nClasses);
    countK = 1;
    for K = params_grid

        writeToFile(fid, ' ', true);
        writeToFile(fid, '------------------------------------------------------------------------------------------------', true);
        writeToFile(fid, ' ', true);
        writeToFile(fid, ['K = ' num2str(K) ' --> ' num2str(countK) '/' num2str(numParams)], true);
        writeToFile(fid, ' ', true);
        writeToFile(fid, '------------------------------------------------------------------------------------------------', true);
        writeToFile(fid, ' ', true);
        for iter = 1:M

            writeToFile(fid, ['Starting validation iteration ' num2str(iter) '/' num2str(M) '...'], true);
            disp(' ');

            %% X-Fold Cross-Validation using KNN classifier
            clear results;
            for j = 1:X_fold

                writeToFile(fid, ['Starting ' num2str(j) ' out of ' num2str(X_fold) ' fold cross-validations.'], false);

                xTrain = {}; xTest = {};
                for i = 1:nClasses % for each class
                    xTrain{i} = []; xTest{i} = [];
                    xTrain{i} = cat(1, X_fold_groups{i}{cat(2, 1:j-1, j+1:X_fold)});
                    xTest{i} = [X_fold_groups{i}{j}];
                    if(j==X_fold)
                        xTest{i} = [xTest{i}; X_fold_groups{i}{X_fold+1}];
                    end
                end


                % Balances the elements
                % Gets elements "e" and classes "c"
                e = [];
                c = [];
                for i = 1:nClasses
                    e = [e; xTrain{i}];
                    c = [c; ones(size(xTrain{i},1), 1)*i];
                end

                if(strcmp(treatMethod, 'norm'))
                    % Normalizes the data
                    [ e, minVals, maxVals ] = normalize( e );
                elseif(strcmp(treatMethod, 'stand'))
                    [ e, meanD, stdDev ] = standarize( e );
                end

                % Builds the classifier
                writeToFile(fid, ['    Building classifier.'], false);
                classifier = ClassificationKNN.fit(e, c,'NumNeighbors', K, 'Distance', distanceMeasure);

                count = 0;
                for i = 1:nClasses
                    count = count + size(xTest{i},1);
                end
                this_xTest = zeros(count, size(xTest{1},2));
                count = 0;
                for i = 1:nClasses
                    this_xTest(count+1:count+size(xTest{i},1), :) = xTest{i};
                    count = count + size(xTest{i},1);
                end
                
                % Apply classifier on test data
                if(strcmp(treatMethod, 'norm'))
                    % Normalizes the data
                    [ this_xTest, ~, ~ ] = normalize( this_xTest, minVals, maxVals );
                elseif(strcmp(treatMethod, 'stand'))
                    [ this_xTest, ~, ~ ] = standarize( this_xTest, meanD, stdDev );
                end
                [res_pred likelihood] = predict(classifier, this_xTest);
                
                count = 0;
                for i = 1:nClasses
                    nSamples = size(xTest{i},1);
                    for l = 1:nSamples
                        results{i}((j-1)*nPerGroup(i) + l) = res_pred(l+count);
                    end
                    count = count + nSamples;
                end

            end % end fold j

            writeToFile(fid, ' ', true);

            %% Error check
            resCounts = zeros(nClasses, nClasses); % true_value x assigned_value
            for i = 1:nClasses
                for j = 1:counts(i)
                    maxClass = results{i}(j);
                    resCounts(i, maxClass) = resCounts(i, maxClass)+1;
                end

                writeToFile(fid, ['Error class ' num2str(i) ': ' num2str((counts(i)-resCounts(i,i)) / counts(i))], true);
            end

            writeToFile(fid, ' ', true);
            writeToFile(fid, 'Confusion matrix:', true);

            topLine = '    ';
            bottom = {};
            totCounts = sum(resCounts,2);
            % Rows true classes, columns predicted classes
            for i = 1:nClasses
                topLine = [topLine num2str(i) '    '];
        %         bottom{i} = [num2str(i) '  ' num2str(resCounts(i,:)]; % total value
                bottom{i} = [num2str(i) '  ' num2str(resCounts(i,:)./totCounts(i))]; % percentage
            end
            writeToFile(fid, topLine, true);
            for i = 1:nClasses
                writeToFile(fid, bottom{i}, true);

                all_errors_weighted(countK, iter, i) = (1/nClasses) * ((counts(i)-resCounts(i,i)) / counts(i));
            end

            tot_error = 1 - (sum(diag(resCounts)) / sum(sum(resCounts)));
            writeToFile(fid, ' ', true);
            writeToFile(fid, ['>>> Total error: ' num2str(tot_error)], true);
            writeToFile(fid, ' ', true);

            all_errors(countK, iter) = tot_error;
        end % end ith iter from M

        countK = countK+1;
    end % end K

    toc

    %% Display errors
    writeToFile(fid, '##################################################################', true);
    writeToFile(fid, ' ', true);
    % disp('All errors: ');
    % disp(all_errors);
    writeToFile(fid, 'K values: ', true);
    writeToFile(fid, params_grid, true);
    writeToFile(fid, 'Mean error: ', true);
    writeToFile(fid, all_errors, true);
    writeToFile(fid, ' ', true);
    for i = 1:nClasses
        writeToFile(fid, ['Weighted errors (' num2str(1/nClasses) ' max) for class ' classes(i)] , true);
        writeToFile(fid, all_errors_weighted(:,:,i), true);
    end
    writeToFile(fid, ' ', true);
    writeToFile(fid, 'Weighted errors mean sum: ', true);
    writeToFile(fid, sum(all_errors_weighted, 3), true);
    writeToFile(fid, ' ', true);

    %% Find parameters of min error
    all_errors = sum(all_errors_weighted, 3);
    val = min(all_errors);
    row = find(all_errors == val);
    best_K(idTest) = params_grid(row(1));
    
    writeToFile(fid, ['Best K: ' num2str(best_K(idTest))], true);
    writeToFile(fid, ' ', true);
    
    %% Apply classification on all TRAINING! (balanced)
    xTrain = {}; xTest = {};
    clear results;
    for i = 1:nClasses
        xTrain{i} = features(randsample(elems{i}, countsB(i)), :);
        xTest{i} = featuresTest(elemsTest{i}, :);
    end
    writeToFile(fid, ' ', true);

    % Balances the elements
    % Gets elements "e" and classes "c"
    e = [];
    c = [];
    for i = 1:nClasses
        e = [e; xTrain{i}];
        c = [c; ones(size(xTrain{i},1), 1)*i];
    end

    if(strcmp(treatMethod, 'norm'))
        % Normalizes the data
        [ e, minVals, maxVals ] = normalize( e );
    elseif(strcmp(treatMethod, 'stand'))
        [ e, meanD, stdDev ] = standarize( e );
    end

    % Builds the classifier
    writeToFile(fid, ['Building classifier.'], false);
    classifier = ClassificationKNN.fit(e, c,'NumNeighbors', K, 'Distance', distanceMeasure);

    count = 0;
    for i = 1:nClasses
        count = count + size(xTest{i},1);
    end
    this_xTest = zeros(count, size(xTest{1},2));
    count = 0;
    for i = 1:nClasses
        this_xTest(count+1:count+size(xTest{i},1), :) = xTest{i};
        count = count + size(xTest{i},1);
    end
    
    if(strcmp(treatMethod, 'norm'))
        % Normalizes the data
        [ this_xTest, ~, ~ ] = normalize( this_xTest, minVals, maxVals );
    elseif(strcmp(treatMethod, 'stand'))
        [ this_xTest, ~, ~ ] = standarize( this_xTest, meanD, stdDev );
    end

    [res_pred likelihood] = predict(classifier, this_xTest);
    
    count = 0;
    for i = 1:nClasses
        nSamples = size(xTest{i},1);
        for l = 1:nSamples
            results{i}(l) = res_pred(l+count);
        end
        count = count + nSamples;
    end

    
    %% Error check on TEST!
    resCounts = zeros(nClasses, nClasses); % true_value x assigned_value
    for i = 1:nClasses
        for j = 1:size(xTest{i},1)
            maxClass = results{i}(j);
            resCounts(i, maxClass) = resCounts(i, maxClass)+1;
        end


        writeToFile(fid, [' >>>>>>>>>> Error class ' num2str(i) ': ' num2str((size(xTest{i},1)-resCounts(i,i)) / size(xTest{i},1))], true);
    end

    writeToFile(fid, ' ', true);
    writeToFile(fid, 'Confusion matrix:', true);

    topLine = '    ';
    bottom = {};
    totCounts = sum(resCounts,2);
    % Rows true classes, columns predicted classes
    for i = 1:nClasses
        topLine = [topLine num2str(i) '    '];
%         bottom{i} = [num2str(i) '  ' num2str(resCounts(i,:)]; % total value
        bottom{i} = [num2str(i) '  ' num2str(resCounts(i,:)./totCounts(i))]; % percentage
    end
    writeToFile(fid, topLine, true);
    for i = 1:nClasses
        writeToFile(fid, bottom{i}, true);
    end

    tot_error = 1 - (sum(diag(resCounts)) / sum(sum(resCounts)));
    writeToFile(fid, ' ', true);
    writeToFile(fid, ['>>>>>>>>>>>>>>>>>> Total error: ' num2str(tot_error)], true);
    writeToFile(fid, ' ', true);
    writeToFile(fid, '##################################################################', true);
    
    errorsTest(idTest) = tot_error;
    
end % end testing on best parameters


%% Print final results for all the TEST evaluations
writeToFile(fid, ' ', true); writeToFile(fid, ' ', true);
writeToFile(fid, '########################################################################################', true);
writeToFile(fid, '########################################################################################', true);
writeToFile(fid, ' ', true);
writeToFile(fid, '>>>>> K values chosen for each test: ', true);
writeToFile(fid, best_K, true);
writeToFile(fid, '>>>>> Error for each test: ', true);
writeToFile(fid, errorsTest, true);
writeToFile(fid, '>>>>> Test folders: ', true);
writeToFile(fid, folder_data, true);
writeToFile(fid, ' ', true);
writeToFile(fid, '########################################################################################', true);
writeToFile(fid, '########################################################################################', true);


% Close file
fclose(fid);



