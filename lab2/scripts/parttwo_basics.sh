#!/bin/bash
# LAB2 Part Two: walk the ROS basics and capture real evidence for each item.
# GUI nodes (turtlesim, rqt_graph, rqt_tf_tree, rviz) run under WSLg; each is
# screenshotted, and every command's text output is logged.
source /opt/ros/noetic/setup.bash
SHOT=${LAB2_ROOT:-$HOME/lab2}/shots
LOG=${LAB2_ROOT:-$HOME/lab2}/logs/parttwo
mkdir -p "$SHOT" "$LOG"

cleanup() {
  echo "--- tearing down ---"
  pkill -9 -f rosmaster  2>/dev/null
  pkill -9 -f rosout     2>/dev/null
  pkill -9 -f turtlesim  2>/dev/null
  pkill -9 -f rqt_graph  2>/dev/null
  pkill -9 -f rqt_tf_tree 2>/dev/null
  pkill -9 -f rviz       2>/dev/null
  pkill -9 -f tf_demo    2>/dev/null
  pkill -9 -f static_transform_publisher 2>/dev/null
  sleep 1
}
trap cleanup EXIT
cleanup

echo "########## $(date -Is) part two start ##########"

if ! command -v scrot >/dev/null; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y scrot imagemagick >/dev/null 2>&1
fi
echo "screenshot tool: $(command -v scrot || command -v import || echo NONE)"

grab() { sleep "${2:-2.5}"; scrot -o "$SHOT/$1.png" 2>/dev/null && echo "  shot $1.png" || echo "  SHOT FAILED $1"; }

echo
echo "=== 1. roscore (the ROS Master) ==="
roscore > "$LOG/roscore.log" 2>&1 &
sleep 6
tail -6 "$LOG/roscore.log"
rosnode list 2>&1 | tee "$LOG/01_rosnode_after_master.txt"

echo
echo "=== 2. turtlesim node ==="
rosrun turtlesim turtlesim_node > "$LOG/turtlesim.log" 2>&1 &
sleep 5
rosnode list | tee "$LOG/02_rosnode_turtlesim.txt"
rostopic list | tee "$LOG/03_rostopic_list.txt"
grab 01_turtlesim 2
rosmsg show geometry_msgs/Twist | tee "$LOG/04_msg_twist.txt"

echo
echo "=== 3. teleop: keyboard node, then a scripted cmd_vel ==="
# turtle_teleop_key reads raw keystrokes from a tty; give it a pty via `script`
# and feed keys, so the node really runs and really publishes.
( printf 'w\nw\nw\na\nw\nw\n' | timeout 12 script -qec "rosrun turtlesim turtle_teleop_key" /dev/null \
    > "$LOG/teleop.log" 2>&1 ) &
sleep 6
rosnode list | tee "$LOG/05_rosnode_with_teleop.txt"
echo "--- what teleop published on /turtle1/cmd_vel (rostopic echo, 3 msgs) ---"
timeout 12 rostopic echo -n 3 /turtle1/cmd_vel > "$LOG/06_rostopic_echo_cmd_vel.txt" 2>&1
head -20 "$LOG/06_rostopic_echo_cmd_vel.txt"
echo "--- fallback: publish one Twist directly ---"
rostopic pub -1 /turtle1/cmd_vel geometry_msgs/Twist -- '[2.0, 0.0, 0.0]' '[0.0, 0.0, 1.0]' \
  > "$LOG/07_rostopic_pub.txt" 2>&1
sleep 2
rostopic echo -n 1 /turtle1/pose > "$LOG/08_turtle_pose.txt" 2>&1
cat "$LOG/08_turtle_pose.txt"
grab 02_turtlesim_moved 1

echo
echo "=== 4. rqt_graph ==="
rosrun rqt_graph rqt_graph > "$LOG/rqt_graph.log" 2>&1 &
grab 03_rqt_graph 5

echo
echo "=== 5. topic introspection ==="
rostopic info /turtle1/cmd_vel | tee "$LOG/09_topic_info_cmdvel.txt"
rostopic info /turtle1/pose    | tee "$LOG/10_topic_info_pose.txt"

echo
echo "=== 6. tear turtlesim down, start the turtle_tf demo ==="
pkill -9 -f turtlesim; pkill -9 -f rqt_graph; pkill -9 -f turtle_teleop_key; sleep 2
roslaunch turtle_tf turtle_tf_demo.launch > "$LOG/tf_demo.log" 2>&1 &
sleep 8
rosnode list | tee "$LOG/11_rosnode_tf_demo.txt"
rostopic list | tee "$LOG/12_rostopic_list_tf_demo.txt"
grab 04_turtle_tf_demo 3

echo
echo "=== 7. rqt_tf_tree ==="
rosrun rqt_tf_tree rqt_tf_tree > "$LOG/rqt_tf_tree.log" 2>&1 &
grab 05_rqt_tf_tree 6

echo
echo "=== 8. tf_echo turtle1 -> turtle2 (5 samples) ==="
timeout 12 rosrun tf tf_echo turtle1 turtle2 > "$LOG/13_tf_echo_turtle1_turtle2.txt" 2>&1
head -22 "$LOG/13_tf_echo_turtle1_turtle2.txt"
echo "--- view_frames ---"
( cd "$LOG" && timeout 25 rosrun tf view_frames > view_frames.log 2>&1; ls -l frames.pdf 2>/dev/null )

echo
echo "=== 9. static transform publisher: the courseware's laser example ==="
rosrun tf static_transform_publisher 0.5 0 0 0 0 0 base_link laser 100 > "$LOG/static_tf.log" 2>&1 &
sleep 4
timeout 8 rosrun tf tf_echo base_link laser > "$LOG/14_tf_echo_base_laser.txt" 2>&1
cat "$LOG/14_tf_echo_base_laser.txt"
pkill -9 -f static_transform_publisher

echo
echo "=== 10. rviz standalone ==="
rviz > "$LOG/rviz.log" 2>&1 &
grab 06_rviz_blank 8
pkill -9 -f rviz; sleep 1

echo "########## $(date -Is) part two done ##########"
ls -l "$SHOT"
