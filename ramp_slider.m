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
h.chute = fill3(ax, NaN(4,1), NaN(4,1), NaN(4,1), [0.15 0.3 0.85]);   % the turning chute, redrawn at each angle
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

btn = @(x, w, str, fn) uicontrol(f, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [x 0.185 w 0.055], ...
                                  'String', str, 'Callback', fn);
btn(0.02, 0.15, 'Play / 再生',          @(~, ~) play(h, S, zB));
btn(0.18, 0.15, 'Stop / 停止',          @(~, ~) bump(f));
btn(0.34, 0.19, 'Aim A-B / 狙い A-B',   @(~, ~) goaim(h, S, zB, 1));
btn(0.54, 0.19, 'Aim A-D / 狙い A-D',   @(~, ~) goaim(h, S, zB, 2));
btn(0.75, 0.11, '⟲ 15°',               @(~, ~) spin(ax, -15));     % turn the table counterclockwise (seen from above)
btn(0.87, 0.11, '⟳ 15°',               @(~, ~) spin(ax, +15));     % clockwise

% rotation: flat on the table only. Freeze axes size/limits so nothing rescales or jumps while turning,
% and if the mouse rotate tool is used, snap the tilt back so it only turns around the vertical axis.
axis(ax, 'vis3d');
set(ax, 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual');
[~, h.el] = view(ax);
try
    r3 = rotate3d(f);
    set(r3, 'ActionPostCallback', @(~, ev) view(ev.Axes, getaz(ev.Axes), h.el));
end

cb = @(~, ~) redraw(h, S, zB);
set(h.ang, 'Callback', cb);
try   % live update while dragging (MATLAB); Octave just updates on release
    addlistener(h.ang, 'ContinuousValueChange', cb);
end
set(h.ang, 'Value', S.th_design);   % open at the design's angle (STL peg position)
redraw(h, S, zB);
end

function spin(ax, d)   % turn the view around the vertical axis only, keep the tilt
[az, el] = view(ax);
view(ax, az + d, el);
end

function az = getaz(ax)
[az, ~] = view(ax);
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
[hit, e, p] = simulate(S.P0at(th), S.v0, th, S.ag, S.c_r, S.L, S.W);
z = zB(p(:,1), p(:,2)) + S.r;                     % drawn mirrored (-y), same as board3d
set(h.path, 'XData', p(:,1), 'YData', -p(:,2), 'ZData', z);
d = [-cosd(th), sind(th)];  nrm = [d(2), -d(1)] * 0.03;   % chute axis and half-width (4 cm gap + rails)
c4 = [S.pivot + S.r_back*d + nrm; S.pivot + S.r_exit*d + nrm; S.pivot + S.r_exit*d - nrm; S.pivot + S.r_back*d - nrm];
zc4 = zB(c4(:,1), c4(:,2)) + [S.h_base(1) + 0.022; 0.004; 0.004; S.h_base(1) + 0.022];   % ~5 cm high at the back, on the felt at the tip
set(h.chute, 'XData', c4(:,1), 'YData', -c4(:,2), 'ZData', zc4);
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
    cup = {S.cupA_B, S.cupA_D};  cr = 100*(cup{hit}(1) + [-1 1]*cup{hit}(2)/2);
    res = sprintf('MISS: off the %s edge %.0f cm from A (cup = %.1f-%.1f cm) / 失敗：%s辺、Aから %.0f cm で落下', ...
                  edgeName{hit}, 100*along, cr(1), cr(2), edgeName{hit}, 100*along);  col = [0.4 0.4 0.4];
end
set(h.title, 'String', {sprintf('Angle / 角度 %.1f°   (exit speed / 出口速度 %.2f m/s)', th, S.v0), res}, 'Color', col);
end
