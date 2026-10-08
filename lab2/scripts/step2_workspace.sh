#!/bin/bash
# LAB2 step 2: repair rosdep, clone the lab code, build the catkin workspace.
source /opt/ros/noetic/setup.bash

echo "########## $(date -Is) step2 start ##########"

echo "=== 1. rosdep sources list, single-line URLs ==="
echo "previous attempt failed with: 'invalid sources list file ... type must be one of [yaml,gbpdistro]'"
sudo tee /etc/ros/rosdep/sources.list.d/20-default.list >/dev/null <<'LIST'
# local override pointing at the Tsinghua rosdistro mirror
rosdistro: 'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml'
base:
  ros: ['https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/base.yaml',
        'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/python.yaml',
        'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/ruby.yaml']
LIST
cat /etc/ros/rosdep/sources.list.d/20-default.list
timeout 240 rosdep update 2>&1 | tail -10
echo "rosdep update rc=$?"

echo
echo "=== 2. clone the lab repository ==="
mkdir -p ~/labs && cd ~/labs
if [ -d VNAV-labs/.git ]; then
  echo "already cloned; refreshing"
  git -C VNAV-labs fetch --all -q && git -C VNAV-labs checkout -q main && git -C VNAV-labs pull -q --ff-only
else
  git clone --depth 1 https://github.com/MIT-SPARK/VNAV-labs.git 2>&1 | tail -3
fi
echo "HEAD=$(git -C VNAV-labs rev-parse HEAD)"
echo "branch=$(git -C VNAV-labs rev-parse --abbrev-ref HEAD)"
ls VNAV-labs
echo "--- lab2 tree ---"
find VNAV-labs/lab2 -maxdepth 3 -type f | sort | head -40

echo
echo "=== 3. catkin workspace ==="
mkdir -p ~/vnav_ws/src
cd ~/vnav_ws
catkin init 2>&1 | tail -20
cp -a ~/labs/VNAV-labs/lab2/two_drones_pkg ~/vnav_ws/src/ 2>&1 || \
  cp -a ~/labs/VNAV-labs/lab2/ROS/two_drones_pkg ~/vnav_ws/src/
echo "--- src tree ---"
find ~/vnav_ws/src -maxdepth 3 | sort | head -30

echo
echo "=== 4. build ==="
catkin build 2>&1 | tail -25
echo "catkin build rc=${PIPESTATUS[0]}"
ls -l ~/vnav_ws/devel/lib/two_drones_pkg/ 2>/dev/null

echo
echo "=== 5. display / screenshot tooling for the RViz evidence ==="
echo "DISPLAY=$DISPLAY WAYLAND=$WAYLAND_DISPLAY"
ls -d /mnt/wslg >/dev/null 2>&1 && echo "wslg ok"
for t in scrot import xwd convert gnome-screenshot; do
  printf "  %-16s %s\n" "$t" "$(command -v $t || echo '-')"
done
timeout 12 xdpyinfo -display :0 2>&1 | head -4 || echo "xdpyinfo missing"

echo "########## $(date -Is) step2 done ##########"
