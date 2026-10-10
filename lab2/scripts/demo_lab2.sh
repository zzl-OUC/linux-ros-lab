#!/bin/bash
# LAB2 一键现场演示：动态场景 + 两个固定系的 RViz 窗口 + TF 树。
# 窗口走 WSLg（DISPLAY=:0），直接弹到 Windows 桌面上，不需要截图。
source /opt/ros/noetic/setup.bash
source "${VNAV_WS:-$HOME/vnav_ws}/devel/setup.bash"
export DISPLAY=:0

PKG="${PKG:-${VNAV_WS:-$HOME/vnav_ws}/src/two_drones_pkg}"
mkdir -p /tmp/lab2demo
rm -f /tmp/lab2demo/roslaunch.log /tmp/lab2demo/rviz_world.log /tmp/lab2demo/rviz_av1.log

pkill -9 -f rviz 2>/dev/null
pkill -9 -f rqt_tf_tree 2>/dev/null
pkill -9 -f roslaunch 2>/dev/null
pkill -9 -f frames_publisher_node 2>/dev/null
pkill -9 -f plots_publisher_node 2>/dev/null
pkill -9 -f rosmaster 2>/dev/null
sleep 1

echo "[1/3] 起场景（frames + plots 两个节点，50 Hz 广播 TF）..."
roslaunch two_drones_pkg two_drones.launch > /tmp/lab2demo/roslaunch.log 2>&1 &
sleep 9

echo "[2/3] 开两个 RViz：左边 fixed frame = world，右边 = av1 ..."
# launch 文件自己会带一个 config/default.rviz 的 RViz（基本是空场景），
# 演示时三个窗口会看花眼，先把它关掉，只留下面两个有内容的。
pkill -9 -f 'config/default.rviz' 2>/dev/null
sleep 1
rviz -d "$PKG/config/lab2_world.rviz" > /tmp/lab2demo/rviz_world.log 2>&1 &
sleep 4
rviz -d "$PKG/config/lab2_av1.rviz" > /tmp/lab2demo/rviz_av1.log 2>&1 &
sleep 8

echo "[3/3] 自检："
rosnode list
echo "--- /visuals 发布频率 ---"
timeout 8 rostopic hz /visuals 2>&1 | tail -2
echo "--- world->av1 实时位姿 ---"
timeout 5 rosrun tf tf_echo world av1 2>&1 | sed -n '2,3p'

cat <<'EOF'

演示时按这个顺序讲（三个点，每个约 20 秒）：
  1) 右/左任一窗口里蓝色那条是 av1 的单位圆轨迹，橙色是 av2 的抛物线轨迹 —— 这是 world 固定系。
  2) 把任一窗口的 Global Options > Fixed Frame 从 world 改成 av1：同一条橙色轨迹立刻变成
     绕着 av1 转的椭圆（半轴 0.5 与 1.118=√1.25）。这一步是全场最值钱的：轨迹点没重算，
     只是换了参考系，说明画的是 TF 的相对位姿而不是屏幕坐标。
  3) 想证明是自己写的：Ctrl+C 停掉，改 frames_publisher_node.cpp 里的半径或角速度，
     catkin build 后重跑本脚本，圆的尺寸马上变。

关掉演示：bash "$(dirname "$0")/demo_lab2_stop.sh"
EOF
