% board3d.m — 3D view of the tilted board, cups and both best shots. Called at the end of sweep.m
% (uses its workspace: L, W, P0, best, cupA_B, cupA_D, ag, c_r, g). Plain MATLAB graphics, no toolboxes.

zExag = 3;            % ponytail: tilt is only a few cm, so z is drawn 3x. Set 1 for true scale
r = 0.02135;          % golf ball radius
zc = [1.3 5 7 3]/100; % felt surface height at corners A B C D (m above table)
zBoard = @(x, y) zc(1)*(1-x/L).*(1-y/W) + zc(2)*(1-x/L).*(y/W) + zc(3)*(x/L).*(y/W) + zc(4)*(x/L).*(1-y/W);

figure('Color', 'w'); hold on; grid on;
daspect([1 1 1/zExag]); view(-35, 30);
xlabel('x (m), A -> D'); ylabel('y (m), A -> B'); zlabel('z (m)');

% table, felt, board edges
surf([-0.2 L+0.1; -0.2 L+0.1], [-0.2 -0.2; W+0.1 W+0.1], zeros(2), 'FaceColor', [0.93 0.85 0.7], 'EdgeColor', 'none');
[bx, by] = meshgrid([0 L], [0 W]);
surf(bx, by, zBoard(bx, by), 'FaceColor', [0.75 0.75 0.75], 'EdgeColor', 'k');
ex = [0 L L 0 0];  ey = [0 0 W W 0];
for k = 1:4  % side skirts down to the table
    xs = ex(k:k+1);  ys = ey(k:k+1);
    fill3([xs fliplr(xs)], [ys fliplr(ys)], [zBoard(xs, ys) 0 0], [0.6 0.6 0.6]);
end
text(0, 0, zc(1)+0.03, 'A'); text(0, W, zc(2)+0.03, 'B'); text(L, W, zc(3)+0.03, 'C'); text(L, 0, zc(4)+0.03, 'D');

% cups: U shape, opening on the board edge, 6 cm wide, 7.5 cm deep
% ponytail: cup heights eyeballed from the photo (one short, one tall). Rail between them not drawn
cupH = [0.06 0.12];  cups = {cupA_B, cupA_D};  depth = 0.075;  half = 0.03;
t = linspace(-pi/2, pi/2, 20);
for c = 1:2
    out = [-(depth-half)*ones(1,2), -(depth-half) - half*cos(t), -(depth-half)*ones(1,2)];  % outward from edge
    out(1) = 0;  out(end) = 0;
    along = cups{c}(1) + [-half, -half, half*sin(t), half, half];
    if c == 1, cx = out; cy = along; else, cx = along; cy = out; end   % A-B cup sticks out in -x, A-D cup in -y
    surf([cx; cx], [cy; cy], [zeros(size(cx)); cupH(c)*ones(size(cx))], 'FaceColor', [0.15 0.15 0.15], 'FaceAlpha', 0.7, 'EdgeColor', 'none');
end

% launcher marker
plot3(P0(1), P0(2), zBoard(P0(1), P0(2)) + 0.03, 'kv', 'MarkerSize', 10, 'MarkerFaceColor', 'k');

% paths: roll on felt, then fall off the edge into the cup
[sxp, syp, szp] = sphere(16);
ball = surf(r*sxp, r*syp, r*szp, 'FaceColor', [1 0.5 0], 'EdgeColor', 'none');
cols = 'rb';  names = {'cup on A-B edge', 'cup on A-D edge'};
P = cell(1, 2);
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
    plot3(P{c}(:,1), P{c}(:,2), P{c}(:,3), [cols(c) '--'], 'LineWidth', 1.5);
end

for c = 1:2
    title(sprintf('Setup %d: %s  (v = %.2f m/s, angle = %.1f deg, z x%d)', c, names{c}, best(c,1), best(c,2), zExag));
    for i = 1:size(P{c}, 1)                             % 10 ms per frame = real time
        set(ball, 'XData', P{c}(i,1) + r*sxp, 'YData', P{c}(i,2) + r*syp, 'ZData', P{c}(i,3) + r*szp);
        drawnow; pause(0.01);
    end
    pause(1);
end
