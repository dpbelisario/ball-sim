% sweep.m — fixed chute (one exit speed) turning about corner D, vary only the launch angle:
% which angles land in each goal cup at corner A. Then opens the 3D board with an angle slider.
% Frame: origin A (low corner), x along A->D, y along A->B. Units: m, s. Runs in MATLAB or Octave, no toolboxes.

%% Board
L = 1.145;  W = 0.805;  g = 9.81;

%% Felt + slope, measured from the overhead full-board video (ball_video.mp4, 2026-10-30, scale from the board edges).
% Re-simulating that whole shot with these two numbers lands within 0.6 cm on average (1.8 cm max) of the real ball
% over 3.6 s. A speed-dependent drag fitted no better, so drag stays one constant.
c_r = 0.34;                               % felt drag (m/s^2)
ag  = -0.38 * [cosd(61), sind(61)];       % slope pull (m/s^2) toward A, 61 deg from the A-D edge (corner heights predicted 0.35 at 71 deg)
% Ramp exit speed from physics (5 x 11.4 cm triangle ramp, 4 cm rail gap, 1 cm rails, golf ball r = 21.35 mm):
%  - ball fits between the rails: resting on the floor its half-width at rail height is 18.1 mm < 20 mm gap/2,
%    so it rolls on the channel floor with its full radius (rails only guide) -> no extra spin penalty
%  - rolling without slipping, no losses: v = sqrt(10/7 g h)                       = 0.84 m/s
%  - sharp ramp -> felt corner (23.7 deg) costs: v' = v (5 cos(theta) + 2) / 7     -> 0.79 m/s
%  (the blue test ramp in ball_video.mp4 measured ~0.76 m/s just after leaving it: consistent)
r_ball = 0.02135;  h_ramp = 0.05;  len_ramp = 0.114;  gap = 0.04;  rail = 0.01;  % h_ramp = slope surface at the top (rails not included)
assert(sqrt(r_ball^2 - (r_ball - rail)^2) < gap/2, 'ball rides on the rails, not the floor: use rolling radius sqrt(r^2-(gap/2)^2)');
th_ramp = atan(h_ramp / len_ramp);
drop = h_ramp - r_ball*(1 - cos(th_ramp));               % ball CENTRE drop: on the slope the centre sits r*cos(theta) above the contact point
v0 = sqrt(10/7 * g * drop) * (5*cos(th_ramp) + 2) / 7;   % ponytail: ideal physics; a filmed release would confirm it

%% Goals (cups sit just off the felt edge, beside corner A)
cupA_B = [0.15, 0.06];    % [center along y, opening width] on edge x=0 (A-B edge)
cupA_D = [0.15, 0.06];    % [center along x, opening width] on edge y=0 (A-D edge)
% 18 cm from A to the cup's far side, 6 cm wide cup -> center at 15 cm

%% Launcher (CAD 発射台ver2 + 発射台固定台): the same 5 x 11.4 cm chute, now on a quarter-circle base in corner D.
% The chute turns about the corner, so the point where the ball meets the felt moves along an arc as the angle changes.
pivot  = [L, 0];          % corner D = centre of the quarter-circle base
r_exit = 0.227;           % ponytail: chute tip (ball meets the felt) 22.7 cm from the corner, scaled off the CAD photos -> measure in SolidWorks
r_back = 0.108;           % chute back wall, from the corner (drawing only, CAD photos)
r_base = [0.146, 0.200];  % base: raised inner disk / outer ring radius (drawing only, CAD photos)
h_base = [0.030, 0.009];  % base heights: inner disk / ring (drawing only, CAD photos)
P0at = @(th) pivot + r_exit * [-cosd(th(:)), sind(th(:))];   % exit point for each angle (deg), one row per angle
th_list = 0:0.1:90;       % angle (deg): 0 = chute along the D->A edge toward A, 90 = along the D-C edge

S = struct('L', L, 'W', W, 'g', g, 'ag', ag, 'c_r', c_r, 'v0', v0, 'P0at', P0at, 'pivot', pivot, 'r_exit', r_exit, ...
           'r_back', r_back, 'r_base', r_base, 'h_base', h_base, 'cupA_B', cupA_B, 'cupA_D', cupA_D);
[win, hit, exitPt] = scoring_windows(S, th_list);

%% Self-check: ball released at rest with no drag must roll toward A
[~, e] = simulate([0.5 0.5], 0, 0, ag, 0, L, W);
assert(e(1) < 0.5 && e(2) < 0.5, 'gravity sign wrong / 重力の向きが逆');

