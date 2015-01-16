function [p, ii, valid] = HistGetProb(hist, v)

dim = numel(hist.num_cells);
if size(v, 1) ~= dim && size(v, 2) == dim
  v = v';
end
if size(v, 1) ~= dim
  error('incompatible v');
end

n = size(v, 2);
if isfield(hist, 'offset')
  v = v + repmat(hist.offset, [1, n]);
end
% idx_zb = floor(v / hist.cellres)';  % zero-base index.
idx_zb = floor(v / hist.cellres)';  % zero-base index.

for i = 1:dim
  if  any(idx_zb(:,i) < 0 | idx_zb(:,i) >= hist.num_cells(i))
    warning('HistGetProb out of bound');
  end
end

valid = true(n, 1);
ii = ones(n, 1);  % one-base index;
for i = 1:dim
  valid = valid & idx_zb(:,i) >= 0 & idx_zb(:,i) < hist.num_cells(i);
  ii = ii + idx_zb(:,i) * prod(hist.num_cells(1:i-1));
end

p = zeros(n, 1);
p(valid) = hist.cells(ii(valid));

end
