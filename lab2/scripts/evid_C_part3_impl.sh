#!/bin/bash
# LAB2 Part Three IV + V: install the completed sources, rebuild, run the moving
# scene, capture RViz in both fixed frames, and verify the geometry numerically.
source /opt/ros/noetic/setup.bash
source ~/vnav_ws/devel/setup.bash
source /mnt/c/Users/13907/lab2/scripts/harness.sh
L="$LOG/part3_impl"; mkdir -p "$L"; rm -f "$L"/*
PKG=~/vnav_ws/src/two_drones_pkg
kill_ros
echo "########## $(date -Is) PART THREE IV+V ##########"

echo "=== install the completed sources ==="
cp -v /mnt/c/Users/13907/lab2/impl/src/frames_publisher_node.cpp $PKG/src/
cp -v /mnt/c/Users/13907/lab2/impl/src/plots_publisher_node.cpp  $PKG/src/
echo "FILL IN markers left: $(grep -c 'FILL IN' $PKG/src/*.cpp | tr '\n' ' ')"
diff -u /mnt/c/Users/13907/lab2/src_snapshot/src/frames_publisher_node.cpp \
        $PKG/src/frames_publisher_node.cpp > "$L/diff_frames.patch"
diff -u /mnt/c/Users/13907/lab2/src_snapshot/src/plots_publisher_node.cpp \
        $PKG/src/plots_publisher_node.cpp  > "$L/diff_plots.patch"
wc -l "$L"/diff_*.patch

echo "=== catkin build ==="
( cd ~/vnav_ws && catkin build 2>&1 | tr -d '\r' | grep -vE "^\[build [0-9]" | tail -12 ) | tee "$L/build.log"
ls -l ~/vnav_ws/devel/lib/two_drones_pkg/

xvfb_up
echo
echo "=== IV: roslaunch the moving scene ==="
roslaunch two_drones_pkg two_drones.launch > "$L/roslaunch_dyn.log" 2>&1 &
sleep 14
rosnode list > "$L/rosnode_dyn.txt" 2>&1; cat "$L/rosnode_dyn.txt"
rostopic list > "$L/rostopic_dyn.txt" 2>&1; cat "$L/rostopic_dyn.txt"
for n in $(rosnode list 2>/dev/null); do echo "### $n"; rosnode info "$n" 2>&1; done > "$L/rosnode_info_dyn.txt"
rviz -d $PKG/config/lab2_world.rviz > "$L/rviz_dyn.log" 2>&1 &
sleep 14
grab 41_dyn_world_1 2
grab 42_dyn_world_2 4
echo "--- tf_echo world av1 / av2 / av1<-av2 ---"
timeout 6 rosrun tf tf_echo world av1 > "$L/tf_world_av1.txt" 2>&1; head -8 "$L/tf_world_av1.txt"
timeout 6 rosrun tf tf_echo world av2 > "$L/tf_world_av2.txt" 2>&1; head -8 "$L/tf_world_av2.txt"
timeout 6 rosrun tf tf_echo av1 av2  > "$L/tf_av1_av2.txt"  2>&1; head -8 "$L/tf_av1_av2.txt"

echo "=== numeric verification (20 s of tf samples + /visuals trails) ==="
timeout 90 python3 /mnt/c/Users/13907/lab2/scripts/verify_trajectories.py 20 > "$L/verify.json" 2>"$L/verify.err"
cat "$L/verify.json"; tail -3 "$L/verify.err"
cp -f /tmp/lab2_tf_samples.csv "$L/" 2>/dev/null; wc -l "$L/lab2_tf_samples.csv" 2>/dev/null

echo "=== V: switch Fixed Frame to av1 ==="
pkill -9 -f rviz; sleep 2
rviz -d $PKG/config/lab2_av1.rviz > "$L/rviz_av1.log" 2>&1 &
sleep 14
grab 43_dyn_av1_1 2
grab 44_dyn_av1_2 4
pkill -9 -f rviz; sleep 1
kill_ros
echo "########## $(date -Is) PART THREE IV+V DONE ##########"
sha256sum "$SHOT"/4*.png | sed 's#/mnt/c/Users/13907/lab2/shots/##'
