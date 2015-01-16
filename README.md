# gbssplime
Generalized Background Subtraction using Super-pixels and Label Integrated
Motion Estimation

Jongwoo Lim, Bohyung Han, “Generalized Background Subtraction using Superpixels
with Label Integrated Motion Estimation,” in ECCV 2014

Project webpage:
http://cvlab.hanyang.ac.kr/proj/gbssplime/

How to run the code
-------------------

1. Build the two mex files - Coarse2FineTwoFrames.mex and mex\_ersv.mex.

2. Run 'Run.m' and choose the dataset to process.
- The test video data will be automatically downloaded.


Parameters
----------

SetupSequence.m:
- vdir = './data/';  : where the dataset is stored.
- rpath = ['../Result/', num2str(vid), '/'];  : where the result is stored.

Run.m
- SAVE\_PROGRESS\_IMAGES = true;  : whether to save intermediate results.

SetupUnifiedParam.m
- a whole bunch of parameters for the algorithm.

