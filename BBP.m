%==========================================================================
% Estimation of Floating BG/FG Model by Nonparametric Belief Propagation
% Pixel-wise binary belief propagation (binary image enhancement)
% 2011. 2. 13. Suha Kwak, POSTECH.
%==========================================================================

function [Ln] = BBP(L)

%- PRELIMINARY
% image size
[irow, icol] = size(L);

% enumerator
BG = 1; 
FG = 2;

% parameters ==============================================================
% the number of loopy BP rounds
nround = 15;

% small numbers
eps_comp = 0.20;    % uncertainty for compatibility clique potentials
eps_obsv = 0.15;    % uncertainty for observation clique potentials

% clique potentials =======================================================
% compatibility clique potential
CmpPot = [1 - eps_comp, eps_comp ; eps_comp, 1 - eps_comp];

% observation clique potential
ObsPot = zeros(irow, icol, 2);
ObsPot(:, :, FG) = double(L);
ObsPot(:, :, BG) = 1 - ObsPot(:, :, FG);
ObsPot = ObsPot .* (1 - 2 * eps_obsv) + eps_obsv;

%- PIXEL-WISE BINARY BELIEF PROPAGATION
% initialization ==========================================================
% incoming messages (the third index: BG[1] and FG[2])
%   ex. LRMsg(i, j, :) = a message FROM the left neighbor of x_ij TO x_ij
LRMsg = ones(irow, icol, 2);   % left to right messages
RLMsg = ones(irow, icol, 2);   % right to left messages
TBMsg = ones(irow, icol, 2);   % top to bottom messages
BTMsg = ones(irow, icol, 2);   % bottom to top messages

% initial belief = observation clique potential
Belief = ObsPot;

% loopy belief propagation ================================================
for ridx = 1 : nround
    % messages at the previous step
    LRMsg_p = LRMsg;
    RLMsg_p = RLMsg;
    TBMsg_p = TBMsg;
    BTMsg_p = BTMsg;

% message update ----------------------------------------------------------
    % left to right messages
    partBelief = Belief(:, 1 : icol - 1, :) ./ RLMsg_p(:, 1 : icol - 1, :);
    LRMsg(:, 2 : icol, BG) = partBelief(:, :, BG) .* CmpPot(BG, BG) + ...
                             partBelief(:, :, FG) .* CmpPot(FG, BG);
    LRMsg(:, 2 : icol, FG) = partBelief(:, :, BG) .* CmpPot(BG, FG) + ...
                             partBelief(:, :, FG) .* CmpPot(FG, FG);
    % right to left messages
    partBelief = Belief(:, 2 : icol, :) ./ LRMsg_p(:, 2 : icol, :);
    RLMsg(:, 1 : icol - 1, BG) = partBelief(:, :, BG) .* CmpPot(BG, BG) + ...
                                 partBelief(:, :, FG) .* CmpPot(FG, BG);
	RLMsg(:, 1 : icol - 1, FG) = partBelief(:, :, BG) .* CmpPot(BG, FG) + ...
                                 partBelief(:, :, FG) .* CmpPot(FG, FG);
    % top to bottom messages
	partBelief = Belief(1 : irow - 1, :, :) ./ BTMsg_p(1 : irow - 1, :, :);
    TBMsg(2 : irow, :, BG) = partBelief(:, :, BG) .* CmpPot(BG, BG) + ...
                             partBelief(:, :, FG) .* CmpPot(FG, BG);
    TBMsg(2 : irow, :, FG) = partBelief(:, :, BG) .* CmpPot(BG, FG) + ...
                             partBelief(:, :, FG) .* CmpPot(FG, FG);
    % bottom to top messages
    partBelief = Belief(2 : irow, :, :) ./ TBMsg_p(2 : irow, :, :);
    BTMsg(1 : irow - 1, :, BG) = partBelief(:, :, BG) .* CmpPot(BG, BG) + ...
                                 partBelief(:, :, FG) .* CmpPot(FG, BG);
	BTMsg(1 : irow - 1, :, FG) = partBelief(:, :, BG) .* CmpPot(BG, FG) + ...
                                 partBelief(:, :, FG) .* CmpPot(FG, FG);

% belief update -----------------------------------------------------------
    % product of messages and observation clique potential
    Belief = LRMsg .* RLMsg .* TBMsg .* BTMsg .* ObsPot;
    
    % belief normalization
    sumBelief = sum(Belief, 3);
    Belief(:, :, BG) = Belief(:, :, BG) ./ sumBelief;
    Belief(:, :, FG) = Belief(:, :, FG) ./ sumBelief;
end


% final labeling ==========================================================
Ln = Belief(:, :, FG) > Belief(:, :, BG);

end



