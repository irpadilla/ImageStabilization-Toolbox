%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Add relevant paths to Matlab
%
% Be sure to create or indicate the folders where the matfiles, figures and videos are going to be stored
%
% | Isaac Rodriguez-Padilla, Nov-2019 |
%
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


% Add relevant paths to Matlab
Path = '/home/irpadilla/Bureau/ImageStabilization-Toolbox/'; % main path where the image stabilization toolbox is located
PathImages   = [Path,'Frames/'                  ]; % path where the frames are stored. If the frames are stored in different subfolders, please indicate the top-level folder
PathStabilizedImages = [Path,'StabilizedFrames/']; % path where the stabilized frames will be stored 
ExtImages    = ['jpg'                     ];   % extension of the images (jpg, png)
PathMatfiles = [Path,'Matfiles/'          ];   % path where the matlab files are or will be stored
PathFigures  = [Path,'Figures/'           ];   % path where the figures are or will be stored
PathMovies   = [PathFigures,'Movies/'     ];   % path where the videos are or will be stored
PathRoutines = [Path,'Support-Routines/'  ];   % path where the Support-Routines are stored
addpath(PathRoutines);

