
function [Bv, Qv] = MotModelEst(O, L, B0, B, Pv)
% [input]
%   O  : the motion map (optical flows)
%   L  : the label map - which pixels would be used
%   B0, B  : the superpixel blocks in the previous and current frame
%     - S     : superpixel labels.
%     - G     : the pairwise graph structure (a binary matrix)
%     - bnum  : the number of superpixels
%   Pv : the parameters for nonparametric belief propagation
%     - minpratio: how many pixels are needed to be an observation of a block
%     - kstd     : bandwidth of the kernels for KDE (observation)
%     - nghd     : mix rate for models from neighbors
% [return]
%   Bv : the association matrix from B0 to B (B0.bnum x B.bnum).
%   Qv : 

% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)

% MOTION MODEL ESTIMATION
Bv = zeros(B0.bnum, B.bnum);
Qv = cell(1, B.bnum);

[h, w, ~] = size(O);
Odata = reshape(O, [h * w, 2])';

hist_cellres = 1;
hist_numcells = [50, 50];
hist_offset = [25, 25];

Oset = cell(1, B.bnum);
Owt = cell(1, B.bnum);
block_sizes = zeros(1, B.bnum);

for bidx = 1 : B.bnum
  % gathering motion information --------------------------------------------
	block_pidx = find(B.S == bidx);
  label_pidx = block_pidx(L(block_pidx) > 0.1);

  Oset{bidx} = Odata(:, label_pidx);
  Owt{bidx} = L(label_pidx);
  block_sizes(bidx) = numel(block_pidx);
  
  if ~Pv.foreground, label_pidx = block_pidx; end;
  if isempty(label_pidx), continue; end;
  [ys, xs] = ind2sub([h, w], label_pidx);
  px = max(1, min(w, round(xs' + Odata(1, label_pidx))));
  py = max(1, min(h, round(ys' + Odata(2, label_pidx))));
  b0idx = B0.S(sub2ind([h, w], py, px));
  num_b0idx = numel(b0idx);
  for i = 1 : num_b0idx
    Bv(b0idx(i), bidx) = Bv(b0idx(i), bidx) + 1.0 / num_b0idx;
  end
end

if nargout <= 1, return; end

%- Observation clique potentials.
for bidx = 1 : B.bnum
  hist = HistNew(hist_numcells, hist_cellres, hist_offset);
  if size(Oset{bidx}, 2) > Pv.minpratio * block_sizes(bidx)
    hist = HistAddObs(hist, Oset{bidx}, Owt{bidx});
  end
  Qv{bidx} = hist;
end

for bidx = 1 : B.bnum
  hist = Qv{bidx};
  neighbors = find(B.G(:, bidx) > 0);
  for i = 1 : numel(neighbors)
    nbidx = neighbors(i);
    hist = HistAddObs(hist, Qv{nbidx}, Pv.nghb);
  end
  Qv{bidx} = HistNormalize(HistConvolve(hist, Pv.kstd));
end

end
