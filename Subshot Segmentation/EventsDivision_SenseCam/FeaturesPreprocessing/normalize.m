%%
%   Normalizes the input data (sets all values from 1 = maximum to 0 =
%   minimum).
%
%   INPUT
%       data -> NxM matrix with N rows representing each sample and M
%           columns representing each feature.
%       minimum -> minimum value stablished for the normalization ONLY IF 
%           we want to adapt it to previously normalized data.
%       maximum -> maximum value stablished for the normalization ONLY IF 
%           we want to adapt it to previously normalized data.
%%%%
function [ norm_data, minimum, maximum ] = normalize( data, minimum, maximum )

    if nargin < 4
        minimum = min(data);
        maximum = max(data);
    end

    norm_data = bsxfun(@rdivide, bsxfun(@minus, data, minimum), maximum - minimum);
    
    % We check that the values don't exceed 1 or 0.
    norm_data(norm_data>1) = 1;
    norm_data(norm_data<0) = 0;
    
end

