% Build necessary mex files.
%

% mex_ersv.mex
%
disp('building mex_ersv.mex...');
mex -O ERS/mex_ersv.cpp ERS/MERC*.cpp

% Coarse2FineTwoFrames.mex
% READ the readme file in the CeLiuOpticalFlow directory.
%
disp('building Coarse2FineTwoFrames.mex...');
mex -O CeLiuOpticalFlow/Coarse2FineTwoFrames.cpp ...
  CeLiuOpticalFlow/OpticalFlow.cpp ...
  CeLiuOpticalFlow/GaussianPyramid.cpp
