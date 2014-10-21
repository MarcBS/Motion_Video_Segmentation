
function LH = buildMRF( pathToFeatures, LH, W, th, maxIter, type )
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
%       type -> MRF function applied {MRF_v1 or MRF_v2}.
%
%%%%

    addpath('MRF');

    %% Parameters

    %% Color hists for each image.
    load([pathToFeatures '/features.mat']); % features
    % DELETE THIS LINE AND UNCOMMENT THE PREVIOUS
%     load([pathToFeatures '/featuresLQOpticalFlow.mat']); % features
    colour = features(:,1:9);
    [colour, ~, ~] = normalize(colour);
    nSamples = size(colour,1);
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
    
    if(strcmp(type, 'MRF_v1'))
        LH = MRF_v1(LH, adj, colour, maxIter, th);
    elseif(strcmp(type, 'MRF_v2'))
        LH = MRF_v2(LH, adj, colour, maxIter, th);
    elseif(strcmp(type, 'MRF_v3'))
        [LH, ~] = MRF_v3(LH, adj, colour, maxIter, th);
    elseif(strcmp(type, 'MRF_v4'))
        [LH, ~] = MRF_v4(LH, adj, colour, maxIter, th);
    elseif(strcmp(type, 'MRF_v5'))
        LH = MRF_v5(LH, adj, colour, maxIter, th);
    elseif(strcmp(type, 'GraphCuts'))
        
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
                adj(i, k) = exp(-distance(colour(i,:), colour(k,:))) / (lenN*th);
%                 adj(i, k) = exp(-( (li==lk) * (distance(colour(i,:), colour(k,:)))  ) )/th;
            end
        end

        labelcost = single(ones(nClasses,nClasses));
        for i = 1:nClasses
            labelcost(i,i) = 0;
        end
        labelcost(1,2) = 2;
        labelcost(2,1) = 2;

        cd '../../GCMEx';
        [labels E E_after] = GCMex((CLASS-1)', single(1-LH'), adj, labelcost, 1);
        cd '../Subshot Segmentation/EventsDivision_Grauman';
        labels = labels+1;
        LH = zeros(nSamples, nClasses);
        for i = 1:nSamples 
            LH(i, labels(i)) = 1;
        end
        
    end

end

function d = distance( X, Y )
    d = sqrt(sum((X-Y).^2));
    d = d/length(X);
end

