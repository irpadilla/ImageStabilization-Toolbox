function printpng(outfilename)
%------------------------------------------------------------------------------------------------------
% printpng('outfilename') 
%
% Saves figure in .png format with the size of a Power Point slide
%
% X1=0; Y1=0; X2=10; Y2=7.5; Size of a Power Point slide (for a standard size 4:3)
%
% |Isaac Rodriguez-Padilla, 2018|
%
%----------------------------------------------------------------------------------------------------


% Size in inches
X1=0; Y1=0; X2=10; Y2=6.09;

set(gcf,'Units', 'inches');
set(gcf,'position',[X1 Y1 X2 Y2]);     % this allows to preview how it would look in the PPT slide size  
set(gcf,'Resize', 'on');
set(gcf,'paperposition',[X1 Y1 X2 Y2]);

% Change Fontsize and LineWidth
set(findall(gcf,'-property','FontSize'  ), 'Fontsize'   , 12          );
set(findall(gcf,'-property','LineWidth' ), 'LineWidth'  , 0.5         );
set(findall(gcf,'-property','MarkerSize'), 'MarkerSize' , 6           );
set(findall(gca,'-property','LineWidth' ), 'LineWidth'  , 1           );

% Also manually change if necessary
%set(findall(gca,'-property','TickLength'), 'TickLength' , [0.02 0.02] );
%set(findall(gca,'-property','XTick'     ), 'XTick'      , 1:1:7       );
%set(findall(gca,'-property','XTickLabel'), 'XTickLabel' , 1:1:7       );
%set(findall(gca,'-property','YTick'     ), 'YTick'      , -4:2:10     );
%set(findall(gca,'-property','YTickLabel'), 'YTickLabel' , 1:1:7       );


% print in .png or .eps
print([outfilename,'.png'],'-dpng','-r300');
%print([outfilename,'.eps'], '-depsc2','-r300');


end

