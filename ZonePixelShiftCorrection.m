%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Correct manually (via ginput) the bad pixel shifts computed with ZonePixelShift.m for a specific sub-image region (Zone)
%
%
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat -----------> generated with ZoneSelection.m
%        ZonePixelShift.mat --> generated with ZonePixelShift.m
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zone number #     
%        refname --> name of the reference image
%      
% OUTPUT:
%        ZonePixelShiftCorrected.mat
%        Z#PxSh. 
%               U_shift --------> sub-image horizontal (azimuth) pixel shift with respect to the reference frame      
%               V_shift --------> sub-image vertical   (tilt)    pixel shift with respect to the reference frame      
%               frameindex -----> index of the frames      
%               badframeindex --> index of the frames that were discarded      
%               LISTE ----------> cell array containing the names of the frames      
%               BADLISTE -------> cell array containing the names of the frames that were discarded      
%               CASE -----------> this variable contains infromation of which of the 4 cases were used to compute/discard the pixel shift       
%
%  
% Useful notation:
%                             A = reference frame 
%                             B = any frame
%                             P = previous frame to B
%      ROIA/     ROIB/     ROIP = sub-image region (Zone) used for computing the pixel shift (keypoint matching)
%     SROIA/    SROIB/    SROIP = stabilized sub-image region
%   ROIEdgA/  ROIEdgB/  ROIEdgP = Canny edge detector applied to a sub-image region 
%  SROIEdgA/ SROIEdgB/ SROIEdgP = Canny edge detector applied to a stabilized sub-image region 
%
%
%
% Sketch:
%         __________
%      - |          |
%        |          |             R   G   B
%      v |  image   |    Im(v,u,[255,255,255])
%        |          |
%      + |__________| 
%        -    u    +
%
% Horizontal pixel shift: 
%                        u_shift --> positive  (the image is moved to the right with respect to the reference image; the camera is moved to the left in azimuth) 
%                        u_shift --> negative  (the image is moved to the left  with respect to the reference image; the camera is moved to the right in azimuth)
%                        
% Vertical pixel shift: 
%                        v_shift --> positive  (the image is moved down with respect to the reference image; the camera is moved up in tilt)
%                        v_shift --> negative  (the image is moved up   with respect to the reference image; the camera is moved down in tilt)
%
%
%  
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 

% Select sub-image zone to correct
Zone = 9;

% Reference frame
refname  = '00000001.jpg';                   % reference frame name
A = im2double(imread([PathImages,refname])); % load reference frame 

% Load pixel shift of the sub-image zone
load([PathMatfiles,'ZonePixelShift.mat']);                                                                                              
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if you want to keep correcting the file

% Rename variables for convenience
U_shift       = eval(['Z',num2str(Zone),'PxSh.U_shift;']);
V_shift       = eval(['Z',num2str(Zone),'PxSh.V_shift;']);
frameindex    = eval(['Z',num2str(Zone),'PxSh.frameindex;']);
badframeindex = eval(['Z',num2str(Zone),'PxSh.badframeindex;']);
LISTE         = eval(['Z',num2str(Zone),'PxSh.LISTE;']);
BADLISTE      = eval(['Z',num2str(Zone),'PxSh.BADLISTE;']);
CASE          = eval(['Z',num2str(Zone),'PxSh.CASE;']);
eval(['clear Z',num2str(Zone),'PxSh']);

% find the index of the reference image
refindex = find(strcmp(LISTE,[PathImages,refname])==1);


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




fig1 = figure('Position', get(0,'Screensize'));
set(gcf,'color','w');
% Plot horizontal pixel shift
ax1 = subplot(4,2,[3,4]);
        p1 = plot(frameindex,U_shift); hold on;
        xlim([frameindex(1),frameindex(end)]);
        ylim = get(ax1,'ylim');
        ylabel(['\Deltau [pixels]']);
