% sweep.m — which launch (speed, angle) from corner B lands in each goal cup at corner A
% Frame: origin A (low corner), x along A->D, y along A->B. Units: m, s.
% Runs in MATLAB or Octave. No toolboxes.

%% Board
L = 1.145;  W = 0.805;  g = 9.81;
sx = mean([3-1.3, 7-5]) / 114.5;          % rise along x (A->D)
sy = mean([5-1.3, 7-3]) / 80.5;           % rise along y (A->B)
ag = -(5/7)*g*[sx, sy];                   % rolling solid sphere, downhill = toward A
c_r = 0.3;  % ponytail: GUESS (m/s^2 felt drag). Fit from a real roll test, it dominates the result

%% Goals (cups sit just off the felt edge, beside corner A)
cupA_B = [0.15, 0.06];    % [center along y, opening width] on edge x=0 (A-B edge)
cupA_D = [0.15, 0.06];    % [center along x, opening width] on edge y=0 (A-D edge)
% 18 cm from A to the cup's far side, 6 cm wide cup -> center at 15 cm

%% Launcher at B
P0 = [0.05, W - 0.05];    % exit point of the launcher, 5 cm in from corner B. Edit to match CAD
v_list = 0.2:0.02:2.5;    % exit speed (m/s)
th_list = -10:0.5:60;     % angle (deg) from straight-toward-A (-y), positive = into board (+x)

[V, TH] = meshgrid(v_list, th_list);
[hit, exitPt] = simulate(P0, V(:), TH(:), ag, c_r, L, W);
inB = hit == 1 & abs(exitPt(:,2) - cupA_B(1)) <= cupA_B(2)/2;
inD = hit == 2 & abs(exitPt(:,1) - cupA_D(1)) <= cupA_D(2)/2;

%% Self-check: ball released at rest with no drag must roll toward A
[~, e] = simulate([0.5 0.5], 0, 0, ag, 0, L, W);
assert(e(1) < 0.5 && e(2) < 0.5, 'gravity sign wrong');

%% Report + plot
fprintf('Cup on A-B edge: %d hits\n', nnz(inB));
fprintf('Cup on A-D edge: %d hits\n', nnz(inD));
% Most forgiving setting per cup = centre of the biggest scoring blob (tolerates launcher scatter)
best = zeros(2, 2);  masks = {inB, inD};
for c = 1:2
    score = conv2(double(reshape(masks{c}, size(V))), ones(7), 'same');  % 7x7 = +-0.06 m/s, +-1.5 deg
    score(~reshape(masks{c}, size(V))) = 0;
    [~, k] = max(score(:));
    best(c,:) = [V(k), TH(k)];
    fprintf('Best for cup %d: v = %.2f m/s, angle = %.1f deg\n', c, best(c,1), best(c,2));
end

figure; hold on;
plot(TH(inB), V(inB), 'r.', TH(inD), V(inD), 'b.');
xlabel('launch angle from -y (deg)'); ylabel('exit speed (m/s)');
legend('cup on A-B edge', 'cup on A-D edge'); grid on;
title(sprintf('Scoring launches from B  (c_r = %.2f)', c_r));

%% 3D board view: both setups, animated
board3d
