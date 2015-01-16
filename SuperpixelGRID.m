% SuperpixelGRID

function labels = SuperpixelGRID(img, labels, num_clusters, opt)

[h, w, ~] = size(img);
[xs, ys] = meshgrid(1:w, 1:h);

for sz = 5 : min(w, h)
  if mod(w, sz) < 2 || mod(h, sz) < 2, continue; end;
  nh = ceil(h / sz);
  nw = ceil(w / sz);
  if nw * nh < num_clusters, break; end;
end

labels = zeros(h, w);
idx = 1;
for y = 1:sz:h
  for x = 1:sz:w
    labels(x <= xs & xs < x + sz & y <= ys & ys < y + sz) = idx;
    idx = idx + 1;
  end
end

end
