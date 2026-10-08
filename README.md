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

`lab2/src/` holds two ROS nodes (`frames_publisher_node`, `plots_publisher_node`);
`lab2/scripts/` holds the preflight, install and evidence-collection scripts used to verify
topic publication, TF frames and RViz behaviour on the real system rather than by inspection.
The scripts are idempotent and safe to read as documentation of what was actually checked.

---

## Not included

Written lab reports are kept out of this repository because they carry name and student
email in their title blocks. Build inputs downloaded from third parties (`dante.txt`) and
upstream clones that own their own history (`vnav-codes/`) are excluded by `.gitignore`.
