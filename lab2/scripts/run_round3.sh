#!/bin/bash
LAB2_ROOT="${LAB2_ROOT:-$HOME/lab2}"
mkdir -p "$LAB2_ROOT/logs"
cd "$(dirname "$0")"
exec >> "$LAB2_ROOT/logs/chain_E.log" 2>&1
for f in key_route_probe.sh evid_D_verify.sh harness.sh verify_trajectories.py; do
  sed -i 's/\r$//' "$f"
done
echo "@@@@@ KEY ROUTE PROBE @@@@@"
bash key_route_probe.sh
echo "@@@@@ D numeric verify (fixed) @@@@@"
bash evid_D_verify.sh
echo "@@@@@ ROUND 3 COMPLETE @@@@@"
