# Linux & ROS Lab Course

Coursework from an undergraduate robotics-vision lab course (`ouc-vlab-course`), based on the
MIT SPARK VNAV lab sequence. Layout: `lab1/` is the Linux / C++ / Git environment setup,
`lab2/` is ROS.

**Environment** — everything here was written and verified on:

| | |
|---|---|
| OS | Ubuntu 20.04.6 LTS (WSL2) |
| Compiler | g++ 9.4.0, `-std=c++11 -Wall -pedantic` |
| Build | CMake 3.16.3 |
| VCS | git 2.25.1 |

## Layout

```
linux-ros-lab/
├── lab1/                 # Linux, C++ and Git environment setup
│   ├── shell/            #   wc counting conventions + fortune redirection answers
│   ├── cppwarmup/        #   the ten warm-up questions, as runnable programs
│   ├── lab1_demo/        #   minimal CMake project (lib + executable)
│   └── RandomVector/     #   the 40-point class exercise
└── lab2/                 # ROS
    ├── src/              #   two publisher nodes
    └── scripts/          #   install, preflight and evidence scripts
```

---

## Lab 1 — Environment setup: Linux, C++, Git

### `lab1/shell/`
Answers to the shell exercises against the *Divine Comedy* corpus.

```bash
wget https://raw.githubusercontent.com/dlang/dmd/master/druntime/benchmark/extra-files/dante.txt
wc -l dante.txt          # lines
wc -w dante.txt          # words
grep -c '[^[:space:]]' dante.txt   # non-blank lines
```

`exercise1.txt` records all three counts. The point of the exercise is that "how many lines"
is not a well-posed question until the counting convention is stated — `wc -l` counts
newlines, so a file with no trailing newline under-reports by one.

`fortunes.txt` is the `fortune-mod` redirection exercise: six quotations accumulated into one
file. This only works with `>>`; `>` truncates on every invocation, which fails silently
because both commands exit 0.

### `lab1/cppwarmup/`
The ten warm-up questions (operators, references, pointers, integer and floating-point
widths, signedness, truthiness), each as a standalone compilable program rather than a
hand-derived answer — every answer here was read off the machine.

```bash
for f in lab1/cppwarmup/*.cpp; do
  g++ -std=c++11 -Wall -pedantic -o "${f%.cpp}" "$f"
done
```

### `lab1/lab1_demo/`
Minimal CMake project demonstrating separate compilation and linking: `my_lib.hpp` declares,
`my_lib.cpp` defines, `main.cpp` consumes, and `target_link_libraries` binds them.

```bash
cd lab1/lab1_demo
mkdir build && cd build
cmake .. && make
./main        # -> "Hello world!" / "In library"
```

### `lab1/RandomVector/`
A class wrapping `std::vector<double>`: constructor seeding `[0, max_val]`, plus `mean()`,
`max()`, `min()`, `print()` and `printHistogram(int bins)`. Implemented without
`<algorithm>`, per the lab's constraint.

```bash
cd lab1/RandomVector
g++ -std=c++11 -Wall -pedantic -o random_vector main.cpp random_vector.cpp
./random_vector
```

## Lab 2 — ROS

`lab2/src/` holds the two ROS nodes that implement the lab's moving scene. `lab2/scripts/` holds
the installer, the preflight probe, and the evidence legs that checked the result on a live ROS
graph rather than by reading the code:

| script | what it establishes |
|---|---|
| `install_ros.sh`, `preflight.sh` | ROS Noetic is installed and the toolchain is present |
| `evid_A_parttwo.sh`, `evid_A2_teleop.sh` | Part Two: `roscore`, turtlesim teleop, `rqt_graph`, `rosnode`/`rostopic`, `turtle_tf`, `rqt_tf_tree` |
| `evid_B_part3_stencil.sh` | the unmodified upstream package builds and runs — the positive control for the legs below |
| `evid_C_part3_impl.sh` | these two nodes build, and RViz draws all three trails in both fixed frames |
| `evid_D_verify.sh` | the geometry is numerically correct, not merely plausible on screen |
| `recheck_repo_copy.sh` | a re-run using this repository's own copies of the two sources |
| `demo_lab2.sh` / `demo_lab2_stop.sh` | one-shot live demo: moving scene plus RViz in `world` and in `av1` |

The load-bearing one is `verify_trajectories.py`. It samples `/tf` at 50 Hz while the scene runs,
recomputes `o2_1 = Rᵀ(o2_w − o1_w)` from the broadcast quaternion, and checks that against what
tf reports — then does the same for the three `/visuals` marker trails. Max absolute residual,
reproduced 2026-10-10 over 489 samples:

| claim | residual |
|---|---|
| `o1_w` stays on the unit circle | 1.1e-16 |
| `o2_w` satisfies `z = 1 − 2x²` with `y ≡ 0` (the parabola arc) | 3.3e-16 |
| `o2_1` stays in the plane `z₁ = 2y₁ + 1` | 6.7e-16 |
| `o2_1` stays on the cylinder `(x₁+1)² + (y₁+½)² = ¼` | 3.9e-16 |
| tf's `o2_1` vs the hand-computed one | 6.7e-16 |

Plane ∩ cylinder is the ellipse the lab asks you to find, and its semi-axes come out of the same
receipt as the in-plane distance from `(−1, −½, 0)`: 0.50000 and 1.11803, against the expected
½ and √5/2 = 1.118034.

Nothing here hard-codes the machine it was written on — the scratch locations are environment
variables:

| var | meaning | default |
|---|---|---|
| `LAB2_ROOT` | scratch dir for `shots/` and `logs/` | `~/lab2` |
| `VNAV_WS` | the catkin workspace | `~/vnav_ws` |
| `PKG` | the ROS package under test | `$VNAV_WS/src/two_drones_pkg` |
| `SRC_DIR` | sources installed into `$PKG/src` by `evid_C_part3_impl.sh` | this repo's `lab2/src` |

```bash
LAB2_ROOT=/tmp/lab2 bash lab2/scripts/evid_C_part3_impl.sh
```

The shipped nodes are the ones `recheck_repo_copy.sh` rebuilt and re-verified on 2026-10-10. No
screenshots are included, so nothing here asks you to trust a picture taken of a different build.

---

## Not included

Written lab reports are kept out of this repository because they carry name and student
email in their title blocks. Build inputs downloaded from third parties (`dante.txt`) and
upstream clones that own their own history (`vnav-codes/`) are excluded by `.gitignore`.

Also excluded is the scaffolding the lab hands out, which belongs to upstream:
`launch/two_drones.launch`, `package.xml`, `CMakeLists.txt` and the `mesh/quadrotor.dae` model.
Clone [MIT-SPARK/VNAV-labs](https://github.com/MIT-SPARK/VNAV-labs) and drop `two_drones_pkg`
into `$VNAV_WS/src` before running the evidence legs — they assume a package that already builds.
The two RViz configs the legs reference (`lab2_world.rviz`, `lab2_av1.rviz`) are local copies of
upstream `default.rviz` that differ only in Fixed Frame (`world` vs `av1`) plus enabled `TF` and
`MarkerArray` displays.
