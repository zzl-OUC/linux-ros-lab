#!/bin/bash
# Can we render RViz into an Xvfb framebuffer (llvmpipe) and grab it with scrot?
# WSLg's XWayland refuses XGetImage (BadMatch), so an in-Linux grab needs a real
# memory framebuffer of its own.
source /opt/ros/noetic/setup.bash
OUT=${LAB2_ROOT:-$HOME/lab2}/shots/_probe
mkdir -p "$OUT"; rm -f "$OUT"/X_*

echo "=== install xvfb + mesa (software GL) ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb x11-utils mesa-utils libgl1-mesa-dri \
  2>&1 | grep -E "^(Setting up|E:|is already the newest)" | head -8

echo "=== start Xvfb :99 ==="
pkill -9 -f "Xvfb :99" 2>/dev/null; sleep 1
Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp > /tmp/xvfb.log 2>&1 &
sleep 3
echo "Xvfb pid=$(pgrep -f 'Xvfb :99' | head -1)"

echo "=== GLX under Xvfb ==="
DISPLAY=:99 glxinfo 2>&1 | grep -iE "^(OpenGL vendor|OpenGL renderer|OpenGL version|direct rendering)" | head -6

echo "=== turtlesim + scrot under Xvfb ==="
roscore > /tmp/x_roscore.log 2>&1 & sleep 5
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 rosrun turtlesim turtlesim_node > /tmp/x_turtle.log 2>&1 &
sleep 7
DISPLAY=:99 xwininfo -root -tree 2>/dev/null | grep -E '"[^"]+":' | head -6
DISPLAY=:99 scrot -o "$OUT/X_turtle.png" 2>&1 | head -2
ls -l "$OUT/X_turtle.png" 2>/dev/null
DISPLAY=:99 xwd -root -silent 2>/dev/null | convert xwd:- "$OUT/X_root.png" 2>&1 | head -2
ls -l "$OUT/X_root.png" 2>/dev/null

echo "=== rviz (needs OpenGL) under Xvfb ==="
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 rviz > /tmp/x_rviz.log 2>&1 &
sleep 14
DISPLAY=:99 xwininfo -root -tree 2>/dev/null | grep -iE 'rviz' | head -4
DISPLAY=:99 scrot -o "$OUT/X_rviz.png" 2>&1 | head -2
ls -l "$OUT/X_rviz.png" 2>/dev/null
tail -5 /tmp/x_rviz.log

echo "=== hashes / dims / non-uniformity ==="
for f in "$OUT"/X_turtle.png "$OUT"/X_root.png "$OUT"/X_rviz.png; do
  if [ -f "$f" ]; then
    printf '%-14s %-10s %-18s uniq_colors=%s\n' "$(basename $f)" \
      "$(identify -format '%wx%h' "$f")" "$(sha256sum "$f" | cut -c1-16)" \
      "$(convert "$f" -format '%k' info: 2>/dev/null)"
  else printf '%-14s MISSING\n' "$(basename $f)"; fi
done

pkill -9 -f rviz; pkill -9 -f turtlesim; pkill -9 -f rosmaster; pkill -9 -f rosout
pkill -9 -f "Xvfb :99"; sleep 1
echo "########## xvfb probe done ##########"
