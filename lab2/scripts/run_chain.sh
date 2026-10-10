#!/bin/bash
LAB2_ROOT="${LAB2_ROOT:-$HOME/lab2}"
mkdir -p "$LAB2_ROOT/logs"
cd "$(dirname "$0")"
exec >> "$LAB2_ROOT/logs/chain_ABC.log" 2>&1
for f in evid_A2_teleop.sh evid_B_part3_stencil.sh evid_C_part3_impl.sh harness.sh; do
  sed -i 's/\r$//' "$f"
done
echo "@@@@@ A2 teleop leg @@@@@"
bash evid_A2_teleop.sh
echo "@@@@@ B part3 stencil @@@@@"
bash evid_B_part3_stencil.sh
echo "@@@@@ C part3 impl @@@@@"
bash evid_C_part3_impl.sh
echo "@@@@@ CHAIN COMPLETE @@@@@"
