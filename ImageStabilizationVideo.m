%--------------------------------------------------------------------------------------------------------------------------------------------
%  Use the transformation parameters to stabilize the image sequence and generate a video comparing unstabilized frames vs stabilized frames
%  Also plot a TIMEX image of the whole image sequence
%
%
% REQUIREMENTS: 
%        SetPath ----------------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat --------------------> generated with ZoneSelection.m
%        ZonePixelShift.mat -----------> generated with ZonePixelShift.m
%        GeometricTransformation.mat --> generated with GeometricTransformation.m
%
% MANUALLY INPUT: 
%        Zone -------------> select which sub-image zones (i.e., keypoints) to use for the geometric transformation (i.e., stabilization)  
%        Filename ---------> define the name of the video 
%        Video.FrameRate --> define frame rate of the video (default is 20 fps) 
%
% OUTPUT:
%        Filename_[transformation].avi
%        ImageTimex_[transformation].png
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%--------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 

% Select the sub-image zones
Zone = [1:14];

% Create colormap
if length(Zone)<10 
   CM = brewermap(length(Zone),'Dark2');
else
   CM = jet(length(Zone));
end

% Load geometric transformation parameters 
load([PathMatfiles,'GeometricTransformation.mat']);                                                                                              

% Rename variables
Gtrans     = TFORM.Gtrans;
tform      = TFORM.tform;
U_shift    = TFORM.U_shift;
V_shift    = TFORM.V_shift;
frameindex = TFORM.frameindex;
LISTE      = TFORM.LISTE;
clear TFORM;

% Video parameters
Filename        = 'ImageStabilizationVideo';
Video           = VideoWriter([PathMovies,Filename,'_',Gtrans,'.avi']);
Video.FrameRate = 20;
open(Video);


% Load sub-image zones and keypoints
load([PathMatfiles,'Zones.mat']);     

% Number of frames
NImages = length(LISTE);

figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'color','w'); 
% Animation loop
for ii = 1:NImages
    B = im2double(imread(LISTE{ii})); % load image

    % Image stabilization
    SB = imwarp(B, tform(ii), 'OutputView', imref2d(size(B)));
    
    % Extract name of the frame
    [~,name,ext] = fileparts(LISTE{ii});
    framename = [name,ext];

    % Unstabilized video
    sp1 = subtightplot(1,2,1,0.01,0.15,0.1);
      imagesc(B);
      axis image;
      title({['Unstabilized video'],[framename]});
      xlabel(['u [pixels]']);
      ylabel(['v [pixels]']);
      set(gca,'LineWidth',1);

    % Stabilized video
    sp2 = subtightplot(1,2,2,0.01,0.15,0.1);
      imagesc(SB);
      axis image;
      title({['Stabilized video'],[framename]});
      xlabel(['u [pixels]']);
      set(gca,'YTickLabel',[]);
      set(gca,'LineWidth',1);

   % Loop over the zones
   for jj = 1:length(Zone)
       eval(['Z = Z',num2str(Zone(jj)),';']); % rename sub-image zone and keypoint variable
       axes(sp1);
       hold on
       %plot([Z.u;Z.u(1)],[Z.v;Z.v(1)],'Color',CM(jj,:)); % plot the sub-image zone
       plot(Z.kuu,Z.kvv,'+','Color',CM(jj,:));           % plot the keypoint
       plot(Z.kuu+U_shift(ii,Zone(jj)),Z.kvv+V_shift(ii,Zone(jj)),'o','Color',CM(jj,:)); % plot the keypoint
       plot([Z.kuu,Z.kuu+U_shift(ii,Zone(jj))],[Z.kvv,Z.kvv+V_shift(ii,Zone(jj))],'-','Color',CM(jj,:)); % plot line
       axes(sp2);
       hold on
       %plot([Z.u;Z.u(1)],[Z.v;Z.v(1)],'Color',CM(jj,:)); % plot the sub-image zone
       plot(Z.kuu,Z.kvv,'+','Color',CM(jj,:));           % plot the keypoint
   end
 

    pause(0.001);
    frame = getframe(gcf);
    writeVideo(Video,frame);
    clf

    % For timex
    if ii == 1
       FramesUnstabilized = B;
       FramesStabilized   = SB; 
    else
       FramesUnstabilized = FramesUnstabilized + B;
       FramesStabilized   = FramesStabilized   + SB; 
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
print([PathFigures,'ImageTimex_',Gtrans,'.png'],'-dpng','-r300');


