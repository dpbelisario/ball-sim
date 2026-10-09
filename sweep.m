% sweep.m — which launch (ramp drop, angle) from corner D lands in each goal cup at corner A
% Frame: origin A (low corner), x along A->D, y along A->B. Units: m, s.
% Runs in MATLAB or Octave. No toolboxes.

%% Board
L = 1.145;  W = 0.805;  g = 9.81;
sx = mean([3-1.3, 7-5]) / 114.5;          % rise along x (A->D)
sy = mean([5-1.3, 7-3]) / 80.5;           % rise along y (A->B)
ag = -(5/7)*g*[sx, sy];                   % rolling solid sphere, downhill = toward A
c_r = 0.2;  % ponytail: GUESS (m/s^2 felt drag). Tune with the 'observed shot' check below, later fit from video
eta = 0.85; % ponytail: ramp losses (1 = perfect ramp). Tune together with c_r

%% Goals (cups sit just off the felt edge, beside corner A)
cupA_B = [0.15, 0.06];    % [center along y, opening width] on edge x=0 (A-B edge)
cupA_D = [0.15, 0.06];    % [center along x, opening width] on edge y=0 (A-D edge)
% 18 cm from A to the cup's far side, 6 cm wide cup -> center at 15 cm

%% Launcher at D
P0 = [L - 0.05, 0.05];    % exit point of the launcher, 5 cm in from corner D. Edit to match CAD
h_list = 0.02:0.0025:0.15; % ramp drop height (m): 2-15 cm
th_list = 0:1:90;         % angle (deg): 0 = along D->A edge, 90 = straight into the board toward C

[H, TH] = meshgrid(h_list, th_list);
V = eta * sqrt(10/7 * g * H);              % rolling ball off a ramp of drop H
[hit, exitPt] = simulate(P0, V(:), TH(:), ag, c_r, L, W);
inB = hit == 1 & abs(exitPt(:,2) - cupA_B(1)) <= cupA_B(2)/2;
inD = hit == 2 & abs(exitPt(:,1) - cupA_D(1)) <= cupA_D(2)/2;

%% Self-check: ball released at rest with no drag must roll toward A
[~, e] = simulate([0.5 0.5], 0, 0, ag, 0, L, W);
assert(e(1) < 0.5 && e(2) < 0.5, 'gravity sign wrong');

%% Observed-shot check: real test was ~5-10 cm ramp, ball went ~55 cm into the board then curved to A
[~, e, p] = simulate(P0, eta*sqrt(10/7*g*0.075), 40, ag, c_r, L, W);
fprintf('Check (7.5 cm drop, 40 deg): max %.0f cm into board, ends at x=%.0f y=%.0f cm. Tune c_r/eta to match reality\n', ...
        100*max(p(:,2)), 100*e(1), 100*e(2));

%% Report + plot
fprintf('Cup on A-B edge: %d hits\n', nnz(inB));
fprintf('Cup on A-D edge: %d hits\n', nnz(inD));
% Most forgiving setting per cup = centre of the biggest scoring blob (tolerates launcher scatter)
best = zeros(2, 3);  masks = {inB, inD};      % [v, angle, h]
for c = 1:2
    m = reshape(masks{c}, size(H));
    score = conv2(double(m), ones(7), 'same');  % 7x7 = +-0.75 cm drop, +-3 deg
    score(~m) = 0;
    [~, k] = max(score(:));
    best(c,:) = [V(k), TH(k), H(k)];
    fprintf('Best for cup %d: ramp drop = %.1f cm (v = %.2f m/s), angle = %.0f deg\n', c, 100*H(k), V(k), TH(k));
end

figure; hold on;
plot(TH(inB), 100*H(inB), 'r.', TH(inD), 100*H(inD), 'b.');
xlabel('launch angle (deg): 0 = along D->A edge, 90 = into board'); ylabel('ramp drop (cm)');
legend('cup on A-B edge', 'cup on A-D edge'); grid on;
title(sprintf('Scoring launches from D  (c_r = %.2f, eta = %.2f)', c_r, eta));

%% 3D board view: both setups, animated
board3d
