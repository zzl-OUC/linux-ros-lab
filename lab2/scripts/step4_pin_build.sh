#!/bin/bash
# step 4: pin the 2023 (ROS 1) revision, repair rosdep from the real upstream file,
# build two_drones_pkg, and copy the stencil sources out for review.
source /opt/ros/noetic/setup.bash

echo "=== 1. rosdep sources list, fetched verbatim from upstream then host-substituted ==="
python3 -c 'import json,base64,urllib.request
u="https://api.github.com/repos/ros/rosdistro/contents/rosdep/sources.list.d/20-default.list"
d=json.load(urllib.request.urlopen(u,timeout=40))
open("/tmp/20-default.list","wb").write(base64.b64decode(d["content"]))'
echo "--- upstream original ---"
cat /tmp/20-default.list
sudo mkdir -p /etc/ros/rosdep/sources.list.d
sed 's#https://raw.githubusercontent.com/ros/rosdistro/master#https://mirrors.tuna.tsinghua.edu.cn/rosdistro#g' \
  /tmp/20-default.list | sudo tee /etc/ros/rosdep/sources.list.d/20-default.list >/dev/null
echo "--- installed (hosts rewritten to the Tsinghua mirror) ---"
cat /etc/ros/rosdep/sources.list.d/20-default.list
echo "--- rosdep update ---"
timeout 300 env ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml \
  rosdep update 2>&1 | tail -10
echo "rosdep rc above; keys cache:"; ls ~/.ros/rosdep/sources.cache 2>/dev/null | wc -l

echo
echo "=== 2. pin the 2023 ROS-1 revision ==="
cd ~/labs/VNAV-labs
git checkout -q 609f31fec484daafef6207ce283d23b424a2072f
echo "HEAD=$(git rev-parse HEAD)  date=$(git log -1 --format=%ci)"
echo "--- lab2 tree at this revision ---"
find lab2 -type f | sort

echo
echo "=== 3. is it really a catkin package? ==="
grep -E "<format>|buildtool_depend|<name>" lab2/two_drones_pkg/package.xml
echo "--- launch file head ---"
head -12 lab2/two_drones_pkg/launch/two_drones.launch

echo
echo "=== 4. rebuild the workspace with this revision ==="
rm -rf ~/vnav_ws/src/two_drones_pkg
cp -a ~/labs/VNAV-labs/lab2/two_drones_pkg ~/vnav_ws/src/
cd ~/vnav_ws
catkin clean -y > /tmp/catkin_clean.log 2>&1; tail -3 /tmp/catkin_clean.log
catkin init > /dev/null 2>&1
catkin build 2>&1 | tr -d '\r' | grep -vE "^\[build [0-9]" | tail -20
echo "--- built executables ---"
ls -l ~/vnav_ws/devel/lib/two_drones_pkg/ 2>&1

echo
echo "=== 5. copy stencil sources out for review ==="
mkdir -p /mnt/c/Users/13907/lab2/src_snapshot
cp -a ~/labs/VNAV-labs/lab2/two_drones_pkg/. /mnt/c/Users/13907/lab2/src_snapshot/
find /mnt/c/Users/13907/lab2/src_snapshot -type f | sed 's#.*/src_snapshot/##' | sort
echo "########## step4 done ##########"
