#!/bin/bash
exec >> /mnt/c/Users/13907/lab2/logs/chain_ABC.log 2>&1
cd /mnt/c/Users/13907/lab2/scripts
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
