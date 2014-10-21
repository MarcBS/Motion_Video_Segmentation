function [ features ] = extractFeatures( video, ini, fin, nBinsPerColor, nBinsMotion, nCellsBlurriness )
%% Extracts colour, motion and blurriness features from the given video.
%
%   INPUT
%       video: video object with all the images.
%       ini: starting image position.
%       fin: final image position.
%       nBinsPerColor: number of bins per color that will be used on the
%           final features representation.
%       nBinsMotion: number of beans that will be used on the final
%           features representation of the SIFT-Optical Flow.
%       nCellsBlurriness: vector [rows cols] indicating the division of 
%           the image in cells of the blurriness detector.
%
%   OUTPUT
%       features: matrix of features extracted from the images, with
%           dimensions [fin-ini, nBinsPerColor * 3 + nBinsMotion +
%                                nCellsBlurriness(1) * nCellsBlurriness(2)].
%
%%%%

    %% Video params
    height = video.Height;
    width = video.Width;

    N = fin-ini+1;
    pos = ini:fin;

    %% Get features
    % Gets Color Histogram (3 bins x 3 colours), Motion (8 bins) and Blurriness (3x3 cells per image, 9)
    % Total = 9 + 8 + 9 = 26 features
    disp('Starting feature extraction...');

    features = zeros(N-1, nBinsPerColor*3 + nBinsMotion + nCellsBlurriness(1)*nCellsBlurriness(2));
    im1 = im2double(read(video, pos(1)));
    for i = 2:N
        im2 = im2double(read(video, pos(i)));
        
        %% Colour
        colour = zeros(3, nBinsPerColor);
        for j = 1:3
            colour(j, :) = imhist(im2(:,:,j), nBinsPerColor)';
        end
        features(i-1, 1:nBinsPerColor*3) = [colour(1,:) colour(2,:) colour(3,:)];

        %% Motion
        cd ..;
        features(i-1, (nBinsPerColor*3+1):(nBinsPerColor*3+nBinsMotion)) = extractFlowHist(im1, im2, nBinsMotion);
        cd('EventsDivision_Grauman');

        %% Blurriness
        features(i-1, (nBinsPerColor*3+nBinsMotion+1):end) = extractBlurriness(im2, 9, nCellsBlurriness); % Gets the blurriness of the image

        if(mod(i,10)==0 && i ~= N)
            disp(['Features extraction progress: ' num2str(i) '/' num2str(N)]);
        end
        im1 = im2;
    end
    disp(['Features extraction complete! ' num2str(i) '/' num2str(N)]);


end

