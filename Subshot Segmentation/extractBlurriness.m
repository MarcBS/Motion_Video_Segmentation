function [ IDM ] = extractBlurriness( img, FiltSize, nCellsBlurriness )

    %%%%%%%%%%
    %
    %   INPUT
    %   
    %   img --> Image in Double format
    %   FiltSize --> suggested value 9, see PerceptualBlurMetric
    %   nCellsBlurriness --> division made to the image for blur
    %       calculation cell by cell
    %
    %%%%%%%%%%
    %
    %   OUTPUT
    %
    %   IDM --> array of blurriness for each cell. Having values from 0
    %   (minimum blurriness) to 1 (maximum blurriness), see
    %   PerceptualBlurMetric.
    %
    %%%%%%%%%%
    
    img = rgb2gray(img);
    props = size(img);
    
    IDM = zeros(1, nCellsBlurriness(1)*nCellsBlurriness(2));
    
    for i = 1:nCellsBlurriness(1)
        for j = 1:nCellsBlurriness(2)
            y1 = floor(props(1)/nCellsBlurriness(1)) * (i-1) +1;
            y2 = floor(props(1)/nCellsBlurriness(1)) * i;
            x1 = floor(props(2)/nCellsBlurriness(2)) * (j-1) +1;
            x2 = floor(props(2)/nCellsBlurriness(2)) * j;
            cellImg = img( y1:y2, x1:x2 );
            IDM((j-1)*nCellsBlurriness(1) + i) = PerceptualBlurMetric(cellImg, 9);
        end
    end

end

