#!/bin/bash
F=/opt/ros/noetic/lib/turtlesim/turtle_teleop_key
echo "exists: $([ -e "$F" ] && echo yes || echo no)"
ls -l "$F" 2>&1
echo "--- file type ---"
file "$F" 2>&1
echo "--- first lines if text ---"
head -3 "$F" 2>&1
echo "--- relevant strings ---"
strings "$F" 2>/dev/null | grep -iE "stdin|tcsetattr|cfmakeraw|getchar|arrow keys|Reading from|isFinite|VMIN|VTIME" | head -20
echo "--- dpkg owner ---"
dpkg -S "$F" 2>&1 | head -2
