%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Plot the sub-image regions (Zones) containing the keypoints in the reference frame 
%
%
% REQUIREMENTS: 
%        SetPath ----> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat --> generated with ZoneSelection.m
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zones to plot     
%        refname --> name of the reference image
%      
% OUTPUT:
%        Zones.png
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Sub-images zones to plot
Zone = [1:14];

% Add relevant paths
SetPath; 

% List frames
ListeImages = rdir([PathImages,'/**/*.',ExtImages]); % rdir is used for old Matlab versions
NImages     = length(ListeImages); 
for ii = 1:NImages
    [~,name{ii,1},ext{ii,1}] = fileparts(ListeImages(ii).name);
    framename{ii,1} = [name{ii,1},ext{ii,1}];
end


% Reference frame (should match with the same time when the GCPs were surveyed)
refname = '00000001.jpg';                           % reference frame name (without path)
refindex = find(strcmp(framename,refname)==1);      % index of the reference frame
if isempty(refindex)
   error('The reference frame has not been found (i.e. check the name is well written)');
end
A = im2double(imread(ListeImages(refindex).name));  % load reference frame


% Plot reference frame
figure
set(gcf,'color','w');
imagesc(A); axis image; hold on;
title('Reference frame');
xlabel('u [pixels]');
ylabel('v [pixels]');

% create colormap
if length(Zone)<10 
   CM = brewermap(length(Zone),'Dark2');
else
   CM = jet(length(Zone));
end

% Loop over the zones
load([PathMatfiles,'Zones.mat']);                     % load sub-image zones and keypoints
for ii = 1:length(Zone)
    eval(['Z = Z',num2str(Zone(ii)),';']);            % rename variable
    plot([Z.u;Z.u(1)],[Z.v;Z.v(1)],'Color',CM(ii,:)); % plot the sub-image zone
    plot(Z.kuu,Z.kvv,'+','Color',CM(ii,:));           % plot the keypoint
    text(Z.u(1)+(Z.u(4)-Z.u(1))/3,Z.v(1)-(Z.v(2)-Z.v(1))/2,['Zone ',num2str(Zone(ii)),''],'Color',CM(ii,:));
end

% Save figure
printpng([PathFigures,'Zones']);


