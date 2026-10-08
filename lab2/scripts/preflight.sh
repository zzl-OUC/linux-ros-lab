#!/bin/bash
# Pre-flight for the ROS install: sudo mode, GPG key route, rosdep mirror route.
{
echo "=== sudo ==="
sudo -n true 2>&1 && echo "passwordless sudo: YES" || echo "passwordless sudo: NO"
sudo -n -v 2>/dev/null; echo "sudo user=$(sudo -n id -un 2>/dev/null)"

echo "=== ros.asc via api.github.com ==="
code=$(curl -s -o /tmp/ros.asc.try -m 20 -w '%{http_code}' \
   https://api.github.com/repos/ros/rosdistro/contents/ros.asc)
echo "api http=$code bytes=$(stat -c%s /tmp/ros.asc.try 2>/dev/null)"
if [ "$code" = "200" ]; then
  python3 - <<'PY'
import json,base64
d=json.load(open('/tmp/ros.asc.try'))
open('/tmp/ros.asc','wb').write(base64.b64decode(d['content']))
print('decoded bytes', len(base64.b64decode(d['content'])))
PY
  head -1 /tmp/ros.asc
  gpg --dearmor < /tmp/ros.asc > /tmp/ros.gpg 2>/dev/null && echo "dearmor OK $(stat -c%s /tmp/ros.gpg) bytes" || echo "dearmor FAILED (maybe already binary)"
fi

echo "=== ros.asc via keyserver ==="
timeout 25 gpg --no-default-keyring --keyring /tmp/ks.gpg --keyserver keyserver.ubuntu.com \
  --recv-keys D2486D2DD834852A06DE077A0F61B50446665333 2>&1 | tail -3

echo "=== rosdep / rosdistro mirror candidates ==="
for u in \
  https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/sources.list.d/20-default.list \
  https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml \
  https://mirrors.tuna.tsinghua.edu.cn/git/rosdistro.git/plain/rosdep/sources.list.d/20-default.list \
  https://mirrors.aliyun.com/ros/ubuntu/dists/focal/Release ; do
  echo "$(curl -s -o /dev/null -m 12 -w '%{http_code}' "$u")  $u"
done

echo "=== apt sources currently in use ==="
grep -h ^deb /etc/apt/sources.list 2>/dev/null | head -5
ls /etc/apt/sources.list.d/ 2>/dev/null
} 2>&1
