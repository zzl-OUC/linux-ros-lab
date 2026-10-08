#!/bin/bash
# LAB2 Part One: install ROS Noetic desktop-full inside Ubuntu-20.04 (WSL2).
# Everything it prints is captured by the caller into logs/install_ros.log.
# Deviations from the courseware are deliberate and printed as DEVINATION lines.

echo "########## $(date -Is) install_ros start ##########"

echo "=== 0. mirror speed test (courseware says packages.ros.org) ==="
for u in https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu \
         http://packages.ros.org/ros/ubuntu \
         https://mirrors.aliyun.com/ros/ubuntu ; do
  read sz t <<<"$(curl -s -o /dev/null -m 40 -w '%{size_download} %{time_total}' \
      "$u/dists/focal/main/binary-amd64/Packages.gz" | awk '{print $1, $2}')"
  echo "  $u  Packages.gz=$sz bytes  time=${t}s"
done
# pick the mirror that returned the most bytes in the least time
BEST=$(for u in https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu \
                http://packages.ros.org/ros/ubuntu \
                https://mirrors.aliyun.com/ros/ubuntu ; do
         r=$(curl -s -o /dev/null -m 40 -w '%{size_download}/%{time_total}' \
             "$u/dists/focal/main/binary-amd64/Packages.gz")
         sz=${r%%/*}; tm=${r##*/}
         [ "${sz:-0}" -gt 1000 ] || continue
         awk -v u="$u" -v s="$sz" -v t="$tm" 'BEGIN{printf "%.0f %s\n", s/t*1000, u}'
       done | sort -rn | head -1 | cut -d' ' -f2-)
echo "CHOSEN_MIRROR=$BEST"
echo "DEVINATION: courseware hard-codes http://packages.ros.org/ros/ubuntu and uses the"
echo "            removed-from-bionic apt-key; here the mirror is chosen by measured"
echo "            throughput below and the key is installed as an apt keyring."

echo
echo "=== 1. apt-key deprecation evidence (courseware's literal command) ==="
python3 -c 'import json,base64,urllib.request
d=json.load(urllib.request.urlopen("https://api.github.com/repos/ros/rosdistro/contents/ros.asc",timeout=40))
open("/tmp/ros.asc","wb").write(base64.b64decode(d["content"]))' || echo "api route failed"
ls -l /tmp/ros.asc; head -1 /tmp/ros.asc
echo "--- what the courseware's 'sudo apt-key add -' prints on focal: ---"
cat /tmp/ros.asc | sudo apt-key add - 2>&1 | head -5
echo "--- cleaning that up, using a keyring instead ---"
sudo apt-key del D2486D2DD834852A06DE077A0F61B50446665333 2>&1 | head -2
sudo rm -f /etc/apt/trusted.gpg~ /etc/apt/trusted.gpg.d/ros.asc* 2>/dev/null

echo
echo "=== 2. install the ROS GPG key as a dearmored keyring ==="
sudo mkdir -p /etc/apt/keyrings
gpg --dearmor < /tmp/ros.asc | sudo tee /etc/apt/keyrings/ros-archive-keyring.gpg >/dev/null
ls -l /etc/apt/keyrings/ros-archive-keyring.gpg
echo "fingerprint:"
gpg --show-keys --with-fingerprint /tmp/ros.asc 2>/dev/null | grep -A1 "^pub" | head -4

echo
echo "=== 3. write the apt source ==="
echo "deb [signed-by=/etc/apt/keyrings/ros-archive-keyring.gpg] $BEST $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/ros-latest.list
cat /etc/apt/sources.list.d/ros-latest.list

echo
echo "=== 4. apt update ==="
sudo apt-get update 2>&1 | tail -12
apt-cache policy ros-noetic-desktop-full 2>/dev/null | head -5

echo
echo "=== 5. install ros-noetic-desktop-full ==="
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y ros-noetic-desktop-full 2>&1 | tail -25
echo "apt install rc=${PIPESTATUS[0]}"

echo
echo "=== 6. extra dependencies from the courseware ==="
sudo apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator \
  python3-vcstool build-essential python3-catkin-tools python-is-python3 2>&1 | tail -8

echo
echo "=== 7. ROS environment in ~/.bashrc ==="
grep -q 'source /opt/ros/noetic/setup.bash' ~/.bashrc || \
  echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
tail -3 ~/.bashrc

echo
echo "=== 8. rosdep init/update through the TUNA rosdistro mirror ==="
sudo rosdep init 2>&1 | tail -3
echo "DEVINATION: rosdep's default 20-default.list points at raw.githubusercontent.com,"
echo "            which is unreachable from this machine; rewritten to the TUNA mirror."
sudo tee /etc/ros/rosdep/sources.list.d/20-default.list >/dev/null <<'LIST'
rosdistro: '
  https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml'
base:
  ros:
    - 'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/base.yaml'
    - 'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/python.yaml'
    - 'https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/ruby.yaml'
LIST
curl -s -o /dev/null -w "base.yaml http=%{http_code}\n" -m 20 \
  https://mirrors.tuna.tsinghua.edu.cn/rosdistro/rosdep/base.yaml
timeout 180 env ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml \
  rosdep update 2>&1 | tail -8

echo
echo "=== 9. verify the install ==="
source /opt/ros/noetic/setup.bash
echo "ROS_DISTRO=$ROS_DISTRO  ROS_VERSION=$ROS_VERSION  ROS_PYTHON_VERSION=$ROS_PYTHON_VERSION"
for c in roscore rosnode rostopic rosbag roslaunch rosrun catkin_make catkin rosdep rviz rqt_graph; do
  printf "  %-14s %s\n" "$c" "$(command -v $c || echo MISSING)"
done
dpkg -l | grep -c '^ii  ros-noetic-' | sed 's/^/  ros-noetic packages installed: /'
echo "########## $(date -Is) install_ros done ##########"
