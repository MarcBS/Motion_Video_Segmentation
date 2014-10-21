%% Joins different events whose means are very similar
function [ data2cluster ] = joinEventsMean( data2cluster, n, N, features )

    global nBinsPerColor;
    global thres_join;
    
    next_c_ids = [];
    i = n;
    while(data2cluster(i) == 0)
        i = i+1;
    end
    this_c = data2cluster(i);
    this_c_ids = [i];
    
    state = 'this';
    for j = (i+1):N
        
        if(strcmp(state, 'this'))
            if(data2cluster(j) == this_c)
                this_c_ids = [this_c_ids j];
            elseif(data2cluster(j) == 0)
                % Do nothing
            else % different cluster
                next_c = data2cluster(j);
                next_c_ids = [next_c_ids j];
                state = 'next';
            end
        else % state = 'next'
            if(data2cluster(j) == next_c)
                next_c_ids = [next_c_ids j];
            elseif(data2cluster(j) == 0)
                % Do nothing
            else % different cluster
                
                % if difference of means is smaller than threshold:
                if(pdist2( mean(features(this_c_ids, 1:nBinsPerColor*3), 1), mean(features(next_c_ids, 1:nBinsPerColor*3), 1) ) < thres_join)
                    
                    % we join the clusters
                    data2cluster(this_c_ids) = next_c;
                    % join new reference cluster
                    this_c_ids = [this_c_ids next_c_ids];
                    
                else
                    % initialize new reference cluster
                    this_c_ids = next_c_ids;
                end
                this_c = next_c;
                % initialize next cluster
                next_c = data2cluster(j);
                next_c_ids = [j];
                
            end
        end
        
    end

end

