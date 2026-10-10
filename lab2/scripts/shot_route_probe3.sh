#!/bin/bash
# Route D produced nothing; run each capture command with its stderr visible.
source /opt/ros/noetic/setup.bash
OUT=${LAB2_ROOT:-$HOME/lab2}/shots/_probe
rm -f "$OUT"/D* "$OUT"/E* "$OUT"/F*
roscore > /tmp/p3_roscore.log 2>&1 & sleep 5
rosrun turtlesim turtlesim_node > /tmp/p3_turtle.log 2>&1 & sleep 6
WID=$(xdotool search --name "TurtleSim" | head -1)
printf 'WID=%s  (hex 0x%s)\n' "$WID" "$(printf %x $WID)"
xdotool windowactivate "$WID" 2>&1 | head -2
xdotool windowraise "$WID" 2>&1 | head -2
sleep 1

echo "--- xwd -id ---"
xwd -id "$WID" -silent > "$OUT/D.xwd"; echo "xwd rc=$? bytes=$(wc -c < "$OUT/D.xwd")"
convert "$OUT/D.xwd" "$OUT/D_window.png" 2>&1 | head -3

echo "--- import -window <id> ---"
import -window "$WID" "$OUT/E_window.png" 2>&1 | head -3
ls -l "$OUT/E_window.png" 2>/dev/null

echo "--- import -frame ---"
import -frame -window "$WID" "$OUT/E_frame.png" 2>&1 | head -3
ls -l "$OUT/E_frame.png" 2>/dev/null

echo "--- scrot -u (focused window) ---"
scrot -u -o "$OUT/F_scrot_u.png" 2>&1 | head -3
ls -l "$OUT/F_scrot_u.png" 2>/dev/null

echo "--- xwd root ---"
xwd -root -silent > "$OUT/G_root.xwd"; echo "rc=$? bytes=$(wc -c < "$OUT/G_root.xwd")"
convert "$OUT/G_root.xwd" "$OUT/G_root.png" 2>&1 | head -3

echo "=== hashes / dims of everything ==="
for f in "$OUT"/D_window.png "$OUT"/E_window.png "$OUT"/E_frame.png "$OUT"/F_scrot_u.png "$OUT"/G_root.png "$OUT"/B_scrot.png; do
  if [ -f "$f" ]; then
    printf '%-16s %-10s %s\n' "$(basename $f)" "$(identify -format '%wx%h' "$f" 2>/dev/null)" "$(sha256sum "$f" | cut -c1-16)"
  else
    printf '%-16s MISSING\n' "$(basename $f)"
  fi
done
pkill -9 -f turtlesim; pkill -9 -f rosmaster; pkill -9 -f rosout; sleep 1
echo "########## done ##########"
