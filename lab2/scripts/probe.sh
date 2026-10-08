#!/bin/bash
# LAB2 feasibility probe. Read-only: prints facts, installs nothing.
{
echo "=== whoami / distro ==="
echo "user=$(whoami) home=$HOME"
cat /etc/os-release | grep PRETTY
echo "kernel=$(uname -r)"

echo "=== disk ==="
df -h / | tail -2
df -h /mnt/c 2>/dev/null | tail -1
echo "apt lists size: $(du -sh /var/lib/apt/lists 2>/dev/null | cut -f1)"
echo "apt cache size: $(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)"

echo "=== WSLg / display ==="
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
ls -d /mnt/wslg 2>/dev/null && echo "wslg present" || echo "NO /mnt/wslg"
echo "libGL: $(ls /usr/lib/wsl/lib 2>/dev/null | tr '\n' ' ')"

echo "=== tools already there ==="
for c in git curl wget catkin rosdep roscore python3 aptitude; do
  printf "%-10s %s\n" "$c" "$(command -v $c || echo '-')"
done
echo "ros installed pkgs: $(dpkg -l 2>/dev/null | grep -c '^ii.*ros-')"
echo "=== existing workspaces ==="
ls -d ~/vnav_ws ~/catkin_ws ~/labs ~/vnav-personal 2>/dev/null
echo "=== network: ros package mirrors ==="
for u in https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/dists/focal/Release \
         http://packages.ros.org/ros/ubuntu/dists/focal/Release \
         https://mirrors.tuna.tsinghua.edu.cn/git/rosdistro/raw/master/20-default.list ; do
  code=$(curl -s -o /dev/null -m 12 -w '%{http_code}' "$u")
  echo "$code  $u"
done
echo "=== github reachability (for VNAV-labs) ==="
git ls-remote --heads https://github.com/MIT-SPARK/VNAV-labs.git 2>&1 | head -3
} 2>&1
