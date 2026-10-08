#!/bin/bash
# Quick availability probe for the packages Part Two / Part Three need.
source /opt/ros/noetic/setup.bash
echo "=== deb packages ==="
for p in ros-noetic-turtle-tf ros-noetic-rqt-tf-tree ros-noetic-tf2-tools ros-noetic-xacro ros-noetic-tf-ros; do
  v=$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null)
  printf '%-28s %s\n' "$p" "${v:-MISSING}"
done
echo "=== rospack find ==="
for k in turtle_tf rqt_tf_tree turtlesim rviz tf tf2_ros geometry_msgs; do
  r=$(rospack find "$k" 2>/dev/null)
  printf '%-14s %s\n' "$k" "${r:-NOTFOUND}"
done
echo "=== launch files we will need ==="
ls /opt/ros/noetic/share/turtle_tf/launch/ 2>/dev/null
ls /opt/ros/noetic/share/turtle_tf/msg/ 2>/dev/null
echo "=== catkin_tools version ==="
catkin --version 2>/dev/null | head -2
