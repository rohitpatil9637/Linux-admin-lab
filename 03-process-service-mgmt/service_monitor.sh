#!/usr/bin/env bash
# Category: 03-process-service-mgmt
# Script: service_monitor.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

require_root

section "Process & Service Monitor"

# 1. Top consuming processes
info "Top 10 CPU Consuming Processes:"
ps -eo pid,ppid,comm,%mem,%cpu --sort=-%cpu | head -n 11 || true

echo ""
info "Top 10 Memory Consuming Processes:"
ps -eo pid,ppid,comm,%mem,%cpu --sort=-%mem | head -n 11 || true

hr

# 2. Service status check & auto-restart
SERVICES=("sshd" "cron" "rsyslog" "networking")
MAX_RETRIES=2
STATE_DIR="/var/tmp/lab-service-monitor"
mkdir -p "${STATE_DIR}"

info "Checking key services..."
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "${svc}" 2>/dev/null; then
        info "Service ${svc} is ACTIVE"
        # Reset fail count if it was failing before
        rm -f "${STATE_DIR}/${svc}.fails"
    else
        warn "Service ${svc} is INACTIVE or FAILED"
        
        # Track failures
        fails=0
        if [[ -f "${STATE_DIR}/${svc}.fails" ]]; then
            fails=$(cat "${STATE_DIR}/${svc}.fails")
        fi
        
        fails=$((fails + 1))
        echo "${fails}" > "${STATE_DIR}/${svc}.fails"
        
        if [[ ${fails} -gt ${MAX_RETRIES} ]]; then
            error "ALERT: Service ${svc} has been down for ${fails} consecutive checks! Manual intervention required."
            # Simulate sending an alert email
            info "-> Sent alert mail to root@localhost"
        else
            info "Attempting to restart ${svc} (Attempt ${fails}/${MAX_RETRIES})..."
            if systemctl restart "${svc}" 2>/dev/null; then
                info "Successfully restarted ${svc}"
                rm -f "${STATE_DIR}/${svc}.fails"
            else
                error "Failed to restart ${svc}"
            fi
        fi
    fi
done

hr

# 3. Create a custom systemd unit file for a lab watchdog service
WATCHDOG_UNIT="/etc/systemd/system/lab-watchdog.service"
WATCHDOG_SCRIPT="/opt/lab/watchdog.sh"

if confirm "Do you want to install and enable the custom lab-watchdog systemd service?" "Y"; then
    info "Creating dummy watchdog script at ${WATCHDOG_SCRIPT}..."
    mkdir -p /opt/lab
    cat << 'EOF' > "${WATCHDOG_SCRIPT}"
#!/usr/bin/env bash
while true; do
    echo "[$(date)] Lab watchdog is alive..." >> /var/log/linux-admin-lab/watchdog.log
    sleep 60
done
EOF
    chmod +x "${WATCHDOG_SCRIPT}"
    
    info "Writing systemd unit to ${WATCHDOG_UNIT}..."
    cat << EOF > "${WATCHDOG_UNIT}"
[Unit]
Description=Lab Watchdog Service
After=network.target

[Service]
Type=simple
ExecStart=${WATCHDOG_SCRIPT}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    info "Reloading systemd daemon and enabling service..."
    systemctl daemon-reload || true
    systemctl enable --now lab-watchdog.service || true
    info "lab-watchdog.service installed."
else
    info "Skipping watchdog service installation."
fi

info "Process & Service Monitor complete."
