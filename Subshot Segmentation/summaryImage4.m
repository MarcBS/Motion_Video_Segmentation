
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
function [ gen_image ] = summaryImage4( props, fileList, source )

    maxWidth = 200;

    gen_image = uint8(ones(props(1)*ceil(length(fileList)/maxWidth), props(2)*(maxWidth-1), 3)*255);
    
    countY = 1;
    countX = 1;
    for i = 1:length(fileList)
        
        im = imread([source '/' fileList(i).name]);

        im = imresize(im, props);
        x1 = ((countX-1)*props(2)+1);
        x2 = (countX*props(2));
        y1 = ((countY-1)*props(1)+1);
        y2 = (countY*props(1));
        gen_image( y1:y2, x1:x2, 1 ) = im(:,:,1);
        gen_image( y1:y2, x1:x2, 2 ) = im(:,:,2);
        gen_image( y1:y2, x1:x2, 3 ) = im(:,:,3);

        countX = countX+1;
        if(mod(countX,maxWidth) == 0)
            countX = 1;
            countY = countY+1;
        end
        
    end

end

