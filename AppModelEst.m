
function [Qc] = AppModelEst(I, L, Qc_tp, B, Pc)
% [input]
%   I     : the image obesrvation (the current video frame)
%   L     : the label map - which pixels would be used
%   Qc_tp : the temporally propagated block appearance models
%   B     : the superpixel blocks
%     - S     : superpixel labels.
%     - G     : the pairwise graph structure (a binary matrix)
%     - bnum  : the number of superpixels
%   Pc    : the parameters for nonparametric belief propagation
%     - minpratio: how many pixels are needed to be an observation of a block
%     - kstd     : (minimum) bandwidth of the kernels for KDE (observation)
%     - nghb     : (obs) comparative weight to consider the neighboing blocks
%     - foreground : FG model estimation (true) or BG model estimation (false)
% [return]
%   Qc : the appearance models of the blocks;
%        the marginalized posteriors w.r.t. each RGB random variable

% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)

% APPEARANCE MODEL AGGRAGATION
Qc = cell(1, B.bnum);
Qc_im = cell(1, B.bnum);

hist_cellres = 8;
hist_numcells = ceil(256 / hist_cellres);

% gathering color (appearance) information --------------------------------
% the set of the observed pixel values at each block
[h, w, d] = size(I);
Cdata = reshape(I, [h * w, d])';
Cset = cell(1, B.bnum);
Cwt = cell(1, B.bnum);
block_sizes = zeros(1, B.bnum);
for bidx = 1 : B.bnum
  % image (color) observations for each block
	pixel_idx = find(B.S == bidx);
  l = L(pixel_idx);
  Cset{bidx} = Cdata(:, pixel_idx(l > 0.1));
  Cwt{bidx} = l(l > 0.1);
  block_sizes(bidx) = numel(pixel_idx);
end

for bidx = 1 : B.bnum
  hist = HistNew([hist_numcells, hist_numcells, hist_numcells], hist_cellres);
  n0 = block_sizes(bidx) - size(Cset{bidx}, 2);
  hist = HistAddObs(hist, 'uniform', n0);
  if Pc.foreground && size(Cset{bidx}, 2) <= Pc.minpratio * block_sizes(bidx)
    continue;
  end
  Qc{bidx} = HistAddObs(hist, Cset{bidx}, 1);
end
  
for bidx = 1 : B.bnum
  hist = Qc{bidx};
  if ~Pc.foreground
    % observation on the neighboring block regions
    neighbors = find(B.G(:, bidx) > 0);
    for i = 1 : numel(neighbors)
      nbidx = neighbors(i);
      hist = HistAddObs(hist, Qc{nbidx}, Pc.nghb);
    end
  end
  Qc_im{bidx} = HistNormalize(HistConvolve(hist, Pc.kstd));
end
  
for bidx = 1 : B.bnum
  % filtering by the observation model
  if ~isempty(Qc_tp{bidx}) && ~isempty(Qc_im{bidx})
    Qc{bidx} = HistNormalize(HistProd(Qc_tp{bidx}, Qc_im{bidx}));
  elseif isempty(Qc_tp{bidx})
    Qc{bidx} = Qc_im{bidx};
  elseif isempty(Qc_im{bidx})
    Qc{bidx} = Qc_tp{bidx};
  else
    Qc{bidx} = [];
  end
end

end



