function [ err ] = classifyFS_SVM( xtrain, ytrain, xtest, ytest )

    % Global parameters
    global C;
    global sigma;
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
    options = statset('MaxIter', 50000);
    nSamples = length(ytest);
    results = zeros(nSamples, nClasses*nClasses);
    margins = zeros(nSamples, nClasses*nClasses);
    for i = 1:nClasses
        c1 = i; c2 = cat(2, 1:(i-1), (i+1):nClasses);
        e1 = [xtrain(ytrain==i, :)]; % elements
        e2 = [];
        % Gets elements from the rest of the classes (ALL)
        for j = 1:(nClasses-1)
            e2 = [e2; xtrain(ytrain==j, :)];
        end
        % Balances them
        indices = randsample(1:size(e2,1), size(e1,1));
        e = [e1; e2(indices, :)];
        c = [ones(size(e1,1),1);ones(size(e1,1),1)*-1];

        % Builds the classifier
        classifier = svmtrain(e, c, 'kernel_function', 'rbf', 'rbf_sigma', sigma, 'boxconstraint', C, 'options', options);
        disp(['Classifier ' num2str(i) ' out of ' num2str(nClasses) ' trained.']);
        
        % Evaluate test samples
        [res margin] = svmclassify2(classifier, xtest);
        margin = abs(margin);
        for l = 1:nSamples
            if( res(l) == 1)
                results(l, nClasses*(i-1) + i) = i;
                margins(l, nClasses*(i-1) + i) = margin(l);
            else
                results(l, nClasses*(i-1) + cat(2,1:i-1,i+1:nClasses)) = cat(2,1:i-1,i+1:nClasses);
                margins(l, nClasses*(i-1) + cat(2,1:i-1,i+1:nClasses)) = margin(l);
            end
        end
    end

    %% Likelihoods calculation for each class
    LH = zeros(nSamples, nClasses);
    for i = 1:nSamples
        this_sample = results(i,results(i,:)>0);
        this_margins = margins(i,results(i,:)>0);
        for j = 1:nClasses
%             LH(i,j) = sum(this_sample==j) / length(this_sample);
            LH(i,j) = sum(this_margins(this_sample==j));
        end
        LH_aux = zeros(1, nClasses);
        for j = 1:nClasses
            LH_aux(j) = LH(i,j)/sum(LH(i,:));
        end
        LH(i,:) = LH_aux;
    end
    
    %% Evaluate classification error
    [ ~, classifyLabel ] = max(LH,[],2);
    err = 1 - sum(classifyLabel==ytest)/nSamples;
    
end

