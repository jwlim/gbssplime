
function [ObsPot, logplikeout, O] = LikelihoodComp(I, I1, I2, ...
  v_fg, v_bg, w_fg, w_bg, masks, warpI2, warpI1, ...
  Qc_BG, Qc_FG, Qv_BG, Qv_FG, B, Pl)
% [input]
%   I     : input image
%   Qc_BG : block-wise appearance models for background (predicted)
%   Qc_FG : block-wise appearance models for foreground (predicted)
%   O     : optical flow map of the current time step
%   Qv_BG : block-wise motion model for background
%   Qv_FG : block-wise motion model for foreground
%   B       : the superpixel blocks in the previous and current frame
%     - S     : superpixel labels.
%     - G     : the pairwise graph structure (a binary matrix)
%     - bnum  : the number of superpixels
%   Pl    : the specification of the blocks
%   - nrnd      : the number of looopy BP rounds
%   - cvar      : bandwidth (variance) for compatibility clique potential
%   - tempa     : temperature parameter for appearance observation likelihoods
%   - tempm     : temperature parameter for motion observation likelihoods
%   - epsc      : the lower bound of compatibility clique potentials
%   - epso      : the lower bound of observation clique potentials
% [return]
%   L           : pixel-wise labels (BG/FG)

% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
% Previous edits:
%==========================================================================
% Estimation of Floating BG/FG Model by Nonparametric Belief Propagation
% Likelihood computation step: 
% 2011. 2. 12. Suha Kwak, POSTECH.
% 2011. 2. 23. Modified by Woonhyun Nam, POSTECH
% 2013. 3. 27. Modified by Bohyung Han, POSTECH
%==========================================================================

global USE_CONSISTENCY_MASK;

% enumerator
BG = 1; FG = 2;
% LEFT = 1; RIGHT = 2; UPPER = 3; LOWER = 4;
% SAME = 1; DIFF = 2;

%- observation clique potentials and pixel-wise likelihood map
%- (the third index: BG[1] and FG[2])
[h, w, d] = size(I);
ObsPot = zeros(h, w, 2);
plike = zeros(h, w, 2);

plike_app_BG = zeros(1, numel(B.S));
plike_app_FG = zeros(1, numel(B.S));
plike_mot_BG = zeros(1, numel(B.S));
plike_mot_FG = zeros(1, numel(B.S));

% m2_fg = repmat(masks(:,:,2) > 1 - eps, [1,1,2]);
m2_fg = repmat(masks(:,:,2), [1,1,2]);
mix2 = w_bg .* (1 - m2_fg) + w_fg .* m2_fg;
O = mix2;

if USE_CONSISTENCY_MASK
  [~, cons2] = ComputeConsistencyMap(I1/255, I2/255, v_fg, v_bg, w_fg, w_bg, masks);
  Wdata = 0.1 + 0.9 * reshape(cons2, [h * w, 2])';
end

Cdata = reshape(I, [h * w, d])';
Odata = reshape(O, [h * w, 2])';
for bidx = 1 : B.bnum  % parfor - resolve slicing issue on B and Iv1
  %- RGB vectors per each pixel in the block
  bcoord = find(B.S(:) == bidx);
  c = Cdata(:, bcoord);
  v = Odata(:, bcoord);
  
  %- Appearance likelihoods w.r.t. BG/FG ----------------------------------
  plike_app_BG(bcoord) = ComputeAppearanceLikelihoods(Qc_BG{bidx}, c, Pl);
  plike_app_FG(bcoord) = ComputeAppearanceLikelihoods(Qc_FG{bidx}, c, Pl);
  
  %- Motion likelihoods w.r.t. BG/FG --------------------------------------
  plike_mot_BG(bcoord) = ComputeMotionLikelihoods(Qv_BG{bidx}, v, Pl);
  plike_mot_FG(bcoord) = ComputeMotionLikelihoods(Qv_FG{bidx}, v, Pl);
  
  if USE_CONSISTENCY_MASK
    w = Wdata(:, bcoord);
    plike_mot_BG(bcoord) = plike_mot_BG(bcoord) .* w(BG,:);
    plike_mot_FG(bcoord) = plike_mot_FG(bcoord) .* w(FG,:);
  end
end

