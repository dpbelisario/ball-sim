function ramp_slider(f, S)
% ramp_slider(f, S) — adds controls to the 3D board figure f (made by board3d). The ramp is fixed
% (exit speed S.v0); only the angle changes:
%   slider: ramp angle 0-90 deg (arrows = 0.1 deg, track click = 1 deg) -> path, ball, IN/MISS redraw live
%   buttons: Play (animate current shot), Stop, Aim A-B / Aim A-D (jump to the middle of that cup's widest window)
%   the scoring angle windows for both cups are listed under the slider
% Moving the slider or pressing any button stops a running animation. Fresh board: close all; board3d
% ramp_slider — 3D表示に操作パネル：角度スライダー（0～90°）、再生／停止／狙いボタン、成功角度範囲の表示。

ax = findobj(f, 'Type', 'axes');  ax = ax(1);
zB = @(x, y) bilin(S.zc, min(max(x, 0), S.L)/S.L, min(max(y, 0), S.W)/S.W);
[h.sx, h.sy, h.sz] = sphere(16);
h.path  = plot3(ax, NaN, NaN, NaN, '-', 'LineWidth', 3, 'Color', [1 0.5 0]);
h.aim   = plot3(ax, NaN, NaN, NaN, 'b-', 'LineWidth', 4);
h.ball  = findobj(f, 'Tag', 'ball');
h.title = get(ax, 'Title');
h.fig   = f;

uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.02 0.115 0.20 0.05], 'BackgroundColor', 'w', ...
          'String', 'Angle / 角度', 'FontWeight', 'bold');
h.ang = uicontrol(f, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.22 0.12 0.62 0.045], ...
                  'Min', 0, 'Max', 90, 'Value', 45, 'SliderStep', [0.1 1]/90);
h.val = uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.85 0.115 0.13 0.05], 'BackgroundColor', 'w', ...
                  'FontWeight', 'bold', 'FontSize', 12, 'String', '');
uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.02 0.005 0.96 0.10], 'BackgroundColor', 'w', ...
          'HorizontalAlignment', 'left', 'String', windowText(S));

btn = @(x, str, fn) uicontrol(f, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [x 0.185 0.22 0.055], ...
                               'String', str, 'Callback', fn);
btn(0.02, 'Play / 再生',          @(~, ~) play(h, S, zB));
btn(0.26, 'Stop / 停止',          @(~, ~) bump(f));
btn(0.50, 'Aim A-B / 狙い A-B',   @(~, ~) goaim(h, S, zB, 1));
btn(0.74, 'Aim A-D / 狙い A-D',   @(~, ~) goaim(h, S, zB, 2));

cb = @(~, ~) redraw(h, S, zB);
set(h.ang, 'Callback', cb);
try   % live update while dragging (MATLAB); Octave just updates on release
    addlistener(h.ang, 'ContinuousValueChange', cb);
end
if ~isnan(S.best(2, 2)), set(h.ang, 'Value', S.best(2, 2)); end   % start on a scoring shot if there is one
redraw(h, S, zB);
end

function s = windowText(S)   % "A-B cup: 21.1-24.9°, ...  |  A-D cup: ..." in both languages
part = cell(1, 2);
for c = 1:2
    w = S.win{c};
    if isempty(w), part{c} = 'none from here / ここからは入らない'; continue; end
    part{c} = strjoin(arrayfun(@(j) sprintf('%.1f–%.1f°', w(j,1), w(j,2)), 1:size(w, 1), 'UniformOutput', false), ',  ');
end
s = {sprintf('Scores / 成功範囲   A-B cup / A-Bカップ: %s', part{1}), ...
     sprintf('                    A-D cup / A-Dカップ: %s', part{2}), ...
     sprintf('Exit speed / 出口速度 %.2f m/s  (fixed ramp / ランプ固定)', S.v0)};
end

function id = bump(f)   % new run id: any animation still looping sees the change and stops
id = getappdata(f, 'run');  if isempty(id), id = 0; end
id = id + 1;  setappdata(f, 'run', id);
end

function goaim(h, S, zB, c)
if isnan(S.best(c, 2)), return; end   % no scoring angle for that cup from here
set(h.ang, 'Value', S.best(c, 2));
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
th = round(get(h.ang, 'Value') * 10) / 10;        % 0.1 deg steps
set(h.val, 'String', sprintf('%.1f°', th));
[hit, e, p] = simulate(S.P0, S.v0, th, S.ag, S.c_r, S.L, S.W);
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
    edgeName = {'A-B', 'A-D'};
    along = e(3 - hit);                           % position along the edge it crossed, measured from A
    res = sprintf('MISS: off the %s edge %.0f cm from A (cup = 12-18 cm) / 失敗：%s辺、Aから %.0f cm で落下', ...
                  edgeName{hit}, 100*along, edgeName{hit}, 100*along);  col = [0.4 0.4 0.4];
end
set(h.title, 'String', {sprintf('Angle / 角度 %.1f°   (exit speed / 出口速度 %.2f m/s)', th, S.v0), res}, 'Color', col);
end
