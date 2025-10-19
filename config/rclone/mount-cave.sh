#!/usr/bin/env bash
#
# Mount terra-cave S3 bucket to ~/Cave with full VFS caching
# This script is designed to be run by LaunchAgent on startup
#
# AWS credentials are read from environment variables:
# - CAVE_AWS_ACCESS_KEY_ID
# - CAVE_AWS_SECRET_ACCESS_KEY
# These should be set in ~/.config/bash/bash_profile_local
#

set -euo pipefail

# Configuration
REMOTE="cave:terra-cave-us-east-1"
MOUNT_POINT="${HOME}/Cave"
LOG_DIR="${HOME}/.cache/rclone"
LOG_FILE="${LOG_DIR}/cave.log"
CACHE_DIR="${HOME}/.cache/rclone/vfs"

# Load environment variables from bash_profile_local if running via LaunchAgent
# LaunchAgent doesn't load user's shell environment, so we need to source it
if [[ -f "${HOME}/.config/bash/bash_profile_local" ]]; then
    # Source the file in a subshell to extract the CAVE_AWS_* variables
    source "${HOME}/.config/bash/bash_profile_local"
fi

# Export AWS credentials from CAVE_ prefixed variables
# rclone expects AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
if [[ -n "${CAVE_AWS_ACCESS_KEY_ID:-}" && -n "${CAVE_AWS_SECRET_ACCESS_KEY:-}" ]]; then
    export AWS_ACCESS_KEY_ID="${CAVE_AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${CAVE_AWS_SECRET_ACCESS_KEY}"
else
    echo "[$(date)] ERROR: CAVE_AWS_ACCESS_KEY_ID and CAVE_AWS_SECRET_ACCESS_KEY not set" | tee -a "${LOG_FILE}"
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

# Mount with optimal settings for Dropbox-like experience
exec /opt/homebrew/bin/rclone nfsmount "${REMOTE}" "${MOUNT_POINT}" \
    --vfs-cache-mode full \
    --vfs-cache-max-size 50G \
    --vfs-cache-max-age 168h \
    --vfs-write-back 5s \
    --vfs-read-ahead 128M \
    --buffer-size 64M \
    --dir-cache-time 5m \
    --poll-interval 15s \
    --cache-dir "${CACHE_DIR}" \
    --log-file "${LOG_FILE}" \
    --log-level INFO \
    --volname "Cave"
