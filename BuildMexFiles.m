% Build necessary mex files.
%

% mex_ersv.mex
%
disp('building mex_ersv.mex...');
mex -O ERS/mex_ersv.cpp ERS/MERC*.cpp

% Coarse2FineTwoFrames.mex
% READ the readme file in the CeLiuOpticalFlow directory.
% In MacOS, I had to edit project.h as in the readme file, and additionally
% edit two following lines.
%   OpticalFlow.cpp line 833 : abs -> ::abs
%   Stochastic.h line 245 : pWeight=NULL -> pWeight==NULL
% Note that the mex interface is changed so the Coarse2FineTwoFrames.cpp 
% file in CeLiuOpticalFlow/ is used instead of the one in mex/.
%
disp('building Coarse2FineTwoFrames.mex...');
mex -O CeLiuOpticalFlow/Coarse2FineTwoFrames.cpp ...
  CeLiuOpticalFlow/OpticalFlow.cpp ...
  CeLiuOpticalFlow/GaussianPyramid.cpp
