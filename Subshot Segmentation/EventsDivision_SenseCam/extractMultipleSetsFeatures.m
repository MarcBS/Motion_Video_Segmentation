source = '/Volumes/SHARED HD/Video Summarization Project Data Sets/R-Clustering';

cameras = {'Narrative', 'Narrative', 'Narrative', 'Narrative', 'Narrative', 'SenseCam', 'SenseCam', 'SenseCam', 'SenseCam', 'SenseCam'};
folders={'Estefania1', 'Estefania2', 'Petia1', 'Petia2', 'Mariella', 'Day1','Day2','Day3','Day4','Day6'};
% folders={'Petia2'};
formats={'.jpg', '.jpg', '.jpg', '.jpg', '.jpg', '.JPG','.JPG','.JPG','.JPG','.JPG'};


extract_features = true;

nBinsPerColor = 3; % max = 256
lenHOG = [3 3 9]; % [rows cols nGradients]
nBinsSIFTFlow = 8;
nCellsBlurriness = [3 3]; % [rows cols]


addpath('..');
addpath('../..');


for i_folder = 1:length(folders)
    video_name = folders{i_folder};
    format = formats{i_folder};
    camera = cameras{i_folder};
    
    disp(['Extracting ' video_name]);
    
    source_ = [source '/' camera '/imageSets/'];
    
    tic
    %% Image retrieval
    fileList = dir([source_ video_name '/*' format]);

    ini = 1;
    fin = length(fileList);

    %% Features extraction
    folder_name = ['Datasets/' video_name '_' num2str(ini) 'to' num2str(fin)];
    if(extract_features)
        features = extractFeatures([source_ '/' video_name], fileList, ini, fin, nBinsPerColor, lenHOG, nBinsSIFTFlow, nCellsBlurriness);
        featuresNoColour = features(:, (nBinsPerColor*3+lenHOG(1)*lenHOG(2)*lenHOG(3)+1):end);

        % Storing features
        mkdir(folder_name);
        save([folder_name '/features.mat'], 'features');
        save([folder_name '/featuresNoColour.mat'], 'featuresNoColour');
    end
    toc
end