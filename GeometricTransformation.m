%---------------------------------------------------------------------------------------------------------------------------------------------------
% Uses the previoulsy computed pixel shifts (keypoint matching) to perform a geometric transformation to stabilize the whole image sequence
% 
% 
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat -----------> generated with ZoneSelection.m
%        ZonePixelShift.mat --> generated with ZonePixelShift.m | use ZonePixelShiftCorrected.mat if ZonePixelShiftCorrection.m was used
%
% MANUALLY INPUT: 
%        Zone ----> select which sub-image zones (i.e., keypoints) to use for the geometric transformation   
%        Gtrans --> select geometric transformation type according to the minimum number of keypoints
%           Example:
%                   Gtrans = 'nonreflectivesimilarity'; % min of 2 keypoints
%                   Gtrans = 'similarity';              % min of 3 keypoints 
%                   Gtrans = 'affine';                  % min of 3 keypoints
%                   Gtrans = 'projective';              % min of 4 keypoints 
%      
% OUTPUT:
%        GeometricTransformation.mat
%        TFORM. 
%              Gtrans ------> name of the geometric transformation used to stabilized the image       
%              tform -------> geometric transformation matrix used to stabilized the image       
%              frameindex --> index of the frames      
%              LISTE -------> cell array containing the names of the frames
%              U_shift -----> horizontal keypoint pixel shift
%              V_shift -----> vertical   keypoint pixel shift
%        GeometricTransformation.png --> this figures is only created if 'nonreflectivesimilarity' or 'similarity' transformation is selected 
%
%
% Note:
%
% u  = referenece image keypoints [pointsRef]
% u' = shifted image keypoints    [pointsA]
% T  = geometric transformation  
%
% Generally we see: u'=Tu
%                   u =(T^-1)u'
%
% However, in this case matlab does:
%                   u =Tu'      ; T == tform 
%                   u'=(T^-1)u  ; T^-1 == invert(tform)
%
% So we are interested in Tinv = invert(tform) so the transformation parameters are properly referenced respect u.    
%
%
% The difference between U_shift and azimuth_shift, and V_shift and tilt_shift is the following:
%     azimuth_shift and tilt_shift are general image translation values computed for the whole image via a geometric transformation ('nonreflectivesimilarity' or 'similarity') using the keypoints correspondences.
%     U_shift and V_shift are the keypoints translational movements computed (and only valid) for each sub-image zone.
% 
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%---------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; clc;                                                                                                                                                                

% Add relevant paths
SetPath; 

% Select which sub-image zones (i.e., keypoints) to use for the geometric transformation
Zone  = [1:14]; 

% Select geometric transformation type (according to the minimum number of keypoints)
%Gtrans = 'nonreflectivesimilarity'; % min of 2 keypoints
%Gtrans = 'similarity';              % min of 3 keypoints 
%Gtrans = 'affine';                  % min of 3 keypoints
Gtrans = 'projective';              % min of 4 keypoints 


% Load sub-image region zones and keypoints
load([PathMatfiles,'Zones.mat']);

% Load Pixel Shift
load([PathMatfiles,'ZonePixelShift.mat']);
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if pixel shifts were corrected with ZonePixelShiftCorrection.m
frameindex = eval(['Z',num2str(Zone(1)),'PxSh.frameindex;']);
for ii = 2:length(Zone)
    % Set the intersection of time (this case frame index) between the different Zones 
    frameindex = eval(['intersect(frameindex,Z',num2str(Zone(ii)),'PxSh.frameindex);']);
end


% Using the intersection frames between zones, find the pixel shift index
U_shift = [];
V_shift = [];
for ii = 1:length(Zone)
      [~,~,I{ii}] = eval(['intersect(frameindex,Z',num2str(Zone(ii)),'PxSh.frameindex);']); % find the intersected index
      U_shift = [U_shift, eval(['Z',num2str(Zone(ii)),'PxSh.U_shift(I{ii});'])]; 
      V_shift = [V_shift, eval(['Z',num2str(Zone(ii)),'PxSh.V_shift(I{ii});'])]; 
      % Keypoints
      kuu(ii) = eval(['Z',num2str(Zone(ii)),'.kuu;']);
      kvv(ii) = eval(['Z',num2str(Zone(ii)),'.kvv;']); 
end

% Using the intersection between frames, find the name of the files
LISTE = eval(['Z',num2str(Zone(1)),'PxSh.LISTE(I{1});']); 

% if there is a time vector, find the intersection index
if isfield(eval(['Z',num2str(Zone(ii)),'PxSh']),['time'])
   time = eval(['Z',num2str(Zone(ii)),'PxSh.time(I{ii});']);
end

% Correspondence between points
pointsREF = [kuu',kvv']; % Keypoints

h = waitbar(0,'Please wait...');
for jj = 1:length(frameindex)

      % Correspondence between points
      pointsA   = [kuu'+U_shift(jj,:)',kvv'+V_shift(jj,:)'];
      
      % Apply geometric transformation
      tform(jj,1) = fitgeotrans(pointsA,pointsREF,Gtrans);
     
      % Invert the transformation matrix so everything is relative to the reference image
      Tinv(jj,1) = invert(tform(jj,1));

      if strcmp(Gtrans,'nonreflectivesimilarity')==1 || strcmp(Gtrans,'similarity')==1

         % Extract scale and rotation part sub-matrix
         H = Tinv(jj).T;
         R = H(1:2,1:2);
   
         % Compute theta (roll) from mean of two possible arctangents
         roll_shift(jj,1) = rad2deg(mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]));
         
         % Compute scale from mean of two stable mean calculations
         scale(jj,1) = mean(R([1 4])/cos(roll_shift(jj)));

         % Translation
         translation = H(3, 1:2);
         azimuth_shift(jj,1) = translation(1,1);
         tilt_shift(jj,1)    = translation(1,2);
      end

