#!/bin/bash
# Numeric leg: sample tf + /visuals while the moving scene runs, and check the
# three trails against the closed forms.  (The first attempt died on a
# rospy.Duration API typo -- see logs/chain_ABC.log.)
source /opt/ros/noetic/setup.bash
source ~/vnav_ws/devel/setup.bash
source /mnt/c/Users/13907/lab2/scripts/harness.sh
L="$LOG/part3_impl"; mkdir -p "$L"
kill_ros; xvfb_up
echo "########## $(date -Is) VERIFY LEG ##########"
sed -n '1,3p' ~/vnav_ws/src/two_drones_pkg/src/frames_publisher_node.cpp >/dev/null
echo "impl installed? broadcaster line: $(grep -c 'tf2_ros::TransformBroadcaster broadcaster' ~/vnav_ws/src/two_drones_pkg/src/frames_publisher_node.cpp)"
echo "impl installed? lookupTransform line: $(grep -c 'lookupTransform(ref_frame, dest_frame, ros::Time(0))' ~/vnav_ws/src/two_drones_pkg/src/plots_publisher_node.cpp)"

roslaunch two_drones_pkg two_drones.launch > "$L/roslaunch_verify.log" 2>&1 &
sleep 14
rosnode list > "$L/verify_rosnode.txt" 2>&1; cat "$L/verify_rosnode.txt"
timeout 120 python3 /mnt/c/Users/13907/lab2/scripts/verify_trajectories.py 25 > "$L/verify.json" 2>"$L/verify.err"
echo "--- receipt ---"
cat "$L/verify.json"
echo "--- stderr ---"; tail -5 "$L/verify.err"
cp -f /tmp/lab2_tf_samples.csv "$L/" 2>/dev/null
wc -l "$L/lab2_tf_samples.csv" 2>/dev/null
kill_ros
echo "########## $(date -Is) VERIFY LEG DONE ##########"
