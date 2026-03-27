#!/usr/bin/env bash
# Category: 01-user-permissions
# Script: setup_users.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

require_root

section "User & Permissions Management"

if ! confirm "This script will create users, groups, directories, and modify sudoers. Proceed?" "N"; then
    warn "Operation aborted by user."
    exit 0
fi

# Ensure all needed tools are present
require_cmd useradd
require_cmd groupadd
require_cmd chpasswd
require_cmd chage
require_cmd setfacl
require_cmd getfacl
require_cmd visudo

info "Creating groups: developers, ops, readonly..."
for g in developers ops readonly; do
    if ! getent group "$g" >/dev/null; then
        groupadd "$g"
        info "Created group $g"
    else
        warn "Group $g already exists"
    fi
done

info "Creating users: alice, bob, carol, dave..."
declare -A user_groups=(
    ["alice"]="developers"
    ["bob"]="developers"
    ["carol"]="ops"
    ["dave"]="readonly"
)

# Default password for everyone
DEFAULT_PASS="LabPass123!"

for u in "${!user_groups[@]}"; do
    group="${user_groups[$u]}"
    if ! getent passwd "$u" >/dev/null; then
        useradd -m -g "$group" -s /bin/bash "$u"
        echo "$u:$DEFAULT_PASS" | chpasswd
        chage -d 0 "$u" # Force password change on next login
        info "Created user $u in group $group (Password forced change)"
    else
        warn "User $u already exists"
    fi
done

info "Creating shared directories and setting permissions..."
mkdir -p /opt/lab/shared /opt/lab/devs-only /opt/lab/ops-only

# /opt/lab/shared (1775)
chmod 1775 /opt/lab/shared
info "Set 1775 on /opt/lab/shared"

# /opt/lab/devs-only (2770)
chgrp developers /opt/lab/devs-only
chmod 2770 /opt/lab/devs-only
info "Set 2770 and group 'developers' on /opt/lab/devs-only"

# /opt/lab/ops-only (2770)
chgrp ops /opt/lab/ops-only
chmod 2770 /opt/lab/ops-only
info "Set 2770 and group 'ops' on /opt/lab/ops-only"

info "Applying POSIX ACLs..."
# Cross-group read access for carol (who is in ops) on devs dir
setfacl -b /opt/lab/devs-only || true
setfacl -m u:carol:r-x /opt/lab/devs-only
info "Granted user 'carol' read-execute access to /opt/lab/devs-only via ACL"

info "Configuring sudoers rules..."
SUDOERS_FILE="/etc/sudoers.d/lab-roles"

TMP_SUDOERS=$(mktemp)
cat << 'EOF' > "$TMP_SUDOERS"
# Sudoers rules for lab roles
%ops ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /bin/systemctl status *
%developers ALL=(ALL) /usr/bin/apt-get update, /usr/bin/apt-get install *
EOF

if visudo -c -f "$TMP_SUDOERS" >/dev/null 2>&1; then
    cp "$TMP_SUDOERS" "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    info "Successfully installed sudoers rules to $SUDOERS_FILE"
else
    error "Sudoers validation failed! Aborting sudoers installation."
    rm -f "$TMP_SUDOERS"
    exit 1
fi
rm -f "$TMP_SUDOERS"

info "Generating user audit report..."
AUDIT_REPORT="/tmp/user_audit_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "======================================"
    echo " User and Permissions Audit Report"
    echo " Generated: $(date)"
    echo "======================================"
    echo ""
    echo "--- Users mapped to lab groups ---"
    for g in developers ops readonly; do
        echo "Group: $g"
        getent group "$g" || echo "  Not found"
    done
    
    echo ""
    echo "--- User Password Change Enforcement ---"
    for u in alice bob carol dave; do
        echo "User: $u"
        chage -l "$u" | grep "Last password change" || echo "  Not found"
    done
    
    echo ""
    echo "--- Directory Permissions and ACLs ---"
    for d in /opt/lab/shared /opt/lab/devs-only /opt/lab/ops-only; do
        echo "Dir: ${d}"
        ls -ld "$d" || true
        getfacl -p "$d" 2>/dev/null | grep -E -v "^# file|^# owner|^# group" || true
        echo ""
    done
} > "$AUDIT_REPORT"

info "Audit report generated at: ${AUDIT_REPORT}"
info "Setup complete."
