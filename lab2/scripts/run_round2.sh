#!/bin/bash
exec >> /mnt/c/Users/13907/lab2/logs/chain_D.log 2>&1
cd /mnt/c/Users/13907/lab2/scripts
for f in evid_A2_teleop.sh evid_D_verify.sh harness.sh verify_trajectories.py; do
  sed -i 's/\r$//' "$f"
done
echo "@@@@@ A2 teleop+laser @@@@@"
bash evid_A2_teleop.sh
echo "@@@@@ D numeric verify @@@@@"
bash evid_D_verify.sh
echo "@@@@@ ROUND 2 COMPLETE @@@@@"
