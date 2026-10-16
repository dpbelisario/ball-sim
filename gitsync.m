function gitsync(msg)
% gitsync          Pull the latest ball-sim from GitHub (safe to run before working).
% gitsync('msg')   Commit every local change with message 'msg' and push to GitHub.
%
% Works the same on local MATLAB and MATLAB Online, as long as the environment
% has a git command and GitHub credentials (Git Credential Manager on Windows,
% the Source Control dialog or a personal access token on MATLAB Online).
% If 'git' is missing, use the Current Folder panel's Source Control menu instead.
here = fileparts(mfilename('fullpath'));
old = cd(here);  restore = onCleanup(@() cd(old));
[st, out] = system('git --version');
if st ~= 0
    error('gitsync:nogit', 'git is not available here. Use Current Folder > Source Control.\n%s', out);
end
if nargin == 0
    sh('git pull --rebase --autostash');
    disp('ball-sim is up to date with GitHub.');
else
    sh('git add -A');
    [st, out] = system('git diff --cached --quiet');
    if st == 0
        disp('Nothing to commit.');
    else
        sh(sprintf('git commit -m "%s"', strrep(msg, '"', '''')));
    end
    sh('git pull --rebase --autostash');
    sh('git push');
    disp('Pushed to GitHub.');
end
end

function sh(cmd)
[st, out] = system(cmd);
fprintf('%s', out);
if st ~= 0, error('gitsync:fail', 'Command failed: %s', cmd); end
end
