function hist = HistNew(num_cells, cellres, offset)

hist = struct('num_cells', num_cells, 'cellres', cellres, ...
              'cells', eps * ones(num_cells));

if nargin >= 3
  hist.offset = offset(:);
end

end
