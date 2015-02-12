
function LH = buildGraphCuts( LH, features, win_len, W, dists )
%% Builds and calculates the MRF for the given samples.
%
%   INPUT
%       LH -> array (nxm) likelihoods for each sample on each cluster, where
%           n = number of samples, m = number of clusters.
%       features -> matrix (nxm) with the pair-wise features, where
%           n = number of samples, m = number of features.
%       win_len -> dimensions of the window used for the random field 
%           (maximum number of consecutive samples set as adjacent nodes)
%           (recommended value: 11).
%       W -> weighting term for the pair-wise term.
%
%%%%

    [~, classes] = max(LH, [], 2);
    
    nSamples = size(features,1);
    nClasses = size(LH,2);
    halfW = floor(win_len/2);
    
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
    
%     dists(adj==0) = 0;
%     dists = dists.^2;
%     expectancy = mean(dists(dists>0));

    
    % The pairwise potential (adj here) must be higher if the neighbouring variables
    % are similar in some way. Preventing from producing a
    % cut (being separated with different labels) between them when 
    % minimizing the energy.
    for i = 1:nSamples
        neighbours = find(adj(i,:));
%             [~, li] = max(LH(i,:));
        lenN = length(neighbours);
        for k = neighbours
%                adj(i, k) = exp(-dists(i, k)^2 / (2*expectancy));
               adj(i, k) = exp(-dists(i, k));
        end
    end

    labelcost = single(ones(nClasses,nClasses));
    for i = 1:nClasses
        labelcost(i,i) = 0;
    end
    
%     labelcost(1,2) = 1;
%     labelcost(2,1) = 1;
%     labelcost(2,3) = 1;
%     labelcost(3,2) = 0;
%     labelcost(1,3) = 0;
%     labelcost(3,1) = 1;
    

    adj = adj * W; % th increases or decreases the importance of the pair-wise term
    LH = 1-LH';
%     LH = LH * (1-W);
    
    cd ..
    cd ..
    cd GCMEx
    [labels, ~, ~] = GCMex((classes-1)', single(LH), adj, labelcost, 1);
    cd ..
    cd 'Subshot Segmentation'
    cd EventsDivision_SenseCam
    
    labels = labels+1;
    LH = zeros(nSamples, nClasses);
    for i = 1:nSamples
        LH(i, labels(i)) = 1;
    end

end

% function d = distance( X, Y )
%     d = (X-Y).^2;
%     d = sqrt(sum(d));
% %     d = d/length(X);
% end

