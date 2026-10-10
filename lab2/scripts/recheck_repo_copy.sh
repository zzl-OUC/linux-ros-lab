#!/bin/bash
# LAB2 re-run of the PUBLIC REPO version of the two nodes (2026-10-10).
# Installed from ~/linux-ros-lab/lab2/src, tf_buffer_ fix applied, rebuilt.
# Evidence goes to a new dated dir so the 2026-09-27 set stays untouched.
source /opt/ros/noetic/setup.bash
source "${VNAV_WS:-$HOME/vnav_ws}/devel/setup.bash"
export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
export DISABLE_ROS1_EOL_WARNINGS=1

OUT="${LAB2_ROOT:-$HOME/lab2}/logs/repo_recheck_$(date +%Y%m%d)"
SHOT=${LAB2_ROOT:-$HOME/lab2}/shots
PKG="${PKG:-${VNAV_WS:-$HOME/vnav_ws}/src/two_drones_pkg}"
mkdir -p "$OUT"

kill_ros() {
  pkill -9 -f roslaunch 2>/dev/null
  pkill -9 -f rosmaster 2>/dev/null
  pkill -9 -f rosout 2>/dev/null
  pkill -9 -f frames_publisher_node 2>/dev/null
  pkill -9 -f plots_publisher_node 2>/dev/null
  pkill -9 -f rviz 2>/dev/null
  pkill -9 -f tf_echo 2>/dev/null
  sleep 2
}
kill_ros

if ! pgrep -f "Xvfb :99" > /dev/null; then
  Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp > /tmp/xvfb.log 2>&1 &
  sleep 3
fi
echo "Xvfb :99 pid=$(pgrep -f 'Xvfb :99' | head -1)"

echo "=== binaries actually used ==="
ls -l --time-style=+%F_%H:%M /home/vnav/vnav_ws/devel/.private/two_drones_pkg/lib/two_drones_pkg/

echo "=== launch moving scene ==="
roslaunch two_drones_pkg two_drones.launch > "$OUT/roslaunch_dyn.log" 2>&1 &
sleep 14
echo "--- rosnode list ---"; rosnode list
echo "--- rostopic list ---"; rostopic list

grab() {
  sleep 2
  scrot -o "$SHOT/$1.png" 2>/dev/null && \
    identify -format "$1  %wx%h colors=%k" "$SHOT/$1.png" 2>/dev/null && echo || \
    echo "  SHOT FAILED $1"
}

rviz -d "$PKG/config/lab2_world.rviz" > "$OUT/rviz_world.log" 2>&1 &
sleep 14
grab repo_41_dyn_world
pkill -9 -f rviz 2>/dev/null; sleep 2

rviz -d "$PKG/config/lab2_av1.rviz" > "$OUT/rviz_av1.log" 2>&1 &
sleep 14
grab repo_42_dyn_av1
pkill -9 -f rviz 2>/dev/null; sleep 2

echo "=== tf echoes ==="
timeout 6 rosrun tf tf_echo world av1 > "$OUT/tf_world_av1.txt" 2>&1; head -6 "$OUT/tf_world_av1.txt"
timeout 6 rosrun tf tf_echo world av2 > "$OUT/tf_world_av2.txt" 2>&1; head -6 "$OUT/tf_world_av2.txt"
timeout 6 rosrun tf tf_echo av1 av2  > "$OUT/tf_av1_av2.txt"  2>&1; head -6 "$OUT/tf_av1_av2.txt"

echo "=== /visuals marker namespaces ==="
rostopic echo -n 1 /visuals > "$OUT/visuals_1.txt" 2>&1
grep -E '^  ns: ' "$OUT/visuals_1.txt" | sort | uniq -c

echo "=== numeric verification (20 s) ==="
timeout 120 python3 "$(dirname "${BASH_SOURCE[0]}")/verify_trajectories.py" 20 > "$OUT/verify.json" 2> "$OUT/verify.err"
cat "$OUT/verify.json"
echo "--- verify.err tail ---"; tail -3 "$OUT/verify.err"

kill_ros
echo "########## RECHECK DONE $(date -Is) ##########"
