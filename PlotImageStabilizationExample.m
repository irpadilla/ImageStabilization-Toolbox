%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Uses the previously computed pixel shifts (keypoint matching) to perform a geometric transformation to stabilize a pair of images with respect to a reference frame
%
% This script is useful to have an idea which geometric transformation type to use before running GeometricTransformation.m
%
%
% REQUIREMENTS: 
%        SetPath --------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat ------------> generated with ZoneSelection.m
%        ZonePixelShift.mat ---> generated with ZonePixelShift.m | use ZonePixelShiftCorrected.mat if ZonePixelShiftCorrection.m was used
%
% MANUALLY INPUT: 
%        Zone -----------------> select which sub-image zones (i.e., keypoints) to use for the geometric transformation   
%        refname --------------> specify the name of the reference frame (the same one choosed in ZoneSelection.m and ZonePixelShift.m)
%        Aname & Bname --------> specify the name of the frames you want to stabilize with respect to the reference frame (refname)
%        keypoints(optional) --> specify if you want to overplot the keypoints in the final image (y/n) [default is 'y']
%        Gtrans ---------------> select geometric transformation type according to the minimum number of keypoints
%           Example:
%                   Gtrans = 'nonreflectivesimilarity'; % min of 2 keypoints
%                   Gtrans = 'similarity';              % min of 3 keypoints 
%                   Gtrans = 'affine';                  % min of 3 keypoints
%                   Gtrans = 'projective';              % min of 4 keypoints 
%
% OUTPUT:
%        [transformation]Stabilization_Bname.png
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; clc;                                                                                                                                                                

% Add relevant paths
SetPath; 

% Select which sub-image zones (i.e., keypoints) to use for the geometric transformation
Zone  = [1:14]; 

% Specify the reference frame
refname = '00000001.jpg'; % reference frame name

% Specify the two frames to stabilize with respect to the reference frame 
Aname = '00000001.jpg';   % name of the unstabilized frame (can also be the reference frame)
Bname = '00000080.jpg';   % name of the unstabilized frame

% Select geometric transformation type (according to the minimum number of keypoints)
%Gtrans = 'nonreflectivesimilarity'; % min of 2 keypoints
%Gtrans = 'similarity';              % min of 3 keypoints 
%Gtrans = 'affine';                  % min of 3 keypoints
Gtrans = 'projective';              % min of 4 keypoints 

% Want to overplot keypoints (y/n)?
keypoints = 'y'; 

% Load sub-image region zones and keypoints
load([PathMatfiles,'Zones.mat']);

% Load Pixel Shift
load([PathMatfiles,'ZonePixelShift.mat']); 
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if pixel shifts were corrected with ZonePixelShiftCorrection.m
frameindex = eval(['Z',num2str(Zone(1)),'PxSh.frameindex;']);
for ii = 2:length(Zone)
    % Set the intersection of time (this case frame index) between the different zones 
    frameindex = eval(['intersect(frameindex,Z',num2str(Zone(ii)),'PxSh.frameindex);']);
end


