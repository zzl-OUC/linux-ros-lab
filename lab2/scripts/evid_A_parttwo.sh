#!/bin/bash
# LAB2 Part Two -- ROS basics, with a capture route that actually sees the windows
# and the teleop timing bug fixed (echo must start BEFORE the keys are fed).
source /opt/ros/noetic/setup.bash
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
L="$LOG/parttwo"; mkdir -p "$L"
kill_ros
xvfb_up
echo "########## $(date -Is) PART TWO (take 2) ##########"

echo
echo "=== 1. roscore ==="
roscore > "$L/roscore.log" 2>&1 &
sleep 6
tail -5 "$L/roscore.log"
rosnode list > "$L/01_rosnode_after_master.txt" 2>&1; cat "$L/01_rosnode_after_master.txt"

echo
echo "=== 2. turtlesim_node ==="
rosrun turtlesim turtlesim_node > "$L/turtlesim.log" 2>&1 &
sleep 6
rosnode list  > "$L/02_rosnode_turtlesim.txt" 2>&1
rostopic list > "$L/03_rostopic_list.txt" 2>&1
cat "$L/02_rosnode_turtlesim.txt"; echo '---'; cat "$L/03_rostopic_list.txt"
rosmsg show geometry_msgs/Twist > "$L/04_msg_twist.txt" 2>&1
grab 21_turtlesim 2

echo
echo "=== 3. teleop: keys fed over time, echo armed first ==="
getpose() { timeout 6 rostopic echo -n 1 /turtle1/pose 2>/dev/null | tr -d '\n' | sed 's/  */ /g'; }
getpose > "$L/05_pose_before_teleop.txt"; echo "pose before: $(cat "$L/05_pose_before_teleop.txt")"

( sleep 5; for k in w w w a w w d d; do printf '%s\n' "$k"; sleep 1.2; done; sleep 4 ) \
  | timeout 22 script -qec "rosrun turtlesim turtle_teleop_key" /dev/null \
  > "$L/teleop.log" 2>&1 &
sleep 2
rosnode list > "$L/06_rosnode_with_teleop.txt" 2>&1
timeout 16 rostopic echo -n 6 /turtle1/cmd_vel > "$L/07_rostopic_echo_cmd_vel.txt" 2>&1
echo "--- cmd_vel messages observed from teleop ---"
cat "$L/07_rostopic_echo_cmd_vel.txt"
sleep 6
getpose > "$L/08_pose_after_teleop.txt"; echo "pose after teleop: $(cat "$L/08_pose_after_teleop.txt")"
grab 22_turtlesim_after_teleop 1
rostopic info /turtle1/cmd_vel > "$L/09_topic_info_cmdvel.txt" 2>&1
rostopic info /turtle1/pose    > "$L/10_topic_info_pose.txt" 2>&1
cat "$L/09_topic_info_cmdvel.txt"

echo
echo "=== 3b. direct rostopic pub (no teleop) ==="
rostopic pub -1 /turtle1/cmd_vel geometry_msgs/Twist -- '[2.0,0.0,0.0]' '[0.0,0.0,1.0]' \
  > "$L/11_rostopic_pub.txt" 2>&1
sleep 2
getpose > "$L/12_pose_after_pub.txt"; echo "pose after pub: $(cat "$L/12_pose_after_pub.txt")"
grab 23_turtlesim_after_pub 1

echo
echo "=== 4. rqt_graph ==="
rosrun rqt_graph rqt_graph > "$L/rqt_graph.log" 2>&1 &
grab 24_rqt_graph 8

echo
echo "=== 5. tear down, bring up turtle_tf demo ==="
pkill -9 -f turtlesim; pkill -9 -f rqt_graph; pkill -9 -f turtle_teleop_key; sleep 3
roslaunch turtle_tf turtle_tf_demo.launch > "$L/tf_demo.log" 2>&1 &
sleep 10
rosnode list  > "$L/13_rosnode_tf_demo.txt" 2>&1
rostopic list > "$L/14_rostopic_list_tf_demo.txt" 2>&1
cat "$L/13_rosnode_tf_demo.txt"; echo '---'; cat "$L/14_rostopic_list_tf_demo.txt"
grab 25_turtle_tf_demo 3

echo
echo "=== 6. rqt_tf_tree ==="
rosrun rqt_tf_tree rqt_tf_tree > "$L/rqt_tf_tree.log" 2>&1 &
grab 26_rqt_tf_tree 8

echo
echo "=== 7. tf_echo turtle1 -> turtle2 ==="
timeout 10 rosrun tf tf_echo turtle1 turtle2 > "$L/17_tf_echo_turtle1_turtle2.txt" 2>&1
head -16 "$L/17_tf_echo_turtle1_turtle2.txt"
( cd "$L" && timeout 30 rosrun tf view_frames > view_frames.log 2>&1; ls -l frames.pdf )

echo
echo "=== 8. the courseware's laser example ==="
rosrun tf static_transform_publisher 0.5 0 0 0 0 0 base_link laser > "$L/static_tf.log" 2>&1 &
sleep 4
timeout 6 rosrun tf tf_echo base_link laser > "$L/18_tf_echo_base_laser.txt" 2>&1
head -10 "$L/18_tf_echo_base_laser.txt"
pkill -9 -f static_transform_publisher

echo
echo "=== 9. rviz standalone ==="
rviz > "$L/rviz.log" 2>&1 &
grab 27_rviz_blank 10
kill_ros
echo "########## $(date -Is) PART TWO DONE ##########"
sha256sum "$SHOT"/2*.png | sed "s#^$SHOT/##"
