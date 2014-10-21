function [ LH, optimalLabels ] = MRF_v4( LH, adj, features, maxIter, th )
%%
%
%   Markov Random Field application over the variables with likelihoods LH
%   and with the edge connections defined by adj.
%
%   INPUT
%       LH -> nxm matrix with each of the variables on the rows and with
%           the likelihoods for each of the classes on the columns.
%       adj -> nxn adjacency matrix with 1 if there is connection and 0 if 
%           there isn't.
%       features -> nxk matrix with features that define each of the 
%           samples. n = num of samples and k = num of features.
%       maxIter -> maximum number of iterations applied to the variables.
%       th -> threshold defining the difference that has to be achieved in
%           order to stop the iterative process.
%
%%%%

    [nSamples, nClasses] = size(LH);
    [ ~, optimalLabels] = max(LH, [], 2);
    
    iter = 1;
    converged = false;
    while (iter <= maxIter && ~converged)
        %% Ising Model applied
        pLH = LH; % previous LH = pLH
        for i = 1:nSamples
            for j = 1:nClasses
                LH(i,j) = 1 - (energy(i, j, pLH, adj, features, optimalLabels) / 3);
            end
            LH(i,:) = LH(i,:) / sum(LH(i,:));
        end
        converged = sum(abs(distance(pLH, LH))) <= th;
        iter = iter+1;
        [ ~, optimalLabels] = max(LH, [], 2);
    end

end

function E = energy(i, j, LH, adj, features, optimalLabels)
% The energy function provides a value between 0 and 2 (1 for data term +
% 1 for smooth term).
    % Data term
    D = 1-LH(i,j);
    
    % Smooth term
    S = 0;
    W = [1.5 0.5]; % weights for the distance and label similarity
    neighbours = find(adj(i,:));
    lenN = length(neighbours);
    for k = neighbours
        
        dist = distance(features(i,:), features(k,:));
        similarity = j ~= optimalLabels(k);
        
        S = S + (dist*W(1) + similarity*W(2)) / (lenN);
        
    end
    
    E = D+S;
end

function d = distance( X, Y )
    d = sum(abs(X-Y))/length(X);
end

