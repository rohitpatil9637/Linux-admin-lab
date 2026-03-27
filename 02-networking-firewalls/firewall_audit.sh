#!/usr/bin/env bash
# Category: 02-networking-firewalls
# Script: firewall_audit.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

require_root

section "Networking & Firewall Audit"

# Detect Active Firewall
FW_TYPE="none"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    FW_TYPE="ufw"
elif command -v iptables >/dev/null 2>&1 && iptables -L -n | grep -q "Chain INPUT"; then
    FW_TYPE="iptables"
fi

info "Detected Firewall: ${FW_TYPE}"

# Generate Audit Report
AUDIT_REPORT="/tmp/network_audit_report_$(date +%Y%m%d_%H%M%S).txt"
info "Generating network audit report to ${AUDIT_REPORT}..."
{
    echo "======================================"
    echo " Network & Firewall Audit Report"
    echo " Generated: $(date)"
    echo "======================================"
    echo ""
    echo "--- Active Firewall ---"
    echo "Type: $FW_TYPE"
    echo ""
    
    echo "--- Current Firewall Rules ---"
    if [[ "$FW_TYPE" == "ufw" ]]; then
        ufw status verbose || true
    elif [[ "$FW_TYPE" == "iptables" ]]; then
        iptables -L -n -v || true
    else
        echo "No supported firewall detected."
    fi
    
    echo ""
    echo "--- Open Ports / Listening Sockets ---"
    if command -v ss >/dev/null 2>&1; then
        ss -tuln || true
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln || true
    else
        echo "Neither 'ss' nor 'netstat' found."
    fi
} > "$AUDIT_REPORT"
info "Audit report completed."

# Baseline Ruleset Application
hr
warn "WARNING: Applying a baseline ruleset will OVERWRITE existing firewall rules."
warn "This action will drop all incoming traffic except SSH (22), HTTP (80), and HTTPS (443)."
if ! confirm "Do you want to apply the baseline firewall ruleset?" "N"; then
    info "Skipping firewall baseline application."
    exit 0
fi

if [[ "$FW_TYPE" == "ufw" ]]; then
    info "Applying UFW baseline..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    # Setup logging
    ufw logging on
    # Allow essential ports
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    info "UFW baseline applied successfully."
elif [[ "$FW_TYPE" == "iptables" ]] || command -v iptables >/dev/null 2>&1; then
    # Fallback to iptables if nothing else is running
    info "Applying iptables baseline..."
    
    # Flush existing rules
    iptables -F
    iptables -X
    
    # Default policies (drop everything incoming/forward, allow outgoing)
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow established/related connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # Allow specified ports
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Log dropped packets (limit to prevent log spam)
    iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-dropped: " --log-level 4
    
    info "iptables baseline applied successfully. Remember to save rules to persist across reboots."
else
    error "Unsupported or missing firewall mechanism (ufw/iptables not found)."
    exit 1
fi

info "Firewall audit and baseline configuration complete."