% Plot vertical pixel shift
ax2 = subplot(4,2,[5,6]);
        p2 = plot(frameindex,V_shift); hold on;
        xlim([frameindex(1),frameindex(end)]);
        xlabel(['Frames']);
        ylim = get(ax2,'ylim');
        ylabel(['\Deltav [pixels]']);

set(findall(fig1,'-property','FontSize'), 'Fontsize', 12);
set(ax1,'LineWidth',1);
set(ax1,'XTickLabel',[]);
set(p1,'LineWidth',0.5,'Marker','.','MarkerSize',6,'color','b');
set(ax2,'LineWidth',1);
set(p2,'LineWidth',0.5,'Marker','.','MarkerSize',6,'color','b');

%% Select manually the bad data %%

A        = rgb2gray(A);                 % convert to grayscale
ROIA     = A(vmin:vmax,umin:umax,:);    % sub-image region
EdgA     = double(edge(A,'canny'));     % enhance borders in all the image
ROIEdgA  = EdgA(vmin:vmax,umin:umax,:); % enhance borders only for the sub-image region 

TX = [];
dindex = []; % deleted frames index
condition = 0;
while condition == 0
   
   clc;
   display('Select manually the bad data');
   clear tx index;
   % Store manually the bad data
   [tx,~] = ginput();
   tx = [tx;TX];
   
   % Find the index matching the pixel shift values and plot them
   for ii = 1:length(tx)
       dif = abs(frameindex-tx(ii));
       index(ii) = max(find(dif==min(dif)));
       d1(ii) = plot(ax1,frameindex(index(ii)),U_shift(index(ii)));
       d2(ii) = plot(ax2,frameindex(index(ii)),V_shift(index(ii)));
   end
   set(d1,'Marker','o','MarkerSize',6,'MarkerFaceColor','r','MarkerEdgeColor','r');
   set(d2,'Marker','o','MarkerSize',6,'MarkerFaceColor','r','MarkerEdgeColor','r');
   
   clc;
   display('press some key');
   pause();
   reply = input('Want to keep selecting bad data? (y/n): ','s');
   if strcmp(reply,'y')
      condition = 0;
      TX = tx;
   else
      condition = 1;

      % Remove repeated values (if they are) and sort the time 
      [~,m1,~] = unique(index); 
      index = index(m1);
      tx    = tx(m1);    


      figure('Position', get(0,'Screensize'));
      set(gcf,'color','w');
      % Loop over selected images
      dindex = [];
      for ii = 1:length(index)
              clear u_shift v_shift;
       
              B       = im2double(imread(char(LISTE(index(ii))))); % load image
              B       = rgb2gray(B);                               % convert to grayscale
              ROIB    = B(vmin:vmax,umin:umax,:);                  % sub-image region
              EdgB    = double(edge(B,'canny'));                   % enhance borders in all the image
              ROIEdgB = EdgB(vmin:vmax,umin:umax,:);               % enhance borders only for the sub-image region
              U_SHIFT = U_shift(index(ii));                        % horizontal pixel shift
              V_SHIFT = V_shift(index(ii));                        % vertical pixel shift
      
              % Sub-image translation (stabilization)
              tform = affine2d([1 0 0; 0 1 0; U_SHIFT V_SHIFT 1]);
              SROIEdgB = imwarp(ROIEdgB, invert(tform), 'OutputView', imref2d(size(ROIEdgB))); 
              SROIB    = imwarp(ROIB, invert(tform), 'OutputView', imref2d(size(ROIB))); 
      
              subplot(3,4,[1,2])
                imagesc(SROIB); hold on; % stabilized sub-image
                plot(ku,kv,'+r');        % keypoint
                axis image;
                colormap(gray(255));
                caxis([0 1]);
                title({['Stabilized sub-image'],['Frame: ',num2str(frameindex(index(ii)))],...
                       ['Pixel shift with respect to the reference frame: \Deltau = ',num2str(U_SHIFT,3),',  \Deltav = ',num2str(V_SHIFT,3)]});
                xlabel(['u [pixels]']);
                ylabel(['v [pixels]']);
              subplot(3,4,[3,4])
                imshowpair(ROIEdgA,SROIEdgB,'ColorChannels','red-cyan'); hold on;
                plot(ku,kv,'+g');       % keypoint
                axis image;
                colormap(gray(255));
                caxis([0 1]);
                title({['Reference frame = red'],['Stabilized sub-image = cyan']});
              subplot(3,4,[5,6])
                imagesc(ROIB); hold on; % unstabilized sub-image
                plot(ku,kv,'+r');       % keypoint
                axis image;
                colormap(gray(255));
                caxis([0 1]);
                title({['Unstabilized sub-image'],['Frame: ',num2str(frameindex(index(ii)))]});
                xlabel(['u [pixels]']);
                ylabel(['v [pixels]']);
              subplot(3,4,[7,8])
                imshowpair(ROIEdgA,ROIEdgB,'ColorChannels','red-cyan'); hold on;
                plot(ku,kv,'+g');       % keypoint
                axis image;
                colormap(gray(255));
                caxis([0 1]);
                title({['Reference frame = red'],['Unstabilized sub-image = cyan']});
              subplot(3,4,[10,11])
                imagesc(ROIA); hold on; % reference frame
                plot(ku,kv,'+r');       % keypoint
                axis image;
                colormap(gray(255));
                caxis([0 1]);
                title({['Reference frame'],['Frame: ' num2str(refindex)]});
                xlabel(['v [pixels]']);
                ylabel(['u [pixels]']);
      
              clc;
              display('press some key');
              pause();
              reply2 = input('Keep the stabilized sub-image (y): \nStabilize manually with ginput (g): \nDiscard frame (n): ','s');
                     if strcmp(reply2,'y')
                        display('Good');
                        display('Please wait...');
                        clf;
                     end
                     if strcmp(reply2,'g')
                        display('Select manually the keypoint position where it should be and press enter');
                        subplot(3,4,[5,6])
                        set(gca,'LineWidth',3);
      
                        % Select manually the keypoint position
                        [gu gv] = ginput; 
                        gu = gu(end);
                        gv = gv(end);
                        plot(gu,gv,'+b');
      
                        subplot(3,4,[5,6])
                        set(gca,'LineWidth',1); 
      
            	        % Computes the pixel shift between the manually selected keypoint and the keypoint from the reference frame                                                 
            	        u_shift = gu-ku;
            	        v_shift = gv-kv;
      
                        % Sub-image translation (stabilization)
                        tform = affine2d([1 0 0; 0 1 0; u_shift v_shift 1]);
                        SMROIEdgB = imwarp(ROIEdgB, invert(tform), 'OutputView', imref2d(size(ROIEdgB))); 
          	        SMROIB    = imwarp(ROIB, invert(tform), 'OutputView', imref2d(size(ROIB))); 
      
                        subplot(3,4,[1,2])
                          imagesc(SMROIB); hold on; % manually stabilized sub-image
                          plot(ku,kv,'+r');         % keypoint
                          axis image;
                          colormap(gray(255));
                          caxis([0 1]);
                          title({['Manually stabilized sub-image'],['Frame: ',num2str(frameindex(index(ii)))],...
                                 ['Pixel shift with respect to the reference frame: \Deltau = ',num2str(u_shift,3),',  \Deltav = ',num2str(v_shift,3)]});
                          xlabel(['u [pixels]']);
                          ylabel(['v [pixels]']);
                        subplot(3,4,[3,4])
                          imshowpair(ROIEdgA,SMROIEdgB,'ColorChannels','red-cyan'); hold on;
                          plot(ku,kv,'+g');      % keypoint
                          axis image;
                          colormap(gray(255));
                          caxis([0 1]);
                          title({['Reference frame = red'],['Stabilized sub-image = cyan']});
      
                          reply3 = input('Is it now fine? (y/n): ','s');
                                 if strcmp(reply3,'y')
                                    display('Good');
                                    display('Please wait...');
                                    clf;
            	         	    U_shift(index(ii)) = u_shift;
            			    V_shift(index(ii)) = v_shift;
            			    CASE(index(ii))    = 3;
                                 end
                                 if strcmp(reply3,'n')
                                    display('This frame will not be taken into account');
                                    display('Please wait...');
                                    clf;
                                    dindex = [dindex; index(ii)];
                                 end
                     end
                     if strcmp(reply2,'n')
                        display('This frame will not be taken into account');
                        display('Please wait...');
                        clf;
                        dindex = [dindex; index(ii)];
                     end
      end

      %% Remove bad data from pixel shift
      badframeindex      = [badframeindex; frameindex(dindex)];
      BADLISTE           = [BADLISTE     ; LISTE{dindex}     ];
      U_shift(dindex)    = [];
      V_shift(dindex)    = [];
      frameindex(dindex) = [];
      LISTE(dindex)      = [];
      CASE(dindex)       = 4 ; % assign bad data to case 4 

      %% Plot once again the pixel shift with the bad data correction %%
      close;      
      fig2 = figure('Position', get(0,'Screensize'));
      set(gcf,'color','w');
      
      % Plot horizontal pixel shift
      ax3 = subplot(4,2,[3,4]);
              p3 = plot(frameindex,U_shift); hold on;
              xlim([frameindex(1),frameindex(end)]);
              ylim = get(ax3,'ylim');
              ylabel(['\Deltau [pixels]']);
      % Plot vertical pixel shift
      ax4 = subplot(4,2,[5,6]);
              p4 = plot(frameindex,V_shift); hold on;
              xlim([frameindex(1),frameindex(end)]);
              ylim = get(ax4,'ylim');
              xlabel(['Frames']);
              ylabel(['\Deltav [pixels]']);
      
      set(findall(fig2,'-property','FontSize'), 'Fontsize', 12);
      set(ax3,'LineWidth',1);
      set(ax3,'XTickLabel',[]);
      set(p3,'LineWidth',0.5,'Marker','.','MarkerSize',6,'color','b');
      set(ax4,'LineWidth',1);
      set(p4,'LineWidth',0.5,'Marker','.','MarkerSize',6,'color','b');
      clc;      
   end
