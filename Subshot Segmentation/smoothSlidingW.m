%% Smoothing clusters using sliding window W
function [ data2cluster ] = smoothSlidingW( data2cluster, n, N )

    global W;

    halfW = floor(W/2);
    for i = n:N
        if(i == 1)
            f = 1; 
            l = min(i+halfW, N);
        elseif(i == N)
            f = max(i-halfW, 1);
            l = N;
        else
            f = max(i-halfW, 1);
            l = min(i+halfW, N);
        end

        this = data2cluster(i);
        window = data2cluster(f:l);
        u = unique(window);
        maxNum = 0;
        maxVal = 0;
        for j = 1:length(u)
            % If the number is greater or is equal and coincides with the
            % cluster of this sample
            if(sum(window==u(j)) > maxNum || (sum(window==u(j)) == maxNum && u(j) == this))
                maxNum = sum(window==u(j));
                maxVal = u(j);
            end
        end
        data2cluster(i) = maxVal;

    end

end

