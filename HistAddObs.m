function hist = HistAddObs(hist, obs, w)

if isstruct(obs)
  if hist.num_cells ~= obs.num_cells
    error('invalid HistAddObs call');
  end
  hist.cells = hist.cells + w .* obs.cells;
elseif ischar(obs) && strcmp(obs, 'uniform')
  hist.cells = hist.cells + w / numel(hist.cells);
else
  [~, ii, valid] = HistGetProb(hist, obs);
  i = ii(valid);
  if numel(w) > 1
    hist.cells(i) = hist.cells(i) + w(valid);
  else
    hist.cells(i) = hist.cells(i) + w;
  end
  
%   idx = floor(obs / hist.cellres) + 1;
%   i = sub2ind(size(hist.cells), idx(1,:), idx(2,:), idx(3,:));
%   hist.cells(i) = hist.cells(i) + w;
end
