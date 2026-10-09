function [hit, exitPt, path] = simulate(P0, v, thDeg, ag, c_r, L, W)
% Vectorised over all launches. path = positions of launch #1 (for plotting). hit: 0 = stopped/left elsewhere, 1 = off x=0 edge, 2 = off y=0 edge.
n = numel(v);  dt = 1e-3;
th = thDeg(:) * pi/180;
p = repmat(P0, n, 1);
u = [-v(:).*cos(th), v(:).*sin(th)];   % angle 0 = straight along D->A (-x), + = into board (+y)
live = true(n, 1);  path = P0;  hit = zeros(n, 1);  exitPt = nan(n, 2);
for step = 1:20000                        % 20 s max
    u(live,:) = u(live,:) + ag*dt;
    s = sqrt(sum(u.^2, 2));
    k = max(0, s - c_r*dt) ./ max(s, eps); % drag shrinks speed, never reverses it -> ball can stop and stay
    u = u .* k;
    p(live,:) = p(live,:) + u(live,:)*dt;
    if live(1) && nargout > 2 && mod(step, 10) == 0, path(end+1,:) = p(1,:); end
    offA_B = live & p(:,1) < 0;  offA_D = live & p(:,2) < 0 & ~offA_B;
    hit(offA_B) = 1;  hit(offA_D) = 2;
    gone = offA_B | offA_D | (live & (p(:,1) > L | p(:,2) > W)) | (live & all(u == 0, 2));
    exitPt(gone,:) = p(gone,:);
    live(gone) = false;
    if ~any(live), break; end
end
exitPt(live,:) = p(live,:);
end
