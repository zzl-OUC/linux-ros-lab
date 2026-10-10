#!/bin/bash
# Hypothesis: `rosrun` breaks stdin inheritance, which is why every key route
# above published nothing -- the reader was fine, the launcher was not.
# Test both spellings side by side, judging only on /turtle1/cmd_vel.
source /opt/ros/noetic/setup.bash
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
L="$LOG/parttwo"; mkdir -p "$L"
kill_ros; xvfb_up
echo "########## $(date -Is) ROSRUN-vs-DIRECT STDIN TEST ##########"
roscore > "$L/rs_roscore.log" 2>&1 & sleep 6
rosrun turtlesim turtlesim_node > "$L/rs_turtle.log" 2>&1 & sleep 6
getpose() { timeout 6 rostopic echo -n 1 /turtle1/pose 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }

feed() {  # feed <label> <exec-mode>
  local label=$1 mode=$2
  getpose > "$L/rs_pose_${label}_before.txt"
  timeout 14 rostopic echo -n 4 /turtle1/cmd_vel > "$L/rs_cmdvel_${label}.txt" 2>&1 &
  local EPID=$!
  python3 - "$mode" > "$L/rs_py_${label}.log" 2>&1 <<'PY'
import os, pty, select, sys, time
mode = sys.argv[1]
pid, fd = pty.fork()
if pid == 0:
    if mode == "rosrun":
        os.execv("/opt/ros/noetic/bin/rosrun",
                 ["rosrun", "turtlesim", "turtle_teleop_key"])
    else:
        os.execv("/opt/ros/noetic/lib/turtlesim/turtle_teleop_key",
                 ["turtle_teleop_key"])
seen = 0
t = time.time()
while time.time() - t < 2.5:
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        try: os.read(fd, 4096)
        except OSError: break
for k in [b"w", b"w", b"w", b"a", b"w", b"w"]:
    os.write(fd, k)
    time.sleep(0.7)
    seen += 1
time.sleep(1.5)
os.write(fd, b"q")
time.sleep(1.0)
print("keys fed:", seen)
print("node exited:", os.waitpid(pid, os.WNOHANG)[0] != 0)
PY
  wait $EPID
  sleep 1
  getpose > "$L/rs_pose_${label}_after.txt"
  echo "--- $label: python says: $(grep -E 'keys fed|node exited' "$L/rs_py_${label}.log" | tr '\n' ' ')"
  echo "    cmd_vel messages: $(grep -c 'linear:' "$L/rs_cmdvel_${label}.txt" 2>/dev/null || echo 0)"
  head -14 "$L/rs_cmdvel_${label}.txt"
  echo "    pose before: $(cat "$L/rs_pose_${label}_before.txt")"
  echo "    pose after : $(cat "$L/rs_pose_${label}_after.txt")"
  pkill -9 -f turtle_teleop_key; sleep 2
}

feed A rosrun
feed B direct

echo "=== what does rosrun actually do with the child? ==="
grep -nE "exec|subprocess|Popen|call\(" /opt/ros/noetic/bin/rosrun 2>/dev/null | head -12
kill_ros
echo "########## $(date -Is) TEST DONE ##########"
