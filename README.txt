Image stabilization toolbox:

This toolbox contain the neccessary scripts to stabilize an image-sequence

The order in which the scripts should be used are indicated with numbers. Numbers inside brackets are optional scripts.

Optional:
(0)   - CorrectPath.m <-- Edit this file if you want to use the scripts with the already created .mat files               

Image Stabilization:
 1    - SetPath.m <------------------- Edit this file before starting
 2    - ZoneSelection.m -------------> PlotZoneSelection.m  | PlotSubimageStabilization.m                     
 3    - ZonePixelShift.m ------------> PlotZonePixelShift.m | HistogramCases.m | PlotSubimageStabilizationExample.m | SubimageStabilizationVideo.m
 4    - GeometricTransformation.m ---> PlotImageStabilizationExample | ImageStabilizationVideo.m

Optional scripts:
(3.1) - ZonePixelShiftCorrection.m --> PlotZonePixelShift.m | HistogramCases.m | PlotSubimageStabilizationExample.m | SubimageStabilizationVideo.m
(3.2) - ZoneTimeVector.m <------------ Edit this file to extract the time information from the name of the frames


The scripts were created with Matlab version: 8.2.0.701 (R2013b)


| Isaac Rodriguez-Padilla, Nov-2019 |
