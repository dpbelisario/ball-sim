function ramp_slider(f, S)
% ramp_slider(f, S) — adds two sliders to the 3D board figure f (made by board3d):
% ramp angle 0-90 deg and ramp drop 2-15 cm. The orange path, the ball and the IN/MISS title
% redraw on every move. To get a fresh board with sliders: close all; board3d
% ramp_slider — 3D表示にスライダーを追加：ランプ角度（0～90°）と落差。動かすたびに軌道・ボール・判定が更新される。

ax = findobj(f, 'Type', 'axes');  ax = ax(1);
zB = @(x, y) bilin(S.zc, min(max(x, 0), S.L)/S.L, min(max(y, 0), S.W)/S.W);
[h.sx, h.sy, h.sz] = sphere(16);
h.path  = plot3(ax, NaN, NaN, NaN, '-', 'LineWidth', 3, 'Color', [1 0.5 0]);
h.aim   = plot3(ax, NaN, NaN, NaN, 'b-', 'LineWidth', 4);
h.ball  = findobj(f, 'Tag', 'ball');
h.title = get(ax, 'Title');

uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.02 0.12 0.32 0.06], 'BackgroundColor', 'w', ...
          'String', 'Angle / 角度 (0 = toward A, 90 = into board)');
uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.02 0.03 0.32 0.06], 'BackgroundColor', 'w', ...
          'String', 'Ramp drop / ランプ落差 (cm)');
h.ang  = uicontrol(f, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.36 0.13 0.60 0.05], ...
                   'Min', 0, 'Max', 90, 'Value', 45, 'SliderStep', [1 5]/90);
h.drop = uicontrol(f, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.36 0.04 0.60 0.05], ...
                   'Min', 2, 'Max', 15, 'Value', 6, 'SliderStep', [0.1 1]/13);

cb = @(~, ~) redraw(h, S, zB);
set([h.ang h.drop], 'Callback', cb);
try   % live update while dragging (MATLAB); Octave just updates on release
    addlistener(h.ang,  'ContinuousValueChange', cb);
    addlistener(h.drop, 'ContinuousValueChange', cb);
end
redraw(h, S, zB);
end

function z = bilin(zc, u, w)   % felt height from corner heights A B C D, u along A->D, w along A->B
z = zc(1)*(1-u).*(1-w) + zc(2)*(1-u).*w + zc(3)*u.*w + zc(4)*u.*(1-w);
end

function redraw(h, S, zB)
th = round(get(h.ang, 'Value') * 2) / 2;          % 0.5 deg steps
hd = round(get(h.drop, 'Value') * 10) / 10;       % 1 mm steps
v = S.eta * sqrt(10/7 * S.g * hd/100);
[hit, e, p] = simulate(S.P0, v, th, S.ag, S.c_r, S.L, S.W);
z = zB(p(:,1), p(:,2)) + S.r;                     % drawn mirrored (-y), same as board3d
set(h.path, 'XData', p(:,1), 'YData', -p(:,2), 'ZData', z);
u = 0.12 * [-cosd(th), sind(th)];                 % ramp direction
set(h.aim, 'XData', S.P0(1) + [0 u(1)], 'YData', -(S.P0(2) + [0 u(2)]), 'ZData', zB(S.P0(1), S.P0(2)) + 0.01 + [0 0]);
if ~isempty(h.ball)
    set(h.ball, 'XData', e(1) + S.r*h.sx, 'YData', -e(2) + S.r*h.sy, 'ZData', z(end) + S.r*h.sz/S.zExag);
end
if hit == 1 && abs(e(2) - S.cupA_B(1)) <= S.cupA_B(2)/2
    res = 'IN: cup on A-B edge / 成功：A-B辺のカップ';  col = [0.75 0 0];
elseif hit == 2 && abs(e(1) - S.cupA_D(1)) <= S.cupA_D(2)/2
    res = 'IN: cup on A-D edge / 成功：A-D辺のカップ';  col = [0 0 0.75];
elseif hit == 0
    res = 'MISS: stopped, or left by the far side / 失敗：停止、または反対側から落下';  col = [0.4 0.4 0.4];
else
    along = e(3 - hit);                           % position along the edge it crossed, measured from A
    res = sprintf('MISS: off the edge %.0f cm from A / 失敗：Aから %.0f cm の位置で落下', 100*along, 100*along);  col = [0.4 0.4 0.4];
end
set(h.title, 'String', {sprintf('Slider / スライダー: angle / 角度 %.1f°, drop / 落差 %.1f cm (v = %.2f m/s)', th, hd, v), res}, 'Color', col);
end
