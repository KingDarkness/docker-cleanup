#!/bin/bash
set -euo pipefail

LOG=/var/log/registry-gc.log
LOCK=/var/lock/registry-gc.lock
CONTAINER_NAME="${REGISTRY_CONTAINER:-registry_registry.1}"
DRY_RUN="${REGISTRY_GC_DRY_RUN:-0}"

trap 'echo "$(date -Is) $(hostname) registry GC failed at line $LINENO" >>"$LOG"' ERR

exec 9>"$LOCK"
flock -n 9 || {
  echo "$(date -Is) $(hostname) registry GC already running" >>"$LOG"
  exit 0
}

: >"$LOG"

CONTAINER=$(/usr/bin/docker ps -q -f "name=${CONTAINER_NAME}")
CONTAINER=${CONTAINER%%$'\n'*}

if [ -z "$CONTAINER" ]; then
  echo "$(date -Is) $(hostname) registry container not found: ${CONTAINER_NAME}" >>"$LOG"
  exit 1
fi

GC_ARGS=(garbage-collect)
if [ "$DRY_RUN" = "1" ]; then
  GC_ARGS+=(--dry-run)
fi
GC_ARGS+=(--delete-untagged /etc/docker/registry/config.yml)

{
  echo "=================================================="
  echo "$(date -Is) $(hostname) registry GC start (container=${CONTAINER}, dry_run=${DRY_RUN})"
  /usr/bin/docker exec "$CONTAINER" bin/registry "${GC_ARGS[@]}"
  echo "$(date -Is) $(hostname) registry GC done"
} >>"$LOG" 2>&1
