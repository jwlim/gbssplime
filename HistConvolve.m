function hist = HistConvolve(hist, sig)

if isempty(hist) || sig < eps
  return;
end

if numel(sig) == 1 && numel(hist.num_cells) > 1
  sig = repmat(sig, size(hist.num_cells));
end

sig = sig / hist.cellres;
dim = numel(hist.num_cells);
for i = 1:dim
  r = ceil(3 * sig(i));
  kernel = exp(-0.5 / sig(i)^2 * ((0:2*r)' - r).^2);
  kernel = kernel / sum(kernel);
  kernel = shiftdim(kernel, -i + 1);
  hist.cells = convn(hist.cells, kernel, 'same');
end

end