%---------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Keypoint matching
%
% This semi-automatic (interactive) script works under a scheme of 4 cases:
%
%         case 1   % Cross-correlation together with a Canny edge detector
%            ref = ROIEdgA;
%            img = ROIEdgB; 
%         case 2   % Cross-correlation together with a Canny edge detector (reference frame is the previous frame)
%            ref = SROIEdgP;
%            img = ROIEdgB; 
%         case 3   % Select manually the keypoint position to compute the pixel shift
%            img = ROIEdgB; 
%
% which does the following:
%
% 1) Compute automatically the horizontal (azimuth) and vertical (tilt) pixel shift of a sub-image region (Zone) with respect to a reference image using a cross-correlation (Guizar-Sicairos et al., 2008) algorithm together with a Canny edge detector (case 1)
%
% 2) If the estimated pixel shift between consecutive frames is higher than a threshold (default: 10 pixels) the script automatically defines the previous stabilized sub-image as the new reference frame and computes the pixel shift again to see if it improves (case 2)
%
% 3) If step 1 or 2 doesn't work (i.e. pixel shift between consecutive frames > 10 pixels), the script gives the user the following options:
%     - Select manually the keypoint position (via ginput) to compute the pixel shift (case 3)
%     - Discard the image (case 4)
% 
% 
% REQUIREMENTS: 
%        SetPath ----> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat --> generated with ZoneSelection.m
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zone number #     
%        refname --> name of the reference image
%      
% OUTPUT:
%        ZonePixelShift.mat
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
%                             A = reference frame (ref) 
%                             B = any frame (img)
%                             P = previous frame to B
%      ROIA/     ROIB/     ROIP = sub-image region (Zone) used for computing the pixel shift (keypoint matching)
%     SROIA/    SROIB/    SROIP = stabilized sub-image region
%   ROIEdgA/  ROIEdgB/  ROIEdgP = Canny edge detector applied to a sub-image region 
%  SROIEdgA/ SROIEdgB/ SROIEdgP = Canny edge detector applied to a stabilized sub-image region 
%
%                        
%                        PixelThreshold = Shift allowed between any image (B) with respect to its previous image (P) [default is 10 pixels]
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
%                        u_shift --> positive  (the image is moved to the right with respect to the reference image; the camera is moved to the left  in azimuth) 
%                        u_shift --> negative  (the image is moved to the left  with respect to the reference image; the camera is moved to the right in azimuth)
%                        
% Vertical pixel shift: 
%                        v_shift --> positive  (the image is moved down with respect to the reference image; the camera is moved up   in tilt)
%                        v_shift --> negative  (the image is moved up   with respect to the reference image; the camera is moved down in tilt)
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%--------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc; 

% Add relevant paths
SetPath; 


% Set parameters
Zone = 14;           % select sub-image zone
PixelThreshold = 10; % maximum pixel shift allowed between consecutive frames


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

% List frames
ListeImages = dir([PathImages,'/*.jpg']);
NImages     = length(ListeImages); 

% Reference image
refname  = '00000001.jpg';   % reference frame name
refindex = find(strcmp({ListeImages.name},refname)==1);         % index of the reference frame
A = im2double(imread([PathImages,ListeImages(refindex).name])); % load reference frame
A        = rgb2gray(A);                 % convert to grayscale
ROIA     = A(vmin:vmax,umin:umax,:);    % sub-image region
EdgA     = double(edge(A,'canny'));     % enhance borders in all the image
ROIEdgA  = EdgA(vmin:vmax,umin:umax,:); % enhance borders only for the sub-image region 


figure('Position', get(0,'Screensize'));
set(gcf,'color','w');
V_shift       =  0;
U_shift       =  0;
vRef_shift    =  0;
uRef_shift    =  0;
frameindex    = [];
LISTE         = {[]};
badframeindex = [];
BADLISTE      = {[]};
jj            =  0; % counter
kk            =  0; % counter

