%------------------------------------------------------------------------------------------------------------------------------------------------
% Image stabilization via 2D translation subpixel cross-correlation (based on Guizar-Sicairos et al., 2008) together with a Canny edge detector
% This would be Case 1 of the semi-authomatic stabilization method
% 
% 
% REQUIREMENTS: 
%        SetPath ----> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat --> generated with ZoneSelection.m
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zone to stabilize    
%        refname --> name of the reference image
%        Bname ----> name of the frame to stabilize
%      
% OUTPUT:
%        u_shift --> sub-image horizontal (azimuth) pixel shift with respect to the reference frame
%        v_shift --> sub-image vertical   (tilt)    pixel shift with respect to the reference frame
%        Zone#Stabilization_Bname.png
%        Zone#StabilizationCanny_Bname.png
%
%
%
% Useful notation:
% 
%  A        = Reference Image
%  ROIA     = Sub-image region (Zone) of the reference image
%  ROIEdgA  = Canny edge detector applied to the sub-image region (Zone) of the reference image.
%  B        = Unstabilized image (frame with vertical/horizontal shift)
%  ROIB     = Sub-image region (Zone) of the unstabilized image
%  ROIEdgB  = Canny edge detector applied to the sub-image region (Zone) of the unstabilized image.
%  SROIB    = Stabilized sub-image with respect to image A
%  SROIEdgB = Canny edge detector applied to the stabilized sub-image
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc; 

% Add relevant paths
SetPath; 

% Select sub-image zone to stabilize
Zone = 1;          


% List frames
ListeImages = rdir([PathImages,'/**/*.',ExtImages]); % rdir is used for old Matlab versions
NImages     = length(ListeImages); 
for ii = 1:NImages
    [~,name{ii,1},ext{ii,1}] = fileparts(ListeImages(ii).name);
    framename{ii,1} = [name{ii,1},ext{ii,1}];
end


% Load reference image
refname  = '00000001.jpg';                         % reference frame name (without the path) 
refindex = find(strcmp(framename,refname)==1);     % index of the reference frame
if isempty(refindex)
   error('The reference frame has not been found (i.e. check the name is well written)');
end
A = im2double(imread(ListeImages(refindex).name)); % load reference frame

% Load unstabilized image
Bname  = '00000080.jpg';                           % name of the unstabilized frame (without the path)
Bindex = find(strcmp(framename,Bname)==1);         % index of the unstabilized frame
if isempty(Bindex)
   error('The frame has not been found (i.e. check the name is well written)');
end
B = im2double(imread(ListeImages(Bindex).name));   % load unstabilized frame

% Convert to gray images
A = rgb2gray(A);
B = rgb2gray(B);

% Enhance Edges (via Canny edge detector)
EdgA = double(edge(A,'canny'));
EdgB = double(edge(B,'canny'));

% Load sub-image zone and keypoint
load([PathMatfiles,'Zones.mat']);

% Rename variables for convenience
umin  = eval(['Z',num2str(Zone),'.umin' ]);
umax  = eval(['Z',num2str(Zone),'.umax' ]);
vmin  = eval(['Z',num2str(Zone),'.vmin' ]);
vmax  = eval(['Z',num2str(Zone),'.vmax' ]);
ku    = eval(['Z',num2str(Zone),'.ku'   ]);
kv    = eval(['Z',num2str(Zone),'.kv'   ]);
kuu   = eval(['Z',num2str(Zone),'.kuu'  ]);
kvv   = eval(['Z',num2str(Zone),'.kvv'  ]);

% Raw sub-image zones (ROI) and sub-image zones processed with the Canny edge detector (ROIEdg)
ROIA    = A(vmin:vmax,umin:umax,:);        
ROIB    = B(vmin:vmax,umin:umax,:);        
ROIEdgA = EdgA(vmin:vmax,umin:umax,:);        
ROIEdgB = EdgB(vmin:vmax,umin:umax,:);        

% Compute the 2D translational pixel shift between frames using Guizar-Sicairos et al. (2008) sub-pixel cross-correlation algorithm
usfac   = 20;                                                  % upsampling factor (1/usfac pixel resolution)
output  = dftregistration(fft2(ROIEdgA),fft2(ROIEdgB),usfac);  % cross-correlation applied to the sub-image zones processed with the Canny edge detector
v_shift = output(3);                                           % vertical (tilt) pixel shift
u_shift = output(4);                                           % horizontal (azimuth) pixel shift

% Careful!! Guizar-Sicarios invert the pixel shift not consistent with the reference frame pixel coordinates. Invert signs to correct this:
v_shift = -v_shift;
u_shift = -u_shift;

