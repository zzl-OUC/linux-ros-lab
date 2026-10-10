#!/bin/bash
# Which mechanism actually delivers keystrokes to turtle_teleop_key?
# Tested candidates, each judged by "did /turtle1/cmd_vel carry a message".
source /opt/ros/noetic/setup.bash
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
L="$LOG/parttwo"; mkdir -p "$L"
kill_ros; xvfb_up
echo "########## $(date -Is) KEY ROUTE PROBE ##########"

roscore > "$L/kr_roscore.log" 2>&1 & sleep 6
rosrun turtlesim turtlesim_node > "$L/kr_turtle.log" 2>&1 & sleep 6

armed() {  # armed <outfile> <n>   -- sets global PID
  timeout 14 rostopic echo -n "$2" /turtle1/cmd_vel > "$1" 2>&1 &
  PID=$!
}
count() { grep -c "linear:" "$1" 2>/dev/null || echo 0; }

echo "=== sanity: does a piped stdin reach a child at all under script? ==="
( sleep 2; printf 'HELLO\n'; sleep 1 ) | timeout 8 script -qec "cat > /tmp/kr_cat.txt" /dev/null >/dev/null 2>&1
echo "  child saw: [$(cat /tmp/kr_cat.txt 2>/dev/null)]"

echo
echo "=== route 1: python pty (own master fd, write keys directly) ==="
armed "$L/kr_r1.txt" 3
python3 - <<'PY' > "$L/kr_r1_py.log" 2>&1 &
import os, pty, select, subprocess, time, sys
pid, fd = pty.fork()
if pid == 0:
    os.execvp("rosrun", ["rosrun", "turtlesim", "turtle_teleop_key"])
time.sleep(4)
for k in [b'w', b'w', b'w', b'a', b'w', b'w']:
    os.write(fd, k)
    time.sleep(0.8)
time.sleep(3)
try:
    os.kill(pid, 9)
except Exception:
    pass
PY
wait $PID
echo "  route1 cmd_vel messages: $(count "$L/kr_r1.txt")"
head -12 "$L/kr_r1.txt"

echo
echo "=== route 2: xterm with allowSendEvents + xdotool key ==="
xterm -xrm 'XTerm*allowSendEvents: true' -fn fixed -geometry 80x12+900+500 \
      -e "rosrun turtlesim turtle_teleop_key" > "$L/kr_xterm2.log" 2>&1 &
sleep 5
TW=$(xdotool search --class "xterm" | tail -1)
echo "  window=${TW:-NONE}"
armed "$L/kr_r2.txt" 3
xdotool windowfocus --sync "$TW" 2>/dev/null
for k in w w w a w w; do xdotool key --window "$TW" --clearmodifiers "$k"; sleep 0.7; done
wait $PID
echo "  route2 cmd_vel messages: $(count "$L/kr_r2.txt")"
head -12 "$L/kr_r2.txt"
pkill -9 -f xterm

echo
echo "=== route 3: xterm, xdotool type (no --window, needs real focus) ==="
xterm -xrm 'XTerm*allowSendEvents: true' -fn fixed -geometry 80x12+900+500 \
      -e "rosrun turtlesim turtle_teleop_key" > "$L/kr_xterm3.log" 2>&1 &
sleep 5
TW=$(xdotool search --class "xterm" | tail -1)
armed "$L/kr_r3.txt" 3
xdotool windowactivate --sync "$TW" 2>/dev/null
xdotool windowfocus --sync "$TW" 2>/dev/null
xdotool type --delay 400 "wwaww" 2>/dev/null
sleep 4
wait $PID
echo "  route3 cmd_vel messages: $(count "$L/kr_r3.txt")"
head -12 "$L/kr_r3.txt"
pkill -9 -f xterm

kill_ros
echo "########## $(date -Is) KEY ROUTE PROBE DONE ##########"
