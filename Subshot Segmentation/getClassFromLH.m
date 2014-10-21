function [ class ] = getClassFromLH( LH )

    [val, pos]=sort(LH,2,'descend');
    [nSamples, nClasses] = size(LH);
    class = zeros(nSamples, 1);
    for i = 1:nSamples
        maxVal = val(i,1);
        j = 2;
        while(j <= nClasses && maxVal == val(i,j))
            j = j+1;
        end
        class(i) = pos(i,randi(j-1));
    end

end

