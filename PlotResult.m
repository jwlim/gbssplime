% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
%

function [out, outimg] = PlotResult(I, O_BG, O_FG, B, L, mask, Qc_BG, Qc_FG, Qv_BG, Qv_FG, ObsPot, logplikeout, title_str)

I = I / 255;
nrows = size(I, 1);
ncols = size(I, 2);

out.title = title_str;

% plot the labeling result
if isempty(L)
  out.label = I;
else
  out.label = I / 2 + repmat(L,[1,1,3]) / 2;
end

% plot the superpixels
out.sp_seg = random_color(B.S);
out.sp_mean = mean_color(B.S, I);

% plot the foreground/background appearance
out.qc_fg = visualize_Qc(B.S, Qc_FG);
out.qc_bg = visualize_Qc(B.S, Qc_BG);

maxrad = max(sqrt(max(max(sum(O_FG.^2, 3)))), sqrt(max(max(sum(O_BG.^2, 3)))));
maxrad = max(1, min(30, maxrad));

% plot the optical flow
[Oimg, maxrad] = FlowToColor(O_FG, maxrad);
out.motion = double(Oimg) / 255;
[Oimg, maxrad] = FlowToColor(O_BG, maxrad);
out.sp_seg = double(Oimg) / 255;

% plot the foreground/background motion models
if ~isempty(Qv_FG)
  out.qv_fg = visualize_Qv(B.S, Qv_FG, maxrad);
end
if ~isempty(Qv_BG)
  out.qv_bg = visualize_Qv(B.S, Qv_BG, maxrad);
end

if ~isempty(ObsPot)
  [out.obs_pot, out.obs_pot_rng] = visualize_plike(ObsPot);
end
if ~isempty(logplikeout)
  data = cat(2, exp(logplikeout.mix * 0.5), exp(logplikeout.app), exp(logplikeout.mot));
  data = max(data, [], 3);
  data = data(~isinf(data));
  rng = [min(data(:)), min(median(data(:)) * 2, max(data(:)))];

  [out.logplike_mix, out.logplike_mix_rng] = visualize_plike(exp(logplikeout.mix * 0.5), rng);
  [out.logplike_app, out.logplike_app_rng] = visualize_plike(exp(logplikeout.app), rng);
  [out.logplike_mot, out.logplike_mot_rng] = visualize_plike(exp(logplikeout.mot), rng);
end

if nargout > 1
  outimg = ones(nrows * 3, ncols * 4, 3) * 0.5;
  outimg(1:nrows, 1:ncols, :) = out.label;
  outimg(nrows + (1:nrows), 1:ncols, :) = out.sp_seg;
  outimg(nrows + (1:nrows), ncols + (1:ncols), :) = out.motion;
  outimg(1:nrows, ncols + (1:ncols), :) = out.sp_mean;
  if isfield(out, 'qc_fg')
    outimg(1:nrows, 2*ncols + (1:ncols), :) = out.qc_fg;
  end
  if isfield(out, 'qc_bg')
    outimg(1:nrows, 3*ncols + (1:ncols), :) = out.qc_bg;
  end
  if isfield(out, 'qv_fg')
    outimg(nrows + (1:nrows), 2*ncols + (1:ncols), :) = out.qv_fg;
  else
    outimg(nrows + (1:nrows), 2*ncols + (1:ncols), :) = repmat(mask, [1,1,3]);
  end  
  if isfield(out, 'qv_bg')
    outimg(nrows + (1:nrows), 3*ncols + (1:ncols), :) = out.qv_bg;
  end
  if isfield(out, 'obs_pot')
    outimg(2*nrows + (1:nrows), 1:ncols, :) = out.obs_pot;
  end
  if isfield(out, 'logplike_mix')
    outimg(2*nrows + (1:nrows), ncols + (1:ncols), :) = out.logplike_mix;
    outimg(2*nrows + (1:nrows), 2*ncols + (1:ncols), :) = out.logplike_app;
    outimg(2*nrows + (1:nrows), 3*ncols + (1:ncols), :) = out.logplike_mot;
  end
end

% if nargout < 1
  clf;
  nr = 3.1;
  nc = 4;
  resize_figure(ncols * nc, nrows * nr);
  
  axes_subplot(nr, nc, 1, 1);
  imagesc(out.label);
  axis image off;
  text(5, 10, 'label', 'color','white','FontWeight','bold');
  
  title(title_str);
  
  axes_subplot(nr, nc, 2, 1);
  imagesc(out.sp_seg);
  axis image off;
  text(5, 10, 'sp-seg', 'color','white','FontWeight','bold');
  
  axes_subplot(nr, nc, 1, 2);
  imagesc(out.sp_mean);
  axis image off;
  text(5, 10, 'sp-mean', 'color','white','FontWeight','bold');
  
  if isfield(out, 'qc_fg')
    axes_subplot(nr, nc, 1, 3);
    imagesc(out.qc_fg);
    axis image off;
    text(5, 10, 'qc-fg-mean', 'FontWeight','bold');
  end
  if isfield(out, 'qc_bg')
    axes_subplot(nr, nc, 1, 4);
    imagesc(out.qc_bg);
    axis image off;
    text(5, 10, 'qc-bg-mean', 'color','white','FontWeight','bold');
  end
  axes_subplot(nr, nc, 2, 2);
  imagesc(out.motion);
  axis image off;
  text(5, 10, 'motion', 'color','white','FontWeight','bold');
  
  if isfield(out, 'qv_fg')
    axes_subplot(nr, nc, 2, 3);
    imagesc(out.qv_fg);
    axis image off;
    text(5, 10, 'qv-fg-mean', 'color','white','FontWeight','bold');
  else
    axes_subplot(nr, nc, 2, 3);
    imagesc(mask);
    axis image off;
    text(5, 10, 'motion-mask', 'FontWeight','bold');
  end  
  if isfield(out, 'qv_bg')
    axes_subplot(nr, nc, 2, 4);
    imagesc(out.qv_bg);
    text(5, 10, 'qv-bg-mean', 'color','white','FontWeight','bold');
    axis image off;
  end

  if isfield(out, 'obs_pot')
    axes_subplot(nr, nc, 3, 1);
    imagesc(out.obs_pot);
    axis image off;
    text(5, 10, 'obs-pot', 'color','white','FontWeight','bold');
  end
  if isfield(out, 'logplike_mix')
    axes_subplot(nr, nc, 3, 2);
    imagesc(out.logplike_mix);
    text(5, 10, 'plike-mix', 'color','white','FontWeight','bold');
    axis image off;
    disp(['plike_mix_rng: ' num2str(out.logplike_mix_rng)]);
    
    axes_subplot(nr, nc, 3, 3);
    imagesc(out.logplike_app);
    text(5, 10, 'plike-app', 'color','white','FontWeight','bold');
    axis image off;
    disp(['plike_app_rng: ' num2str(out.logplike_app_rng)]);
    
    axes_subplot(nr, nc, 3, 4);
    imagesc(out.logplike_mot);
    text(5, 10, 'plike-mot', 'color','white','FontWeight','bold');
    axis image off;
    disp(['plike_mot_rng: ' num2str(out.logplike_mot_rng)]);
  end
  drawnow;
