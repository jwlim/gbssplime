%

function [G, ids, edges] = BuildGraphFromLabel(labels)

L0 = labels(:, 1:end-1);
L1 = labels(:, 2:end);
flag = (L0 ~= L1);
edges = [L0(flag), L1(flag)];

L0 = labels(1:end-1, :);
L1 = labels(2:end, :);
flag = (L0 ~= L1);
all_edges = [edges; L0(flag), L1(flag)];
edges = unique(all_edges, 'rows');

ids = unique(labels);
n = numel(ids);

G = zeros(n, n);
for i = 1:size(edges,1)
  e1 = find(ids == edges(i,1));
  e2 = find(ids == edges(i,2));
  G(e1, e2) = G(e1, e2) + 1;
  G(e2, e1) = G(e2, e1) + 1;
end

end