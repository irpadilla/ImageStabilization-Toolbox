%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Define the sub-image region (Zone) containing the keypoint in the reference frame 
%
%
% REQUIREMENTS: 
%        SetPath --> generated with SetPath.m to add the relevant paths to Matlab 
%
% MANUALLY INPUT: 
%        refname --> name of the reference image
%        Zone -----> sub-image zone number #     
%      
% OUTPUT:
%        Zones.mat
%        Z#. 
%           kuu----> keypoint position (horizontal image coordinate)       
%           kvv ---> keypoint position (vertical   image coordinate)     
%           ku ----> keypoint position (horizontal image coordinate with respect to the sub-image zone)     
%           kv ----> keypoint position (vertical   image coordinate with respect to the sub-image zone)
%           umin --> sub-image zone position (horizontal min image coordinate)      
%           umax --> sub-image zone position (horizontal max image coordinate)      
%           vmin --> sub-image zone position (vertical   min image coordinate)       
%           vmax --> sub-image zone position (verical    max image coordinate)      
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 


% List frames
ListeImages = rdir([PathImages,'/**/*.',ExtImages]); % rdir is used for old Matlab versions
NImages     = length(ListeImages); 
for ii = 1:NImages
    [~,name{ii,1},ext{ii,1}] = fileparts(ListeImages(ii).name);
    framename{ii,1} = [name{ii,1},ext{ii,1}];
end


% Reference frame (must match with the same time when the GCPs were surveyed)
refname  = '00000001.jpg';                          % reference frame name (without path)
refindex = find(strcmp(framename,refname)==1);      % index of the reference frame
if isempty(refindex)
   error('The reference frame has not been found (i.e. check the name is well written)');
end
A = im2double(imread(ListeImages(refindex).name));  % load reference frame
A = rgb2gray(A);                                    % convert to grayscale         

% Select the sub-image zone you want to define (change number)
Zone = 15;


% Plot reference frame
f1 = figure('Position', get(0,'Screensize'));
imagesc(A); axis image; hold on;
colormap(gray(255));
caxis([0 1]);
title('Reference frame');
xlabel('u [pixels]');
ylabel('v [pixels]');


%% Zone Selection %%

% Select the corresponding zone (4 points) around the keypoint allowing for some inter-frame movement
% 1st point should be top-left, 2nd point bottom-left, 3rd point bottom-right and 4th point top-right
[Z.u Z.v] = ginput;
figure(f1)
set(gcf,'color','w');
h = impoly(gca,[Z.u Z.v]);
disp('Please edit the zone and press any key to continue')
pause();

newpos = getPosition(h);
delete(h);
Z.u = newpos(:,1);
Z.v = newpos(:,2);
Z.u = round(Z.u);
Z.v = round(Z.v);

% Plot the selected Zone
plot([Z.u;Z.u(1)],[Z.v;Z.v(1)],'r');
text(Z.u(1)+(Z.u(4)-Z.u(1))/3,Z.v(1)-(Z.v(2)-Z.v(1))/4,['Zone ',num2str(Zone),''],'FontWeight','Bold','Color','r');

%% Keypoint Selection %%

% Rename variables
Z.umin = Z.u(2);
Z.umax = Z.u(3);
Z.vmin = Z.v(1);
Z.vmax = Z.v(2);

% plot sub-image zone 
figure('Position', get(0,'Screensize'));
imagesc(A(Z.vmin:Z.vmax,Z.umin:Z.umax,:)); 
colormap(gray(255));
caxis([0 1]);
axis image;
hold on;
title(['Sub-image zone ',num2str(Zone),'']);
xlabel('u [pixels]');
ylabel('v [pixels]');

% Select keypoint
disp('Please select the keypoint and press enter to continue')
[Z.ku Z.kv] = ginput;
plot(Z.ku,Z.kv,'r+','MarkerSize',10);

% Keypoint position with respect to the full-size image
Z.kuu = Z.u(1)+Z.ku;
Z.kvv = Z.v(1)+Z.kv;
figure(f1)
plot(Z.kuu,Z.kvv,'r+','MarkerSize',10);


%% Save Zone and Keypoint position %%

% Rename variable
eval(['Z',num2str(Zone),' = Z;']); 


% Save Zone and keypoint 
if exist([PathMatfiles,'Zones.mat'],['file'])
   save([PathMatfiles,'Zones.mat'],['Z',num2str(Zone)],'-append');
else
   save([PathMatfiles,'Zones.mat'],['Z',num2str(Zone)]);
end







