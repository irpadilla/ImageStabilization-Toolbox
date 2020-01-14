%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% This script is useful to rename the path of the frames saved in the variables LISTE and BADLISTE created by the scripts: ZonePixelShift.mat / ZonePixelShiftCorrected.mat / GeometrictTransformation.mat 
%
% Use this script if the folders containing the frames or the matfiles have been changed or modified
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; clc;

% Previous path used before (check for example Z1PxSh.LISTE{1} inside ZonePixelShift.mat)
OldPathImages   = '/home/irpadilla/Bureau/ImageStabilization-Toolbox/demoClip2/'  ;   % path where the frames/images were stored before

% Path where the files are located now
NewPathImages   = '/.../democlip2/'       ; % path where the frames/images are currently stored. If the frames are stored in different subfolders, please indicate the top-level folder [Please edit]
NewPathMatfiles = '/.../Matfiles/'        ; % path where the matlab files are currently stored  [Please edit]
NewPathRoutines = '/.../Support-Routines/'; % path where the Support-Routines are currently stored [Please edit]
addpath(NewPathRoutines);

% Extension of the images (jpg, png)
ExtImages = 'jpg';

% Select the sub-image zones
Zone = [1:14];


% List frames
ListeImages = rdir([NewPathImages,'/**/*.',ExtImages]); % rdir is used for old Matlab versions
NImages     = length(ListeImages); 
for ii = 1:NImages
    [newfilepath{ii,1},name{ii,1},ext{ii,1}] = fileparts(ListeImages(ii).name);
    framename{ii,1} = [name{ii,1},ext{ii,1}];
end


% ZonePixelShift.mat
if exist([NewPathMatfiles,'ZonePixelShift.mat'],['file'])
   load([NewPathMatfiles,'ZonePixelShift.mat']);
   for ii = 1:length(Zone)
       try
          % Rename variable
          LISTE    = eval(['Z',num2str(Zone(ii)),'PxSh.LISTE']);
          BADLISTE = eval(['Z',num2str(Zone(ii)),'PxSh.BADLISTE']);
   
          N = length(LISTE);
          if N ~= 1 && length(LISTE{1}) ~= 0 % check that the file is not empty
             % Replace the previous path with the current one
             for jj = 1:length(LISTE)
                 [~,nameLISTE,extLISTE] = fileparts(LISTE{jj}); 
                 framenameLISTE = [nameLISTE,extLISTE];
                 indexLISTE = find(strcmp(framename,framenameLISTE));
                 eval(['Z',num2str(Zone(ii)),'PxSh.LISTE{jj} = [newfilepath{indexLISTE},''/'',framenameLISTE];']);
             end
          end

          M = length(BADLISTE);
          if M ~= 1 && length(BADLISTE{1}) ~= 0 % check that the file is not empty
             % Replace the previous path with the current one
             for jj = 1:length(BADLISTE)
                 [~,nameBADLISTE,extBADLISTE] = fileparts(BADLISTE{jj}); 
                 framenameBADLISTE = [nameBADLISTE,extBADLISTE];
                 indexBADLISTE = find(strcmp(framename,framenameBADLISTE));
                 eval(['Z',num2str(Zone(ii)),'PxSh.BADLISTE{jj} = [newfilepath{indexBADLISTE},''/'',framenameBADLISTE];']);
             end
          end

          % Overwrite the files with the updated path
          save([NewPathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone(ii)),'PxSh'],'-append');  

          % clear variable
          eval(['clear Z',num2str(Zone(ii)),'PxSh']);

       end 
   end
end



% ZonePixelShiftCorrected.mat
if exist([NewPathMatfiles,'ZonePixelShiftCorrected.mat'],['file'])
   load([NewPathMatfiles,'ZonePixelShiftCorrected.mat']);
   for ii = 1:length(Zone)
       try
          % Rename variable
          LISTE    = eval(['Z',num2str(Zone(ii)),'PxSh.LISTE']);
          BADLISTE = eval(['Z',num2str(Zone(ii)),'PxSh.BADLISTE']);
   
          N = length(LISTE);
          if N ~= 1 && length(LISTE{1}) ~= 0 % check that the file is not empty
             % Replace the previous path with the current one
             for jj = 1:N
                 [~,nameLISTE,extLISTE] = fileparts(LISTE{jj}); 
                 framenameLISTE = [nameLISTE,extLISTE];
                 indexLISTE = find(strcmp(framename,framenameLISTE));
                 eval(['Z',num2str(Zone(ii)),'PxSh.LISTE{jj} = [newfilepath{indexLISTE},''/'',framenameLISTE];']);
             end
          end

          M = length(BADLISTE);
          if M ~= 1 && length(BADLISTE{1}) ~= 0 % check that the file is not empty
             % Replace the previous path with the current one
             for jj = 1:M
                 [~,nameBADLISTE,extBADLISTE] = fileparts(BADLISTE{jj}); 
                 framenameBADLISTE = [nameBADLISTE,extBADLISTE];
                 indexBADLISTE = find(strcmp(framename,framenameBADLISTE));
                 eval(['Z',num2str(Zone(ii)),'PxSh.BADLISTE{jj} = [newfilepath{indexBADLISTE},''/'',framenameBADLISTE];']);
             end
          end

          % Overwrite the files with the updated path
          save([NewPathMatfiles,'ZonePixelShiftCorrected.mat'],['Z',num2str(Zone(ii)),'PxSh'],'-append');  

          % clear variable
          eval(['clear Z',num2str(Zone(ii)),'PxSh']);

       end 
   end
end


% GeometricTransformation.mat
if exist([NewPathMatfiles,'GeometricTransformation.mat'],['file'])
   load([NewPathMatfiles,'GeometricTransformation.mat']);
   try
      % Rename variable
      LISTE = TFORM.LISTE;

      % Replace the previous path with the current one
      for jj = 1:length(LISTE)
          [~,nameLISTE,extLISTE] = fileparts(LISTE{jj}); 
          framenameLISTE = [nameLISTE,extLISTE];
          indexLISTE = find(strcmp(framename,framenameLISTE));
          TFORM.LISTE{jj} = [newfilepath{indexLISTE},'/',framenameLISTE];
      end

      % Overwrite the files with the updated path
      save([NewPathMatfiles,'GeometricTransformation.mat'],['TFORM']);  

   end
end

