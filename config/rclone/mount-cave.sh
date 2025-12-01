#!/usr/bin/env bash
#
# Mount Cave WebDAV server to ~/Cave with full VFS caching
# This script is designed to be run by LaunchAgent on startup
#
# WebDAV credentials are read from environment variables:
# - CAVE_WEBDAV_USER
# - CAVE_WEBDAV_PASS
# These should be set in ~/.config/bash/bash_profile_local
#

set -euo pipefail

# Configuration
REMOTE="cave:"
MOUNT_POINT="${HOME}/Cave"
LOG_DIR="${HOME}/.cache/rclone"
LOG_FILE="${LOG_DIR}/cave.log"
CACHE_DIR="${HOME}/.cache/rclone/vfs"

# Load environment variables from bash_profile_local if running via LaunchAgent
# LaunchAgent doesn't load user's shell environment, so we need to source it
if [[ -f "${HOME}/.config/bash/bash_profile_local" ]]; then
    source "${HOME}/.config/bash/bash_profile_local"
fi

# Validate WebDAV credentials are set
if [[ -z "${CAVE_WEBDAV_USER:-}" || -z "${CAVE_WEBDAV_PASS:-}" ]]; then
    echo "[$(date)] ERROR: CAVE_WEBDAV_USER and CAVE_WEBDAV_PASS not set" | tee -a "${LOG_FILE}"
    echo "[$(date)] Please add these to ~/.config/bash/bash_profile_local" | tee -a "${LOG_FILE}"
    exit 1
fi

# Ensure directories exist
mkdir -p "${MOUNT_POINT}"
mkdir -p "${LOG_DIR}"
mkdir -p "${CACHE_DIR}"

# Check if already mounted
if mount | grep -q "on ${MOUNT_POINT}"; then
    echo "[$(date)] Cave already mounted at ${MOUNT_POINT}" | tee -a "${LOG_FILE}"
    exit 0
fi

# Check if rclone config exists
if [ ! -f "${HOME}/.config/rclone/rclone.conf" ]; then
    echo "[$(date)] ERROR: rclone.conf not found. Please configure rclone first." | tee -a "${LOG_FILE}"
    exit 1
fi

echo "[$(date)] Mounting ${REMOTE} to ${MOUNT_POINT}..." | tee -a "${LOG_FILE}"

# Mount optimized for fast local browsing, relaxed sync
exec /opt/homebrew/bin/rclone nfsmount "${REMOTE}" "${MOUNT_POINT}" \
    --webdav-user "${CAVE_WEBDAV_USER}" \
    --webdav-pass "${CAVE_WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --vfs-cache-max-size 50G \
    --vfs-cache-max-age 168h \
    --vfs-write-back 2m \
    --vfs-read-ahead 128M \
    --buffer-size 64M \
    --dir-cache-time 1h \
    --attr-timeout 1h \
    --transfers 8 \
    --checkers 16 \
    --cache-dir "${CACHE_DIR}" \
    --log-file "${LOG_FILE}" \
    --log-level INFO \
    --volname "Cave"