tic
% Frame loop
for ii = 1:NImages
    display(['Frame: ',num2str(ii), ' (',ListeImages(ii).name,')']); % comment this for faster computation results
          
    %% Sub-image stabilization

    % Load image and define sub-image region
    B       = im2double(imread([PathImages,ListeImages(ii).name]));  % load image
    B       = rgb2gray(B);                             % convert to grayscale
    ROIB    = B(vmin:vmax,umin:umax,:);                % sub-image region
    EdgB    = double(edge(B,'canny'));                 % enhance borders in all the image
    ROIEdgB = EdgB(vmin:vmax,umin:umax,:);             % enhance borders only for the sub-image region
  
    if jj~=0
       % Load previous image and define sub-image region
       P     = im2double(imread(LISTE{end}));        % load previous image
       P     = rgb2gray(P);                          % make grayscale
       ROIP  = P(vmin:vmax,umin:umax,:);             % sub-image region
       tform = affine2d([1 0 0; 0 1 0; U_shift(end) V_shift(end) 1]);                   % create affine2d object for translation
       SROIP    = imwarp(ROIP, invert(tform), 'OutputView', imref2d(size(ROIP)));       % sub-image region translation (stabilization) of the previous frame  
       EdgP     = double(edge(P,'canny'));                                              % enhance borders in all the image
       ROIEdgP  = EdgP(vmin:vmax,umin:umax,:);                                          % enhance borders only for the sub-image region
       tform    = affine2d([1 0 0; 0 1 0; U_shift(end) V_shift(end) 1]);                % create affine2d object for translation
       SROIEdgP = imwarp(ROIEdgP, invert(tform), 'OutputView', imref2d(size(ROIEdgP))); % stabilized sub-image region of the previous image with enhanced borders 
    end   

    % Set parameters before entering the while loop
    clear SROIEdgB SROIB V_SHIFT U_SHIFT

    ll = 0; % initialize counter
    condition  = 0;
    condition2 = 0;
    while condition == 0
       
          ll = ll+1; % counter
       
       if jj == 0
             P = A;
             SROIEdgP   = ROIEdgA;
             SROIP      = ROIA;
             ROIP       = ROIA;
             frameindex = refindex; % index of the reference frame
       end      

       if ~any(ROIEdgB(:)) || ~any(ROIEdgA(:)) % will be true if matrix is full of zeros
           kk = kk+1; % counter
           badframeindex  = [badframeindex ; ii];
           BADLISTE{kk,1} = [PathImages,ListeImages(ii).name];
           condition2 = 1;
           break
       end
          
          % Different pixel shift computation methods
          switch ll

             case 1   % Cross-correlation together with a Canny edge detector 
                ref = ROIEdgA;
                img = ROIEdgB; 
             case 2   % Cross-correlation together with a Canny edge detector (reference frame is the previous frame)
                ref = SROIEdgP;
                img = ROIEdgB; 
             case 3   % Select manually the keypoint position to compute the pixel shift
                img = ROIEdgB; 
                subplot(3,4,[1,2])
                  imagesc(SROIB{1}); hold on; % stabilized sub-image with respect to the reference frame
                  plot(ku,kv,'+r');           % keypoint
                  axis image;
                  colormap(gray(255));
                  caxis([0 1]);
                  title({['Stabilized sub-image (using the reference frame)'],[ListeImages(ii).name],...
                         ['Pixel shift with respect to the previous frame: \Deltav = ',num2str(V_SHIFT{1}-V_shift(end),3),',  \Deltau = ',num2str(U_SHIFT{1}-U_shift(end),3)],...
                         ['Pixel shift with respect to the reference frame: \Deltav = ',num2str(V_SHIFT{1},3),',  \Deltau = ',num2str(U_SHIFT{1},3)]});
                  xlabel(['u [pixels]']);
                  ylabel(['v [pixels]']);
                subplot(3,4,[3,4])
                  imagesc(SROIB{2}); hold on; % stabilized sub-image with respect to the previous frame
                  plot(ku,kv,'+r');           % keypoint
                  axis image;
                  colormap(gray(255));
                  caxis([0 1]);
                  title({['Stabilized sub-image (using the previous stabilized sub-image as reference)'],[ListeImages(ii).name],...
                         ['Pixel shift with respect to the previous frame: \Deltav = ',num2str(V_SHIFT{2}-V_shift(end),3),',  \Deltau = ',num2str(U_SHIFT{2}-U_shift(end),3)],...
                         ['Pixel shift with respect to the reference frame: \Deltav = ',num2str(V_SHIFT{2},3),',  \Deltau = ',num2str(U_SHIFT{2},3)]});
                  xlabel(['u [pixels]']);
                  ylabel(['v [pixels]']);
                subplot(3,4,[5,6])
                  imagesc(ROIB); hold on;    % unstabilized sub-image
                  plot(ku,kv,'+r');          % keypoint
                  axis image;
                  colormap(gray(255));
                  caxis([0 1]);
                  title({['Unstabilized sub-image'],[ListeImages(ii).name]});
                  xlabel(['u [pixels]']);
                  ylabel(['v [pixels]']);
                subplot(3,4,7)
                  imagesc(ROIA); hold on;    % reference sub-image
                  plot(ku,kv,'+r');          % keypoint
                  axis image;
                  colormap(gray(255));
                  caxis([0 1]);
                  title({['Reference frame'],[ListeImages(refindex).name],...
                         ['Pixel shift: \Deltav = ',num2str(vRef_shift,3),',  \Deltau = ',num2str(uRef_shift,3)]});
                  xlabel(['u [pixels]']);
                  ylabel(['v [pixels]']);
                subplot(3,4,8)
                  imagesc(SROIP); hold on;   % reference sub-image (previous stabilized sub-image)
                  plot(ku,kv,'+r');          % keypoint
                  axis image;
                  colormap(gray(255));
                  caxis([0 1]);
                  title({['Previous stabilized sub-image'],[ListeImages(frameindex(end)).name],...
                         ['Pixel shift with respect to the reference frame: \Deltav = ',num2str(V_shift(end),3),',  \Deltau = ',num2str(U_shift(end),3)]});
                  xlabel(['u [pixels]']);
                  ylabel(['v [pixels]']);
                  subplot(3,4,9)
                    imshowpair(ROIEdgA,ROIEdgB,'ColorChannels','red-cyan'); hold on;
                    plot(ku,kv,'+g');        % keypoint
                    axis image;
                    colormap(gray(255));
                    caxis([0 1]);
                    title({['Reference frame = red'],['Unstabilized sub-image = cyan']});
                  subplot(3,4,10)
                    imshowpair(SROIEdgP,ROIEdgB,'ColorChannels','red-cyan'); hold on;
                    plot(ku,kv,'+g');        % keypoint
                    axis image;
                    colormap(gray(255));
                    caxis([0 1]);
                    title({['Previous stabilized sub-image = red'],['Unstabilized sub-image = cyan']});
                  subplot(3,4,11)
                    imshowpair(SROIEdgP,SROIEdgB{1},'ColorChannels','red-cyan'); hold on;
                    plot(ku,kv,'+g');        % keypoint
                    axis image;
                    colormap(gray(255));
                    caxis([0 1]);
                    title({['Reference frame = red'],['Stabilized sub-image = cyan']});
                  subplot(3,4,12)
                    imshowpair(SROIEdgP,SROIEdgB{2},'ColorChannels','red-cyan'); hold on;
                    plot(ku,kv,'+g');        % keypoint
                    axis image;
                    colormap(gray(255));
                    caxis([0 1]);
                    title({['Previous stabilized sub-image = red'],['Stabilized sub-image = cyan']});
                     
                    clc;
                    display('press some key');
                    pause()
                    reply = input('Keep the stabilized sub-image using the reference frame (1) \nKeep the stabilized sub-image using the previous stabilized image as reference (2) \nStabilize manually with ginput (g) \nDiscard frame (n): ','s');
                           if strcmp(reply,'1')
                              display('Good');
                              display('Please wait...');
                              clf;
                              ll = 1;
                              v_shift = V_SHIFT{1};
                              u_shift = U_SHIFT{1};
                              break
                           end
                           if strcmp(reply,'2')
                              display('Good');
                              display('Please wait...');
                              clf;
                              ll = 2;
                              v_shift = V_SHIFT{2};
                              u_shift = U_SHIFT{2};
                              break
                           end
                           if strcmp(reply,'g')
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
                           end
                           if strcmp(reply,'n')
                              display('This frame will not be taken into account');
                              display('Please wait...');
                              clf;
                              kk = kk+1; % counter
                              badframeindex  = [badframeindex ; ii];
                              BADLISTE{kk,1} = [PathImages,ListeImages(ii).name];
                              condition2 = 1;
                              break
                           end

          end


       % Compute the sub-image pixel shift 
       usfac = 20;             % pixel up-sampling factor (for the cross-correlation)
       output = dftregistration(fft2(ref),fft2(ROIEdgB),usfac); % cross-correlation
       v_shift   = output(3);  % vertical   pixel shift
       u_shift   = output(4);  % horizontal pixel shift
       % Careful!! Guizar-Sicarios invert the pixel shift not consistent with the reference frame pixel coordinates. Invert signs to correct this:
       v_shift = -v_shift;
       u_shift = -u_shift;

       if ll == 3
          % Computes the pixel shift between the manually selected keypoint and the keypoint from the reference frame                                                 
          u_shift = gu-ku;
          v_shift = gv-kv;
       end

       % Image translation (stabilization)
       tform = affine2d([1 0 0; 0 1 0; u_shift v_shift 1]);
       SROIEdgB{ll} = imwarp(ROIEdgB, invert(tform), 'OutputView', imref2d(size(ROIEdgB))); 
       SROIB{ll}    = imwarp(ROIB, invert(tform), 'OutputView', imref2d(size(ROIB))); 

       % Store temporary variables for each case
       V_SHIFT{ll} = v_shift;   % vertical pixel shifts
       U_SHIFT{ll} = u_shift;   % horizontal pixel shifts


       if ll == 3
             subplot(3,4,[1,2,3,4])
               imagesc(SROIB{3}); hold on;  % stabilized sub-image
               plot(ku,kv,'+r');            % keypoint
               axis image;
               colormap(gray(255));
               caxis([0 1]);
               title({['Manually stabilized sub-image'],[ListeImages(ii).name],...
                      ['Pixel shift with respect to the previous stabilized sub-image: \Deltav = ',num2str(V_SHIFT{3}-V_shift(end),3),',  \Deltau = ',num2str(U_SHIFT{3}-U_shift(end),3)],...
                      ['Pixel shift with respect to the reference frame: \Deltav = ',num2str(V_SHIFT{3},3),',  \Deltau = ',num2str(U_SHIFT{3},3)]});
               xlabel(['u [pixels]']);
               ylabel(['v [pixels]']);
             subplot(3,4,11)
               imshowpair(ROIEdgA,SROIEdgB{3},'ColorChannels','red-cyan'); hold on;
               plot(ku,kv,'+g');            % keypoint
               axis image;
               colormap(gray(255));
               caxis([0 1]);
               title({['Reference frame = red'],['Stabilized sub-image = cyan']});
             subplot(3,4,12)
               imshowpair(SROIEdgP,SROIEdgB{3},'ColorChannels','red-cyan'); hold on;
               plot(ku,kv,'+g');            % keypoint
               axis image;
               colormap(gray(255));
               caxis([0 1]);
               title({['Previous stabilized sub-image = red'],['Stabilized sub-image = cyan']});
                
               reply2 = input('Is it now fine? (y/n): ','s');
                      if strcmp(reply2,'y')
                         display('Good');
                         display('Please wait...');
                         clf;
                      end
                      if strcmp(reply2,'n')
                         display('This frame will not be taken into account');
                         display('Please wait...');
                         clf;
                         kk = kk+1; % counter
                         badframeindex  = [badframeindex ; ii];
                         BADLISTE{kk,1} = [PathImages,ListeImages(ii).name];
                         condition2 = 1;
                      end
                break

       end
       
       % Pixel shift threshold 
       if ( abs(v_shift-V_shift(end))<PixelThreshold && abs(u_shift-U_shift(end))<PixelThreshold )
          condition = 1;
       else
          condition = 0;
       end
          
    end % end of while loop 
    
    
    if jj == 0
       V_shift = [];
       U_shift = [];
       frameindex = [];
    end

    if condition2 == 0
       % Store parameters with respect to the reference image
       jj = jj+1; % counter
       V_shift     = [V_shift    ; v_shift ];
       U_shift     = [U_shift    ; u_shift ];
       frameindex  = [frameindex ; ii      ];
       LISTE{jj,1} = [PathImages,ListeImages(ii).name];
       CASE(jj,1)  = ll;  % Pixel shift method
    end
