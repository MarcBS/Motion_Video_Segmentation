
function LH = buildMRF( pathToFeatures, LH, W, th, maxIter, type, featureSelection)
%% Builds and calculates the MRF for the given samples.
%
%   INPUT
%       pathToFeatures -> path to the folder where are the features 
%           (colour hist to analyse (the file must be called features.mat).
%       LH -> matrix (nxm) with likelihoods for each of the classes, where
%           n = number of samples and m = number of classes.
%       W -> dimensions of the window used for the random field (maximum
%           number of consecutive samples set as adjacent nodes
%           (recommended value: 11).
%       th -> threshold for checking convergence. Or for determining the
%           number of final segmentations when type=GraphCuts.
%       maxIter -> maximum number of iterations applied in the MRF.
%       type -> MRF function applied.
%       featureSelection -> indicates if we want to perform a feature
%           selection.
%       (deprecated)flag -> indicates if we want to penalize the change of label S M or
%           not.
%
%%%%
    
    %% Color hists for each image.
    load([pathToFeatures '/features.mat']); % features
    colourAndHOG = features(:,1:(9+81));

    
    % %% Add CNNfeatures (test lines: delete when not needed)
    % load([pathToFeatures '/CNNfeatures.mat']);
    % colourAndHOG = [colourAndHOG CNNfeatures(2:end, :)];

    
    
%     %%%%%%% Caution! Features outliers correction with log
%     colLength = 3;
%     HOGLength = [3 3 9];
%     load('D:\Video Summarization Project\Code\Subshot Segmentation\EventsDivision_SenseCam\FeaturesTests\featureSelection.mat');
% 
%     not0 = fs(1:(colLength*3 + HOGLength(1)*HOGLength(2)*HOGLength(3)))==1;
%     
%     colourAndHOG(:,find(not0==1)<=(colLength*3)) = abs(colourAndHOG(:,find(not0==1)<=(colLength*3)));
%     for i = 1:3
%         for j = find(find(not0==1)<=(colLength*3))
%             colourAndHOG(:,j) = log10(colourAndHOG(:,j));
%             if(i~=3)
%                 colourAndHOG((colourAndHOG(:,j)<0),j) = 0;
%             else
%                 colourAndHOG((colourAndHOG(:,j)==-Inf),j) = min(colourAndHOG(~(colourAndHOG(:,j)==-Inf),j));
%             end
%         end
%     end
%     %%%%%%%
    
%     colourAndHOG = features(:,1:(9));
    [colourAndHOG, ~, ~] = standarize(colourAndHOG);
%     [colourAndHOG, ~, ~] = normalize(colourAndHOG);
    nSamples = size(colourAndHOG,1);
    nClasses = size(LH,2);
    halfW = floor(W/2);
    
    %% Adjacency matrix and nStates per sample (nClasses per sample)
    adj = sparse(nSamples, nSamples);
    for i = 1:nSamples
        minN = (i-halfW);
        maxN = (i+halfW);
        if(minN < 1)
            minN = 1;
        end
        if(maxN > nSamples)
            maxN = nSamples;
        end
        adj(i,cat(2, minN:(i-1), (i+1):maxN)) = 1;
    end
    
    if(strcmp(type, 'GraphCuts'))
        
        % Trying Graph-Cut algorithm
%         [~, CLASS] = max(LH, [], 2);
        CLASS = getClassFromLH(LH);
        % The pairwise potential (adj here) must be higher if the neighbouring variables
        % are similar in some way (colour in this case). Preventing from producing a
        % cut (being separated with different labels) between them when 
        % minimizing the energy.
        for i = 1:nSamples
            neighbours = find(adj(i,:));
%             [~, li] = max(LH(i,:));
            lenN = length(neighbours);
            for k = neighbours
%                 [~, lk] = max(LH(k,:));
                adj(i, k) = exp(-distance(colourAndHOG(i,:), colourAndHOG(k,:))) / lenN;
%                 adj(i, k) = exp(-( (li==lk) * (distance(colourAndHOG(i,:), colourAndHOG(k,:)))  ) )/th;
            end
        end

        labelcost = single(ones(nClasses,nClasses));
        for i = 1:nClasses
            labelcost(i,i) = 0;
        end
        
        % Increase cost between T - S
        % Decrease cost between S - M (because colors can be equal due
        % to the same environment)
        
        % SVM
        labelcost(1,2) = 1;
        labelcost(2,1) = 1;
        labelcost(2,3) = 1;
        labelcost(3,2) = 0;
        labelcost(1,3) = 0;
        labelcost(3,1) = 1;

        % KNN NOT USEFUL!
%         labelcost(1,2) = 1;
%         labelcost(2,1) = 0;
%         labelcost(2,3) = 0.5;
%         labelcost(3,2) = 1;
%         labelcost(1,3) = 0.2;
%         labelcost(3,1) = 0.2;
%         labelcost(2,2) = 0.2;

        
        adj = adj * th; % th increases or decreases the importance of the pair-wise term

        cd '../../GCMEx';
        [labels E E_after] = GCMex((CLASS-1)', single(1-LH'), adj, labelcost, 1);
        cd '../Subshot Segmentation/EventsDivision_SenseCam';
        labels = labels+1;
        LH = zeros(nSamples, nClasses);
        for i = 1:nSamples 
            LH(i, labels(i)) = 1;
        end
        
    end

end

function d = distance( X, Y )
    d = (X-Y).^2;
    d = sqrt(sum(d));
    d = d/length(X);
end

