#!/bin/bash
# Which screenshot route actually captures WSLg windows?
# scrot on :0 gave 6 byte-identical blanks -> test the weston route instead.
source /opt/ros/noetic/setup.bash
OUT=/mnt/c/Users/13907/lab2/shots/_probe
mkdir -p "$OUT"; rm -f "$OUT"/*.png

echo "=== available capturers ==="
for c in weston-screenshooter scrot import gnome-screenshot spectacle grim; do
  printf '%-22s %s\n' "$c" "$(command -v $c || echo '-')"
done
echo "=== display env ==="
echo "DISPLAY=$DISPLAY WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-none}"
echo "WAYLAND_SOCKET=$WAYLAND_SOCKET"
ls -l /mnt/wslg/ 2>/dev/null | head
echo "XWAYLAND0 socket:"; ls -l /tmp/.X11-unix/ 2>/dev/null

echo "=== start turtlesim so there is a real window ==="
roscore > /tmp/probe_roscore.log 2>&1 &
sleep 5
rosrun turtlesim turtlesim_node > /tmp/probe_turtle.log 2>&1 &
sleep 6
echo "window list (xwininfo tree):"
xwininfo -root -tree 2>/dev/null | grep -E '"[^"]+":' | head -12

echo "=== route A: weston-screenshooter ==="
weston-screenshooter "$OUT/A_wayland.png" 2>&1 | head -3
ls -l "$OUT"/A_wayland.png 2>/dev/null || echo "A: not produced (arg may be unsupported)"
# older builds write a fixed path
for p in ~/weston-screenshooter.png ~/screenshot.png; do
  [ -f "$p" ] && { mv "$p" "$OUT/A_fixed.png"; echo "A fixed-path hit: $p"; }
done

echo "=== route B: scrot on DISPLAY :0 ==="
DISPLAY=:0 scrot -o "$OUT/B_scrot.png" 2>&1 | head -2
ls -l "$OUT/B_scrot.png" 2>/dev/null

echo "=== route C: import -window root ==="
DISPLAY=:0 import -window root "$OUT/C_import.png" 2>&1 | head -3
ls -l "$OUT/C_import.png" 2>/dev/null

echo "=== route D: xwd single window (the turtlesim window id) ==="
WID=$(DISPLAY=:0 xdotool search --name "Turtlesim" 2>/dev/null | head -1)
echo "window id = ${WID:-none}"
if [ -n "$WID" ]; then
  DISPLAY=:0 xwd -id "$WID" -silent > "$OUT/D.xwd" 2>/dev/null && \
    convert "$OUT/D.xwd" "$OUT/D_window.png" 2>/dev/null && ls -l "$OUT/D_window.png"
fi

echo "=== hashes (distinct = the route really sees the window) ==="
sha256sum "$OUT"/*.png 2>/dev/null
echo "=== dims ==="
for f in "$OUT"/*.png; do [ -f "$f" ] && printf '%s %s\n' "$(basename $f)" "$(identify -format '%wx%h mean=%[mean]' "$f" 2>/dev/null)"; done

pkill -9 -f turtlesim; pkill -9 -f rosmaster; pkill -9 -f rosout; sleep 1
echo "########## probe done ##########"
