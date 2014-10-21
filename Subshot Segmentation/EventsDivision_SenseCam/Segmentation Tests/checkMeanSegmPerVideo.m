
%%
%
%   Checks the average number of segmentations per video and the relative
%   number of frames per segmentation in each one.
%
%%%%

folder_segm = 'D:\Video Summarization Project\Results\SenseCam Segmentation\Labeling SenseCam';

files = dir([folder_segm '/*.txt']);

sequences_total = [];
% Show info for each file
disp(' ');
for i = 1:length(files)
    
    %% Reads file
    offset = 1;
    sequences = []; labels = {};
    count = 1;
    fid = fopen([folder_segm '/' files(i).name], 'r');
    while ~feof(fid)
        line = fgets(fid);
        line = strread(line, '%s', 'delimiter', ' ');

        len = str2num(line{3}) - str2num(line{1}) + 1;
        sequences = [sequences len];

        labels{count} = line{4};
        count = count +1;
    end
    sequences_total = [sequences_total sequences];
    
    %% Reads name
    name = regexp(files(i).name, '_', 'split');
    name = regexp(name{2}, '\.', 'split');
    name = name{1};
    disp(['File name: ' name]);
    
    %% Shows segmentation info
    disp(['Number of images: ' num2str(sum(sequences))]);
    disp(['Number of events: ' num2str(length(sequences))]);
    disp(['Mean frames per event: ' num2str(sum(sequences)/length(sequences))]);
    
    disp(' ');
end

%% Show global results
disp('######################################################');
disp('GLOBAL RESULTS:');
disp(' ');

disp(['Number of images: ' num2str(sum(sequences_total))]);
disp(['Number of events: ' num2str(length(sequences_total))]);
disp(['Mean frames per event: ' num2str(sum(sequences_total)/length(sequences_total))]);

disp('######################################################');


