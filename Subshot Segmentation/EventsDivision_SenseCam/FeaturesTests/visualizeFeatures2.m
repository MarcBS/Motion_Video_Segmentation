
%% 
%   This script is only used for feature visualization purposes.
%%%%

addpath('..');
addpath('../..');
addpath('../../..');

%% Data params
path_data = '../../EventsDivision_SenseCam/Datasets';
folder_data = {'0BC25B01-7420-DD20-A1C8-3B2BD6C87CB0_1to4255'; '2E1048A6ECT_1to1156'; ...
    '5FA739A3-AAC4-E84B-F7CB-2179AD879AE3_1to285'; '6FD1B048-A2F2-4CAB-1EFE-266503F59CD3_1to3537'; ...
    '8B6E4826-77F5-66BF-FCBA-4054D0E84B0B_1to3306'; '16F8AB43-5CE7-08B0-FD11-BA1E372425AB_1to3233'; ... 
    '819DC958-7BFE-DCC8-C792-B54B9641AA75_1to4095'; 'A06514ED-60B5-BF77-5549-2ED885FD7788_1to3303'; ...
    'B07CCAA9-FEBF-E8F3-B637-B021D652CA48_1to4278'; 'D3B168F2-40C8-7BAB-5DA2-4577404BAC7A_1to4311'};
classesShort = {'T', 'S', 'M'};
classes = {'In Transit', 'Static', 'Moving Camera'}; % In Transit, Static, Moving Camera
classesColour = ['r'; 'g'; 'b'];

% Parameters
elemsToShow = 3900; % 3900, 200
typeGraphic = 'mean'; % 'normal', 'mean', 'variance' or 'var7'
consecutive = false;
W = 5;

featuresNum = [9 81 8 9 9];
featuresType = {'C', 'H', 'S', 'B', 'D'}; % (Colour, HOG, SIFT Flow, Blurriness)
featuresTypeLong = {'Colour', 'HOG', 'SIFT Flow', 'Blurriness', 'Color Difference'};

% showingFeatures = (9+81+1):(9+81+8+9+9);
showingFeatures = 99:107;

%% Preparation of the features axes strings for printing the result
rowFeatures = {};
count = 1;
countInserted = 1;
for i = 1:length(featuresType)
    for j = 1:featuresNum(i)
        if(~isempty(find(showingFeatures==count)))
            rowFeatures{countInserted} = [featuresType{i} num2str(j)];
            countInserted = countInserted+1;
        end
        count = count+1;
    end
end

%% Features and labels collecting
numFolders = length(folder_data);
nClasses = length(classes);
f = [];
labels = [];
for idFold = 1:numFolders
    load([path_data '/' folder_data{idFold} '/labels_result.mat']); % labels_result
    load([path_data '/' folder_data{idFold} '/features.mat']); % features
    f = [f; features];
    labels = [labels labels_result(:).label];
end
features = f;
features = standarize(features);


%% Find "elemsToShow" consecutive images for each class
haveClass = zeros(1, nClasses);
idsClasses = zeros(nClasses, elemsToShow);
if(consecutive)
    i = 1;
    label_consecutive = 0;
    while(sum(haveClass) < nClasses && i <= length(labels))
        if(labels(i) == label_consecutive)
            if(~haveClass(label_consecutive)) % if we do not have a set of consecutive images for this label
                count_consecutive = count_consecutive+1;
                this_consecutive(count_consecutive) = i;
                if(sum(this_consecutive==0) == 0) % finished finding samples of this label
                    haveClass(label_consecutive) = 1;
                    idsClasses(label_consecutive, :) = this_consecutive;
                end
            end
        else % finished consecutive labels in a row
            this_consecutive = zeros(1, elemsToShow);
            count_consecutive = 1;
            label_consecutive = labels(i);
            this_consecutive(1) = i;
        end
        i = i+1;
    end