plike(:, :, BG) = reshape(plike_app_BG, size(B.S));
plike(:, :, FG) = reshape(plike_app_FG, size(B.S));
logplike_app = log(plike + eps);

plike(:, :, BG) = reshape(plike_mot_BG, size(B.S));
plike(:, :, FG) = reshape(plike_mot_FG, size(B.S));
logplike_mot = log(plike + eps);

% observation clique potentials ===========================================
logplike = logplike_app .* Pl.tempa + logplike_mot .* Pl.tempm;

ObsPot(:, :, BG) = exp(logplike(:, :, BG)) ...
                ./ (exp(logplike(:, :, BG)) + exp(logplike(:, :, FG)) + eps);
ObsPot(:, :, FG) = 1 - ObsPot(:, :, BG);

logplikeout.mix = logplike;
logplikeout.app = logplike_app ./ 3; % * Pl.tempa;
logplikeout.mot = logplike_mot ./ 2; % * Pl.tempm;
end


function plike_app = ComputeAppearanceLikelihoods(Qc, c, Pl)
if isempty(Qc)
  plike_app = Pl.like_nomodel_app;
elseif isstruct(Qc)  %- Histogram appearance model.
  if (sum(Qc.cells(:)) < eps)
    plike_app = Pl.like_nomodel_app;
  else
    plike_app = HistGetProb(Qc, c);
  end
else  %- kde appearance model.
  plike_app = evaluate(Qc, c);
end
end

function plike_mot = ComputeMotionLikelihoods(Qv, v, Pl)
if isempty(Qv)
  plike_mot = Pl.like_nomodel_mot;
elseif isstruct(Qv)
  if isfield(Qv, 'cells')  %- Histogram motion model.
    plike_mot = HistGetProb(Qv, v);
  else
    plike_mot = mvnpdf(v', Qv.mu', Qv.cov);
  end
else  % USE_KDE
  pts = getPoints(Qv);
  bws = getBW(Qv) + Pl.conv;
  ws = getWeights(Qv);
  plike_mot = evaluate(kde(pts, bws, ws), v);
end
end


function [c1, c2] = ComputeConsistencyMap(I1, I2, v_fg, v_bg, w_fg, w_bg, masks)
thr = 0.025;
[x,y] = meshgrid(1:size(I1,2), 1:size(I1,1));
mask1_fgpp = masks(:,:,1);
mask2_fgp = masks(:,:,2);
mask1_bgpp = masks(:,:,3);
mask2_bgp = masks(:,:,4);
vx_fg = v_fg(:,:,1);
vy_fg = v_fg(:,:,2);
wx_fg = w_fg(:,:,1);
wy_fg = w_fg(:,:,2);
vx_bg = v_bg(:,:,1);
vy_bg = v_bg(:,:,2);
wx_bg = w_bg(:,:,1);
wy_bg = w_bg(:,:,2);

m1_fg = 1 - Transfer(mask2_fgp, vx_bg, vy_bg) .* (1 - mask1_fgpp);
m2_fg = 1 - Transfer(mask1_fgpp, wx_bg, wy_bg) .* (1 - mask2_fgp);
m1_bg = 1 - Transfer(1 - mask2_fgp, vx_fg, vy_fg) .* (mask1_fgpp);
m2_bg = 1 - Transfer(1 - mask1_fgpp, wx_fg, wy_fg) .* (mask2_fgp);

g = exp(-(-3:3).^2/2);
g = g / sum(g);