% end
end


function [flag] = boundary(labels)

flag = zeros(size(labels));
flag(1:end-1, 1:end) = (labels(1:end-1, 1:end) ~= labels(2:end, 1:end));
flag(1:end, 1:end-1) = flag(1:end, 1:end-1) | ...
  (labels(1:end, 1:end-1) ~= labels(1:end, 2:end));
end


function [ret] = half_image(img)

[nr, nc, d] = size(img);
nr2 = nr / 2;
nc2 = nc / 2;
ret = zeros(nr2, nc2, d);
for i = 1:d
  ret(:,:,i) = reshape(mean(im2col(img(:,:,i), [2,2], 'distinct'), 1), [nr2, nc2]);
end
end


function [out] = random_color(labels)

ids = unique(labels);
[h, w, ~] = size(labels);
img = zeros(3, w * h);
for i = 1 : numel(ids)
  idx = find(labels == ids(i));
  img(:, idx) = repmat(rand(3, 1), [1, numel(idx)]);
end
out = reshape(img', [h, w, 3]);
end


function [out] = mean_color(labels, I)

ids = unique(labels);
[h, w, d] = size(I);
img = reshape(I, [h * w, d])';
for i = 1 : numel(ids)
  idx = find(labels == ids(i));
  img(:, idx) = repmat(mean(img(:,idx), 2), [1, numel(idx)]);
end
out = reshape(img', [h, w, 3]);
b = boundary(labels);
out = out .* (1 - 0.5 * repmat(b,[1,1,3]));
end


function [out] = visualize_Qc(labels, Qc)

ids = unique(labels);
[h, w, ~] = size(labels);
img = zeros(3, w * h);
for i = 1 : numel(ids)
  idx = find(labels == ids(i));
  if isempty(Qc{i})
    img(:, idx) = 1.0;
  elseif isstruct(Qc{i})  % histogram
    img(:, idx) = repmat(HistMean(Qc{i}) / 255, [1, numel(idx)]);
  else
    img(:, idx) = repmat(mean(Qc{i}) / 255, [1, numel(idx)]);
  end
end
out = reshape(img', [h, w, 3]);
end


function [out] = visualize_Qv(labels, Qv, maxrad)

ids = unique(labels);
[h, w, ~] = size(labels);
img = zeros(3, w * h);
for i = 1 : numel(ids)
  idx = find(labels == ids(i));
  if isempty(Qv{i})
    img(:, idx) = 0.5;
  else
    if isstruct(Qv{i})
      if isfield(Qv{i}, 'cells')
        c = FlowToColor(HistMean(Qv{i}), maxrad);
      else
        c = FlowToColor(Qv{i}.mu, maxrad);
      end
    else
      c = FlowToColor(mean(Qv{i}), maxrad);
    end
    img(:, idx) = repmat(double(c(:)) / 255, [1, numel(idx)]);
  end
end
out = reshape(img', [h, w, 3]);
end


function [out, rng] = visualize_plike(logplike, rng)

[h, w, ~] = size(logplike);
data = logplike(~isinf(logplike));
if nargin < 2
  rng = [min(data), max(data)];
end
mask_val = 0.1;
bg_mask = mask_val * (logplike(:,:,1) > logplike(:,:,2));
fg_mask = mask_val * (logplike(:,:,2) > logplike(:,:,1));
out = cat(3, max(0, min(1, (logplike - rng(1)) / (rng(2) - rng(1) + eps)) * (1 - mask_val)) ...
  + cat(3, bg_mask, fg_mask), zeros(h, w));
end


function resize_figure(w, h)
old_units = get(gcf, 'Units');
set(gcf, 'Units', 'pixels');
figpos = get(gcf, 'Position');
newpos = [figpos(1), figpos(2), w, h];
set(gcf, 'Position', newpos);
set(gcf, 'Units', old_units);
set(gcf, 'Resize', 'off');
end


function axes_subplot(nr, nc, r, c)

% [c, r] = ind2sub([nc, nr], idx);
axis_w = 1 / nc;
axis_h = 1 / nr;
axes('position', [(c - 1) * axis_w, (floor(nr) - r) * axis_h, axis_w, axis_h]);
end
