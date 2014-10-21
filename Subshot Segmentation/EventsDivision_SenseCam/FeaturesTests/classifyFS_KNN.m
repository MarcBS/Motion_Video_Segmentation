function [ err ] = classifyFS_KNN( xtrain, ytrain, xtest, ytest )

    % Global parameters
    global k;
    global distMetric;
    global treatMethod;
    
    disp(' ');
    disp('Starting CV...');
    
    %% Normalize / Standardize
    if(strcmp(treatMethod, 'norm'))
        % Normalizes the data
        [ xtrain, minVals, maxVals ] = normalize( xtrain );
        [ xtest ] = normalize(xtest, minVals, maxVals);
    elseif(strcmp(treatMethod, 'stand'))
        [ xtrain, meanD, stdDev ] = standarize( xtrain );
        [ xtest ] = normalize(xtest, meanD, stdDev);
    end
    
    %% Classify
    nClasses = length(unique(ytrain));
    nSamples = length(ytest);

    % Gets elements "e" and classes "c"
    e = [];
    c = [];
    for i = 1:nClasses
        e = [e; xtrain(ytrain==i, :)];
        c = [c; ones(sum(ytrain==i),1)*i];
    end

    % Builds the classifier
    classifier = ClassificationKNN.fit(e, c, 'NumNeighbors', k, 'Distance', distMetric);
    disp('Classifier trained.');

    % Evaluate test samples
    [~, likelihood] = predict(classifier, xtest);
    
    %% Evaluate classification error
    [ ~, classifyLabel ] = max(likelihood,[],2);
    err = 1 - sum(classifyLabel==ytest)/nSamples;
    
end

