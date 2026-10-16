function [win, hit, e] = scoring_windows(S, th)
% scoring_windows(S, th) — simulate one launch per angle in th (deg) at the fixed exit speed S.v0.
% win{1} / win{2}: angle windows [from to] (one row per window) that land in the A-B / A-D edge cup.
% hit, e: simulate.m outputs per angle (which edge it left by, and where).
th = th(:);
[hit, e] = simulate(S.P0, S.v0 * ones(size(th)), th, S.ag, S.c_r, S.L, S.W);
in = {hit == 1 & abs(e(:,2) - S.cupA_B(1)) <= S.cupA_B(2)/2, ...
      hit == 2 & abs(e(:,1) - S.cupA_D(1)) <= S.cupA_D(2)/2};
win = cell(1, 2);
for c = 1:2
    d = diff([0; in{c}; 0]);                      % +1 where a run of scoring angles starts, -1 after it ends
    win{c} = [th(d(1:end-1) == 1), th(d(2:end) == -1)];
end
end