% Using the intersection between zones, find the pixel shift index
for ii = 1:length(Zone)
      [~,~,I{ii}] = eval(['intersect(frameindex,Z',num2str(Zone(ii)),'PxSh.frameindex);']); % find the intersected index
      V_shift{ii} = eval(['Z',num2str(Zone(ii)),'PxSh.V_shift(I{ii});']); 
      U_shift{ii} = eval(['Z',num2str(Zone(ii)),'PxSh.U_shift(I{ii});']); 
      LISTE       = eval(['Z',num2str(Zone(ii)),'PxSh.LISTE(I{ii});']);
      clear name ext framename;
      for jj = 1:length(LISTE)
           [~,name{jj,1},ext{jj,1}] = fileparts(LISTE{jj});
           framename{jj,1} = [name{jj,1},ext{jj,1}];
      end 
      Aindex = find(strcmp(framename,Aname)==1);  % index of the frame A
      Bindex = find(strcmp(framename,Bname)==1);  % index of the frame B
      if isempty(Aindex)
         error(['The frame ',Aname,' for zone ',num2str(Zone(ii)),' has not been found. Probably it was discarded during ZonePixelShift.m or the path where the images are stored have been modified (i.e. check the variable LISTE and correct with CorrectPath.m if this is the case). Maybe try with another frame']);
      end
      if isempty(Bindex)
         error(['The frame ',Bname,' for zone ',num2str(Zone(ii)),' has not been found. Probably it was discarded during ZonePixelShift.m or the path where the images are stored have been modified (i.e. check the variable LISTE and correct with CorrectPath.m if this is the case). Maybe try with another frame']);
      end
      % Find the pixel shift index for the specific frame A and B
      U_shiftA(ii) = U_shift{ii}(Aindex);
      V_shiftA(ii) = V_shift{ii}(Aindex);
      U_shiftB(ii) = U_shift{ii}(Bindex);
      V_shiftB(ii) = V_shift{ii}(Bindex);
      % Keypoints
      kuu(ii) = eval(['Z',num2str(Zone(ii)),'.kuu;']);
      kvv(ii) = eval(['Z',num2str(Zone(ii)),'.kvv;']); 
end


% Keypoint matching
pointsREF = [kuu',kvv']; 
pointsA   = [kuu'+U_shiftA',kvv'+V_shiftA'];
pointsB   = [kuu'+U_shiftB',kvv'+V_shiftB'];

% Find frame A and B
LISTEA = cell2mat(LISTE(Aindex));
LISTEB = cell2mat(LISTE(Bindex));

% Load images
imgA = im2double(imread(LISTEA));
imgB = im2double(imread(LISTEB));

% Convert to gray scale
imgA = rgb2gray(imgA);
imgB = rgb2gray(imgB);


%% Image stabilization

figure_I
% Unstabilized images
subtightplot(1,2,1,0.01,0.15,0.1)
imshowpair(imgA,imgB,'ColorChannels','red-cyan'); hold on;
if refname == Aname
    title({['Reference frame (',refname,') = red '],['Unstabilized frame (',Bname,') = cyan']});
else
    title({['Unstabilized frame (',Aname,') = red '],['Unstabilized frame (',Bname,') = cyan']});
end
set(gca,'LineWidth',1); 

% Overplot keypoints
if strcmp(keypoints,'y')==1
   plot(pointsA(:,1),pointsA(:,2),'+r');
   plot(pointsB(:,1),pointsB(:,2),'+c');
   set(findall(gcf,'-property','MarkerSize'), 'MarkerSize' , 6);
end

%% Step 4. Estimating Transform from Noisy Correspondences
% translate image A to reference image
tform_A  = fitgeotrans(pointsA,pointsREF,Gtrans);
imgA_stb = imwarp(imgA, tform_A, 'OutputView', imref2d(size(imgA))); 
% translate image B to reference image
tform_B  = fitgeotrans(pointsB,pointsREF,Gtrans);
imgB_stb = imwarp(imgB, tform_B, 'OutputView', imref2d(size(imgB))); 

% Stabilized images
subtightplot(1,2,2,0.01,0.15,0.1)
imshowpair(imgA_stb,imgB_stb,'ColorChannels','red-cyan'); hold on;
if refname == Aname
    title({['Reference frame (',refname,') = red '],['Stabilized frame (',Bname,') = cyan']});
else
    title({['Stabilized frame (',Aname,') = red '],['Stabilized frame (',Bname,') = cyan']});
end
set(gca,'LineWidth',1); 

% Overplot keypoints
if strcmp(keypoints,'y')==1
   plot(kuu',kvv','+g');
   set(findall(gcf,'-property','MarkerSize'), 'MarkerSize' , 6);
end

set(findall(gcf,'-property','FontSize'), 'Fontsize', 12);

% save figure
print([PathFigures,Gtrans,'Stabilization_',name{Bindex},'.png'],'-dpng','-r300');


