%==========================================================================
% Genralized Background Subtraction using Superpixels and Label Integrated
%   Motion Estimation (ECCV 2014)
% 
% Setup the input video and initial mask for processing.
% The default data location is './data/'.
% 
% Authors: Jongwoo Lim (Hanyang U), Bohyung Han (POSTECH)
%     based on the implementation by Suha Kwak (POSTECH)
%==========================================================================

vdir = './data/';
if ~exist(vdir, 'dir'), mkdir(vdir); end;

if exist('set_vid', 'var')
  vid = set_vid;
  clear set_vid;
else
  disp(' Test videos');
  disp(' 1. Figure skating');
  disp(' 2. American football');
  disp(' 3. Hopkins, car 1');
  disp(' 4. Hopkins, car 2');
  disp(' 5. Hopkins, people 1');
  disp(' 6. Hopkins, people 2');
  disp(' 7. PV person');
  disp(' 8. Cycle');
  disp(' 9. Tennis');
  disp('10. ETH_reduced');
  disp('11. javelin');
  disp('12. pitching');
  vid = input(' Select one of the above videos : ');
end

switch vid
  case 1,  seq_name = 'skating1.mat';
  case 2,  seq_name = 'NFL.mat';
  case 3,  seq_name = 'hopkins_car1.mat';
  case 4,  seq_name = 'hopkins_car2.mat';
  case 5,  seq_name = 'hopkins_people1.mat';
  case 6,  seq_name = 'hopkins_people2.mat';
  case 7,  seq_name = 'PV_person.mat';
  case 8,  seq_name = 'cycle1.mat';
  case 9,  seq_name = 'tennis.mat';
  case 10,  seq_name = 'ETH_reduced.mat';
  case 11,  seq_name = 'javelin.mat';
  case 12,  seq_name = 'pitching.mat';
  otherwise, % vid = 1; seq_name = 'skating1.mat'];
    error(['unknown vid ' num2str(vid) '...']);
end
vpath = [vdir, seq_name];
if ~exist(vpath, 'file')
  seq_url = ['http://cvlab.hanyang.ac.kr/proj/gbssplime/data/', seq_name];
  disp(['Downloading ' seq_name ' from ' seq_url '...' ]);
  urlwrite(seq_url, vpath);
end
fprintf(1, 'Loading %d : %s...\n', vid, vpath);
evalc(['load ', vpath]);

% Path for saving results.
rpath = ['./result/', num2str(vid), '/'];
mkdir(rpath);

