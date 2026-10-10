#!/bin/bash
# 关掉 LAB2 演示起的所有东西（只杀 ROS 与 RViz，不动别的）
pkill -9 -f rviz 2>/dev/null
pkill -9 -f rqt_tf_tree 2>/dev/null
pkill -9 -f roslaunch 2>/dev/null
pkill -9 -f frames_publisher_node 2>/dev/null
pkill -9 -f plots_publisher_node 2>/dev/null
pkill -9 -f rosmaster 2>/dev/null
pkill -9 -f rosout 2>/dev/null
echo "LAB2 演示进程已全部关闭"
