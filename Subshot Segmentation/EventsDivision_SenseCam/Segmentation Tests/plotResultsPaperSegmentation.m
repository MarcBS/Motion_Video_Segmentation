
%         Method & Acc. T & Acc. S & Acc. M & Acc. Avrg. \\
%         \hline
%         	SVM & 0.7900 & 0.6606 & 0.4090 & 0.6463 \\
%         \hline
%         	SVM + GC & 0.6358 & 0.5986 & 0.7637 & 0.6243 \\
%         \hline
%         	KNNe & 0.5025 & 0.7961 & 0.3965 & 0.7064 \\
%         \hline
%         	KNNe + GC & 0.3722 & 0.9235 & 0.4623 & {\bf 0.7916} \\
%         \hline
%         	KNNc & 0.6339 & 0.6699 & 0.4726 & 0.6403 \\
%         \hline
%         	KNNc + GC & {\bf 0.5476} & {\bf 0.7715} & {\bf 0.6473} & {\bf 0.7259}

addpath('../../..')

results = [0.7900 0.6606  0.4090  0.6463; 0.6358  0.5986  0.7637  0.6243; ...
    0.5025  0.7961  0.3965  0.7064; 0.3722  0.9235  0.4623  0.7916;...
    0.6339  0.6699  0.4726  0.6403; 0.5476 0.7715 0.6473 0.7259;...
    0.6160 0.6797 0.4601 0.6435; 0.5027 0.7730 0.6358 0.7196];
labels = {'T', 'S', 'M', 'Avrg.'};
methods = {'SVM', 'SVM + GC', 'KNNe', 'KNNe + GC', 'KNNc', 'KNNc + GC', 'KNNc NO FS', 'KNNc + GC NO FS'};
colors = [[1 0 0]; [0.4 0 0]; [0 0 1]; [0 0 0.4]; [0 1 0]; [0 0.5 0]];

f=figure;
for i = 1:size(results,1)
   
%     line(1:size(results,2), results(i,:), 'Color', colors(i,:), 'LineWidth', 3);
%     bar(results(i,:), 'histc');
%     hold all;

    
    
end
bar(results', 'hist');
colormap(hot)

xticklabel_rotate(linspace(1,4.2,4), 0, labels, 'FontSize', 14,'interpreter','none');
ylabel('Accuracy', 'FontSize', 16);
xlabel('Class', 'FontSize', 16);
legend(methods,3);
title('Mean Accuracy for all the Methods', 'FontSize', 16);
set(gca, 'FontSize', 14);
saveas(f, 'Mean Accuracy Methods.jpg')

