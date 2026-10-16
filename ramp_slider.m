function ramp_slider()
% ramp_slider — interactive top-down board: drag sliders to turn the ramp (0-90 deg) and change its drop.
% The path, and whether it scores, redraws on every move. Opened at the end of sweep.m.
% Uses the board/physics values sweep.m left in the base workspace as S.
% ramp_slider — スライダーでランプの向き（0～90°）と落差を変えると、軌道と成功判定が更新される。

try
    S = evalin('base', 'S');
catch
    error('Run run_sim first (it sets up the board). / 先に run_sim を実行してください。');
end

f = figure('Color', 'w', 'Name', 'Ramp slider / ランプ角度スライダー', 'NumberTitle', 'off');
try, theme(f, 'light'); end
ax = axes('Parent', f, 'Position', [0.10 0.30 0.86 0.56]);
hold(ax, 'on'); axis(ax, 'equal'); grid(ax, 'on');
set(ax, 'YDir', 'reverse');                 % top-down, like the table photo: A top-left, D top-right
xlim(ax, [-0.12 S.L + 0.08]); ylim(ax, [-0.12 S.W + 0.08]);
xlabel(ax, {'x (m), A -> D', 'x (m)、A→D'}); ylabel(ax, {'y (m), A -> B', 'y (m)、A→B'});

fill([0 S.L S.L 0], [0 0 S.W S.W], [0.82 0.82 0.82], 'Parent', ax, 'EdgeColor', 'k');
rectangle('Parent', ax, 'Position', [-0.075, S.cupA_B(1) - S.cupA_B(2)/2, 0.075, S.cupA_B(2)], 'FaceColor', [0.9 0.3 0.3]);
rectangle('Parent', ax, 'Position', [S.cupA_D(1) - S.cupA_D(2)/2, -0.075, S.cupA_D(2), 0.075], 'FaceColor', [0.3 0.3 0.9]);
lbl = {'A', 'B', 'C', 'D'};  cx = [0 0 S.L S.L];  cy = [0 S.W S.W 0];
for k = 1:4
    text(cx(k) + 0.04*sign(cx(k) - S.L/2), cy(k) + 0.04*sign(cy(k) - S.W/2), lbl{k}, 'Parent', ax, ...
         'FontWeight', 'bold', 'FontSize', 16, 'BackgroundColor', [1 1 0.75], 'EdgeColor', 'k', 'HorizontalAlignment', 'center');
end
plot(ax, S.P0(1), S.P0(2), 'bs', 'MarkerSize', 12, 'MarkerFaceColor', 'b');

h.path  = plot(ax, NaN, NaN, '-', 'LineWidth', 2.5, 'Color', [1 0.5 0]);
h.end   = plot(ax, NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [1 0.5 0], 'MarkerEdgeColor', 'k');
h.aim   = plot(ax, NaN, NaN, 'b-', 'LineWidth', 3);
h.title = title(ax, '');

uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.05 0.13 0.30 0.06], 'BackgroundColor', 'w', ...
          'String', 'Angle / 角度: 0 = toward A, 90 = into board');
uicontrol(f, 'Style', 'text', 'Units', 'normalized', 'Position', [0.05 0.03 0.30 0.06], 'BackgroundColor', 'w', ...
          'String', 'Ramp drop / ランプ落差 (cm)');
h.ang  = uicontrol(f, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.36 0.14 0.58 0.05], ...
                   'Min', 0, 'Max', 90, 'Value', 45, 'SliderStep', [1 5]/90);
h.drop = uicontrol(f, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.36 0.04 0.58 0.05], ...
                   'Min', 2, 'Max', 15, 'Value', 6, 'SliderStep', [0.1 1]/13);

cb = @(~, ~) redraw(h, S);
set([h.ang h.drop], 'Callback', cb);
try   % live update while dragging (MATLAB); Octave just updates on release
    addlistener(h.ang,  'ContinuousValueChange', cb);
    addlistener(h.drop, 'ContinuousValueChange', cb);
end
redraw(h, S);
end

function redraw(h, S)
th = round(get(h.ang, 'Value') * 2) / 2;          % 0.5 deg steps
hd = round(get(h.drop, 'Value') * 10) / 10;       % 1 mm steps
v = S.eta * sqrt(10/7 * S.g * hd/100);
[hit, e, p] = simulate(S.P0, v, th, S.ag, S.c_r, S.L, S.W);
set(h.path, 'XData', p(:,1), 'YData', p(:,2));
set(h.end, 'XData', e(1), 'YData', e(2));
u = 0.12 * [-cosd(th), sind(th)];                 % ramp direction arrow
set(h.aim, 'XData', S.P0(1) + [0 u(1)], 'YData', S.P0(2) + [0 u(2)]);
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
set(h.title, 'String', {sprintf('angle / 角度 %.1f°   drop / 落差 %.1f cm   (v = %.2f m/s)', th, hd, v), res}, 'Color', col);
end
