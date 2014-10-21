

data = zeros(11,2);
data(1:5,1) = 1;
data(6:10,1) = -1;
data(11,1) = -4.67;

data(1:5,2) = linspace(1,5,5);
data(6:10,2) = linspace(1,5,5);
data(11,2) = 6;

scatter(data(:,1), data(:,2));

classifier = svmtrain(data, [ones(1,5) ones(1,6)*-1]);

[labels margins] = svmclassify2(classifier, data);

disp('Done');