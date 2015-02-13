function saveFeatures( folder_name, features, featuresNoColour )

    save([folder_name '/features.mat'], 'features');
    save([folder_name '/featuresNoColour.mat'], 'featuresNoColour');

end

