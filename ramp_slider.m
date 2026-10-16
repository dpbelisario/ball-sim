function ramp_slider(f, S)
% ramp_slider(f, S) — adds controls to the 3D board figure f (made by board3d):
%   sliders: ramp angle 0-90 deg, ramp drop 2-15 cm -> path, ball and IN/MISS title redraw on every move
%   buttons: Play (animate current shot), Stop, Best A-B / Best A-D (jump to the sweep's best setting and play)
% Moving a slider or pressing any button stops a running animation. Fresh board: close all; board3d
% ramp_slider — 3D表示に操作パネルを追加：スライダー（角度・落差）、再生／停止／最適設定ボタン。

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

h.fig = f;
btn = @(x, str, fn) uicontrol(f, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [x 0.195 0.22 0.055], ...
                               'String', str, 'Callback', fn);
btn(0.02, 'Play / 再生',          @(~, ~) play(h, S, zB));
btn(0.26, 'Stop / 停止',          @(~, ~) bump(f));
btn(0.50, 'Best A-B / 最適 A-B',  @(~, ~) gobest(h, S, zB, 1));
btn(0.74, 'Best A-D / 最適 A-D',  @(~, ~) gobest(h, S, zB, 2));

cb = @(~, ~) redraw(h, S, zB);
set([h.ang h.drop], 'Callback', cb);
try   % live update while dragging (MATLAB); Octave just updates on release
    addlistener(h.ang,  'ContinuousValueChange', cb);
    addlistener(h.drop, 'ContinuousValueChange', cb);
end
redraw(h, S, zB);
end

function id = bump(f)   % new run id: any animation still looping sees the change and stops
id = getappdata(f, 'run');  if isempty(id), id = 0; end
id = id + 1;  setappdata(f, 'run', id);
end

function gobest(h, S, zB, c)
if S.best(c, 3) == 0, return; end   % no scoring drop found for that cup at th_aim
set(h.ang, 'Value', S.best(c, 2));  set(h.drop, 'Value', 100*S.best(c, 3));
play(h, S, zB);
end

function play(h, S, zB)
[p, z] = redraw(h, S, zB);
if isempty(h.ball), return; end
n = size(p, 1);
k = [1:5:n, n];                                   % every 5th point = 50 ms frames, real time
fall = linspace(z(end), S.r, 6)';                 % ball drops to the table if it left the board
id = bump(h.fig);
for i = [k, -(1:numel(fall))]
    if ~ishandle(h.fig) || getappdata(h.fig, 'run') ~= id, return; end   % stopped, slider moved, or closed
    if i > 0, x = p(i,1); y = p(i,2); zz = z(i); else, x = p(n,1); y = p(n,2); zz = fall(-i); end
    set(h.ball, 'XData', x + S.r*h.sx, 'YData', -y + S.r*h.sy, 'ZData', zz + S.r*h.sz/S.zExag);
    drawnow; pause(0.05);
end
end

function z = bilin(zc, u, w)   % felt height from corner heights A B C D, u along A->D, w along A->B
z = zc(1)*(1-u).*(1-w) + zc(2)*(1-u).*w + zc(3)*u.*w + zc(4)*u.*(1-w);
end

function [p, z] = redraw(h, S, zB)
bump(h.fig);                                      % stop any running animation
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
