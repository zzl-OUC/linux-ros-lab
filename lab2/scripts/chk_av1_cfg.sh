#!/bin/bash
source /opt/ros/noetic/setup.bash
PKG=~/vnav_ws/src/two_drones_pkg
echo "=== the two configs as written ==="
for f in lab2_world lab2_av1; do
  echo "--- $f.rviz"
  grep -nE "Fixed Frame|Class: rviz/TF|Target Frame" $PKG/config/$f.rviz
done
echo
echo "=== rviz logs: did it complain about the fixed frame? ==="
for f in ${LAB2_ROOT:-$HOME/lab2}/logs/part3_impl/rviz_av1.log \
         ${LAB2_ROOT:-$HOME/lab2}/logs/part3_impl/rviz_dyn.log; do
  echo "--- $f"; grep -aiE "fixed frame|Frame not found|does not exist|Warning|ERROR" "$f" 2>/dev/null | head -6
done
echo
echo "=== pixel comparison: is the av1 view actually different? ==="
cd ${LAB2_ROOT:-$HOME/lab2}/shots
for p in "41_dyn_world_1 42_dyn_world_2" "41_dyn_world_1 43_dyn_av1_1" "43_dyn_av1_1 44_dyn_av1_2"; do
  set -- $p
  d=$(compare -metric AE "$1.png" "$2.png" null: 2>&1)
  echo "  $1 vs $2 : differing pixels = $d"
done