%% Report: aim windows per cup / 各カップの成功角度範囲
names = {'A-B edge cup', 'A-D edge cup'};  namesJ = {'A-B辺のカップ', 'A-D辺のカップ'};
fprintf('\nExit speed %.2f m/s, felt drag %.2f, slope pull %.2f m/s^2, chute tip %.1f cm from corner D\n', v0, c_r, norm(ag), 100*r_exit);
fprintf('出口速度 %.2f m/s、フェルト抵抗 %.2f、傾斜の加速度 %.2f m/s^2、シュート先端はD角から %.1f cm\n\n', v0, c_r, norm(ag), 100*r_exit);
best = nan(2, 2);  fan = {zeros(0, 2), zeros(0, 2)};      % [v, angle]
for c = 1:2
    w = win{c};
    if isempty(w)
        fprintf('%s: NO angle scores from D at this exit speed / %s：この出口速度ではDからどの角度でも入らない\n', names{c}, namesJ{c});
        continue
    end
    for j = 1:size(w, 1)
        fprintf('%s: %.1f° to %.1f°  -> aim %.1f° (±%.1f°)\n', names{c}, w(j,1), w(j,2), mean(w(j,:)), diff(w(j,:))/2);
        fprintf('  %s：%.1f°～%.1f° → 狙い %.1f°（±%.1f°）\n', namesJ{c}, w(j,1), w(j,2), mean(w(j,:)), diff(w(j,:))/2);
        fan{c}(end+1,:) = [v0, mean(w(j,:))];
    end
    [~, k] = max(diff(w, 1, 2));                           % widest window = most forgiving aim
    best(c,:) = [v0, mean(w(k,:))];
end

%% How much the aim moves if the measured numbers are a bit off / 測定誤差で狙い角度がどれだけ動くか
fprintf('\nSensitivity (aim angle of each window) / 感度（各範囲の狙い角度）:\n');
cases = {'measured / 測定値', c_r, v0; 'drag -0.03', c_r-0.03, v0; 'drag +0.03', c_r+0.03, v0; ...
         'speed -0.05', c_r, v0-0.05; 'speed +0.05', c_r, v0+0.05};
for i = 1:size(cases, 1)
    S2 = S;  S2.c_r = cases{i,2};  S2.v0 = cases{i,3};
    w2 = scoring_windows(S2, th_list);
    txt = cell(1, 2);
    for c = 1:2
        if isempty(w2{c}), txt{c} = 'none / なし'; else, txt{c} = sprintf('%.1f° ', mean(w2{c}, 2)); end
    end
    fprintf('  %-18s  A-B cup: %-16s  A-D cup: %s\n', cases{i,1}, txt{1}, txt{2});
end
fprintf('\n');

%% Aim chart: where the ball leaves the board for every angle / 角度ごとの落下位置
along = nan(size(th_list(:)));
along(hit == 1) = exitPt(hit == 1, 2);  along(hit == 2) = exitPt(hit == 2, 1);
figure; hold on; grid on;
try, theme(gcf, 'light'); end   % readable text in MATLAB dark mode
hf = fill([0 90 90 0], 100*(cupA_B(1) + [-1 -1 1 1]*cupA_B(2)/2), [0.85 1 0.85], 'EdgeColor', 'none');
a1 = along;  a1(hit ~= 1) = NaN;  a2 = along;  a2(hit ~= 2) = NaN;   % NaN gaps keep both series (and the legend) even if one is empty
h1 = plot(th_list, 100*a1, 'r.');  h2 = plot(th_list, 100*a2, 'b.');
xlabel({'launch angle (deg): 0 = along D->A edge, 90 = into board', '発射角度（度）：0 = D→A辺に沿う、90 = 盤面の内側へ'});
ylabel({'where it leaves the board: distance from A (cm)', '盤面から落ちる位置：Aからの距離 (cm)'});
legend([hf h1 h2], 'cup opening (12-18 cm) / カップの開口部', 'leaves by A-B edge / A-B辺から落下', 'leaves by A-D edge / A-D辺から落下');
title({sprintf('Aim chart from D  (v0 = %.2f m/s, drag = %.2f)', v0, c_r), 'Dからの狙い角度チャート：緑の帯に入れば成功'});
xlim([0 90]); ylim([0 100]);

%% 3D board with the angle slider / 3D表示と角度スライダー
S.win = win;
board3d
