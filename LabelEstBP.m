
function [L, ObsPotAllRaw] = LabelEstBP(I, ObsPot, Pl)
  % [input]
  %   I     : input image
  %   Qc_BG : block-wise appearance models for background (predicted)
  %   Qc_FG : block-wise appearance models for foreground (predicted)
  %   O     : optical flow map of the current time step
  %   Qv_BG : block-wise motion model for background
  %   Qv_FG : block-wise motion model for foreground
  %   B       : the superpixel blocks in the previous and current frame
  %     - S     : superpixel labels.
  %     - G     : the pairwise graph structure (a binary matrix)
  %     - bnum  : the number of superpixels
  %   Pl    : the specification of the blocks
  %   - nrnd      : the number of looopy BP rounds
  %   - cvar      : bandwidth (variance) for compatibility clique potential
  %   - tempa     : temperature parameter for appearance observation likelihoods
  %   - tempm     : temperature parameter for motion observation likelihoods
  %   - epsc      : the lower bound of compatibility clique potentials
  %   - epso      : the lower bound of observation clique potentials
  % [return]
  %   L           : pixel-wise labels (BG/FG)

% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
% Previous history:
%==========================================================================
% Estimation of Floating BG/FG Model by Nonparametric Belief Propagation
% Label estimation by conventional pixel-wise BP
% 2011. 2. 12. Suha Kwak, POSTECH.
% 2011. 2. 23. Modified by Woonhyun Nam, POSTECH
% 2013. 3. 27. Modified by Bohyung Han, POSTECH
%==========================================================================


% PRELIMINARY
% image size
[h, w, ~] = size(I);
% number of segmentations
num_seg = numel(ObsPot);

% enumerator
BG = 1; FG = 2;
LEFT = 1; RIGHT = 2; UPPER = 3; LOWER = 4;
SAME = 1; DIFF = 2;


% compatibility clique potentials =========================================
CmpPot = ones(h, w, 4, 2);
    % h, w : node indices
    % 4    : four direction (1=left, 2=right, 3=upper, 4=lower)
    % 2    : two cases, whether the two labels are same(1) or not(2)
imdif_LR = sum(((I(:, 2:w, :) - I(:, 1:w-1, :)) ./ 255) .^ 2, 3);
imdif_TB = sum(((I(2:h, :, :) - I(1:h-1, :, :)) ./ 255) .^ 2, 3);

% compatibility clique potential for the case of two same labels
CmpPot(:, 2:w, LEFT, SAME) = exp(-imdif_LR ./ Pl.cvar);     % with the left-neighboring node
CmpPot(:, 1:w-1, RIGHT, SAME) = exp(-imdif_LR ./ Pl.cvar);  % with the right-neighboring node
CmpPot(2:h, :, UPPER, SAME) = exp(-imdif_TB ./ Pl.cvar);    % with the upper-neighboring node
CmpPot(1:h-1, :, LOWER, SAME) = exp(-imdif_TB ./ Pl.cvar);  % with the lower-neighboring node
CmpPot(:, :, :, DIFF) = 1 - CmpPot(:, :, :, SAME);
CmpPot = CmpPot .* (1 - 2 * Pl.epsc) + Pl.epsc;


% PIXEL-WISE BINARY BELIEF PROPAGATION
% initialization ==========================================================
% incoming messages (the third index: BG[1] and FG[2])
%   ex. LRMsg(i, j, :) = a message FROM the left neighbor of x_ij TO x_ij
LRMsg = ones(h, w, 2);   % left to right messages
RLMsg = ones(h, w, 2);   % right to left messages
TBMsg = ones(h, w, 2);   % top to bottom messages
BTMsg = ones(h, w, 2);   % bottom to top messages

% initial belief = observation clique potential
ObsPotAllRaw = ObsPot{1};
for i=2:num_seg
  ObsPotAllRaw = ObsPotAllRaw .* ObsPot{i};
end
ObsPotAllRaw = ObsPotAllRaw.^(1/num_seg);

ObsPotAll = ObsPotAllRaw .* (1 - 2 * Pl.epso) + Pl.epso;
Belief = ObsPotAll;


% loopy belief propagation ================================================
for ridx = 1 : Pl.nrnd
  % messages at the previous time step
  LRMsg_p = LRMsg;
  RLMsg_p = RLMsg;
  TBMsg_p = TBMsg;
  BTMsg_p = BTMsg;
  
% message update ----------------------------------------------------------
  % left to right messages
  partBelief = Belief(:, 1 : w - 1, :) ./ RLMsg_p(:, 1 : w - 1, :);
  LRMsg(:, 2 : w, BG) = ...
    partBelief(:, :, BG) .* CmpPot(:, 1 : w - 1, RIGHT, SAME) + ...
    partBelief(:, :, FG) .* CmpPot(:, 1 : w - 1, RIGHT, DIFF);
  LRMsg(:, 2 : w, FG) = ...
    partBelief(:, :, BG) .* CmpPot(:, 1 : w - 1, RIGHT, DIFF) + ...
    partBelief(:, :, FG) .* CmpPot(:, 1 : w - 1, RIGHT, SAME);
  % right to left messages
  partBelief = Belief(:, 2 : w, :) ./ LRMsg_p(:, 2 : w, :);
  RLMsg(:, 1 : w - 1, BG) = ...
    partBelief(:, :, BG) .* CmpPot(:, 2 : w, LEFT, SAME) + ...
    partBelief(:, :, FG) .* CmpPot(:, 2 : w, LEFT, DIFF);
  RLMsg(:, 1 : w - 1, FG) = ...
    partBelief(:, :, BG) .* CmpPot(:, 2 : w, LEFT, DIFF) + ...
    partBelief(:, :, FG) .* CmpPot(:, 2 : w, LEFT, SAME);
  % top to bottom messages
  partBelief = Belief(1 : h - 1, :, :) ./ BTMsg_p(1 : h - 1, :, :);
  TBMsg(2 : h, :, BG) = ...
    partBelief(:, :, BG) .* CmpPot(1 : h - 1, :, LOWER, SAME) + ...
    partBelief(:, :, FG) .* CmpPot(1 : h - 1, :, LOWER, DIFF);
  TBMsg(2 : h, :, FG) = ...
    partBelief(:, :, BG) .* CmpPot(1 : h - 1, :, LOWER, DIFF) + ...
    partBelief(:, :, FG) .* CmpPot(1 : h - 1, :, LOWER, SAME);
  % bottom to top messages
  partBelief = Belief(2 : h, :, :) ./ TBMsg_p(2 : h, :, :);
  BTMsg(1 : h - 1, :, BG) = ...
    partBelief(:, :, BG) .* CmpPot(2 : h, :, UPPER, SAME) + ...
    partBelief(:, :, FG) .* CmpPot(2 : h, :, UPPER, DIFF);
  BTMsg(1 : h - 1, :, FG) = ...
    partBelief(:, :, BG) .* CmpPot(2 : h, :, UPPER, DIFF) + ...
    partBelief(:, :, FG) .* CmpPot(2 : h, :, UPPER, SAME);
  
% belief update -----------------------------------------------------------
  % product of messages and observation clique potential
  Belief = LRMsg .* RLMsg .* TBMsg .* BTMsg .* ObsPotAll;
  
  % belief normalization
  sumBelief = sum(Belief, 3);
  Belief(:, :, BG) = Belief(:, :, BG) ./ sumBelief;
  Belief(:, :, FG) = Belief(:, :, FG) ./ sumBelief;
end

% final labeling ==========================================================
L = Belief(:, :, FG) > Belief(:, :, BG);

end