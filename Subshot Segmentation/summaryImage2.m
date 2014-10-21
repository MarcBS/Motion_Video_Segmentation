
% Creates a summary image of all the events extracted from the set of
% images.
%
% props: final proportions of the images
% num_clusters: number of events extracted from the set
% n_summaryImages: number of images shown for each event
% result_data: cell structure with lists of images' ids for each event
% fileList: list of files where the images are stored or video loaded
% source: path to the directory where the images are ('' if using video)
% source_type: type of the source {images, video}
% ini: initial image for the video extraction (0 if source_type == images)
% labels_text: labels assigned to each of the events (leave empty [] for
%               not writing it).
function [ gen_image ] = summaryImage2( props, num_clusters, n_summaryImages, result_data, fileList, source, source_type, ini, labels_text )

    colours = {[1 0 0]; [0 1 0]; [0 0 1]};
    labels = {'T'; 'S'; 'M'};

    maxWidth = 200;

    gen_image = uint8(ones(props(1)*ceil(length({result_data{:}})/maxWidth), props(2)*(maxWidth-1), 3)*255);

    
    countY = 1;
    countX = 1;
    for i = 1:num_clusters
        this_c = result_data{i};
        n_elems = length(this_c);
        
        for j = 1:n_elems
        
            idLabel = find(ismember(labels, labels_text(i)));

            im = uint8(ones(props(1), props(2), 3));
            im(:,:,1) = im(:,:,1) * colours{idLabel}(1)*255;
            im(:,:,2) = im(:,:,2) * colours{idLabel}(2)*255;
            im(:,:,3) = im(:,:,3) * colours{idLabel}(3)*255;

            y1 = ((countX-1)*props(1)+1);
            y2 = (countX*props(1));
            x1 = ((countY-1)*props(2)+1);
            x2 = (countY*props(2));
            gen_image( x1:x2, y1:y2, 1 ) = im(:,:,1);
            gen_image( x1:x2, y1:y2, 2 ) = im(:,:,2);
            gen_image( x1:x2, y1:y2, 3 ) = im(:,:,3);
            
            countX = countX+1;
            if(mod(countX,maxWidth) == 0)
                countX = 1;
                countY = countY+1;
            end

        end

    end

end

