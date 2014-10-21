%% Performing simple tests about the SIFT Flow features

addpath('../../../SIFTflow');
addpath('../../../SIFTflow/mexDenseSIFT');
addpath('../../../SIFTflow/mexDiscreteFlow');


resizeDiv = 5;

%% SIFT Flow parameters
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


%% Images loading
img_folder = 'D:\Documentos\Vicon Revue Data\16F8AB43-5CE7-08B0-FD11-BA1E372425AB/';
% imgsTstr = {'00009561.jpg', '00009562.jpg'};
imgsTstr = {'00010849.jpg', '00010850.jpg'};
% imgsTstr = {'00009611.jpg', '00009612.jpg'};
% imgsTstr = {'00010134.jpg', '00010135.jpg'};

imgsSstr = {'00011161.jpg', '00011162.jpg'};
% imgsSstr = {'00011864.jpg', '00011865.jpg'};

% imgsMstr = {'00009484.jpg', '00009485.jpg'};
imgsMstr = {'00009466.jpg', '00009467.jpg'};

labelUsing = 'S';


% % test, delete lines
% img_folder = 'D:\Video Summarization Project\Code\SIFT\vlfeat-0.9.16\data/';
% imgsTstr = {'roofs2.jpg', 'roofs1.jpg'};

% Loading test (class In Transit) and static (class Static) images.
imgsT = {};
for i = 1:length(imgsTstr)
%     imgsT{i} = single(rgb2gray(imread([img_folder imgsTstr{i}])));
    imgsT{i} = imread([img_folder imgsTstr{i}]);
    props = size(imgsT{i}) / resizeDiv;
    imgsT{i} = imresize(imgsT{i}, props(1:2));
    imgsT{i} = im2double(imresize(imfilter(imgsT{i},fspecial('gaussian',7,1.),'same','replicate'),0.5,'bicubic'));
    
end
imgsS = {};
for i = 1:length(imgsSstr)
%     imgsS{i} = single(rgb2gray(imread([img_folder imgsSstr{i}])));
    imgsS{i} = imread([img_folder imgsSstr{i}]);
    props = size(imgsS{i}) / resizeDiv;
    imgsS{i} = imresize(imgsS{i}, props(1:2));
    imgsS{i} = im2double(imresize(imfilter(imgsS{i},fspecial('gaussian',7,1.),'same','replicate'),0.5,'bicubic'));
    
end
imgsM = {};
for i = 1:length(imgsMstr)
%     imgsS{i} = single(rgb2gray(imread([img_folder imgsSstr{i}])));
    imgsM{i} = imread([img_folder imgsMstr{i}]);
    props = size(imgsM{i}) / resizeDiv;
    imgsM{i} = imresize(imgsM{i}, props(1:2));
    imgsM{i} = im2double(imresize(imfilter(imgsM{i},fspecial('gaussian',7,1.),'same','replicate'),0.5,'bicubic'));
    
end


%% Aplication of the SIFT Flow on the Static images
if(strcmp(labelUsing, 'S'))
    sift1 = mexDenseSIFT(imgsS{1},cellsize,gridspacing);
    sift2 = mexDenseSIFT(imgsS{2},cellsize,gridspacing);

    tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc
    % tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,'');toc

    warpI2=warpImage(imgsS{2},vx,vy);
    figure,subplot(2,2,1),imshow(imgsS{1}), title('Image 1');

    % display flow
    clear flow;
    flow(:,:,1)=vx;
    flow(:,:,2)=vy;
end


%% Aplication of the SIFT Flow on the In Transit images
if(strcmp(labelUsing, 'T'))
    sift1 = mexDenseSIFT(imgsT{1},cellsize,gridspacing);
    sift2 = mexDenseSIFT(imgsT{2},cellsize,gridspacing);

    tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc
    % tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,'');toc

    warpI2=warpImage(imgsT{2},vx,vy);
    figure,subplot(2,2,1),imshow(imgsT{1}), title('Image 1');

    % display flow
    clear flow;
    flow(:,:,1)=vx;
    flow(:,:,2)=vy;
end


%% Aplication of the SIFT Flow on the Moving Camera images
if(strcmp(labelUsing, 'M'))
    sift1 = mexDenseSIFT(imgsM{1},cellsize,gridspacing);
    sift2 = mexDenseSIFT(imgsM{2},cellsize,gridspacing);

    tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc
    % tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,'');toc

    warpI2=warpImage(imgsM{2},vx,vy);
    figure,subplot(2,2,1),imshow(imgsM{1}), title('Image 1');

    % display flow
    clear flow;
    flow(:,:,1)=vx;
    flow(:,:,2)=vy;
end


%% Plotting the flow images

deg = acosd(vx./hypot(vx, vy));


% Draws the optical flow arrows
props = size(vx) / 10;
vx = imresize(vx, props);
vy = imresize(vy, props);

u = reshape(vx',1,size(vx,1)*size(vx,2));
v = reshape(vy',1,size(vy,1)*size(vy,2));
y = reshape(repmat((1:size(vx,1))', 1, size(vx,2))', 1, size(vy,1)*size(vy,2));
x = repmat(1:size(vx,2), 1, size(vx,1));



subplot(2,2,2),imshow(warpI2), title('Image 2 warped over image 1');
subplot(2,2,3),imshow(flowToColor(flow)), title('SIFT Flow coloured');
subplot(2,2,4),quiver(x,y,u,v), title('SIFT Flow arrows');

disp('Done');



