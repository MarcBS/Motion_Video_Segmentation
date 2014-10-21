%% Extracts the SIFT Flow from the input images im1 and im2
% and outputs the result into an nBits histogram
function flow = extractSIFTFlowHist(im1, im2, nBins)
    
    addpath('../SIFTflow');
    addpath('../SIFTflow/mexDenseSIFT');
    addpath('../SIFTflow/mexDiscreteFlow');
    
    % set SIFT flow parameters
    cellsize=3;
    gridspacing=1;

    SIFTflowpara.alpha=2*255;
    SIFTflowpara.d=40*255;
    SIFTflowpara.gamma=0.005*255;
    SIFTflowpara.nlevels=4;
    SIFTflowpara.wsize=2;
    SIFTflowpara.topwsize=10;
    SIFTflowpara.nTopIterations = 60;
    SIFTflowpara.nIterations= 30;

    
    % Preprocesses the images
%     resizeDiv = 5;
%     props = size(im1) / resizeDiv;
%     im1 = imresize(im1, props(1:2));
%     im2 = imresize(im2, props(1:2));
    im1 = im2double(imresize(imfilter(im1,fspecial('gaussian',7,1.),'same','replicate'),0.5,'bicubic'));
    im2 = im2double(imresize(imfilter(im2,fspecial('gaussian',7,1.),'same','replicate'),0.5,'bicubic'));
    
    % Calculates sift flow
    sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
    sift2 = mexDenseSIFT(im2,cellsize,gridspacing);

    [vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);
    
%     % Gets the degrees for each angle
%     deg = acosd(vx./hypot(vx, vy));
%     
%     % Gets the histogram with nBins
%     flow2 = zeros(1,nBins);
%     flow2(1, :) = hist(deg(:), nBins)';
    
    %% SIFT_Flow histogram using the same techinque than HOG (using magnitudes)
    angles=atan2(vy,vx);
    magnit=((vy.^2)+(vx.^2)).^.5;

    v_angles=angles(:);    
    v_magnit=magnit(:);
    K=max(size(v_angles));

    %assembling the histogram with 9 bins (range of 20 degrees per bin)
    bin=0;
    flow=zeros(1,nBins);
    for ang_lim=-pi+2*pi/nBins:2*pi/nBins:pi
        bin=bin+1;
        for k=1:K
            if v_angles(k)<ang_lim
                v_angles(k)=100;
                flow(bin)=flow(bin)+v_magnit(k);
            end
        end
    end

    flow = flow/(norm(flow)+0.01);
    
    
end
