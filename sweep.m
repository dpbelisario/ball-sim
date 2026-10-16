% sweep.m — fixed ramp (one exit speed), vary only the launch angle from corner D:
% which angles land in each goal cup at corner A. Then opens the 3D board with an angle slider.
% Frame: origin A (low corner), x along A->D, y along A->B. Units: m, s. Runs in MATLAB or Octave, no toolboxes.

%% Board
L = 1.145;  W = 0.805;  g = 9.81;
sx = mean([3-1.3, 7-5]) / 114.5;          % rise along x (A->D), from corner heights A 1.3, B 5, C 7, D 3 cm
sy = mean([5-1.3, 7-3]) / 80.5;           % rise along y (A->B)
ag = -(5/7)*g*[sx, sy];                   % rolling solid sphere, downhill = toward A (direction from the corners)

%% Measured from the overhead roll video (PXL_20261016_063356301), tape-measure scale:
% felt drag 0.21-0.22, slope pull 0.30-0.32 m/s^2 (corners predict 0.35: board is flatter mid-board),
% exit speed off the 5 cm blue ramp ~0.67 m/s (ideal 0.84 -> ramp keeps ~80%)
c_r    = 0.22;  % ponytail: felt drag (m/s^2), +-0.03. More rolls tighten it
G_meas = 0.31;  % ponytail: measured slope pull (m/s^2); replaces the corner-based 0.35, same direction
% Ramp exit speed from physics (5 x 11.4 cm triangle ramp, 4 cm rail gap, 1 cm rails, golf ball r = 21.35 mm):
%  - ball fits between the rails: resting on the floor its half-width at rail height is 18.1 mm < 20 mm gap/2,
%    so it rolls on the channel floor with its full radius (rails only guide) -> no extra spin penalty
%  - rolling without slipping, no losses: v = sqrt(10/7 g h)                       = 0.84 m/s
%  - sharp ramp -> felt corner (23.7 deg) costs: v' = v (5 cos(theta) + 2) / 7     -> 0.79 m/s
%  (video measured 0.67 +-0.05; real shots reaching the A-B cup need >= 0.73, consistent with ~0.79)
r_ball = 0.02135;  h_ramp = 0.05;  len_ramp = 0.114;  gap = 0.04;  rail = 0.01;
assert(sqrt(r_ball^2 - (r_ball - rail)^2) < gap/2, 'ball rides on the rails, not the floor: use rolling radius sqrt(r^2-(gap/2)^2)');
th_ramp = atan(h_ramp / len_ramp);
v0 = sqrt(10/7 * g * h_ramp) * (5*cos(th_ramp) + 2) / 7;   % ponytail: ideal physics; a filmed release would confirm it
ag = ag * G_meas / norm(ag);

%% Goals (cups sit just off the felt edge, beside corner A)
cupA_B = [0.15, 0.06];    % [center along y, opening width] on edge x=0 (A-B edge)
cupA_D = [0.15, 0.06];    % [center along x, opening width] on edge y=0 (A-D edge)
% 18 cm from A to the cup's far side, 6 cm wide cup -> center at 15 cm

%% Launcher at D
P0 = [L - 0.05, 0.05];    % exit point of the launcher, 5 cm in from corner D. Edit to match CAD
th_list = 0:0.1:90;       % angle (deg): 0 = along D->A edge toward A, 90 = straight into the board

S = struct('L', L, 'W', W, 'g', g, 'ag', ag, 'c_r', c_r, 'v0', v0, 'P0', P0, 'cupA_B', cupA_B, 'cupA_D', cupA_D);
[win, hit, exitPt] = scoring_windows(S, th_list);

%% Self-check: ball released at rest with no drag must roll toward A
[~, e] = simulate([0.5 0.5], 0, 0, ag, 0, L, W);
assert(e(1) < 0.5 && e(2) < 0.5, 'gravity sign wrong / 重力の向きが逆');

%% Report: aim windows per cup / 各カップの成功角度範囲
names = {'A-B edge cup', 'A-D edge cup'};  namesJ = {'A-B辺のカップ', 'A-D辺のカップ'};
fprintf('\nExit speed %.2f m/s, felt drag %.2f, slope pull %.2f m/s^2\n', v0, c_r, G_meas);
fprintf('出口速度 %.2f m/s、フェルト抵抗 %.2f、傾斜の加速度 %.2f m/s^2\n\n', v0, c_r, G_meas);
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
