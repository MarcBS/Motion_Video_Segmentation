
%% Performing simple tests about the SIFT features


addpath('../../../SIFT');
run ../../../SIFT/vlfeat-0.9.16/toolbox/vl_setup

%% SIFT Parameters
r = 2.5; % Edge threshold: More EdgeThreshold --> More permisivity
pt = 3.5; % Peak threshold: Less PeakThreshold --> More permisivity
mt = 1.5; % Match threshold: Less Match threshold --> More permisivity

%% Images loading
img_folder = 'D:\Documentos\Vicon Revue Data\16F8AB43-5CE7-08B0-FD11-BA1E372425AB/';
% imgsTstr = {'00009561.jpg', '00009562.jpg'};
imgsTstr = {'00010849.jpg', '00010850.jpg'};
imgsSstr = {'00011161.jpg', '00011162.jpg'};

% Loading test (class In Transit) and static (class Static) images.
imgsT = {};
for i = 1:length(imgsTstr)
    imgsT{i} = single(rgb2gray(imread([img_folder imgsTstr{i}])));
end
imgsS = {};
for i = 1:length(imgsSstr)
    imgsS{i} = single(rgb2gray(imread([img_folder imgsSstr{i}])));
end



%% Execute SIFT on each image (In Transit)
% Less PeakThreshold --> More permisivity
% More EdgeThreshold --> More permisivity
[fT1, dT1] = vl_sift(imgsT{1}, 'PeakThresh', pt, 'EdgeThresh', r);
[fT2, dT2] = vl_sift(imgsT{2}, 'PeakThresh', pt, 'EdgeThresh', r);

% Show keypoints for each image
% figure;show_keypoints(imgT1, fT1);
% figure;show_keypoints(imgT2, fT2);

% Performs a matching between the 2 images
[matches, scores] = vl_ubcmatch(dT1, dT2, mt);
figure;show_matches(imgsT{1},imgsT{2},fT1,fT2,matches);


%% Execute SIFT on each image (Static)
% Less PeakThreshold --> More permisivity
% More EdgeThreshold --> More permisivity
[fS1, dS1] = vl_sift(imgsS{1}, 'PeakThresh', pt, 'EdgeThresh', r);
[fS2, dS2] = vl_sift(imgsS{2}, 'PeakThresh', pt, 'EdgeThresh', r);

% Show keypoints for each image
% figure;show_keypoints(imgT1, fT1);
% figure;show_keypoints(imgT2, fT2);

% Performs a matching between the 2 images
% Less Match threshold --> More permisivity
[matches, scores] = vl_ubcmatch(dS1, dS2, mt);
figure;show_matches(imgsS{1},imgsS{2},fS1,fS2,matches);




