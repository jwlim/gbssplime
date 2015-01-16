# gbssplime
Generalized Background Subtraction using Super-pixels and Label Integrated
Motion Estimation

Jongwoo Lim, Bohyung Han, “Generalized Background Subtraction using Superpixels
with Label Integrated Motion Estimation,” in ECCV 2014

How to run
----------

1. Download the dataset from

2. Build the two mex files - Coarse2FineTwoFrames.mex and mex\_ersv.mex.

3. Run 'Run.m' and choose the dataset to process.


Parameters
----------

SetupSequence.m:
- vpath = './data/';  : where the dataset is.
- rpath = ['../Result/', num2str(vid), '/'];  : where the result is stored.

Run.m
- SAVE\_PROGRESS\_IMAGES = true;  : whether to save intermediate results.

SetupUnifiedParam.m
- a whole bunch of parameters for the algorithm.

