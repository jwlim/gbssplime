
function [Qc_tp] = TempModelPropagateSP(Qc_prev, Bv, B, Pt)
% [input]
%   Qv      : the current block motion models
%   Qc_prev : the block appearance models at the previous time step
%   B       : the superpixel blocks in the previous and current frame
%     - S     : superpixel labels.
%     - G     : the pairwise graph structure (a binary matrix)
%     - bnum  : the number of superpixels
%   Pt      : the set of parameters for temporal model propatation
%     - transtd  : BW of the state transition probability (Gaussian conv.)
% [return]
%   Qc_tp   : the temporally propagated block appearance models

% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)

% TEMPORAL MODEL PROPAGATION
% block appearance models by temporal model propagation
Qc_tp = cell(1, B.bnum);

for bidx = 1 : B.bnum

% aggregation of the previous appearance models ---------------------------
  % previous blocks with nonzero weights (overlapped blocks)
  oblist = find(Bv(:, bidx));
  breg_weight = Bv(:, bidx)';
  
  valid = (oblist > 0);
  for i = 1:numel(oblist)
    valid(i) = ~isempty(Qc_prev{oblist(i)});
  end
  oblist = oblist(valid);
  if isempty(oblist), continue; end
  
  qc1 = Qc_prev{oblist(1)};
  obs_added = false;
  hist = HistNew(qc1.num_cells, qc1.cellres);
  % aggregation of the appearance models at the previous time step
  for idx = 1 : length(oblist)
    obidx = oblist(idx);
    hist = HistAddObs(hist, Qc_prev{obidx}, breg_weight(obidx));
    obs_added = true;
  end
  if obs_added
    Qc_tp{bidx} = HistNormalize(HistConvolve(hist, Pt.transtd));
  end
end

end
