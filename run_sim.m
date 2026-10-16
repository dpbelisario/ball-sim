% run_sim.m - entry point. Run this from anywhere: local MATLAB (R2026a) or MATLAB Online.
% Puts this folder on the path (so simulate, board3d and gitsync stay callable afterwards),
% moves into it, then runs sweep.m. Note: run('.../run_sim.m') restores your original
% folder when it finishes; the path entry stays.
here = fileparts(mfilename('fullpath'));
addpath(here);
cd(here);
sweep
