#!/usr/bin/env bash
set -euo pipefail

# Visual formatting
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}             SYSTEM DIAGNOSTIC & HEALTH REPORT            ${NC}"
echo -e "${CYAN}==========================================================${NC}"

# 1. Host & Uptime Information
echo -e "\n${YELLOW}--- [1] HOST & SYSTEM INFO ---${NC}"
echo "Hostname     : $(hostname)"
echo "Kernel       : $(uname -r)"
echo "Current Time : $(date)"
echo "System Uptime: $(uptime -p)"
echo "Load Average : $(uptime | awk -F'load average:' '{ print $2 }' | xargs)"

# 2. CPU & Memory Utilization
echo -e "\n${YELLOW}--- [2] MEMORY & RESOURCE UTILIZATION ---${NC}"
free -h
echo ""
echo "Top CPU Processes:"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 5

# 3. Disk Storage Capacity
echo -e "\n${YELLOW}--- [3] DISK CAPACITY ---${NC}"
df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs

# 4. Network Details & Floating VIP Status
echo -e "\n${YELLOW}--- [4] NETWORK CONFIGURATION ---${NC}"
echo "Active IPv4 Addresses:"
ip -4 -o addr show | awk '{print "  " $2 ": " $4}'

if ip -4 addr show | grep -q "192.168.56.100"; then
    echo -e "VIP Status   : ${GREEN}OWNED (192.168.56.100 is ACTIVE on this node)${NC}"
else
    echo -e "VIP Status   : NOT ASSIGNED (Standby or not configured)"
fi

# 5. Core Services Health Audit
echo -e "\n${YELLOW}--- [5] MANAGED SERVICES AUDIT ---${NC}"
CHECK_SERVICES=("next-app.service" "haproxy" "keepalived")

for SVC in "${CHECK_SERVICES[@]}"; do
    if systemctl list-unit-files "$SVC" &>/dev/null; then
        if systemctl is-active --quiet "$SVC"; then
            echo -e "  [+] $SVC : ${GREEN}ACTIVE (Running)${NC}"
        else
            echo -e "  [-] $SVC : ${RED}INACTIVE / FAILED${NC}"
        fi
    fi
done

# 6. Active Listening Ports
echo -e "\n${YELLOW}--- [6] ACTIVE LISTENING PORTS (TCP) ---${NC}"
sudo ss -tulpn | grep LISTEN | awk '{print "  Port: " $5 "\tProcess: " $7}'

echo -e "\n${CYAN}==========================================================${NC}"
echo -e "${CYAN}                 END OF SYSTEM REPORT                     ${NC}"
echo -e "${CYAN}==========================================================${NC}"