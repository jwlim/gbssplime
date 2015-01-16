
function PlotImages(varargin)

% Authors: Jongwoo Lim (Hanyang U)

num_row = 0;
images_idx = zeros(nargin, 1);
texts = cell(nargin, 1);
title_str = [];
widths = zeros(nargin, 1);
heights = zeros(nargin, 1);
for idx = 1:nargin
  arg = varargin{idx};
  if ~iscell(arg), arg = {arg}; end;
  if ischar(arg{1})
    if num_row == 0
      title_str = arg{1};
    else
      texts{num_row} = arg;
    end
  else
    num_row = num_row + 1;
    images_idx(num_row) = idx;
    w = 0;
    h = 0;
    for i = 1:numel(arg)
      w = w + size(arg{i}, 2);
      h = max(h, size(arg{i}, 1));
    end
    widths(num_row) = w;
    heights(num_row) = h;
  end
end

clf;
win_width = max(widths);
win_height = sum(heights);
ResizeFigure(win_width, win_height);

win_y = 1.0;
for row = 1:num_row
  idx = images_idx(row);
  arg = varargin{idx};
  if ~iscell(arg), arg = {arg}; end;
  num_col = numel(arg);
  axis_h = heights(row) / win_height;
  win_x = 0;
  win_y = win_y - axis_h;
  for col = 1:num_col
    axis_w = size(arg{col}, 2) / widths(row);
% disp([row, col, idx, win_x, win_y, axis_w, axis_h]);
    ax = axes('position', [win_x, win_y, axis_w, axis_h]);
    imshow(arg{col}, 'Parent', ax);
    axis image off;
    if col <= numel(texts{row})
      text(5, 10, texts{row}{col}, ...
        'FontName','FixedWidth', 'FontSize',12, 'Color','red','FontWeight','bold');
    end
    win_x = win_x + axis_w;
  end
end
if ~isempty(title_str);
  title(title_str);
end

end

function ResizeFigure(w, h)
old_units = get(gcf, 'Units');
set(gcf, 'Units', 'pixels');
figpos = get(gcf, 'Position');
newpos = [figpos(1), figpos(2), w, h];
set(gcf, 'Position', newpos);
set(gcf, 'Units', old_units);
% set(gcf, 'Resize', 'off');
end


function AxesSubplot(nr, nc, r, c, axis_w, axis_h)
% [c, r] = ind2sub([nc, nr], idx);
if nargin < 5, axis_w = 1 / nc; end;
if nargin < 6, axis_h = 1 / nr; end;
axes('position', [(c - 1) * axis_w, (floor(nr) - r) * axis_h, axis_w, axis_h]);
end
