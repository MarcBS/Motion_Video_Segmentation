function IDM = PerceptualBlurMetric (Image, FiltSize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IDM = PerceptualBlurMetric (Image, FiltSize)          %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          %
% Computes Image Degradation Measure (IDM)              %
%                                                       %
% Inputs - Image - Input Image                          %
%        - FiltSize - metric parameter - suggested value%
%                     9.                                %
% Output - the image's IDM with 0 corresponding to the  %
%          lowest and 1 to the highest degradation      %
%          levels.                                      %        
%                                                       %
% Ref: F. Crete, T. Dolmiere, P. Ladret and M. Nicolas, %
%      “The Blur Effect: Perception and Estimation with %
%       a New No-Reference Perceptual Blur Metric”,     %
%       proc. of Human Vision and Electronic Imaging    %
%       XII/Electronic Imaging 2007, SPIE Vol. 6492,    %
%       San-Jose, CA, 2007.                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Writen by -Barak Fishbain                             %
% Faculty of Engineering - Tel-Aviv University          %
% www.eng.tau.ac.il/~barak                              %
% November 2007                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [m n] = size(Image);
    
    Hv = 1/FiltSize*ones(1,FiltSize); Hh = Hv';
    Bver = conv2(Image, Hv, 'same');
    Bhor = conv2(Image, Hh, 'same');
    
    Bver = Bver(ceil(FiltSize/2):m-floor(FiltSize/2), ceil(FiltSize/2):n-floor(FiltSize/2));
    Bhor = Bhor(ceil(FiltSize/2):m-floor(FiltSize/2), ceil(FiltSize/2):n-floor(FiltSize/2));
    Image = Image(ceil(FiltSize/2):m-floor(FiltSize/2), ceil(FiltSize/2):n-floor(FiltSize/2));
    [m n] = size(Image);
    
    D_Fver = abs(conv2(Image, [1 -1], 'same'));
    D_Fhor = abs(conv2(Image, [1 -1]', 'same'));
    D_Fver = D_Fver(1:m-1, 1:n-1); 
    D_Fhor = D_Fhor(1:m-1, 1:n-1);
    
    D_Bver = abs(conv2(Bver, [1 -1], 'same'));
    D_Bhor = abs(conv2(Bhor, [1 -1]', 'same'));
    D_Bver = D_Bver(1:m-1, 1:n-1); 
    D_Bhor = D_Bhor(1:m-1, 1:n-1);
    
    
    D_Vver = max(0,D_Fver-D_Bver);
    D_Vhor = max(0,D_Fhor-D_Bhor);
        
    s_Fver = sum(D_Fver(:));
    s_Fhor = sum(D_Fhor(:));
    s_Vver = sum(D_Vver(:));
    s_Vhor = sum(D_Vhor(:));
    
    b_Fver = (s_Fver - s_Vver)/s_Fver;
    b_Fhor = (s_Fhor - s_Vhor)/s_Fhor;
    
    IDM = max(b_Fver, b_Fhor);
    
    
    