#!/usr/bin/env bash
# utils/common.sh
# Shared utility functions for the Linux Administration Lab Project

# Strict mode: exit on error, undefined vars, or pipeline failures

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Logging Configuration
LOG_DIR="/var/log/linux-admin-lab"
LOG_FILE="${LOG_DIR}/lab.log"

# Try to create log directory (fails silently if we aren't root)
mkdir -p "${LOG_DIR}" 2>/dev/null || true
touch "${LOG_FILE}" 2>/dev/null || true

# Helper: Timestamp
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Base logger
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local ts
    ts=$(timestamp)
    
    # Print to stdout/stderr with color
    if [[ "${level}" == "ERROR" ]]; then
        echo -e "${color}[${ts}] [${level}] ${message}${NC}" >&2
    else
        echo -e "${color}[${ts}] [${level}] ${message}${NC}"
    fi

    # Log to file, stripping ANSI color codes
    if [[ -w "${LOG_FILE}" ]]; then
        echo "[${ts}] [${level}] ${message}" >> "${LOG_FILE}"
    fi
}

info() {
    _log "INFO" "${GREEN}" "$1"
}

warn() {
    _log "WARN" "${YELLOW}" "$1"
}

error() {
    _log "ERROR" "${RED}" "$1"
}

section() {
    local msg="$1"
    echo -e "\n${CYAN}======================================================================${NC}"
    echo -e "${CYAN}:: ${msg} ::${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    
    if [[ -w "${LOG_FILE}" ]]; then
        echo "======================================================================" >> "${LOG_FILE}"
        echo ":: ${msg} ::" >> "${LOG_FILE}"
        echo "======================================================================" >> "${LOG_FILE}"
    fi
}

hr() {
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "This script must be run as root (or via sudo)."
        exit 1
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        error "Required command not found: ${cmd}. Please install it."
        exit 1
    fi
}

confirm() {
    local prompt="$1"
    local default="${2:-N}"
    local prompt_suffix

    if [[ "${default}" == "Y" || "${default}" == "y" ]]; then
        prompt_suffix="[Y/n]"
    else
        prompt_suffix="[y/N]"
    fi

    echo -ne "${YELLOW}${prompt} ${prompt_suffix} ${NC}"
    read -r response

    if [[ -z "${response}" ]]; then
        response="${default}"
    fi

    case "${response}" in
        [yY][eE][sS]|[yY]) 
            return 0 
            ;;
        *) 
            return 1 
            ;;
    esac
}
