#!/bin/bash
# The node's banner says only "Use arrow keys to move the turtle. 'q' to quit."
# Feed real arrow-key escape sequences (ESC [ A) instead of w/a, and judge on
# /turtle1/cmd_vel plus the pose delta.
source /opt/ros/noetic/setup.bash
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
L="$LOG/parttwo"; mkdir -p "$L"
kill_ros; xvfb_up
echo "########## $(date -Is) ARROW-KEY TELEOP ##########"
echo "=== full usage text the node prints ==="
strings /opt/ros/noetic/lib/turtlesim/turtle_teleop_key | grep -aiE "keyboard|arrow|quit|spin|linear|angular|w a s d|reset" | head -10

roscore > "$L/ak_roscore.log" 2>&1 & sleep 6
rosrun turtlesim turtlesim_node > "$L/ak_turtle.log" 2>&1 & sleep 6
getpose() { timeout 6 rostopic echo -n 1 /turtle1/pose 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }
getpose > "$L/ak_pose_before.txt"; echo "pose before: $(cat "$L/ak_pose_before.txt")"

timeout 20 rostopic echo -n 6 /turtle1/cmd_vel > "$L/ak_cmdvel.txt" 2>&1 &
EPID=$!
python3 - > "$L/ak_py.log" 2>&1 <<'PY'
import os, pty, select, time
pid, fd = pty.fork()
if pid == 0:
    os.execv("/opt/ros/noetic/lib/turtlesim/turtle_teleop_key", ["turtle_teleop_key"])
def drain(n):
    t = time.time()
    while time.time() - t < n:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: os.read(fd, 4096)
            except OSError: return
        else:
            time.sleep(0.05)
drain(2.5)
# Up, Up, Up, Left, Up, Right  (ESC [ <A|B|C|D>)
seq = {1:"A", 2:"B", 3:"C", 4:"D"}
keys = [b"\x1b[A"] * 3 + [b"\x1b[D"] + [b"\x1b[A"] * 2 + [b"\x1b[C"]
for i, k in enumerate(keys):
    os.write(fd, k)
    drain(1.1)
    print("fed %d %s" % (i + 1, k))
drain(2.0)
os.write(fd, b"q"); drain(1.0)
print("node exited:", os.waitpid(pid, os.WNOHANG)[0] != 0)
PY
wait $EPID
echo "=== cmd_vel published by the arrow keys ==="
cat "$L/ak_cmdvel.txt"
sleep 2
getpose > "$L/ak_pose_after.txt"
echo "pose after : $(cat "$L/ak_pose_after.txt")"
echo "python: $(grep -c 'fed' "$L/ak_py.log") keys; $(grep 'node exited' "$L/ak_py.log")"
rosnode list > "$L/ak_rosnode.txt" 2>&1; cat "$L/ak_rosnode.txt"
rostopic info /turtle1/cmd_vel > "$L/ak_topicinfo.txt" 2>&1; cat "$L/ak_topicinfo.txt"
rosrun rqt_graph rqt_graph > "$L/ak_rqtgraph.log" 2>&1 &
grab 28_teleop_graph 9
pkill -9 -f turtle_teleop_key
grab 29_turtlesim_teleop_moved 1
kill_ros
echo "########## $(date -Is) ARROW-KEY TELEOP DONE ##########"
sha256sum "$SHOT"/28*.png "$SHOT"/29*.png 2>/dev/null | sed "s#^$SHOT/##"