waitbar(jj/length(frameindex),h)
end
close(h);


if strcmp(Gtrans,'nonreflectivesimilarity')==1 || strcmp(Gtrans,'similarity')==1

   figure('units','normalized','outerposition',[0 0 1 1]);
   X1=0; Y1=0; X2=10; Y2=12;
   set(gcf, 'Units', 'inches');
   set(gcf,'position',[X1 Y1 X2 Y2]);
   set(gcf, 'Resize', 'off');
   set(gcf,'paperposition',[X1 Y1 X2 Y2]);
   set(gcf,'color','w');

   % Plot horizontal pixel shift (azimuth deviation)
   ax1 = subtightplot(4,1,1,0.02,0.15,0.1);
         if exist('time')
            p1 = plot(time,azimuth_shift,'.-'); hold on;
            datetick('x','dd-mmm-yyyy','keeplimits');  % edit for better viewing
            xlim([time(1),time(end)]);
         else
            p1 = plot(frameindex,azimuth_shift,'.-'); hold on;
            xlim([frameindex(1),frameindex(end)]);
         end
         set(ax1,'XTickLabel',[]);
         ylabel(['\DeltaAzimuth [pixels]']);
         set(ax1,'LineWidth',1);
         set(p1,'LineWidth',1,'color','b');
   % Plot vertical pixel shift (tilt deviation)
   ax2 = subtightplot(4,1,2,0.02,0.15,0.1);
         if exist('time')
            p2 = plot(time,tilt_shift,'.-'); hold on;
            datetick('x','dd-mmm-yyyy','keeplimits');  % edit for better viewing
            xlim([time(1),time(end)]);
         else
            p2 = plot(frameindex,tilt_shift,'.-'); hold on;
            xlim([frameindex(1),frameindex(end)]);
         end
         set(ax2,'XTickLabel',[]);
         ylabel(['\DeltaTilt [pixels]']);
         set(ax2,'LineWidth',1);
         set(p2,'LineWidth',1,'color','b');
   % Plot rotation (roll deviation)
   ax3 = subtightplot(4,1,3,0.02,0.15,0.1);
         if exist('time')
            p3 = plot(time,roll_shift,'.-'); hold on;
            datetick('x','dd-mmm-yyyy','keeplimits');  % edit for better viewing
            xlim([time(1),time(end)]);
         else
            p3 = plot(frameindex,roll_shift,'.-'); hold on;
            xlim([frameindex(1),frameindex(end)]);
         end
         set(ax3,'XTickLabel',[]);
         ylabel(['\DeltaRoll [\circ]']);
         set(ax3,'LineWidth',1);
         set(p3,'LineWidth',1,'color','b');
   % Plot scaling
   ax4 = subtightplot(4,1,4,0.02,0.15,0.1);
         if exist('time')
            p4 = plot(time,scale,'.-'); hold on;
            datetick('x','dd-mmm-yyyy','keeplimits');  % edit for better viewing
            xlim([time(1),time(end)]);
            xlabel('Time');
         else
            p4 = plot(frameindex,scale,'.-'); hold on;
            xlim([frameindex(1),frameindex(end)]);
            xlabel('Frames');
         end
         ylabel(['Scale']);
         set(ax4,'LineWidth',1);
         set(p4,'LineWidth',1,'color','b');
         
   set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);
   set(findall(gcf,'-property','MarkerSize'), 'MarkerSize' , 12);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data

if strcmp(Gtrans,'nonreflectivesimilarity')==1 || strcmp(Gtrans,'similarity')==1

   % Create a structure file
   if exist('time')
      TFORM = struct('Gtrans',Gtrans,'tform',tform,'time',time,'frameindex',frameindex,'LISTE',{LISTE},'U_shift',U_shift,'V_shift',V_shift,'azimuth_shift',azimuth_shift,'tilt_shift',tilt_shift,'roll_shift',roll_shift,'scale',scale);
   else
      TFORM = struct('Gtrans',Gtrans,'tform',tform,'frameindex',frameindex,'LISTE',{LISTE},'U_shift',U_shift,'V_shift',V_shift,'azimuth_shift',azimuth_shift,'tilt_shift',tilt_shift,'roll_shift',roll_shift,'scale',scale);
   end
   
   % Save figure
   print([PathFigures,'GeometricTransformation.png'],'-dpng','-r300'); 

else

   % Create a structure file
   if exist('time')
      TFORM = struct('Gtrans',Gtrans,'tform',tform,'time',time,'frameindex',frameindex,'LISTE',{LISTE},'U_shift',U_shift,'V_shift',V_shift);
   else
      TFORM = struct('Gtrans',Gtrans,'tform',tform,'frameindex',frameindex,'LISTE',{LISTE},'U_shift',U_shift,'V_shift',V_shift);
   end

end


% Save the pixel shifts as well as other variables
save([PathMatfiles,'GeometricTransformation.mat'],['TFORM']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


