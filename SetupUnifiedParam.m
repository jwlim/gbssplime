%==========================================================================
% Genralized Background Subtraction using Superpixels and Label Integrated
%   Motion Estimation (ECCV 2014)
% 
% Setup unified parameters.
% 
% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
%     based on the implementation by Suha Kwak (POSTECH)
%==========================================================================

% The number of rounds for iterative model-label estimation.
nround = 3;

num_superpixels = 300;  % [50 100 200]; [50 200 400];
num_seg = numel(num_superpixels);

flow_param = [0.012, 0.75, 20, 3, 1, 1];

% motion flags
SUPERPIXEL = 'ers';  % 'ers', 'grid' - for_comparison;

% For comparison
global SINGLE_MOTION;  %- Used in ComputeMotion.
global USE_CONSISTENCY_MASK;  %- In LikelihoodComp.

SINGLE_MOTION = false;
USE_CONSISTENCY_MASK = ~SINGLE_MOTION;

% The parameters for appearance and motion estimation.
%  - minpratio: how many pixels are needed to be an observation of a block
%  - kstd     : (minimum) bandwidth of the kernels for KDE (observation)
%  - nghd     : mix rate for models from neighbors

minpratio = 0.1;  % 1e-1 or 2e-2 (2,7)

Pc_BG.minpratio = minpratio;
Pc_BG.kstd = 10;  % 5, 10  //, 12
Pc_BG.nghb = 0.1;  % 0.1, 0.5, 0.4, 1
Pc_BG.foreground = false;

Pc_FG.minpratio = minpratio;
Pc_FG.kstd = 10;  % 10  //, 6
Pc_FG.nghb = 0.1;  % 0.3, 0, 0.2, 0.5
Pc_FG.foreground = true;

Pv_BG.minpratio = minpratio;
Pv_BG.kstd = 3;  % 1, 0.5
Pv_BG.nghb = 0.1;  % 0.1, 0.5, 0.4, 1
Pv_BG.foreground = false;

Pv_FG.minpratio = minpratio;
Pv_FG.kstd = 3;  % 1, 0.5, 0.3, 0.2, 1e-5
Pv_FG.nghb = 0.1;  % 0.1, 0.5, 0.4, 1
Pv_FG.foreground = true;

% The parameters for temporal propagation (prediction).
%  - transtd : BW of the state transition probability (Gaussian conv.)

Pt.transtd = 7;

% The parameters for pixel-wise label estimation.
%  - tempa : temperature parameter for appearance observation likelihoods
%  - tempm : temperature parameter for motion observation likelihoods

Pl.tempa = 0.7;  % 0.9, 0.7, 1, 0.5
Pl.tempm = 0.3;  % 0.1, 0, 0.5, 0.5

% The pamemters used in LabelEst(BP).
%  - nrnd : the number of looopy BP rounds
%  - cvar : bandwidth (variance) for compatibility clique potential
%  - epsc : the lower bound of compatibility clique potentials
%  - epso : the lower bound of observation clique potentials
%  - conv : std for motion model convolution (motion likelihood)

Pl.nrnd = 10;
Pl.cvar = 5;  % 5, 50
Pl.epsc = 0.15;  % 0.15, 0.1
Pl.epso = 0.1;  % 0.15, 0.1

Pl.like_nomodel_app = eps;
Pl.like_nomodel_mot = eps;

% Save parameters and the associated information.
save([rpath, 'param.mat'], 'vpath', 'rpath', ...
  'nround', 'Pv_BG', 'Pv_FG', 'Pt', 'Pc_BG', 'Pc_FG', 'Pl', ...
  'num_superpixels', 'SUPERPIXEL', ...
  'SINGLE_MOTION', 'USE_CONSISTENCY_MASK');

