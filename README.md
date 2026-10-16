# ball-sim

Ball launcher simulation for the tilted felt board: which ramp drop height and launch
angle from corner D lands the ball in each goal cup at corner A. Plain MATLAB, no
toolboxes, no absolute paths, so the same files run on local MATLAB and on MATLAB Online.

| File | What it does |
| --- | --- |
| `run_sim.m` | Entry point. Adds its folder to the path, `cd`s there, runs `sweep`. Run this. |
| `sweep.m` | Board geometry, launcher, parameter sweep, scoring plot. Calls `board3d` at the end. |
| `simulate.m` | Vectorised rolling-ball integrator (gravity on the tilt + felt drag). |
| `board3d.m` | Animated 3D view of the board, cups and the two best shots. |
| `ramp_slider.m` | Adds two sliders under the 3D board (ramp angle 0-90 deg, drop 2-15 cm); path, ball and IN/MISS redraw live. Called by `board3d`; fresh board with sliders: `close all; board3d`. |
| `gitsync.m` | Optional helper: `gitsync` pulls, `gitsync('message')` commits and pushes. |

## Run it

In the MATLAB Command Window, with any current folder:

```matlab
run('C:\Users\David\Documents\MATLAB\ball-sim\run_sim.m')   % local Windows laptop
run('/MATLAB Drive/ball-sim/run_sim.m')                     % MATLAB Online (after cloning there)
```

Or open the folder in the Current Folder panel and type `run_sim`. Either way the folder
ends up on the MATLAB path, so `gitsync` works afterwards from any folder.
Tunable physics knobs are marked `ponytail:` in `sweep.m` and `board3d.m`.

## Keeping both machines in sync through GitHub

GitHub (`main` branch) is the single source of truth. Each machine has its own clone and
nothing else is shared. The rule on every machine, every time:

1. **Pull before you start**: `gitsync` (or `!git pull` or Source Control > Pull).
2. Work, run `run_sim`.
3. **Commit and push when you stop**: `gitsync('what changed')` (or Source Control > Commit, then Push).

If both machines edited the same lines before pulling, git reports a conflict on pull;
open the file, keep the version you want, then commit and push again.

### Local MATLAB R2026a (Windows laptop)

Clone lives at `C:\Users\David\Documents\MATLAB\ball-sim` (MATLAB's default user folder).
Git for Windows with Git Credential Manager is installed, so `git push` signs in
through the browser the first time and remembers it.

```bash
git clone https://github.com/dpbelisario/ball-sim "C:\Users\David\Documents\MATLAB\ball-sim"
```

### MATLAB Online

One-time clone into MATLAB Drive, either way:

- Current Folder panel: right-click > **Source Control > Manage Files**, source control
  integration **Git**, repository path `https://github.com/dpbelisario/ball-sim`,
  sandbox `/MATLAB Drive/ball-sim`, Retrieve.
- Or in the Command Window: `!git clone https://github.com/dpbelisario/ball-sim`

Pushing from MATLAB Online needs a GitHub **personal access token** (classic, `repo`
scope) as the password when prompted; MATLAB Online remembers it for the session.
`gitsync` works there too when the `git` command is available; otherwise use the
Source Control menu, which does the same thing.

## Repo hygiene

- `.gitattributes` normalises line endings (Windows checkout vs. Linux on MATLAB Online).
- `.gitignore` drops MATLAB autosaves (`*.asv`), generated code and run logs.
