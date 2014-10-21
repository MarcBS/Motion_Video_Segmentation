%% Penalization between consecutive similar images with different labels
function data2cluster = penalizeConsecutiveImages( data2cluster, n, N, features )

    global nBinsPerColor;
    global thres_penal;
    global min_dif_row;

    for i = (n+1):N
        if(data2cluster(i) ~= 0)
            prev = i-1;
            while(prev > 0 && data2cluster(prev) == 0)
                prev = prev-1;
            end
            if(prev > 0)
                if(data2cluster(prev) ~= data2cluster(i))
                    if(pdist2(features(prev, 1:nBinsPerColor*3), features(i, 1:nBinsPerColor*3)) < thres_penal)
                        data2cluster(i) = data2cluster(prev);
                    else
                        % If there is a row of images of size "min_dif_row - 1"
                        % or less, that are between a couple of images
                        % with low distance, then we delete that row
                        to_delete = [prev];
                        go_on = true;
                        j = 2;
                        while(go_on && j <= min_dif_row)
                            prev = prev-1;
                            while(prev > 0 && data2cluster(prev) == 0)
                                prev = prev-1;
                            end
                            if(prev > 0)
                                if(pdist2(features(prev, 1:nBinsPerColor*3), features(i, 1:nBinsPerColor*3)) > thres_penal)
                                    to_delete = [to_delete prev];
                                else
                                    go_on = false;
                                end
                            else
                                go_on = false;
                            end
                            j=j+1;
                        end
                        % If finished successfuly finding a row shorter than "min_dif_row":
                        if(length(to_delete) > 0 && length(to_delete) <= (min_dif_row-1))
                            data2cluster(to_delete) = 0;
                        end
                    end
                end
            end
        end
    end

end

