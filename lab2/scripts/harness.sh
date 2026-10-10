#!/bin/bash
# Shared harness: a private Xvfb display so window grabs actually work.
# (WSLg's XWayland answers XGetImage with BadMatch, so in-Linux screenshots of
#  WSLg windows come back uniformly black -- see logs/xvfb_probe.log.)
export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
export DISABLE_ROS1_EOL_WARNINGS=1
# Everything below is overridable, so this runs on a machine other than the one it
# was written on:
#   LAB2_ROOT  scratch dir holding shots/ and logs/       (default ~/lab2)
#   SRC_DIR    node sources to install into the package   (default this repo's lab2/src)
#   VNAV_WS    the catkin workspace                       (default ~/vnav_ws)
#   PKG        the ROS package under test                 (default $VNAV_WS/src/two_drones_pkg)
export LAB2_ROOT="${LAB2_ROOT:-$HOME/lab2}"
export SRC_DIR="${SRC_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../src" && pwd)}"
export VNAV_WS="${VNAV_WS:-$HOME/vnav_ws}"
export PKG="${PKG:-$VNAV_WS/src/two_drones_pkg}"
SHOT="$LAB2_ROOT/shots"
LOG="$LAB2_ROOT/logs"
mkdir -p "$SHOT" "$LOG"

xvfb_up() {
  if ! pgrep -f "Xvfb :99" >/dev/null; then
    Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp > /tmp/xvfb.log 2>&1 &
    sleep 3
  fi
  echo "Xvfb :99 pid=$(pgrep -f 'Xvfb :99' | head -1)"
}

grab() {  # grab <name> [settle-seconds]
  sleep "${2:-2.5}"
  scrot -o "$SHOT/$1.png" 2>/dev/null && \
    echo "  shot $1.png  $(identify -format '%wx%h colors=%k' "$SHOT/$1.png" 2>/dev/null)" || \
    echo "  SHOT FAILED $1"
}

kill_ros() {
  pkill -9 -f rosmaster 2>/dev/null
  pkill -9 -f rosout     2>/dev/null
  pkill -9 -f turtlesim  2>/dev/null
  pkill -9 -f rqt_graph  2>/dev/null
  pkill -9 -f rqt_tf_tree 2>/dev/null
  pkill -9 -f rviz       2>/dev/null
  pkill -9 -f static_transform_publisher 2>/dev/null
  pkill -9 -f turtle_teleop_key 2>/dev/null
  pkill -9 -f roslaunch  2>/dev/null
  pkill -9 -f rosserver  2>/dev/null
  pkill -9 -f tf_demo    2>/dev/null
  pkill -9 -f plots_publisher_node 2>/dev/null
  pkill -9 -f frames_publisher_node 2>/dev/null
  sleep 2
}
