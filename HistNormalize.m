function hist = HistNormalize(hist)

if isempty(hist)
  return;
end

s = sum(hist.cells(:));
if s > 0
  hist.cells = hist.cells / s;
else
  hist = [];
end
end
