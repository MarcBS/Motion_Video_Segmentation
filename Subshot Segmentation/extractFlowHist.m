%% Extracts the Optical Flow from the input images im1 and im2
% and outputs the result into an nBits histogram
function flow = extractFlowHist(im1, im2, nBins)
    
    addpath('../OpticalFlow');
    addpath('../OpticalFlow/mex');
    
    
    % set optical flow parameters (see Coarse2FineTwoFrames.m for the definition of the parameters)
    alpha = 0.012;
    ratio = 0.5;
    minWidth = 50;
    nOuterFPIterations = 1;
    nInnerFPIterations = 3;
    nSORIterations = 5;
    
    % other parameters
%     alpha = 0.012;
%     ratio = 0.25;
%     minWidth = 20;
%     nOuterFPIterations = 7;
%     nInnerFPIterations = 1;
%     nSORIterations = 30;

    para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];
    
    % compute optical flow
    [vx,vy,warpI2] = Coarse2FineTwoFrames(im1,im2, para);
%     [vx,vy,warpI2] = Coarse2FineTwoFrames(im1,im2);
    
    
    % image only for optical flow visualization
% %     clear imflow
% %     imflow(:,:,1) = vx;
% %     imflow(:,:,2) = vy;
% %     imflow = flowToColor(imflow);
% % 
% %     imwrite(imflow,fullfile(['im_flow' num2str(i) '.jpg']),'quality',100);
    
    
    % Translate the data into degrees and into nBins
    deg = acosd(vx./hypot(vx, vy));
    
    flow2 = zeros(1,nBins);
    flow2(1, :) = hist(deg(:), nBins)';

    %% Optical Flow histogram using the same techinque than HOG (using magnitudes)
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
