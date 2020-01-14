%---------------------------------------------------------------------------------------------------------------------------------------------------
% Plot the histogram of cases used to compute the pixel shift for the sub-image zones (for keypoint matching)
%
% The cases are: 
%               case 1   % Pixel shift computed by using the reference frame
%               case 2   % Pixel shift computed by using the previous stabilized frame as reference
%               case 3   % Manually selection of the keypoint position to compute the pixel shift
%               case 4   % Manually discarded frame
%
%  Note that case 1 and case 2 are computed automatically while case 3 and case 4 requires user intervention.
%  So this histogram gives and idea on how much user intervention was required for the pixel shift computation.
%  It is also true that some cases corresponding to case 1 and case 2 required user intervention/confirmation.
% 
% 
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        ZonePixelShift.mat --> generated with ZonePixelShift.m | use ZonePixelShiftCorrected.mat if ZonePixelShiftCorrection.m was used
%
% MANUALLY INPUT: 
%        Zone --> select the sub-image zones  
%      
% OUTPUT:
%        HistogramCases.png
%
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%---------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; clc;                                                                                                                                                                

% Add relevant paths
SetPath; 

% Select the sub-image zone(s) 
Zone = [1:14]; 


% Load the sub-image zone(s) files
load([PathMatfiles,'ZonePixelShift.mat']);
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if pixel shifts were corrected with ZonePixelShiftCorrection.m

CASES = [];
for ii = 1:length(Zone)
    CASE  = eval(['Z',num2str(Zone(ii)),'PxSh.CASE;']);
    CASES = [CASES;CASE];
end

figure_I
[NN XX] = hist(CASES,[1:4]);
hist(CASES,[1:4]);
lc = length(CASES);
xt = get(gca,'Xtick');
labels = {[num2str(NN(1)/lc*100,2),' %'],[num2str(NN(2)/lc*100,2),' %'],[num2str(NN(3)/lc*100,2),' %'],[num2str(NN(4)/lc*100,2),' %']};
text(xt,NN,labels,'HorizontalAlignment','center','VerticalAlignment','bottom');
xlabel('Case for pixel shift estimation');
ylabel('Frequency [number of frames processed]'); 
set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);


% Save figure
print([PathFigures,'HistogramCases.png'],'-dpng','-r300');

