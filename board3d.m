% board3d.m — 3D view of the tilted board, cups and both best shots. Called at the end of sweep.m
% (uses its workspace: L, W, P0, best, cupA_B, cupA_D, ag, c_r, g). Plain MATLAB graphics, no toolboxes.
% View matches the table photo: A (goal) back-left, D (blue launcher) back-right, B front-left, C front-right.
% The sim frame (y = A->B) is mirrored vs. that view, so everything is drawn at -y.

zExag = 2;            % ponytail: tilt is only a few cm, so z is drawn 2x. Set 1 for true scale
r = 0.02135;          % golf ball radius
zc = [1.3 5 7 3]/100; % felt surface height at corners A B C D (m above table)
zBoard = @(x, y) zc(1)*(1-x/L).*(1-y/W) + zc(2)*(1-x/L).*(y/W) + zc(3)*(x/L).*(y/W) + zc(4)*(x/L).*(1-y/W);

figure('Color', 'w'); hold on; grid on;
set(gca, 'Position', [0.08 0.27 0.88 0.58]);   % room at the bottom for the ramp sliders
try, theme(gcf, 'light'); end   % MATLAB dark mode greys out all text; force light (no-op on older MATLAB/Octave)
daspect([1 1 1/zExag]); view(-10, 50);
xlabel({'x (m), A -> D', 'x (m)、A→D'}); ylabel({'distance from A-D edge (m)', 'A-D辺からの距離 (m)'}); zlabel({'z (m)', '高さ (m)'});

% table, felt, board edges
surf([-0.2 L+0.1; -0.2 L+0.1], -[-0.2 -0.2; W+0.1 W+0.1], zeros(2), 'FaceColor', [0.93 0.85 0.7], 'EdgeColor', 'none');
[bx, by] = meshgrid([0 L], [0 W]);
surf(bx, -by, zBoard(bx, by), 'FaceColor', [0.75 0.75 0.75], 'EdgeColor', 'k');
ex = [0 L L 0 0];  ey = [0 0 W W 0];
for k = 1:4  % side skirts down to the table
    xs = ex(k:k+1);  ys = ey(k:k+1);
    fill3([xs fliplr(xs)], -[ys fliplr(ys)], [zBoard(xs, ys) 0 0], [0.6 0.6 0.6]);
end
lbl = {'A', 'B', 'C', 'D'};  cx4 = [0 0 L L];  cy4 = [0 W W 0];
off = 0.07;                                      % labels sit just outside each corner, boxed so they read on any background
for k = 1:4
    text(cx4(k) + off*sign(cx4(k) - L/2), -(cy4(k) + off*sign(cy4(k) - W/2)), zc(k) + 0.05, lbl{k}, ...
         'FontWeight', 'bold', 'FontSize', 18, 'Color', 'k', 'BackgroundColor', [1 1 0.75], 'EdgeColor', 'k', ...
         'HorizontalAlignment', 'center');
end

% cups: U shape, opening on the board edge, 6 cm wide, 7.5 cm deep
% both cups identical; height is cosmetic (ball scoring is decided at the felt edge). Rail between them not drawn
cupH = 0.10;  cups = {cupA_B, cupA_D};  depth = 0.075;  half = 0.03;
t = linspace(-pi/2, pi/2, 20);
for c = 1:2
    out = [-(depth-half)*ones(1,2), -(depth-half) - half*cos(t), -(depth-half)*ones(1,2)];  % outward from edge
    out(1) = 0;  out(end) = 0;
    along = cups{c}(1) + [-half, -half, half*sin(t), half, half];
    if c == 1, ux = out; uy = along; else, ux = along; uy = out; end   % A-B cup sticks out in -x, A-D cup in -y
    surf([ux; ux], -[uy; uy], [zeros(size(ux)); cupH*ones(size(ux))], 'FaceColor', [0.15 0.15 0.15], 'FaceAlpha', 0.7, 'EdgeColor', 'none');
end

% launcher: blue marker sitting on the felt at its exit point
plot3(P0(1), -P0(2), zBoard(P0(1), P0(2)) + 0.01, 'bs', 'MarkerSize', 12, 'MarkerFaceColor', 'b');

% paths: roll on felt, then fall off the edge into the cup
[sxp, syp, szp] = sphere(16);
ball = surf(r*sxp, r*syp, r*szp, 'FaceColor', [1 0.5 0], 'EdgeColor', 'none', 'Tag', 'ball');
cols = 'rb';  names = {'cup on A-B edge', 'cup on A-D edge'};  namesJ = {'A-B辺のカップ', 'A-D辺のカップ'};
P = cell(1, 2);
fanCol = {[1 0.7 0.7], [0.7 0.7 1]};          % faint: every scoring angle from the sweep table
for c = 1:2
    for j = 1:size(fan{c}, 1)
        [~, ~, p] = simulate(P0, fan{c}(j,1), fan{c}(j,2), ag, c_r, L, W);
        plot3(p(:,1), -p(:,2), zBoard(min(max(p(:,1), 0), L), min(max(p(:,2), 0), W)) + r, '-', 'Color', fanCol{c});
    end
end
for c = 1:2
    [~, ~, p] = simulate(P0, best(c,1), best(c,2), ag, c_r, L, W);
    z = zBoard(min(max(p(:,1), 0), L), min(max(p(:,2), 0), W)) + r;
    vel = (p(end,:) - p(end-1,:)) / 0.01;               % path is sampled every 10 ms
    tf = (0:0.01:sqrt(2*z(end)/g))';                    % free fall from edge height to table
    drop = [p(end,:) + tf*vel, z(end) - 0.5*g*tf.^2];
    drop(:,3) = max(drop(:,3), r);
    lim = -(depth - r);                                 % cup back wall stops the ball
    if c == 1, drop(:,1) = max(drop(:,1), lim); else, drop(:,2) = max(drop(:,2), lim); end
    P{c} = [p z; drop];
    plot3(P{c}(:,1), -P{c}(:,2), P{c}(:,3), [cols(c) '--'], 'LineWidth', 1.5);
end

yt = get(gca, 'YTick');  set(gca, 'YTickLabel', arrayfun(@(v) sprintf('%.1f', -v), yt, 'UniformOutput', false));  % show distances as positive

for c = 1:2
    title({sprintf('Setup %d: %s  (ramp drop %.1f cm, angle %.0f deg, z x%d)', c, names{c}, 100*best(c,3), best(c,2), zExag), ...
           sprintf('設定%d：%s（ランプ落差 %.1f cm、角度 %.0f°、高さ%d倍表示）', c, namesJ{c}, 100*best(c,3), best(c,2), zExag)});
    for i = [1:5:size(P{c}, 1), size(P{c}, 1)]          % every 5th point = 50 ms frames, still real time (MATLAB Online redraws are slow)
        set(ball, 'XData', P{c}(i,1) + r*sxp, 'YData', -P{c}(i,2) + r*syp, 'ZData', P{c}(i,3) + r*szp/zExag);  % /zExag keeps it round
        drawnow; pause(0.05);
    end
    pause(0.5);
end

% sliders: turn the ramp 0-90 deg and change its drop; live path + ball redraw on this figure
S.zc = zc;  S.r = r;  S.zExag = zExag;
ramp_slider(gcf, S);
