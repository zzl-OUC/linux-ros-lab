#!/bin/bash
exec >> /mnt/c/Users/13907/lab2/logs/chain_E.log 2>&1
cd /mnt/c/Users/13907/lab2/scripts
for f in key_route_probe.sh evid_D_verify.sh harness.sh verify_trajectories.py; do
  sed -i 's/\r$//' "$f"
done
echo "@@@@@ KEY ROUTE PROBE @@@@@"
bash key_route_probe.sh
echo "@@@@@ D numeric verify (fixed) @@@@@"
bash evid_D_verify.sh
echo "@@@@@ ROUND 3 COMPLETE @@@@@"
