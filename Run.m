%==========================================================================
% Genralized Background Subtraction using Superpixels and Label Integrated
%   Motion Estimation (ECCV 2014)
% 
% Main inference module
% 
% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
%     based on the implementation by Suha Kwak (POSTECH)
%==========================================================================

if ~exist('rpath', 'var')
  SetupSequence;
end

SetupUnifiedParam;

SAVE_PROGRESS_IMAGES = true;

%--------------------------------------------------------------------------
%- Initialization
[irow, icol, ~, nframe] = size(Iseq);
tidx = 1;
disp('-- Frame 1')

B = cell(1, num_seg);
Iorg = double(Iseq(:,:,:,tidx));
I = Iorg;
O = zeros(irow, icol, 2);

for i = 1:num_seg
  B{i} = struct('bnum', num_superpixels(i));
  switch SUPERPIXEL
    case 'ers'
      B{i}.S = SuperpixelERS(I, zeros(size(I,1), size(I,2)), B{i}.bnum);
    case 'grid', B{i}.S = SuperpixelGRID(I, [], num_superpixels(i));
    otherwise, error(['invalid SUPERPIXEL ' SUPERPIXEL]);
  end
  B{i}.G = BuildGraphFromLabel(B{i}.S);
  B{i}.bnum = size(B{i}.G, 1);
end
L = BBP(L0);
mot_mask = L;

%- Build block appearance models at the first frame.
disp('Initial appearance model estimation')
Qc_empty = cell(1, num_seg);
Qc_BG = cell(1, num_seg);
Qc_FG = cell(1, num_seg);
Qv_BG = cell(1, num_seg);
Qv_FG = cell(1, num_seg);
ObsPotAll = [];
ObsPot = cell(1, num_seg);
logplike = cell(1, num_seg);
out = cell(1, num_seg);
for i = 1:num_seg
  Qc_empty{i} = cell(1, B{i}.bnum);
  Qc_BG{i} = AppModelEst(I, ~L, Qc_empty{i}, B{i}, Pc_BG);
  Qc_FG{i} = AppModelEst(I, L, Qc_empty{i}, B{i}, Pc_FG);
  Qv_BG{i} = [];
  Qv_FG{i} = [];
  ObsPot{i} = [];
  logplike{i} = [];
  
  figure(i); 
  [out{i}, outimg] = PlotResult(Iorg, O, O, B{i}, L, mot_mask, ...
    Qc_BG{i}, Qc_FG{i}, Qv_BG{i}, Qv_FG{i}, ObsPot{i}, logplike{i}, ...
    ['frame ' num2str(tidx)]);
  if SAVE_PROGRESS_IMAGES
    imwrite(outimg, sprintf([rpath, 'dump_%03d_f_%d.png'], tidx, i));
  end
end
Qc_BG_tp = cell(1, num_seg);
Qc_FG_tp = cell(1, num_seg);
Bv_BG = cell(1, num_seg);  % block motion models 
Bv_FG = cell(1, num_seg);

imwrite(out{1}.label, sprintf([rpath, 'L%04d.png'], tidx));

%--------------------------------------------------------------------------
%- Iterative estimation