end
% Please wait...
toc
close all;

% Count all the bad data and assign them to Case 4
case4 = ones(length(badframeindex),1).*4;
CASE  = [CASE;case4];

% Horizontal (azimuth) pixel shift
display(['Horizontal (azimuth) pixel shift: Max = ',num2str(max(U_shift)),...          % maximum horizontal (azimuth) pixel shift
                                        ' , Min = ',num2str(min(U_shift)),...          % minimum horizontal (azimuth) pixel shift
                                        ' , Std = ',num2str(std(detrend(U_shift))) ]); % detrended standard deviation of horizontal (azimuth) pixel shift
% Vertical (tilt) pixel shift
display(['Vertical (tilt) pixel shift: Max = ',num2str(max(V_shift)),...               % maximum vertical (tilt) pixel shift
                                   ' , Min = ',num2str(min(V_shift)),...               % minimum vertical (tilt) pixel shift
                                   ' , Std = ',num2str(std(detrend(V_shift))) ]);      % detrended standard deviation of vertical (tilt) pixel shift


%% Plot Pixel Shift %%%%%%%%%%%%

figure_I
% Plot horizontal pixel shift
ax1 = subtightplot(2,1,1,0.05,0.15,0.1);
        p1 = plot(frameindex,U_shift); hold on;
        xlim([frameindex(1),frameindex(end)]);
        set(ax1,'XTickLabel',[]);
        ylabel(['\Deltau [pixels]']);
        set(ax1,'LineWidth',1);
        set(p1,'LineWidth',0.5,'color','b');

