
%%%%%%% For using this file, comment "loadParameters" line in mainSubshotsClassification.m

%% Datasets parameters
source = '/Volumes/SHARED HD/Video Summarization Project Data Sets/R-Clustering';

cameras = {'Narrative', 'Narrative', 'Narrative', 'Narrative', 'Narrative', 'SenseCam', 'SenseCam', 'SenseCam', 'SenseCam', 'SenseCam'};
folders={'Estefania1', 'Estefania2', 'Petia1', 'Petia2', 'Mariella', 'Day1','Day2','Day3','Day4','Day6'};
formats={'.jpg', '.jpg', '.jpg', '.jpg', '.jpg', '.JPG','.JPG','.JPG','.JPG','.JPG'};

results_folder = '/Volumes/SHARED HD/R-Clustering Results';

%% Method Parameters
loadParameters;


%% Start test for all folders
for i_fold = 1:length(folders)

    % Get folder info
    video_name = folders{i_fold};
    camera = cameras{i_fold};
    format = formats{i_fold};
    
    % Execute main classification
    mainSubshotsClassification;
    
    % Store results
    Results_Motion.fMeasure_Motion = vec_perC;
    Results_Motion.Wpairwise_tested = w_values;
    save([results_folder '/' video_name '/Results_Motion-Based_' video_name '.mat'], 'Results_Motion');
end