% Sub-image translation (stabilization)
tform = affine2d([1 0 0; 0 1 0; u_shift v_shift 1]);   % create a 2D affine transformation considering only translation 
SROIB = imwarp(ROIB, invert(tform), 'OutputView', imref2d(size(ROIA)));

% Enhance Edges (via Canny edge detector)
SROIEdgB = double(edge(SROIB,'canny'));

%% Sub-image stabilization plots
figure_I
% Reference frame
subplot(2,2,1)
  imagesc(ROIA); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame
  axis image;
  colormap(gray(255));
  caxis([0 1]);
  title({['Reference sub-image: ',refname],['Keypoint position: (k_{u} , k_{v})']});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
% Unstabilized sub-image
subplot(2,2,2)
imagesc(ROIB); hold on; 
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame 
  plot(ku+u_shift,kv+v_shift,'+m','MarkerSize',10); % keypoint location with respect to the shifted sub-image
  axis image;
  colormap(gray(255));
  caxis([0 1]);
  title({['Unstabilized sub-image: ',Bname],['Keypoint position: (k_{u''} = k_{u}+\Deltau , k_{v''} = k_{v}+\Deltav)'],['\Deltau = ',num2str(u_shift),' ,  \Deltav = ',num2str(v_shift)]});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
% Overlapped reference sub-image with unstabilized sub-image
subplot(2,2,3)
  imshowpair(ROIA,ROIB,'ColorChannels','red-cyan'); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame 
  plot(ku+u_shift,kv+v_shift,'+m','MarkerSize',10); % keypoint location with respect to the shifted sub-image
  axis image;
  axis on;
  set(gca,'TickLength',[0 0]);
  title({['Reference frame = Red'],['Unstabilized sub-image = Cyan']});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
% Stabilized sub-image
subplot(2,2,4)
imagesc(SROIB); hold on; 
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the shifted sub-image
  axis image;
  colormap(gray(255));
  caxis([0 1]);
  title({['Stabilized sub-image: ',Bname],['Keypoint position: (k_{u} = k_{u''}-\Deltau , k_{v} = k_{v''}-\Deltav)'],['\Deltau = ',num2str(u_shift),' ,  \Deltav = ',num2str(v_shift)]});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);

% Save figure
print([PathFigures,'Zone',num2str(Zone),'Stabilization_',Bname(1:end-4),'.png'],'-dpng','-r300');

%% Same as before, but using the sub-image zones processed with the Canny edge detector
% Sub-image stabilization plots
figure_I
ax1 = subplot(2,2,1);
  imagesc( cat(3, ROIEdgA, zeros(size(ROIEdgA)), zeros(size(ROIEdgA)) ) ); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame
  axis image;
  title({['Reference frame: ',refname],['Keypoint position: (k_{u} , k_{v})']});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
ax2 = subplot(2,2,2);
  imagesc( cat(3, zeros(size(ROIEdgB)), ROIEdgB, ROIEdgB ) ); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame 
  plot(ku+u_shift,kv+v_shift,'+m','MarkerSize',10); % keypoint location with respect to the shifted sub-image
  axis image;
  title({['Unstabilized sub-image: ',Bname],['Keypoint position: (k_{u''} = k_{u}+\Deltau , k_{v''} = k_{v}+\Deltav)'],['\Deltau = ',num2str(u_shift),' ,  \Deltav = ',num2str(v_shift)]});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
subplot(2,2,3)
  imshowpair(ROIEdgA,ROIEdgB,'ColorChannels','red-cyan'); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the reference frame 
  plot(ku+u_shift,kv+v_shift,'+m','MarkerSize',10); % keypoint location with respect to the shifted sub-image
  axis image;
  axis on;
  set(gca,'TickLength',[0 0]);
  title({['Reference frame = Red'],['Unstabilized sub-image = Cyan']});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);
subplot(2,2,4)
  imshowpair(ROIEdgA,SROIEdgB,'ColorChannels','red-cyan'); hold on;
  plot(ku,kv,'+g','MarkerSize',10);                 % keypoint location with respect to the shifted sub-image
  axis image;
  axis image;
  axis on;
  set(gca,'TickLength',[0 0]);
  title({['Reference frame = Red'],['Stabilized sub-image = Cyan']});
  xlabel(['u [pixels]']); 
  ylabel(['v [pixels]']); 
  set(gca,'LineWidth',1);

% Save figure
print([PathFigures,'Zone',num2str(Zone),'StabilizationCanny_',name{Bindex},'.png'],'-dpng','-r300');




