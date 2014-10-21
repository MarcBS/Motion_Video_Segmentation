%% Delete events with less than C_min images
% Sets to 0 the data2cluster id of all the deleted images
function [ data2cluster ] = deleteShortEvents( data2cluster, n, N )

    global C_min;

    id_first = n;
    this_clus = data2cluster(id_first);
    this_count = 1;
    id_last = n;
    for i = (n+1):N
        if(data2cluster(i) ~= this_clus)
            if(this_count < C_min)
                data2cluster(id_first:id_last) = 0;
            end
            id_first = i;
            this_clus = data2cluster(id_first);
            this_count = 0;
        end
        id_last = i;
        this_count = this_count +1;
    end

end

