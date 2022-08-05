%--------------------------------------------------------------------------------------------------------------------------------------------
%  Use the transformation parameters to stabilize the image sequence and save each stabilized image
%
%
% REQUIREMENTS: 
%        SetPath ----------------------> generated with SetPath.m to add the relevant paths to Matlab 
%        Zones.mat --------------------> generated with ZoneSelection.m
%        ZonePixelShift.mat -----------> generated with ZonePixelShift.m
%        GeometricTransformation.mat --> generated with GeometricTransformation.m
%
%
% | Isaac Rodriguez-Padilla, Aug-2020 |
%
%--------------------------------------------------------------------------------------------------------------------------------------------

clear all; close all; fclose('all'); clc

% Add relevant paths
SetPath; 

% Load geometric transformation parameters 
load([PathMatfiles,'GeometricTransformation.mat']);                                                                                              

% Rename variables
tform      = TFORM.tform;
LISTE      = TFORM.LISTE;
clear TFORM;

% Number of frames
NImages = length(LISTE);

% Image loop
wb = waitbar(0,'Please wait...');
for ii = 1:NImages

    B = im2double(imread(LISTE{ii})); % load image

    % Image stabilization
    SB = imwarp(B, tform(ii), 'OutputView', imref2d(size(B)));
    
    % Extract name of the frame
    [~,name,ext] = fileparts(LISTE{ii});
    framename = [name,ext];

    % Save figure
    imwrite(SB,[PathStabilizedImages,framename],'jpg','Quality',95);

waitbar(ii/NImages,wb)
end
close(wb);




