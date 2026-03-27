# Linux Admin Lab Report

## Overview
This report breaks down how I built my Linux Administration Lab, the problems I solved along the way, and some findings from testing the scripts. I wanted to create a hands-on way to practice user management, network auditing, service monitoring, and storage auditing in Bash.

## Environment
- **OS:** Mostly tested on Ubuntu 22.04 and Debian, though the commands are pretty standard.
- **Shell:** Bash (I used `set -euo pipefail` everywhere to catch bugs early)
- **Privileges:** `root` or `sudo` is required for almost everything, since we are doing admin tasks.
- **Tools used:** `iptables`/`ufw`, `ss`/`netstat`, `setfacl`, `visudo`, `chage`, and `lvm2`.

## What I wanted to achieve
1. Set up secure, role-based access for different types of users.
2. Figure out what ports are open and lock the system down with a basic firewall.
3. Keep an eye on system services and automatically restart them if they crash.
4. Check disk usage and automate some simple config backups.

## Modules & Testing

### Module 01: User Permissions
I built `01-user-permissions/setup_users.sh` to get some practice with the principle of least privilege.
```bash
$ sudo ./01-user-permissions/setup_users.sh
[INFO] Creating groups: developers, ops, readonly...
[INFO] Created user alice in group developers (Password forced change)
[INFO] Applying POSIX ACLs...
[INFO] Successfully installed sudoers rules to /etc/sudoers.d/lab-roles
```

### Module 02: Networking and Firewalls
My `02-networking-firewalls/firewall_audit.sh` script figures out which firewall daemon is running and lists out the open connections.
```bash
$ sudo ./02-networking-firewalls/firewall_audit.sh
[INFO] Detected Firewall: iptables
[WARN] WARNING: Applying a baseline ruleset will OVERWRITE existing firewall rules.
Do you want to apply the baseline firewall ruleset? [y/N] y
[INFO] iptables baseline applied successfully.
```

### Module 03: Process and Service Management
I wrote `03-process-service-mgmt/service_monitor.sh` to track which processes are eating up the CPU and memory, and to blindly restart any missing services.
```bash
$ sudo ./03-process-service-mgmt/service_monitor.sh
[INFO] Top 10 CPU Consuming Processes:
  PID  PPID COMMAND         %MEM %CPU
    1     0 systemd          0.1  0.0
[WARN] Service sshd is INACTIVE or FAILED
[INFO] Attempting to restart sshd (Attempt 1/2)...
[INFO] Successfully restarted sshd
```

### Module 04: Filesystem and Storage
Finally, `04-filesystem-storage/disk_audit.sh` backs up the `/etc` directory to a tarball and checks LVM statuses.
```bash
$ sudo ./04-filesystem-storage/disk_audit.sh
[INFO] Disk Usage (df -h):
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G   15G  4.0G  79% /
[INFO] Creating backup of /etc to /opt/lab/backups/etc_backup_20260327_120000.tar.gz...
[INFO] Backup created successfully
```

## Things I learned
- Sticking to native tools (`df`, `du`, `ss`) instead of installing extra packages makes the scripts way more reliable and portable across different distros.
- Using `set -euo pipefail` is great for catching typos and missing variables, but it's annoying when commands like `grep` return a non-zero exit code because they didn't find a match. I had to use `|| true` in a few places to stop the script from blowing up unnecessarily.

## How I'd improve this later (Hardening)
1. **Firewall:** Move from basic `iptables` commands to a proper zone-based setup using `firewalld` or `nftables`.
2. **Users:** Instead of creating local users, I'd connect the server to LDAP or Active Directory.
3. **Tracking:** Use `auditd` at the kernel level to properly log file accesses instead of just relying on `setfacl` permissions.
