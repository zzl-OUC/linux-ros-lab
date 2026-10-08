#!/bin/bash
for f in /mnt/c/Users/13907/lab2/logs/part3_impl/rviz_*.log \
         /mnt/c/Users/13907/lab2/logs/part3_stencil/rviz_*.log; do
  echo "--- $(basename $f)"
  tr -cd '\11\12\15\40-\176' < "$f" | grep -aiE "warn|error|mesh|fail|throttl|deprecat|invalid" | head -6
done
echo "=== full text of one rviz log (first 40 non-empty lines) ==="
tr -cd '\11\12\15\40-\176' < /mnt/c/Users/13907/lab2/logs/part3_impl/rviz_av1.log | grep -av "^$" | head -40
