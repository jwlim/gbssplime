function [img, maxrad] = FlowToColor(flow, maxrad, show_circle)

%  flowToColor(flow, maxFlow) flowToColor color codes flow field, normalize
%  based on specified value, 
% 
%  flowToColor(flow) flowToColor color codes flow field, normalize
%  based on maximum flow present otherwise 

%   According to the c++ source code of Daniel Scharstein 
%   Contact: schar@middlebury.edu

%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007-10-31 18:33:30 (Wed, 31 Oct 2006) $

% Copyright 2007, Deqing Sun.
%
%                         All Rights Reserved
%
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose other than its incorporation into a
% commercial product is hereby granted without fee, provided that the
% above copyright notice appear in all copies and that both that
% copyright notice and this permission notice appear in supporting
% documentation, and that the name of the author and Brown University not be used in
% advertising or publicity pertaining to distribution of the software
% without specific, written prior permission.
%
% THE AUTHOR AND BROWN UNIVERSITY DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
% INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
% PARTICULAR PURPOSE.  IN NO EVENT SHALL THE AUTHOR OR BROWN UNIVERSITY BE LIABLE FOR
% ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 

UNKNOWN_FLOW_THRESH = 1e9;

if nargin < 3, show_circle = false; end;

[height width nBands] = size(flow);

if (height == 2 && width * nBands == 1) || (width == 2 && height * nBands == 1)
  img = computeColor(flow(1) / maxrad, flow(2) / maxrad);
  return
elseif nBands ~= 2
  error('flowToColor: image must have two bands');
end;    

u = flow(:,:,1);
v = flow(:,:,2);

% fix unknown flow
idxUnknown = (abs(u)> UNKNOWN_FLOW_THRESH) | (abs(v)> UNKNOWN_FLOW_THRESH) ;
u(idxUnknown) = 0;
v(idxUnknown) = 0;

if ~exist('maxrad', 'var')
  rad = sqrt(u.^2 + v.^2);
  maxrad = max(rad(:));
end

u = u / (maxrad + eps);
v = v / (maxrad + eps);

% compute color
img = computeColor(u, v);  
    
% unknown flow
IDX = repmat(idxUnknown, [1 1 3]);
img(IDX) = 0;

if show_circle
  r = maxrad;
  k = 2 * r + 1;
  circle_flow = cat(3, repmat(-r:r, [k,1]), repmat((-r:r)', [1,k]));
  circle_flow(sqrt(sum(circle_flow.^2, 3)) > r) = nan;
  circle_rgb = FlowToColor(circle_flow, r);
  for i = 1:k
    for j = 1:k
      if ~isnan(circle_flow(i, j, 1))
        img(i, j, :) = circle_rgb(i, j, :);
      end
    end
  end
end
end


function img = computeColor(u,v)

%   computeColor color codes flow field U, V

%   According to the c++ source code of Daniel Scharstein 
%   Contact: schar@middlebury.edu

%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007-10-31 21:20:30 (Wed, 31 Oct 2006) $

% Copyright 2007, Deqing Sun.
%
%                         All Rights Reserved
%
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose other than its incorporation into a
% commercial product is hereby granted without fee, provided that the
% above copyright notice appear in all copies and that both that
% copyright notice and this permission notice appear in supporting
% documentation, and that the name of the author and Brown University not be used in
% advertising or publicity pertaining to distribution of the software
% without specific, written prior permission.
%
% THE AUTHOR AND BROWN UNIVERSITY DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
% INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
% PARTICULAR PURPOSE.  IN NO EVENT SHALL THE AUTHOR OR BROWN UNIVERSITY BE LIABLE FOR
% ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 

nanIdx = isnan(u) | isnan(v);
u(nanIdx) = 0;
v(nanIdx) = 0;

colorwheel = makeColorwheel();
ncols = size(colorwheel, 1);

rad = sqrt(u.^2 + v.^2);

a = atan2(-v, -u)/pi;

fk = (a+1) /2 * (ncols-1) + 1;  % -1~1 maped to 1~ncols
   
k0 = floor(fk);                 % 1, 2, ..., ncols

k1 = k0+1;
k1(k1==ncols+1) = 1;

f = fk - k0;

for i = 1:size(colorwheel, 2)
    tmp = colorwheel(:,i);
    col0 = tmp(k0)/255;
    col1 = tmp(k1)/255;
    col = (1-f).*col0 + f.*col1;   
   
    idx = (rad <= 1);
    col(idx) = 1 - rad(idx) .* (1 - col(idx));  % increase saturation with radius
    col(~idx) = col(~idx) * 0.75;               % out of range
    
    img(:,:,i) = uint8(floor(255 * col .* (1 - nanIdx)));         
end;
end


function colorwheel = makeColorwheel()

%   color encoding scheme

%   adapted from the color circle idea described at
%   http://members.shaw.ca/quadibloc/other/colint.htm


RY = 15;
YG = 6;
GC = 4;
CB = 11;
BM = 13;
MR = 6;

ncols = RY + YG + GC + CB + BM + MR;

colorwheel = zeros(ncols, 3); % r g b

col = 0;
%RY
colorwheel(1:RY, 1) = 255;
colorwheel(1:RY, 2) = floor(255*(0:RY-1)/RY)';
col = col+RY;

%YG
colorwheel(col+(1:YG), 1) = 255 - floor(255*(0:YG-1)/YG)';
colorwheel(col+(1:YG), 2) = 255;
col = col+YG;

%GC
colorwheel(col+(1:GC), 2) = 255;
colorwheel(col+(1:GC), 3) = floor(255*(0:GC-1)/GC)';
col = col+GC;

%CB
colorwheel(col+(1:CB), 2) = 255 - floor(255*(0:CB-1)/CB)';
colorwheel(col+(1:CB), 3) = 255;
col = col+CB;

%BM
colorwheel(col+(1:BM), 3) = 255;
colorwheel(col+(1:BM), 1) = floor(255*(0:BM-1)/BM)';
col = col+BM;

%MR
colorwheel(col+(1:MR), 3) = 255 - floor(255*(0:MR-1)/MR)';
colorwheel(col+(1:MR), 1) = 255;
end