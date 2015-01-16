function hist = HistProd(hist1, hist2, normalize)

hist = hist1;
if isempty(hist1), hist = hist2; end;
if isempty(hist1) || isempty(hist2)
  if ~isempty(hist)
    hist.cells = zeros(size(hist.cells));
  end
  return;
end

if any(hist1.num_cells ~= hist2.num_cells)
  error('incompatible hist1 and hist2');
end
hist = hist1;
hist.cells = hist1.cells .* hist2.cells;

s = sum(hist.cells(:));
if s > 0 && nargin > 2 && normalize
  hist.cells = hist.cells / s;
end
end
