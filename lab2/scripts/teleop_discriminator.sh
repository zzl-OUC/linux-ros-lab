#!/bin/bash
# Discriminator: does turtle_teleop_key ever READ its stdin at all?
# Positive control = 'q' must make the node exit.  If it does not exit, the keys
# are not reaching the reader and "no cmd_vel" is an instrument failure, not a
# statement about teleop.
source /opt/ros/noetic/setup.bash
source /mnt/c/Users/13907/lab2/scripts/harness.sh
L="$LOG/parttwo"; mkdir -p "$L"
kill_ros; xvfb_up
echo "########## $(date -Is) TELEOP DISCRIMINATOR ##########"
roscore > "$L/di_roscore.log" 2>&1 & sleep 6
rosrun turtlesim turtlesim_node > "$L/di_turtle.log" 2>&1 & sleep 6

echo "=== control 0: does the pty deliver bytes to a child at all? ==="
python3 - > "$L/di_cat.txt" 2>&1 <<'PY'
import os, pty, time
pid, fd = pty.fork()
if pid == 0:
    os.execvp("cat", ["cat", "-v", "/dev/stdin"])
time.sleep(2)
os.write(fd, b"HELLO\r")
time.sleep(1)
os.write(fd, b"\x04")          # Ctrl-D
time.sleep(1)
try: os.waitpid(pid, os.WNOHANG)
except Exception: pass
PY
cat "$L/di_cat.txt"

echo
echo "=== the real question: teleop under a pty, keys then 'q' ==="
python3 - > "$L/di_teleop.txt" 2>&1 <<'PY'
import os, pty, select, time
pid, fd = pty.fork()
if pid == 0:
    os.environ.setdefault("ROS_NAMESPACE", "")
    os.execv("/opt/ros/noetic/lib/turtlesim/turtle_teleop_key",
             ["turtle_teleop_key"])
out = []
def drain(n=1.0):
    t = time.time()
    while time.time() - t < n:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: out.append(os.read(fd, 4096).decode("utf-8", "replace"))
            except OSError: break
drain(2.0)
print("--- banner ---"); print("".join(out)); out.clear()
for k in [b"w", b"w", b"w", b"a"]:
    os.write(fd, k); drain(0.9)
print("--- after 4 keys, node alive? ---",
      "ALIVE" if os.waitpid(pid, os.WNOHANG)[0] == 0 else "DEAD")
os.write(fd, b"q"); drain(1.5)
st = os.waitpid(pid, os.WNOHANG)
print("--- after 'q':", "DEAD (keys ARE being read)" if st[0] else "STILL ALIVE (stdin never reaches the reader)")
PY
cat "$L/di_teleop.txt"

echo
echo "=== and the topic, with a longer/looser window ==="
rosrun turtlesim turtle_teleop_key < /dev/null > "$L/di_devnull.log" 2>&1 &
sleep 3
echo "  teleop started with stdin=/dev/null; rostopic info:"
rostopic info /turtle1/cmd_vel 2>&1 | head -8
sleep 2
pkill -9 -f turtle_teleop_key
kill_ros
echo "########## $(date -Is) DISCRIMINATOR DONE ##########"