% Plot vertical pixel shift
ax2 = subtightplot(2,1,2,0.05,0.15,0.1);
        p2 = plot(frameindex,V_shift); hold on;
        xlim([frameindex(1),frameindex(end)]);
        xlabel(['Frames']);
        ylabel(['\Deltav [pixels]']);
        set(ax2,'LineWidth',1);
        set(p2,'LineWidth',0.5,'color','b');

set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);
set(findall(gcf,'-property','Marker'), 'Marker' , '.');
set(findall(gcf,'-property','MarkerSize'), 'MarkerSize' , 6);

%% Plot histogram of CASES %%%%%%%%%%%%

figure_I
[NN XX] = hist(CASE,[1:4]);
hist(CASE,[1:4]);
lc = length(CASE);
xt = get(gca,'Xtick');
labels = {[num2str(NN(1)/lc*100,2),' %'],[num2str(NN(2)/lc*100,2),' %'],[num2str(NN(3)/lc*100,2),' %'],[num2str(NN(4)/lc*100,2),' %']};
text(xt,NN,labels,'HorizontalAlignment','center','VerticalAlignment','bottom');
xlabel('Case for pixel shift estimation');
ylabel('Frequency [number of frames processed]'); 
set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);



%% Save data %%%%%%%%%%%%

% Create a structure file
eval(['Z',num2str(Zone),'PxSh = struct(''V_shift'',V_shift,''U_shift'',U_shift,''frameindex'',frameindex,''LISTE'',{LISTE},''badframeindex'',badframeindex,''BADLISTE'',{BADLISTE},''CASE'',CASE);']);


% Save the pixel shifts as well as other variables
if exist([PathMatfiles,'ZonePixelShift.mat'],['file'])
   save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone),'PxSh'],'-append');
else
   save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone),'PxSh']);
end

