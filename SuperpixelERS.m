% SuperpixelERS

function [labels, out, bmap, sp_sizes] = SuperpixelERS(img, labels, num_clusters, opt)

if ~exist('num_clusters', 'var'), num_clusters = 200; end;
if ~exist('opt', 'var'), opt = ''; end;

% %// Our implementation can take both color and grey scale images.
% grey_img = double(rgb2gray(img));

%// You can also specify your preference parameters. The parameter values
%// (lambda_prime = 0.5, sigma = 5.0) are chosen based on the experiment
%// results in the Berkeley segmentation dataset.
%// lambda_prime = 0.5; sigma = 5.0;
%// [labels] = mex_ers(grey_img,nC,lambda_prime,sigma);
%// You can also use 4 connected-grid graph. The algorithm uses 8-connected 
%// graph as default setting. By setting conn8 = 0 and running
%// [labels] = mex_ers(grey_img,nC,lambda_prime,sigma,conn8),
%// the algorithm perform segmentation uses 4-connected graph. Note that 
%// 4 connected graph is faster.
% lambda_prime = 0.5;sigma = 5.0; 
% conn8 = 1; % flag for using 8 connected grid graph (default setting).

if strcmp(opt, 'image')
  [labels] = mex_ers(double(img), [], num_clusters);
  %[labels] = mex_ers(double(img), num_clusters, lambda_prime, sigma);
  %[labels] = mex_ers(double(img), num_clusters, lambda_prime, sigma, conn8);

  % grey scale iamge
  %[labels] = mex_ers(grey_img, num_clusters);
  %[labels] = mex_ers(grey_img, num_clusters, lambda_prime, sigma);
  %[labels] = mex_ers(grey_img, num_clusters, lambda_prime, sigma,conn8);
else
  [labels] = mex_ersv(double(img), double(labels), num_clusters);
end

labels = labels + 1;  % make labels to 1-num_clusters.

if nargout > 1 || nargout == 0
  %// Randomly color the superpixels
  [out] = random_color(labels, num_clusters);
end

if nargout > 2 || nargout == 0
  %// Compute the boundary map and superimpose it on the input image in the
  %// green channel.
  %// The seg2bmap function is directly duplicated from the Berkeley
  %// Segmentation dataset which can be accessed via
  %// http://www.eecs.berkeley.edu/Research/Projects/CS/vision/bsds/
  [bmap] = seg2bmap(labels);
end

if nargout > 3 || nargout == 0
  %// Compute the superpixel sizes.
  sp_sizes = zeros(num_clusters, 1);
  for i = 1:num_clusters
    sp_sizes(i) = sum(labels(:) == i - 1);
  end
end

if nargout == 0
  clf;
  subplot(2, 2, 1);
  imagesc(img / 255);
  axis image off;
  subplot(2, 2, 2);
  imagesc(out);
  axis image off;
  subplot(2, 2, 3);
  imagesc(img / 512 + repmat(bmap, [1,1,3])/2);
  axis image off;
  subplot(2, 2, 4);
  hist(sp_sizes, 20);
end

end


function [out] = random_color(labels, num_clusters)

[h, w, ~] = size(labels);
img = zeros(3, w * h);
for i = 0:(num_clusters-1)
  idx = find(labels==i);
  img(:, idx) = repmat(rand(3, 1), [1, numel(idx)]);
end
out = reshape(img', [h, w, 3]);
end


function [bmap] = seg2bmap(seg)

[h,w] = size(seg);
e = zeros(h, w);
s = zeros(h, w);
se = zeros(h, w);

e(:, 1:end-1) = seg(:, 2:end);
s(1:end-1, :) = seg(2:end, :);
se(1:end-1, 1:end-1) = seg(2:end, 2:end);

bmap = (seg ~= e | seg ~= s | seg ~= se);
bmap(end,:) = (seg(end,:) ~= e(end,:));
bmap(:,end) = (seg(:,end) ~= s(:,end));
bmap(end,end) = 0;
end
