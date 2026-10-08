#!/bin/bash
# Find the ROS-1 era revision of VNAV-labs, fix rosdep, get a screenshot tool.
source /opt/ros/noetic/setup.bash
cd ~/labs/VNAV-labs

echo "=== branches / tags ==="
git ls-remote --heads origin 2>&1 | head -20
git ls-remote --tags origin 2>&1 | head -20

echo
echo "=== unshallow so history is searchable ==="
git fetch --unshallow origin 2>&1 | tail -3 || git fetch origin 2>&1 | tail -3
echo "commits on main: $(git rev-list --count HEAD)"

echo
echo "=== when did lab2/two_drones_pkg/launch change, and to what ==="
git log --oneline --follow --name-status -- lab2/two_drones_pkg/launch 2>/dev/null | head -30
echo
echo "--- last commit where the ROS1 XML launch existed ---"
git log --oneline --all --diff-filter=D --name-only -- 'lab2/two_drones_pkg/launch/two_drones.launch' | head -10
echo
echo "=== does main's package.xml use ament or catkin? ==="
grep -E "<buildtool_depend>|<format>|<export>" lab2/two_drones_pkg/package.xml | head -10
echo
echo "=== search all history for a tree containing the XML launch ==="
for c in $(git rev-list --all -- lab2/two_drones_pkg | head -60); do
  if git cat-file -e "$c:lab2/two_drones_pkg/launch/two_drones.launch" 2>/dev/null; then
    echo "FOUND_ROS1_LAUNCH $c $(git log -1 --format=%ci $c)"
  fi
done | head -10

echo
echo "=== rosdep: official init then host-substitution ==="
sudo rm -f /etc/ros/rosdep/sources.list.d/20-default.list
sudo rosdep init 2>&1 | tail -2
echo "--- generated file, before ---"
head -8 /etc/ros/rosdep/sources.list.d/20-default.list
sudo sed -i 's#https://raw.githubusercontent.com/ros/rosdistro/master#https://mirrors.tuna.tsinghua.edu.cn/rosdistro#g' \
  /etc/ros/rosdep/sources.list.d/20-default.list
echo "--- generated file, after host substitution ---"
cat /etc/ros/rosdep/sources.list.d/20-default.list
timeout 240 env ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml \
  rosdep update 2>&1 | tail -8

echo
echo "=== screenshot tool, with errors visible ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y scrot 2>&1 | tail -8
command -v scrot && scrot --version 2>&1 | head -2
