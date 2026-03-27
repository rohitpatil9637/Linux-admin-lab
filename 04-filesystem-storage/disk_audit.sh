#!/usr/bin/env bash
# Category: 04-filesystem-storage
# Script: disk_audit.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

require_root

section "Filesystem & Storage Audit"

# 1. Disk usage per partition
info "Disk Usage (df -h):"
df -h

# 2. Filesystems over 80% usage
hr
info "Checking for filesystems over 80% usage..."
df -hP | awk 'NR>1 {print $5 " " $6}' | while read -r use mount_point; do
    percent=${use%\%}
    # Handle potentially non-numeric outputs or weird filesystems gracefully
    if [[ "$percent" =~ ^[0-9]+$ ]] && [[ "$percent" -ge 80 ]]; then
        warn "High disk usage on ${mount_point}: ${use}"
    fi
done

hr

# 3. Top 10 largest files/directories under /
info "Finding top 10 largest files and directories under /..."
info "Scanning... (this may take a moment, ignoring virtual filesystems)"
du -ah --exclude="/proc" --exclude="/sys" --exclude="/dev" --exclude="/run" / 2>/dev/null | sort -rh | head -n 11 || true

hr

# 4. Simulate LVM commands
info "Checking Logical Volume Manager (LVM) status..."
if command -v pvs >/dev/null 2>&1; then
    info "Physical Volumes (pvs):"
    pvs || true
    echo ""
    info "Volume Groups (vgs):"
    vgs || true
    echo ""
    info "Logical Volumes (lvs):"
    lvs || true
else
    warn "LVM tools (pvs, vgs, lvs) not found on this system."
fi

hr

# 5. Backup /etc to /opt/lab/backups/
BACKUP_DIR="/opt/lab/backups"
BACKUP_FILE="${BACKUP_DIR}/etc_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

info "Creating backup of /etc to ${BACKUP_FILE}..."
mkdir -p "${BACKUP_DIR}"

if confirm "Do you want to proceed with the backup of /etc?" "Y"; then
    if tar -czf "${BACKUP_FILE}" /etc 2>/dev/null; then
        info "Backup created successfully as ${BACKUP_FILE}"
    else
        error "Backup creation failed!"
    fi
else
    info "Backup of /etc skipped by user."
fi

hr

# 6. Set up a logrotate config for lab logs
LOGROTATE_DIR="/etc/logrotate.d"
LOGROTATE_FILE="${LOGROTATE_DIR}/linux-admin-lab"

if [[ -d "${LOGROTATE_DIR}" ]]; then
    info "Installing logrotate configuration for lab logs..."
    if confirm "Do you want to install the logrotate config?" "Y"; then
        cat << 'EOF' > "${LOGROTATE_FILE}"
/var/log/linux-admin-lab/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF
        info "Installed logrotate config at ${LOGROTATE_FILE}"
    else
        info "Skipping logrotate configuration."
    fi
else
    warn "Logrotate directory ${LOGROTATE_DIR} not found. Skipping logrotate task."
fi

info "Filesystem & Storage Audit complete."
