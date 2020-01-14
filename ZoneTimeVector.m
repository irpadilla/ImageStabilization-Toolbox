%-------------------------------------------------------------------------------------------------------------
% Creates a time vector from the variable LISTE [name of the .jpg files] and from the variable BADLISTE [name of the discarded frames] 
%          Example used in this script: 20181005-092453-409.jpg [EDIT THE SCRIPT IF OTHER FORMAT IS USED] 
%
% REQUIREMENTS: 
%        SetPath -------------> generated with SetPath.m to add the relevant paths to Matlab 
%        ZonePixelShift.mat --> generated with ZonePixelShift.m | use ZonePixelShiftCorrected.mat if ZonePixelShiftCorrection.m was used
%
% MANUALLY INPUT: 
%        Zone -----> sub-image zones     
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
%               time -----------> time according to the names in LISTE       
%               badtime --------> time according to the names of BADLISTE       
%
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%-------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 

% Select the sub-image zone(s)
Zone = [1,2,3,4];

% Load pixel shift
load([PathMatfiles,'ZonePixelShift.mat']); 
%load([PathMatfiles,'ZonePixelShiftCorrected.mat']); % use this instead of the previous line if pixel shifts were corrected with ZonePixelShiftCorrection.m 

for ii = 1:length(Zone)
    
    
    % Rename for convenience
    LISTE    = eval(['Z',num2str(Zone(ii)),'PxSh.LISTE;']); 
    BADLISTE = eval(['Z',num2str(Zone(ii)),'PxSh.BADLISTE;']); 
    

    % Loop over the frames
    N = length(LISTE);
    if N ~= 1 && length(LISTE{1}) ~= 0 % check that the file is not empty
       for jj = 1:N

           % Extract only the name of the frame
           [~,name,~] = fileparts(LISTE{jj});

           % Extract the date from the name [EDIT IF NECCESSARY]
           year   = str2num( name(1:4)   );
           month  = str2num( name(5:6)   );
           day    = str2num( name(7:8)   );
           hour   = str2num( name(10:11) );
           minute = str2num( name(12:13) );
           sec    = str2num( name(14:15) );
           eval(['Z',num2str(Zone(ii)),'PxSh.time(jj,1) = datenum(year,month,day,hour,minute,sec);']);
       end
    end
    
    % Loop over the frames
    M = length(BADLISTE);
    if M ~= 1 && length(BADLISTE{1}) ~= 0 % check that the file is not empty
       for kk = 1:M

           % Extract only the name of the discarded frames
           [~,name,~] = fileparts(BADLISTE{kk});

           % Extract the date from the name [EDIT IF NECCESSARY]
           year   = str2num( name(1:4)   );
           month  = str2num( name(5:6)   );
           day    = str2num( name(7:8)   );
           hour   = str2num( name(10:11) );
           minute = str2num( name(12:13) );
           sec    = str2num( name(14:15) );
           eval(['Z',num2str(Zone(ii)),'PxSh.badtime(kk,1) = datenum(year,month,day,hour,minute,sec);']);
       end
    end
    %% Overwrite the variable including the time index
    if exist([PathMatfiles,'ZonePixelShift.mat'],['file'])
       save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone(ii)),'PxSh'],'-append');
    else
       save([PathMatfiles,'ZonePixelShift.mat'],['Z',num2str(Zone(ii)),'PxSh']);
    end
    
    
    %% Use this if you want to overwrite the file: ZonePixelShiftCorrected.m
    %if exist([PathMatfiles,'ZonePixelShiftCorrected.mat'],['file'])
    %   save([PathMatfiles,'ZonePixelShiftCorrected.mat'],['Z',num2str(Zone(ii)),'PxSh'],'-append');
    %else
    %   save([PathMatfiles,'ZonePixelShiftCorrected.mat'],['Z',num2str(Zone(ii)),'PxSh']);
    %end

end
