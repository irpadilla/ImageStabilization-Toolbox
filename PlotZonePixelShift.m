%-------------------------------------------------------------------------------------------------------------------------------------
% Keypoint tracking:
%
% Plot the horizontal (azimuth) and vertical (tilt) displacements of the different sub-image zones expressed in terms of pixel shift
%
%
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat -----------> generated with ZoneSelection.m
%        ZonePixelShift.mat --> generated with ZonePixelShift.m | use ZonePixelShiftCorrected.mat if ZonePixelShiftCorrection.m was used
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zones     
%      
% OUTPUT:
%        ZonePixelShift.png
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 | 
%
%-------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; clc;

% Add relevant paths
SetPath; 

% Select the sub-image zone(s)
Zone  = [1:14];  

% Create colormap 
if length(Zone)<10 
   CM = brewermap(length(Zone),'Dark2');
else
   CM = jet(length(Zone));
end

% Load pixel shift
load([PathMatfiles,'ZonePixelShift.mat']);
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if pixel shifts were corrected with ZonePixelShiftCorrection.m

% Plot horizontal (azimuth) pixel shift
ZONE = [];
figure_I 
for ii = 1:length(Zone)
    subtightplot(2,1,1,0.05,0.15,0.1)
    if isfield(eval(['Z',num2str(Zone(ii)),'PxSh']),['time'])
       eval(['plot(Z',num2str(Zone(ii)),'PxSh.time,Z',num2str(Zone(ii)),'PxSh.U_shift,''.-'',''Color'',[CM(ii,:)],''LineWidth'',1);']); hold on;
    else
       eval(['plot(Z',num2str(Zone(ii)),'PxSh.frameindex,Z',num2str(Zone(ii)),'PxSh.U_shift,''Color'',[CM(ii,:)],''LineWidth'',1);']); hold on;
    end
    ZONE{ii} = ['Zone ',num2str(Zone(ii)),''];
end
if isfield(eval(['Z',num2str(Zone(ii)),'PxSh']),['time'])
   datetick('x','dd-mmm-yyyy','keeplimits');  % edit for better viewing
   eval(['xlim([Z',num2str(Zone(ii)),'PxSh.time(1),Z',num2str(Zone(ii)),'PxSh.time(end)]);']);
else
   eval(['xlim([Z',num2str(Zone(ii)),'PxSh.frameindex(1),Z',num2str(Zone(ii)),'PxSh.frameindex(end)]);']);
end
set(gca,'XTickLabel',[]);
ylabel(['\Deltau [pixels]']);
set(gca,'LineWidth',1);

% Plot vertical (tilt) pixel shift
ZONE = [];
for ii = 1:length(Zone)
    subtightplot(2,1,2,0.05,0.15,0.1)
    if isfield(eval(['Z',num2str(Zone(ii)),'PxSh']),['time'])
       eval(['plot(Z',num2str(Zone(ii)),'PxSh.time,Z',num2str(Zone(ii)),'PxSh.V_shift,''.-'',''Color'',[CM(ii,:)],''LineWidth'',1);']); hold on;
    else
       eval(['plot(Z',num2str(Zone(ii)),'PxSh.frameindex,Z',num2str(Zone(ii)),'PxSh.V_shift,''Color'',[CM(ii,:)],''LineWidth'',1);']); hold on;
    end
    ZONE{ii} = ['Zone ',num2str(Zone(ii)),''];
end
if isfield(eval(['Z',num2str(Zone(ii)),'PxSh']),['time'])
   datetick('x','dd-mmm-yyyy','keeplimits'); % edit for better viewing
   eval(['xlim([Z',num2str(Zone(ii)),'PxSh.time(1),Z',num2str(Zone(ii)),'PxSh.time(end)]);']);
   xlabel(['Time']);
else
   eval(['xlim([Z',num2str(Zone(ii)),'PxSh.frameindex(1),Z',num2str(Zone(ii)),'PxSh.frameindex(end)]);']);
   xlabel(['Frames']);
end
ylabel(['\Deltav [pixels]']);
set(gca,'LineWidth',1);
legend(ZONE,'location','Best');

% Save figure
print([PathFigures,'ZonePixelShift.png'],'-dpng','-r300');