I1s = I1;
I2s = I2;
for k = 1:3, I1s(:,:,k) = conv2(conv2(I1(:,:,k), g, 'same'), g', 'same'); end;
for k = 1:3, I2s(:,:,k) = conv2(conv2(I2(:,:,k), g, 'same'), g', 'same'); end;

warpI2_fg = I2s;
for k = 1:3, warpI2_fg(:,:,k) = interp2(I2s(:,:,k), x + vx_fg, y + vy_fg); end;
warpI2_bg = I2s;
for k = 1:3, warpI2_bg(:,:,k) = interp2(I2s(:,:,k), x + vx_bg, y + vy_bg); end;
warpI1_fg = I1s;
for k = 1:3, warpI1_fg(:,:,k) = interp2(I1s(:,:,k), x + wx_fg, y + wy_fg); end;
warpI1_bg = I1s;
for k = 1:3, warpI1_bg(:,:,k) = interp2(I1s(:,:,k), x + wx_bg, y + wy_bg); end;

diff1_fg = mean(abs(I1s - warpI2_fg), 3);
diff2_fg = mean(abs(I2s - warpI1_fg), 3);
diff1_bg = mean(abs(I1s - warpI2_bg), 3);
diff2_bg = mean(abs(I2s - warpI1_bg), 3);

o1_fg = (diff1_fg > diff1_bg + thr) .* mask1_fgpp; % .* m1_bg;
o1_bg = (diff1_bg > diff1_fg + thr) .* m1_fg .* (1 - mask1_fgpp);
o2_fg = (diff2_fg > diff2_bg + thr) .* mask2_fgp; % .* m2_bg;
o2_bg = (diff2_bg > diff2_fg + thr) .* m2_fg .* (1 - mask2_fgp);

o1_fgp = Transfer(o2_fg, vx_fg, vy_fg, x, y);
% o1_bgp = Transfer(o2_bg, vx_bg, vy_bg, x, y);
o2_fgp = Transfer(o1_fg, wx_fg, wy_fg, x, y);
% o2_bgp = Transfer(o1_bg, wx_bg, wy_bg, x, y);

c1 = max(0, min(1, 1 - cat(3, o1_bg, o1_fg + o1_fgp)));
c2 = max(0, min(1, 1 - cat(3, o2_bg, o2_fg + o2_fgp)));
c1 = imdilate(c1, strel('disk', 1)) .* cat(3, m1_bg, m1_fg);
c2 = imdilate(c2, strel('disk', 1)) .* cat(3, m2_bg, m2_fg);

% fgbg_diff1 = sqrt(sum((v_fg - v_bg).^2, 3));
% fgbg_diff2 = sqrt(sum((w_fg - w_bg).^2, 3));
% c1(:,:,2) = c1(:,:,2) .* (1 + (fgbg_diff1 > 1.0)) * 0.5;
% c2(:,:,2) = c2(:,:,2) .* (1 + (fgbg_diff2 > 1.0)) * 0.5;

figure(11)
PlotImages(...
{mask1_fgpp + mask1_bgpp / 2, mask2_fgp + mask2_bgp / 2 }, ...
{m1_fg *.8 + mask1_fgpp *.2 , m2_fg *.8 + mask2_fgp *.2 }, ...
{m1_bg *.8 + mask1_fgpp *.2 , m2_bg *.8 + mask2_fgp *.2 }, ...
{c1(:,:,1) *.8 + mask1_fgpp *.2, c2(:,:,1) *.8 + mask2_fgp *.2}, ... % del BG
{c1(:,:,2) *.8 + mask1_fgpp *.2, c2(:,:,2) *.8 + mask2_fgp *.2} ... % del FG
);
% {(fgbg_diff1 < 1.0)*.8 + mask1_fgpp*.2, (fgbg_diff2 < 1.0)*.8 + mask2_fgp*.2 }, ...
drawnow;

% imwrite(mask1_fgpp + mask1_bgpp / 2, 'mask1pp.png');
% imwrite(mask2_fgp + mask2_bgp / 2, 'mask2p.png');
% imwrite(m1_fg *.8 + mask1_fgpp *.2, 'mask1fg_diff.png');
% imwrite(m2_fg *.8 + mask2_fgp *.2, 'mask2fg_diff.png');
% imwrite(m1_bg *.8 + mask1_fgpp *.2, 'mask1bg_diff.png');
% imwrite(m2_bg *.8 + mask2_fgp *.2, 'mask2bg_diff.png');
% imwrite(c1(:,:,1) *.8 + mask1_fgpp *.2, 'mask1bg_del.png');
% imwrite(c2(:,:,1) *.8 + mask2_fgp *.2, 'mask2bg_del.png');
% imwrite(c1(:,:,2) *.8 + mask1_fgpp *.2, 'mask1fg_del.png');
% imwrite(c2(:,:,2) *.8 + mask2_fgp *.2, 'mask2fg_del.png');

end

function m = Transfer(mask, vx, vy, x, y)

if nargin < 5
  [x, y] = meshgrid(1:size(vx,2), 1:size(vx,1));
end
m = interp2(mask, x + vx, y + vy);
m(isnan(m)) = 0;
end
