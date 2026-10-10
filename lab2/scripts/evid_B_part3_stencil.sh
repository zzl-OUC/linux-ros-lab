#!/bin/bash
# LAB2 Part Three I + III, run against the UNMODIFIED stencil build:
#   I   workspace + static scene
#   III the four questions (nodes / no-roslaunch / pub-sub + mesh topic / static:=True)
source /opt/ros/noetic/setup.bash
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"   # LAB2_ROOT / SRC_DIR / VNAV_WS / PKG
source "$VNAV_WS/devel/setup.bash"
L="$LOG/part3_stencil"; mkdir -p "$L"; rm -f "$L"/*
PKG=~/vnav_ws/src/two_drones_pkg
kill_ros
xvfb_up
echo "########## $(date -Is) PART THREE I+III (stencil) ##########"
echo "git HEAD of clone: $(cd ~/labs/VNAV-labs && git rev-parse --short HEAD)"
echo "--- stencil still unfilled? (FILL IN markers present) ---"
grep -c "FILL IN" $PKG/src/frames_publisher_node.cpp $PKG/src/plots_publisher_node.cpp

# ---------- build an rviz config that adds the TF display (== Add -> TF) ----------
for ff in world av1; do
  awk -v ff="$ff" '
    /^    - Class: rviz\/MarkerArray/ {inMA=1}
    /^  Enabled: true$/ && inMA {
      print "    - Class: rviz/TF"
      print "      Enabled: true"
      print "      Frame Timeout: 15"
      print "      Frames:"
      print "        All Enabled: true"
      print "      Marker Scale: 1"
      print "      Name: TF"
      print "      Show Arrows: true"
      print "      Show Axes: true"
      print "      Show Names: true"
      print "      Tree:"
      print "        {}"
      print "      Update Interval: 0"
      print "      Value: true"
      inMA=0
    }
    { if ($0=="    Fixed Frame: world") { print "    Fixed Frame: " ff } else print }
  ' "$PKG/config/default.rviz" > "$PKG/config/lab2_$ff.rviz"
  echo "config lab2_$ff.rviz: $(grep -c 'Class: rviz/TF' $PKG/config/lab2_$ff.rviz) TF display(s), $(grep 'Fixed Frame:' $PKG/config/lab2_$ff.rviz | tr -d ' ')"
done
cp -a $PKG/config/lab2_*.rviz "$L/"

echo
echo "=== I. static scene via roslaunch (static:=True) ==="
roslaunch two_drones_pkg two_drones.launch static:=True _rviz_fixed_frame:=world \
  > "$L/roslaunch_static.log" 2>&1 &
sleep 14
rosnode list > "$L/Q1_rosnode_list.txt" 2>&1
echo "--- Q1: nodes running ---"; cat "$L/Q1_rosnode_list.txt"
rostopic list > "$L/Q3a_rostopic_list.txt" 2>&1
echo "--- topics ---"; cat "$L/Q3a_rostopic_list.txt"
for n in $(rosnode list 2>/dev/null); do
  echo "### rosnode info $n" ; rosnode info "$n" 2>&1
done > "$L/Q3_rosnode_info.txt"
sed -n '1,200p' "$L/Q3_rosnode_info.txt"
rviz -d $PKG/config/lab2_world.rviz > "$L/rviz_static.log" 2>&1 &
grab 31_static_scene_world 12
timeout 8 rosrun tf tf_echo world av1 > "$L/Q1b_tf_echo_world_av1.txt" 2>&1
head -8 "$L/Q1b_tf_echo_world_av1.txt"
timeout 8 rosrun tf tf_echo world av2 > "$L/Q1c_tf_echo_world_av2.txt" 2>&1
head -8 "$L/Q1c_tf_echo_world_av2.txt"
rostopic echo -n 1 /tf_static > "$L/Q1d_tf_static.txt" 2>&1
cat "$L/Q1d_tf_static.txt"

echo
echo "=== III-Q4: what changes when static:=True is omitted (stencil code) ==="
kill_ros; sleep 2
roslaunch two_drones_pkg two_drones.launch > "$L/roslaunch_nostatic.log" 2>&1 &
sleep 12
rosnode list > "$L/Q4_rosnode_list.txt" 2>&1; echo "--- nodes ---"; cat "$L/Q4_rosnode_list.txt"
echo "--- plots_publisher_node stdout (it is stuck waiting) ---"
cat ~/.ros/log/latest/plots_publisher_node-3-stdout.log 2>/dev/null | head -5
grep -l "Waiting for av1" ~/.ros/log/latest/*.log 2>/dev/null
find ~/.ros/log/latest -name '*plots*' -o -name '*frames*' | sort
for f in $(find ~/.ros/log/latest -name '*stdout.log' | sort); do
  echo "## $f"; head -4 "$f"
done > "$L/Q4_node_stdout.txt" 2>&1
cat "$L/Q4_node_stdout.txt"
echo "--- tf_echo world av1 with static omitted ---"
timeout 8 rosrun tf tf_echo world av1 > "$L/Q4_tf_echo_fail.txt" 2>&1
head -6 "$L/Q4_tf_echo_fail.txt"
rviz -d $PKG/config/lab2_world.rviz > "$L/rviz_nostatic.log" 2>&1 &
grab 32_nostatic_blank 12
kill_ros

echo
echo "=== III-Q2: the same static scene WITHOUT roslaunch (plain rosrun) ==="
roscore > "$L/roscore_manual.log" 2>&1 & sleep 6
rosrun tf2_ros static_transform_publisher 1 0 0 0 0 0 1 world av1 > "$L/sp_av1.log" 2>&1 &
rosrun tf2_ros static_transform_publisher 0 0 1 0 0 0 1 world av2 > "$L/sp_av2.log" 2>&1 &
sleep 4
rosrun two_drones_pkg plots_publisher_node > "$L/plots_manual.log" 2>&1 &
sleep 6
rosnode list > "$L/Q2_rosnode_list.txt" 2>&1; echo "--- nodes ---"; cat "$L/Q2_rosnode_list.txt"
timeout 8 rosrun tf tf_echo world av1 > "$L/Q2_tf_echo_av1.txt" 2>&1; head -8 "$L/Q2_tf_echo_av1.txt"
timeout 8 rosrun tf tf_echo av1 av2  > "$L/Q2_tf_echo_rel.txt" 2>&1; head -8 "$L/Q2_tf_echo_rel.txt"
rviz -d $PKG/config/lab2_world.rviz > "$L/rviz_manual.log" 2>&1 &
grab 33_manual_static 12
kill_ros
echo "########## $(date -Is) PART THREE I+III DONE ##########"
sha256sum "$SHOT"/3*.png | sed "s#^$SHOT/##"
