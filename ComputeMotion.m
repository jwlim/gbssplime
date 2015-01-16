% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
%

function [v_fg, v_bg, w_fg, w_bg, masks, warpI2, warpI1] = ...
  ComputeMotion(I1, I2, L, dilate, sigma, flow_param)

global SINGLE_MOTION;  %- For comparison.

if nargin < 4, dilate = 0; end;
if nargin < 5, sigma = 0; end;
if nargin < 6, flow_param = []; end;
max_flow = 10;

%- mask1_?? is the esitmated fg/bg mask in the previous frame (f1).
mask1_fg = max(0, min(1, double(L)));
mask1_bg = GetBGMask(mask1_fg, dilate, sigma);

sigma_fg = 1;
rad = ceil(3 * sigma_fg);
g = exp(-(-rad:rad).^2 / (2 * sigma_fg^2));
g = g / sum(g);
mask1_fg = conv2(conv2(mask1_fg, g, 'same'), g', 'same');

[x,y] = meshgrid(1:size(L,2), 1:size(L,1));

%- Estimate the global motion.
[vx, vy, warpI2] = Coarse2FineTwoFrames(I1, I2, [], flow_param);
[wx, wy, warpI1] = Coarse2FineTwoFrames(I2, I1, [], flow_param);

%- mask2_?? is a transferred version of the mask1_?? using the global motion.
mask2_fg = Transfer(mask1_fg, wx, wy, x, y);
mask2_bg = Transfer(mask1_bg, wx, wy, x, y); % .* GetBGMask(mask2_fg, dilate, sigma);
%- Compute the back-propagated mask, 1->2->1.
mask1_fgp = Transfer(mask2_fg, vx, vy, x, y);
mask1_bgp = Transfer(mask2_bg, vx, vy, x, y); % .* GetBGMask(mask1_fgp, dilate, sigma);

if SINGLE_MOTION
  v_fg = cat(3, vx, vy);
  w_fg = cat(3, wx, wy);
  v_bg = cat(3, vx, vy);
  w_bg = cat(3, wx, wy);
  masks = cat(3, mask1_fg, mask2_fg, mask1_bgp, mask2_bg);
  warpI2 = {warpI2, warpI2};
  warpI1 = {warpI1, warpI1};
  return;
end

%- Compute fg/bg motions using the estimated masks.
[vx_fg, vy_fg, warpI2_fg] = Coarse2FineTwoFrames(I1, I2, mask1_fg, flow_param);
[wx_fg, wy_fg, warpI1_fg] = Coarse2FineTwoFrames(I2, I1, mask2_fg, flow_param);
[vx_bg, vy_bg, warpI2_bg] = Coarse2FineTwoFrames(I1, I2, mask1_bgp, flow_param);
[wx_bg, wy_bg, warpI1_bg] = Coarse2FineTwoFrames(I2, I1, mask2_bg, flow_param);

mask2_fgp = Transfer(mask1_fg, wx_fg, wy_fg, x, y);  %- fg or fgp?
mask2_bgp = Transfer(mask1_bgp, wx_bg, wy_bg, x, y) .* GetBGMask(mask2_fgp, dilate, sigma);
mask1_fgpp = Transfer(mask2_fgp, vx_fg, vy_fg, x, y);
mask1_bgpp = Transfer(mask2_bgp, vx_bg, vy_bg, x, y) .* GetBGMask(mask1_fgpp, dilate, sigma);

v_fg = cat(3, vx_fg, vy_fg);
w_fg = cat(3, wx_fg, wy_fg);
v_bg = cat(3, vx_bg, vy_bg);
w_bg = cat(3, wx_bg, wy_bg);

figure(20);
PlotImages(...
  {I1, I2}, ... %{1-abs(I1 - warpI2), 1-abs(I2 - warpI1)}, 
  {warpI2_fg, warpI2_bg}, ... 
  {0.5 - abs(I1 - warpI2_fg) + abs(I1 - warpI2_bg)},...
  {1-abs(I1 - warpI2_fg), 1-abs(I1 - warpI2_bg)},...
  {(mask1_fg * 0.8 + 0.2 * mask1_fgpp) + mask1_bgpp / 2, mask2_fgp + mask2_bgp / 2}, ...
  {FlowToColor(v_fg, max_flow), FlowToColor(w_fg, max_flow)},...
  {FlowToColor(v_bg, max_flow), FlowToColor(w_bg, max_flow)});
drawnow;

masks = cat(3, mask1_fg, mask2_fgp, mask1_bgpp, mask2_bgp);
warpI2 = {warpI2_fg, warpI2_bg};
warpI1 = {warpI1_fg, warpI1_bg};
end


function m = Transfer(mask, vx, vy, x, y)

if nargin < 5
  [x, y] = meshgrid(1:size(vx,2), 1:size(vx,1));
end
m = interp2(mask, x + vx, y + vy);
m(isnan(m)) = 0;
end


function mask_bg = GetBGMask(mask_fg, dilate, sigma)

if dilate > 0
  mask_bg = imerode(1 - mask_fg, strel('disk', dilate));
end
if sigma > 0
  rad = ceil(3 * sigma);
  g = exp(-(-rad:rad).^2 / (2 * sigma^2));
  g = g / sum(g);
  mask_bg = conv2(conv2(mask_bg, g, 'same'), g', 'same');
end
end
