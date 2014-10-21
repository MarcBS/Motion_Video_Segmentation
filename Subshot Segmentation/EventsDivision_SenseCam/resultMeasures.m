function resultMeasures( labels )
%%
%
%   Labels is a cell structure containing a cell for each ground truth
%   label. Each of this cells containing the set of test labels obtained
%   for all the samples corresponding to that ground truth label.
%
%%%%

    disp(' ');
    nClasses = length(labels);
    
    % The Rows represent the true classes
    % The Columns represent the predicted classes
    confMatrix = zeros(nClasses, nClasses);
    confMatrixPercentage = zeros(nClasses, nClasses);
    
    for n = 1:nClasses
        
        this_labels = labels{n};
        % confusion matrix calculation
        for m = 1:nClasses
            confMatrix(n,m) = sum(this_labels==m);
            confMatrixPercentage(n,m) = sum(this_labels==m)/length(this_labels);
        end
        
        % accuracy for each class
        disp(['Accuracy class ' num2str(n-1) ': ' sprintf('%.3f', confMatrix(n,n)/sum(confMatrix(n,:)))]);
    end
    
    % total accuracy
    disp(' ');
    disp(['Total accuracy: ' sprintf('%.3f', sum(diag(confMatrix)) / sum(sum(confMatrix)))]);
    
    %% show confMatrices
    disp(' ');
    disp('Confusion Matrix with absolute values:'); labels = '  ';
    for n = 1:nClasses
        labels = [labels sprintf('%5d', n) ' '];
    end
    disp(labels);
    for n = 1:nClasses
        line = [num2str(n) ' '];
        for m = 1:nClasses
            line = [line sprintf('%5d', confMatrix(n,m)) ' '];
        end
        disp(line);
    end
    
    disp(' ');
    disp('Confusion Matrix with percentage:'); labels = '   ';
    for n = 1:nClasses
        labels = [labels sprintf('%5d', n) '  '];
    end
    disp(labels);
    for n = 1:nClasses
        line = [num2str(n) '  '];
        for m = 1:nClasses
%             line = [line num2str(confMatrixPercentage(n,m)) ' '];
            line = [line sprintf('%.3f', confMatrixPercentage(n,m)) '  '];
        end
        disp(line);
    end
    

end