end

% Horizontal (azimuth) pixel shift
display(['Horizontal (azimuth) pixel shift: Max = ',num2str(max(U_shift)),...          % maximum horizontal (azimuth) pixel shift
                                        ' , Min = ',num2str(min(U_shift)),...          % minimum horizontal (azimuth) pixel shift
                                        ' , Std = ',num2str(std(detrend(U_shift))) ]); % detrended standard deviation of horizontal (azimuth) pixel shift
% Vertical (tilt) pixel shift
display(['Vertical (tilt) pixel shift: Max = ',num2str(max(V_shift)),...               % maximum vertical (tilt) pixel shift
                                   ' , Min = ',num2str(min(V_shift)),...               % minimum vertical (tilt) pixel shift
                                   ' , Std = ',num2str(std(detrend(V_shift))) ]);      % detrended standard deviation of vertical (tilt) pixel shift


%% Save data %%%%%

% Create a structure file
eval(['Z',num2str(Zone),'PxSh = struct(''V_shift'',V_shift,''U_shift'',U_shift,''frameindex'',frameindex,''LISTE'',{LISTE},''badframeindex'',badframeindex,''BADLISTE'',{BADLISTE},''CASE'',CASE);']);


%% Save the pixel shifts as well as other variables 
%if exist([PathMatfiles,'ZonePixelShiftCorrected.mat'],['file'])
%   save([PathMatfiles,'ZonePixelShiftCorrected.mat'],['Z',num2str(Zone),'PxSh'],'-append');
%else
%   save([PathMatfiles,'ZonePixelShiftCorrected.mat'],['Z',num2str(Zone),'PxSh']);
%end


%% WARNING: This overwrites the the previous .mat file generated by ZonePixelShift.m so be careful
if exist([PathMatfiles,'ZonePixelShift.mat'],['file'])
   save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone),'PxSh'],'-append');
else
   save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone),'PxSh']);
end


