function figure_I()
%------------------------------------------------------------------------------------------------------
% figure_I() 
%
% Open a figure with the size of a Power Point slide
%
% X1=0; Y1=0; X2=10; Y2=7.5; Size of a Power Point slide (for a standard size 4:3)
%
% |Isaac Rodriguez-Padilla, 2018|
%
%----------------------------------------------------------------------------------------------------


% Size in inches
X1=0; Y1=0; X2=10; Y2=6.09;

figure
set(gcf,'Units', 'inches');
set(gcf,'position',[X1 Y1 X2 Y2]);     % this allows to preview how it would look in the PPT slide size  
set(gcf,'Resize', 'off');
set(gcf,'paperposition',[X1 Y1 X2 Y2]);
set(gcf,'color','w');

end

