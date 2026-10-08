#!/bin/bash
# Shared harness: a private Xvfb display so window grabs actually work.
# (WSLg's XWayland answers XGetImage with BadMatch, so in-Linux screenshots of
#  WSLg windows come back uniformly black -- see logs/xvfb_probe.log.)
export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
export DISABLE_ROS1_EOL_WARNINGS=1
SHOT=/mnt/c/Users/13907/lab2/shots
LOG=/mnt/c/Users/13907/lab2/logs
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
