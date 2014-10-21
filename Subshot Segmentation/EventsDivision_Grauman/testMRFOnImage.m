
function main()

    addpath('../../GCMex');
    addpath('..');

    img = imread('D:\Documentos\Dropbox\MAI Compartit\CV\Practica1\P2\Code\imagesP2/images65.jpg');
    [h, w, c] = size(img);
    figure(4);imshow(img);
    img = imresize(img, [h/5 w/5]);
    
    img_G = rgb2gray(img);
    

    % Number of different segmentation colours
    nClasses = 3;
    resultColours = [1 0 0; 0 1 0; 0 0 1; 0.5 0.5 0; 0 0.5 0.5];
    maxIter = 2;
    th = 0;

    % Builds features vector
    [h, w, c] = size(img);
    nSamples = h*w;
    features = zeros(nSamples, c);
    for i = 1:c
        features(:,i) = reshape(img(:,:,i)', nSamples, 1);
    end
    colour = features;
    [colour, ~, ~] = normalize(colour);

    % Initializes likelihoods
    LH = ones(nSamples, nClasses)*(1/2/(nClasses-1));
    thres = 255*3/nClasses;
    for i = 1:h
        for j = 1:w
            this_p = (i-1)*w+j;
            found = false; k = nClasses;
            while (k > 0 && ~found)
                if(sum(img(i,j,:)) >= thres*(k-1))
                    found = true;
                    LH(this_p, k) = 0.5;
                end
                k = k-1;
            end
        end
    end
    
    figure;
    imshow(getResultImg(resultColours, LH, h, w));
    title('Original Segmentation');
    originalLH = LH;
    GT = getClassFromLH(originalLH);
%     [~, GT] = max(originalLH, [], 2);
    
    % Inserts random noise
    prob = 0.37;
    for i = 1:nSamples
        if(rand(1) <= prob)
            change = randi(nClasses-1, 1, 1);
            LH(i,:) = circshift(LH(i,:)',change)';
        end
    end
    figure;
    imshow(getResultImg(resultColours, LH, h, w));
    title('Random Noise');
    modifiedLH = LH;
    labelsMod = getClassFromLH(modifiedLH);
%     [~, labelsMod] = max(modifiedLH, [], 2);

    % Adjacency matrix
%     adj = zeros(nSamples, nSamples);
    adj = sparse(nSamples, nSamples);
    for i = 1:h
        for j = 1:w
            %   x5  x1  x6
            %   x2  x   x3
            %   x7  x4  x8
            if(i > 1) adj((i-2)*w+j, (i-1)*w+j) = 1; end % x1
            if(j > 1) adj((i-1)*w+j-1, (i-1)*w+j) = 1; end % x2
            if(j < w) adj((i-1)*w+j+1, (i-1)*w+j) = 1; end % x3
            if(i < h) adj((i)*w+j, (i-1)*w+j) = 1; end % x4
            if(i > 1 && j > 1) adj((i-2)*w+j-1, (i-1)*w+j) = 1; end % x5
            if(i > 1 && j < w) adj((i-2)*w+j+1, (i-1)*w+j) = 1; end % x6
            if(j > 1 && i < h) adj((i)*w+j-1, (i-1)*w+j) = 1; end % x7
            if(j < w && i < h) adj((i)*w+j+1, (i-1)*w+j) = 1; end % x8
        end
    end
    
    
    % Trying Graph-Cut algorithm
%     [~, CLASS] = max(LH, [], 2);
    CLASS = getClassFromLH(LH);
    % The pairwise potential (adj here) must be higher if the neighbouring variables
    % are similar in some way (colour in this case). Preventing from producing a
    % cut (being separated with different labels) between them when 
    % minimizing the energy.
    for i = 1:nSamples
        neighbours = find(adj(i,:));
%         [~, li] = max(LH(i,:));
        for k = neighbours
%             [~, lk] = max(LH(k,:));
%             adj(i, k) = exp(-( (li==lk) * (distance(colour(i,:), colour(k,:)))  ) );
            adj(i, k) = exp(-distance(colour(i,:), colour(k,:))) / (length(neighbours)*2);
        end
    end

    labelcost = single(ones(nClasses,nClasses));
    for i = 1:nClasses
        labelcost(i,i) = 0;
    end
%     labelcost = single(rand(nClasses));

    cd '../../GCMEx';
    [labels E E_after] = GCMex((CLASS-1)', single(1-LH'), adj, labelcost, 1);
    cd '../Subshot Segmentation/EventsDivision_Grauman';
    labels = labels+1;
    LH_GC = zeros(nSamples, nClasses);
    for i = 1:nSamples 
        LH_GC(i, labels(i)) = 1;
    end
    figure;imshow(getResultImg(resultColours, LH_GC, h, w));
    title('GCMex');
    
    
%     [~, labelsGC] = max(LH_GC, [], 2);
    labelsGC = getClassFromLH(LH_GC);
    disp(['Accuracy with noise: ' num2str(sum(GT==labelsMod)/length(GT))]);
    disp(['Accuracy: ' num2str(sum(GT==labelsGC)/length(GT))]);
    disp('Graph-Cut done.');
    
    
    % Applies MRF
    iter = 0;
    converged = false;
    figure(5);
    imshow(getResultImg(resultColours, LH, h, w));
    
%     LH = (1-LH);

    % version 3
%     [ ~, optimalLabels] = max(LH, [], 2);
    
    while (iter <= maxIter && ~converged)
        %% Ising Model applied
        pLH = LH; % previous LH = pLH
        for i = 1:nSamples
            for j = 1:nClasses
                % If the energy is too high, then we get a similar
                % likelihood to its neighbours
                
                % version 2
%                 if(exp(-energy(i, j, pLH, adj, colour, '')) > 0.5)
%                     neighbours = find(adj(i,:));
%                     nLen = length(neighbours);
%                     LH(i,j) = 0;
%                     for k = neighbours
%                         LH(i,j) = LH(i, j) + LH(k,j);
%                     end
%                     LH(i,j) = LH(i,j)/nLen;
%                 end

                % version 1
                LH(i,j) = energy(i, j, pLH, adj, colour, '');

                % version 3
%                 LH(i,j) = exp(- energy(i, j, pLH, adj, colour, optimalLabels));

            end
            LH(i,:) = LH(i,:) / sum(LH(i,:));
            

        end
        converged = sum(abs(distance(pLH, LH))) <= th;
        iter = iter+1;
        
        [ ~, optimalLabels] = max(LH, [], 2);
        
        if(mod(iter,1)==0)
            % Shows image
            figure(5);
            imshow(getResultImg(resultColours, LH, h, w));
        end
    end
    
    figure(5);
    imshow(getResultImg(resultColours, LH, h, w));
    
    disp('Done');
end


function E = energy(i, j, LH, adj, colour, optimalLabels)
    % version 2 and 3
%     E = 1-LH(i,j);
    % version 1
    E = LH(i,j);
    
    neighbours = find(adj(i,:));
    lenN = length(neighbours);
    for k = neighbours
        % version 3
%         E = E + ( ( j ~= optimalLabels(k) ) * exp( - (distance(colour(i,:), colour(k,:)) ) ) ) / lenN ;
        % version 2
%         E = E + ( abs( LH(i,j) - LH(k,j) ) * exp( - (distance(colour(i,:), colour(k,:)) ^2) ) ) / lenN ;
        % version 1
        E = E - ( ( LH(i,j) - LH(k,j) ) * exp( - (distance(colour(i,:), colour(k,:)) ^2) ) ) / lenN ;
    end
end

function d = distance( X, Y )
%     difs = (X-Y);
%     d = sqrt(sum(difs.^2));
%     d = 1-exp(-d);
    
    d = sqrt(sum((X-Y).^2));
    d = d/length(X);
end



function res = getResultImg(resultColours, LH, h, w)

    res = zeros(h, w, 3);
%     [~, labels] = max(LH,[],2);
    labels = getClassFromLH(LH);
    result_img = resultColours(labels,:);
    result_img = reshape(result_img, [h w 3]);
    for i = 1:3
        res(:,:,i) = reshape(result_img(:,:,i), [w h])';
    end
    res = imresize(res, [h*5, w*5]);
    
end

