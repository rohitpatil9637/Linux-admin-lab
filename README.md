# Linux Admin Lab

[![Shell Scripting](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat&logo=linux&logoColor=black)](https://www.kernel.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Overview
Welcome to my Linux Administration Lab! This is a collection of Bash scripts I put together to practice and demonstrate various Linux sysadmin tasks. The scripts cover some of the most common things you'd run into: managing users and permissions, auditing network and firewall rules, monitoring services, and keeping an eye on storage.

I built this mostly to automate routine tasks and practice writing clean, safe shell scripts (like using `set -euo pipefail`).

## Prerequisites
- A Linux environment (I tested this mostly on Ubuntu/Debian, but it can work on CentOS/RHEL too).
- `root` or `sudo` privileges, since a lot of the commands need it.

## Quick Start
clone the repo and run whatever module you're interested in:

```bash
git clone https://github.com/rohitpatil9637/Linux-admin-lab.git
cd linux-admin-lab

# Make the scripts executable
chmod +x **/*.sh

# Example: Run the user setup script
sudo ./01-user-permissions/setup_users.sh
```

## Modules
| Module | What it does |
| :--- | :--- |
| **01-User-Permissions** | Creates `ops`, `developers`, and `readonly` groups. Sets up specific users, creates shared folders with sticky bit / SetGID, applies POSIX ACLs, and drops a custom `sudoers` file. |
| **02-Networking-Firewalls** | Checks for `iptables` or `ufw`, lists open ports using `ss` or `netstat`, and lets you optionally enforce a strict baseline firewall (only allowing 22, 80, 443). |
| **03-Process-Service-Mgmt** | Finds processes hogging CPU/Memory using `ps`. Checks if essential services (like sshd) are running, restarts them if they fail, and sets up a dummy systemd watchdog service as an example. |
| **04-Filesystem-Storage** | Checks disk usage, looks for the largest directories, plays around with lvm commands (`pvs`, `vgs`, `lvs`), backs up `/etc` via tarball, and sets up `logrotate` for the lab logs. |

## Documentation
Check out the [Lab Report](docs/lab-report.md) for my notes on how everything works, things I noticed during testing, and ideas for further hardening the server.

## Directory Structure
```text
linux-admin-lab/
├── 01-user-permissions/
│   └── setup_users.sh
├── 02-networking-firewalls/
│   └── firewall_audit.sh
├── 03-process-service-mgmt/
│   └── service_monitor.sh
├── 04-filesystem-storage/
│   └── disk_audit.sh
├── docs/
│   └── lab-report.md
├── utils/
│   └── common.sh
└── README.md
```

## Security Warning
Just a heads up: some of these scripts (especially `firewall_audit.sh`) will make actual changes to your system if you let them. For example, it might drop your existing iptables rules or mess with `/etc/sudoers`. I added `[y/N]` confirmation prompts for anything destructive, but definitely don't run these on a production server without reviewing the code first!



by --- ROHIT PATIL
