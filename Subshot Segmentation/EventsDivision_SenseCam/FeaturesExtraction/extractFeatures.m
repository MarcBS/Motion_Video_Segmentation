function [ features ] = extractFeatures( source, fileList, ini, fin, nBinsPerColor, lenHOG, nBinsSIFTFlow, nCellsBlurriness )
%% Extracts colour, motion and blurriness features from the given video.
%
%   INPUT
%       source: source folder of the images.
%       fileList: list of images from which we have to extract their
%           features
%       ini: starting image position.
%       fin: final image position.
%       nBinsPerColor: number of bins per color that will be used on the
%           final features representation.
%       lenHOG: length of the HOG vector extracted [rows, cols, nGradients].
%       nBinsMotion: number of beans that will be used on the final
%           features representation of the SIFT-Optical Flow.
%       nCellsBlurriness: vector [rows cols] indicating the division of 
%           the image in cells of the blurriness detector.
%
%   OUTPUT
%       features: matrix of features extracted from the images, with
%           dimensions [fin-ini, nBinsPerColor * 3 + lenHOG(1) * lenHOG(2)
%                                * lenHOG(3) + nBinsMotion +
%                                nCellsBlurriness(1) * nCellsBlurriness(2) 
%                                + nBinsPerColor * 3].
%
%%%%

    %% Video params
    CW = 5; % colour difference applyed over the previous CW images.
%     resizeDiv = 5;
    maxSize = 410; % maximum size of the larger side in pixels
    
    N = fin-ini+1;
    pos = ini:fin;
    
    HOGResize = [80 108];

    %% Get features
    % Gets Color Histogram (3 bins x 3 colours), lenHOG (3x3 cells x 9
    % gradients), Motion (8 bins), Blurriness (3x3 cells per image, 9) and
    % Color Difference (like Color Histogram but performing the difference
    % between the current image and the mean of the previous CW images).
    % Total = 9 + 81 + 8 + 9 + 9 = 116 features
    disp('Starting feature extraction...');

    features = zeros(N-1, nBinsPerColor*3 + lenHOG(1)*lenHOG(2)*lenHOG(3) + nBinsSIFTFlow + nCellsBlurriness(1)*nCellsBlurriness(2) + nBinsPerColor*3);
    im1 = im2double(imread([source '/' fileList(pos(1)).name]));
    % Resize 
%     props = size(im1) / resizeDiv;
    props = size(im1) ./ (max(size(im1))/maxSize);
    im1 = imresize(im1, props(1:2));
    for i = 2:N
%     for i = 600:N
        im2 = im2double(imread([source '/' fileList(pos(i)).name]));
        im2 = imresize(im2, props(1:2));
        
        %% Colour
        colour = zeros(3, nBinsPerColor);
        for j = 1:3
            colour(j, :) = imhist(im2(:,:,j), nBinsPerColor)';
        end
        features(i-1, 1:nBinsPerColor*3) = [colour(1,:) colour(2,:) colour(3,:)];

        %% HOG
        im2resize = imresize(im2, HOGResize);
        features(i-1, (nBinsPerColor*3+1):(nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3))) = HOGparam(rgb2gray(im2resize), lenHOG(1), lenHOG(2), lenHOG(3));
        
        %% SIFT-Flow, Motion
        cd ..;
        features(i-1, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+1):(nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+nBinsSIFTFlow)) = extractSIFTFlowHist(im1, im2, nBinsSIFTFlow);
        cd('EventsDivision_SenseCam');

        %% Blurriness
        features(i-1, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+nBinsSIFTFlow+1):(nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+nBinsSIFTFlow+nCellsBlurriness(1)*nCellsBlurriness(2))) = extractBlurriness(im2, 9, nCellsBlurriness); % Gets the blurriness of the image
 
        %% Color Difference
        if(i == 2) % if first image
            colour = zeros(3, nBinsPerColor);
            for j = 1:3
                colour(j, :) = imhist(im1(:,:,j), nBinsPerColor)';
            end
            features(i-1, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+nBinsSIFTFlow+nCellsBlurriness(1)*nCellsBlurriness(2)+1):end) = features(i-1, 1:nBinsPerColor*3) - mean([colour(1,:) colour(2,:) colour(3,:)]);
        else % performs the difference of colour between the current image and the previous CW ones as maximum.
            minCol = max(1, i-1-CW);
            features(i-1, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+nBinsSIFTFlow+nCellsBlurriness(1)*nCellsBlurriness(2)+1):end) = features(i-1, 1:nBinsPerColor*3) - mean(features(minCol:(i-2), 1:nBinsPerColor*3));
        end
        
        %% Progress printing
        if(mod(i,50)==0 && i ~= N)
            disp(['Features extraction progress: ' num2str(i) '/' num2str(N)]);
        end
        im1 = im2;
    end
    disp(['Features extraction complete! ' num2str(i) '/' num2str(N)]);


end

