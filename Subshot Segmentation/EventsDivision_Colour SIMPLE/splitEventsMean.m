function [ data2cluster ] = splitEventsMean( data2cluster, n, N, features, W2 )

    global nBinsPerColor;
    global thres_split;
    
    for i = (n+1):N
        
        this_c = data2cluster(i);
        prev = i-1;
        if(this_c ~= 0)
            while(prev > 0 && data2cluster(prev) == 0)
                prev = prev-1;
            end
            if(prev > 0)
                if(this_c == data2cluster(prev))
                    idsLeft = [prev];
                    idsRight = [i];
                    j = 1;
                    go_on = true;
                    prev = prev-1;
                    next = i+1;
                    % Finds the W2 left values
                    while(j <= W2 && go_on)
                        while(prev > 0 && data2cluster(prev) == 0)
                            prev = prev-1;
                        end
                        if(prev > 0)
                            if(data2cluster(prev) == this_c)
                                idsLeft = [idsLeft prev];
                            else
                                go_on = false;
                            end
                        else
                            go_on = false;
                        end
                        j = j+1;
                    end
                    go_on = true;
                    j = 1;
                    % Finds the W2 right values
                    while(j <= W2 && go_on)
                        while(next < N && data2cluster(next) == 0)
                            next = next+1;
                        end
                        if(next < N)
                            if(data2cluster(next) == this_c)
                                idsRight = [idsRight next];
                            else
                                go_on = false;
                            end
                        else
                            go_on = false;
                        end
                        j = j+1;
                    end

                    % Checks means
                    if(pdist2( mean(features(idsLeft, 1:nBinsPerColor*3), 1), mean(features(idsRight, 1:nBinsPerColor*3), 1) ) > thres_split)
                         % Changes cluster adding 1 to all the following images
                        % (from i)
                        for j = i:N
                            data2cluster(j) = data2cluster(j) +1;
                        end
                    end

                end
            end
        end
        
    end

end

