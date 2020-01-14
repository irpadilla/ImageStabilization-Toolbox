%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%  Use the horizontal (azimuth) and vertical (tilt) pixel shifts to stabilize the sub-image sequence and generate a video comparing unstabilized frames vs stabilized frames
%  Also plot a TIMEX image of the whole image sequence
%
%
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat -----------> generated with ZoneSelection.m
%        ZonePixelShift.mat --> generated with ZonePixelShift.m
%
% MANUALLY INPUT: 
%        Zone -------------> select one sub-image zone to stabilize
%        Filename ---------> define the name of the video 
%        Video.FrameRate --> define frame rate of the video (default is 20 fps) 
%
% OUTPUT:
%        Filename.avi
%        Zone#Timex.png
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 

% Select only one sub-image zone
Zone = 1;

% Video parameters
Filename        = ['Zone',num2str(Zone),'StabilizationVideo.avi'];
Video           = VideoWriter([PathMovies,Filename]);
Video.FrameRate = 20;
open(Video);


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
eval(['clear Z',num2str(Zone)]);


% Load sub-image zone pixel shift 
load([PathMatfiles,'ZonePixelShift.mat']);

% Rename variables for convenience
U_shift       = eval(['Z',num2str(Zone),'PxSh.U_shift;']);
V_shift       = eval(['Z',num2str(Zone),'PxSh.V_shift;']);
frameindex    = eval(['Z',num2str(Zone),'PxSh.frameindex;']);
badframeindex = eval(['Z',num2str(Zone),'PxSh.badframeindex;']);
LISTE         = eval(['Z',num2str(Zone),'PxSh.LISTE;']);
BADLISTE      = eval(['Z',num2str(Zone),'PxSh.BADLISTE;']);
CASE          = eval(['Z',num2str(Zone),'PxSh.CASE;']);
eval(['clear Z',num2str(Zone),'PxSh']);

% Number of frames
NImages = length(LISTE);

figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'color','w');
% Animation loop
for ii = 1:NImages

    B     = im2double(imread(LISTE{ii}));                                   % load image
    ROIB  = B(vmin:vmax,umin:umax,:);                                       % extract the sub-image zone 
    tform = affine2d([1 0 0; 0 1 0; U_shift(ii) V_shift(ii) 1]);            % create a 2D affine transformation considering only translation
    SROIB = imwarp(ROIB, invert(tform), 'OutputView', imref2d(size(ROIB))); % sub-image stabilization
    
    % Extract the name of the frame
    [~,name,ext] = fileparts(LISTE{ii});
    framename = [name,ext];

    % Unstabilized video
    sp1 = subtightplot(1,2,1,0.01,0.15,0.1);
      imagesc(ROIB); hold on;
      plot(ku,kv,'g+','MarkerSize',10);           % plot the keypoint
      axis image;
      title({['Unstabilized video'],[framename]});
      xlabel(['u [pixels]']);
      ylabel(['v [pixels]']);
      set(gca,'LineWidth',1);

    % Stabilized video
    sp2 = subtightplot(1,2,2,0.01,0.15,0.1);
      imagesc(SROIB); hold on;
      plot(ku,kv,'g+','MarkerSize',10);           % plot the keypoint
      axis image;
      title({['Stabilized video'],[framename],['\Deltau = ',num2str(U_shift(ii),2),' , \Deltav = ',num2str(V_shift(ii),2)]});
      xlabel(['u [pixels]']);
      set(gca,'YTickLabel',[]);
      set(gca,'LineWidth',1);
 

    pause(0.001);
    frame = getframe(gcf);
    writeVideo(Video,frame);
    clf

    % For timex
    if ii == 1
       FramesUnstabilized = ROIB;
       FramesStabilized   = SROIB; 
    else
       FramesUnstabilized = FramesUnstabilized + ROIB;
       FramesStabilized   = FramesStabilized   + SROIB; 
    end
end
close(Video);
close all;



%% Plot timex
TimexUnstabilized = FramesUnstabilized/NImages;
TimexStabilized   = FramesStabilized/NImages;

figure_I
subtightplot(1,2,1,0.01,0.15,0.1)
  imagesc(TimexUnstabilized);
  title(['Unstabilized Timex']);
  xlabel(['u [pixels]']);
  ylabel(['v [pixels]']);
  axis image;
  set(gca,'LineWidth',1);
subtightplot(1,2,2,0.01,0.15,0.1)
  imagesc(TimexStabilized);
  title(['Stabilized Timex']);
  xlabel(['u [pixels]']);
  set(gca,'YTickLabel',[]);
  axis image;
  set(gca,'LineWidth',1);
  set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);

% Save figure
print([PathFigures,'Zone',num2str(Zone),'Timex.png'],'-dpng','-r300');


