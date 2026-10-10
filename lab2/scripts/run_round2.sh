#!/bin/bash
LAB2_ROOT="${LAB2_ROOT:-$HOME/lab2}"
mkdir -p "$LAB2_ROOT/logs"
cd "$(dirname "$0")"
exec >> "$LAB2_ROOT/logs/chain_D.log" 2>&1
for f in evid_A2_teleop.sh evid_D_verify.sh harness.sh verify_trajectories.py; do
  sed -i 's/\r$//' "$f"
done
echo "@@@@@ A2 teleop+laser @@@@@"
bash evid_A2_teleop.sh
echo "@@@@@ D numeric verify @@@@@"
bash evid_D_verify.sh
echo "@@@@@ ROUND 2 COMPLETE @@@@@"