for tidx = 2 : nframe
%   save('snapshot.mat', 'tidx', 'L', 'B', 'Qc_BG', 'Qc_FG', 'Qv_BG', 'Qv_FG');
%   load('snapshot.mat');
  
  Iorg = double(Iseq(:,:,:,tidx));
  I = Iorg;
  Ip = double(Iseq(:,:,:,tidx-1));
  Lp = L;
  
  disp('Compute optical flow');
  tic
  [v_fg, v_bg, w_fg, w_bg, masks, warpI2, warpI1] = ...
      ComputeMotion(Ip/255, I/255, L, 7, 2, flow_param);
  toc
  O_BG = w_bg;
  O_FG = w_fg;
  mot_mask = masks(:,:,2) + masks(:,:,4) / 2;
  L = masks(:,:,2);
  
  tic
  B0 = B;  %- The previous superpixel block structure.
  for i = 1:num_seg
    switch SUPERPIXEL
      case 'ers'
        B{i}.S = SuperpixelERS(I, zeros(size(I,1), size(I,2)), B{i}.bnum);
      case 'grid',
      otherwise, error(['invalid SUPERPIXEL ' SUPERPIXEL]);
    end
    B{i}.G = BuildGraphFromLabel(B{i}.S);
    B{i}.bnum = size(B{i}.G, 1);
  end
  toc
  
  for i = 1:num_seg  %- Plot the initial state.
    figure(i);
    [out{i}, outimg] = PlotResult(Iorg, O_BG, O_FG, B0{i}, L, mot_mask, ...
      Qc_BG{i}, Qc_FG{i}, Qv_BG{i}, Qv_FG{i}, ObsPot{i}, logplike{i}, ...
      ['frame ' num2str(tidx)]);
    if SAVE_PROGRESS_IMAGES
      imwrite(outimg, sprintf([rpath, 'dump_%03d_0_%d.png'], tidx, i));
    end
  end
  
  tic
  disp('Current observation estimate')
  Qc = cell(1, num_seg);
  for i = 1:num_seg
    Qc{i} = AppModelEst(I, ones(irow, icol), cell(1, num_superpixels(i)),...
      B{i}, Pc_BG);
  end
  toc
  
  %- Iterative model-label estimation -------------------------------------
  for ridx = 1 : nround
    disp(['-- Frame ', num2str(tidx), ' (round ', num2str(ridx), ')'])
    
    L_BG = ~L;
    L_FG = L;
    
    disp('Motion model estimation')
    tic
    for i = 1:num_seg
      [Bv_BG{i}, Qv_BG{i}] = MotModelEst(O_BG, L_BG, B0{i}, B{i}, Pv_BG);
    end
    for i = 1:num_seg
      [Bv_FG{i}, Qv_FG{i}] = MotModelEst(O_FG, L_FG, B0{i}, B{i}, Pv_FG);
    end
    toc
    
    disp('Temporal propagation of appearance model')
    tic
    for i=1:num_seg
      Qc_BG_tp{i} = TempModelPropagateSP(Qc_BG{i}, Bv_BG{i}, B{i}, Pt);
      Qc_FG_tp{i} = TempModelPropagateSP(Qc_FG{i}, Bv_FG{i}, B{i}, Pt);
    end
    toc
    
    tic
    disp('Appearance model update')
    for i = 1:num_seg
      for j = 1:numel(Qc_BG_tp{i})
        Qc_BG_tp{i}{j} = HistProd(Qc_BG_tp{i}{j}, Qc{i}{j}, false);
      end
      for j = 1:numel(Qc_FG_tp{i})
        Qc_FG_tp{i}{j} = HistProd(Qc_FG_tp{i}{j}, Qc{i}{j}, false);
      end
    end
    toc
    
    disp('Label estimation')
    tic
    for i=1:num_seg
      [ObsPot{i}, logplike{i}, O_mix] = LikelihoodComp(I, Ip, Iorg, ...
        v_fg, v_bg, w_fg, w_bg, masks, warpI2, warpI1, ...
        Qc_BG_tp{i}, Qc_FG_tp{i}, Qv_BG{i}, Qv_FG{i}, B{i}, Pl);
    end
    
    disp('Label estimation BP')
    [L, ObsPotAll] = LabelEstBP(I, ObsPot, Pl);
    toc
    masks(:,:,1) = Lp;
    masks(:,:,2) = L;
    
    for i = 1:num_seg  %- plot the intermediate result.
      figure(i);
      [out{i}, outimg] = PlotResult(Iorg, O_BG, O_mix, B{i}, L, mot_mask, ...
        Qc_BG_tp{i}, Qc_FG_tp{i}, Qv_BG{i}, Qv_FG{i}, ObsPot{i}, logplike{i}, ...
        ['frame ' num2str(tidx) '/ round ' num2str(ridx)]);
      if SAVE_PROGRESS_IMAGES
        imwrite(outimg, sprintf([rpath, 'dump_%03d_%d_%d.png'], tidx, ridx, i));
      end
    end
  end
  
  disp(['-- Frame ', num2str(tidx), ' (finished)'])
  disp('Temporal propagation of appearance model')
  tic
  for i=1:num_seg
    Qc_BG_tp{i} = TempModelPropagateSP(Qc_BG{i}, Bv_BG{i}, B{i}, Pt);
    Qc_FG_tp{i} = TempModelPropagateSP(Qc_FG{i}, Bv_FG{i}, B{i}, Pt);
  end
  toc
  tic
  disp('Appearance model update')
  for i = 1:num_seg
    Qc_BG{i} = AppModelEst(I, L_BG, Qc_BG_tp{i}, B{i}, Pc_BG);
    Qc_FG{i} = AppModelEst(I, L_FG, Qc_FG_tp{i}, B{i}, Pc_FG);
  end
  toc
  
  for i = 1:num_seg
    figure(i);
    [out{i}, outimg] = PlotResult(Iorg, O_BG, O_FG, B{i}, L, mot_mask, ...
      Qc_BG{i}, Qc_FG{i}, Qv_BG{i}, Qv_FG{i}, ObsPot{i}, logplike{i}, ...
      ['frame ' num2str(tidx)]);
    if SAVE_PROGRESS_IMAGES
      imwrite(outimg, sprintf([rpath, 'dump_%03d_f_%d.png'], tidx, i));
    end
  end
  imwrite(out{1}.label, sprintf([rpath, 'L%04d.png'], tidx));
end
