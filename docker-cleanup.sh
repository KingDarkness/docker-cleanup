#!/bin/bash
set -euo pipefail

LOG=/var/log/docker-cleanup.log
LOCK=/var/lock/docker-cleanup.lock

trap 'echo "$(date -Is) $(hostname) docker cleanup failed at line $LINENO" >>"$LOG"' ERR

exec 9>"$LOCK"
flock -n 9 || {
  echo "$(date -Is) $(hostname) docker cleanup already running" >>"$LOG"
  exit 0
}

: >"$LOG"

{
  echo "=================================================="
  echo "$(date -Is) $(hostname) docker cleanup start"
  echo "--- before ---"
  docker system df

  # Chỉ xóa container đã dừng
  docker container prune -f

  # Chỉ xóa image dangling, không dùng -a
  docker image prune -f

  # Giữ build cache 2 ngày gần nhất
  docker builder prune -f --filter until=48h

  echo "--- after ---"
  docker system df
  echo "$(date -Is) $(hostname) docker cleanup done"
} >>"$LOG" 2>&1