% Pick "elemsToShow" samples randomly
else
    for c = 1:nClasses
        if(elemsToShow <= length(find(labels==c)))
            idsClasses(c, :) = randsample(find(labels==c), elemsToShow);
            haveClass(c) = 1;
        end
    end
end

%% Plot information obtained
if(sum(haveClass) == nClasses) % found enough samples for all classes
    
    % Calculate mean for each class
    if(strcmp(typeGraphic, 'mean'))
        f=figure;
        meanClasses = zeros(nClasses, length(showingFeatures));
        for c = 1:nClasses
            meanClasses(c, :) = mean(features(idsClasses(c, :), showingFeatures));
            line(1:length(showingFeatures), meanClasses(c,:), 'Color', classesColour(c), 'LineWidth', 2);
            hold all;
        end
        addText = ' Mean';
    
    elseif(strcmp(typeGraphic, 'variance'))
        f=figure;
        varClasses = zeros(nClasses, length(showingFeatures));
        for c = 1:nClasses
            varClasses(c, :) = var(features(idsClasses(c, :), showingFeatures));
            line(1:length(showingFeatures), varClasses(c,:), 'Color', classesColour(c), 'LineWidth', 2);
            hold all;
        end
        addText = ' Variance';
        
    elseif(strcmp(typeGraphic, 'var7'))
        hW = floor(W/2);
        feat_aux = {};
        feat = {};
        % Get features for the selected samples
        for c = 1:nClasses
            feat_aux{c} = features(idsClasses(c, :), showingFeatures);
            feat{c} = zeros(size(idsClasses,2)-hW*2, length(showingFeatures));
        end
        % Calculate variances in groups of W consecutive samples
        for c = 1:nClasses
            count = 1;
            for i = (hW+1):(size(idsClasses,2)-hW)
                feat{c}(count,:) = var(feat_aux{c}((i-hW):(i+hW), :));
                count = count +1;
            end
        end
        % Plot result
        f=figure;
        for i = 1:(elemsToShow-hW*2)
            for c = 1:nClasses
                line(1:length(showingFeatures), feat{c}(i, showingFeatures), 'Color', classesColour(c), 'LineWidth', 2);
                hold all;
            end
        end
        addText = [' Variance for each ' num2str(W) ' consecutive samples.'];
        
    elseif(strcmp(typeGraphic, 'normal'))
        % Plot features for each sample
        f=figure;
        for i = 1:elemsToShow
            for c = 1:nClasses
                line(1:length(showingFeatures), features(idsClasses(c, i), showingFeatures), 'Color', classesColour(c), 'LineWidth', 2);
                hold all;
            end
        end
        addText = '';
        
    end
    
    
    xticklabel_rotate(1:length(showingFeatures), 90, rowFeatures, 'FontSize', 16,'interpreter','none');
%     xtick = get(gca, 'xTick');
%     txt = text(1:sum(featuresNum), repmat(0, 1, sum(featuresNum)), rowFeatures, 'HorizontalAlignment', 'right', 'Rotation', 90);
%     set(xtick, txt);
    xlabel('Features', 'FontSize', 16);
    ylabel(['Feature Value' addText], 'FontSize', 16);
    title('Comparison of the features on each class', 'FontSize', 16);
    set(gca,'FontSize',16);
    legend(classes, 0);
    
    %% Save result
    if(strcmp(typeGraphic, 'mean'))
        saveas(f, 'Features Comparison Mean.jpg');
    elseif(strcmp(typeGraphic, 'variance'))
        saveas(f, 'Features Comparison VarianceAll.jpg');
    elseif(strcmp(typeGraphic, 'var7'))
        saveas(f, 'Features Comparison Variance.jpg');
    elseif(strcmp(typeGraphic, 'normal'))
        saveas(f, 'Features Comparison.jpg');
    end
    
else
    disp('Not enough consecutive samples for all classes:');
    disp(classesShort);
    disp(haveClass);
end

