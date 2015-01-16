function m = HistMean(hist)

if isfield(hist, 'offset')
  offset = hist.offset;
else
  offset = zeros(numel(hist.num_cells), 1);
end
dim = numel(hist.num_cells);
m = zeros(dim, 1);
for i = 1:dim
  c = hist.cells;
  d = circshift((1:dim)', dim - i);
  for j = 1:dim-1
    c = mean(c, d(j));
  end
  c = squeeze(c);
  c = c ./ (sum(c) + eps);
  l = (1:numel(c)) * hist.cellres - hist.cellres / 2 - offset(i);
  m(i) = sum(c(:) .* l(:));
end

end