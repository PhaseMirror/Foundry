#!/bin/sh
set -eu

if [ -S /var/run/docker.sock ]; then
  socket_gid=$(stat -c '%g' /var/run/docker.sock)
  group_name=$(getent group "$socket_gid" | cut -d: -f1 || true)
  if [ -z "$group_name" ]; then
    group_name=host-docker
    groupadd --gid "$socket_gid" "$group_name"
  fi
  usermod --append --groups "$group_name" vscode
fi

exec "$@"
