#!/bin/sh
set -eu

if [ "$#" -gt 0 ] && [ "$1" != "serve" ]; then
  exec "$@"
fi

is_auth_enabled() {
  if [ "${QWENPAW_AUTH_ENABLED+x}" ]; then
    flag="${QWENPAW_AUTH_ENABLED}"
  else
    flag="${COPAW_AUTH_ENABLED:-}"
  fi
  flag="$(printf '%s' "$flag" | tr '[:upper:]' '[:lower:]')"
  [ "$flag" = "true" ] || [ "$flag" = "1" ] || [ "$flag" = "yes" ]
}

warn_if_auth_off() {
  if is_auth_enabled; then
    return
  fi

  cat >&2 <<EOF
============================================================
SECURITY NOTICE: QwenPaw is listening on the container network
without authentication.

Enable QWENPAW_AUTH_ENABLED=true unless the sandbox network is
isolated and access is controlled by the sandbox platform.
============================================================
EOF
}

mkdir -p \
  "${QWENPAW_WORKING_DIR}" \
  "${QWENPAW_SECRET_DIR}" \
  "${QWENPAW_BACKUP_DIR}"

if [ ! -f "${QWENPAW_WORKING_DIR}/config.json" ]; then
  echo "No config.json found; initializing QwenPaw with defaults."
  qwenpaw init --defaults --accept-security
fi

export QWENPAW_PORT="${QWENPAW_PORT:-8088}"
warn_if_auth_off

exec qwenpaw app --host 0.0.0.0 --port "${QWENPAW_PORT}"
