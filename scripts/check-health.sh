#!/usr/bin/env bash
set -euo pipefail

# Define IP endpoints
WEB01="192.168.56.20:3000"
WEB02="192.168.56.21:3000"
LB01="192.168.56.10"
LB02="192.168.56.11"
VIP="192.168.56.100"

# Color formatting for readable terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}          Cluster Infrastructure Health Check             ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Helper function to check an HTTP endpoint
check_endpoint() {
    local target_name="$1"
    local url="$2"
    local expected_code="${3:-200}"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$url" || echo "000")

    if [ "$http_code" = "$expected_code" ]; then
        echo -e "  [+] ${target_name} (${url}) -> ${GREEN}HEALTHY (HTTP ${http_code})${NC}"
        return 0
    else
        echo -e "  [-] ${target_name} (${url}) -> ${RED}FAILED (HTTP ${http_code})${NC}"
        return 1
    fi
}

# 1. Test Backend Nodes Directly
echo -e "\n${YELLOW}[1/4] Checking Backend Web Applications (Port 3000)...${NC}"
check_endpoint "web-01 Application" "http://${WEB01}/" || true
check_endpoint "web-01 Health Route" "http://${WEB01}/health" || true
check_endpoint "web-02 Application" "http://${WEB02}/" || true
check_endpoint "web-02 Health Route" "http://${WEB02}/health" || true

# 2. Test Load Balancers Port 80 Directly
echo -e "\n${YELLOW}[2/4] Checking HAProxy Load Balancers (Port 80)...${NC}"
check_endpoint "lb-01 Primary LB" "http://${LB01}/" || true
check_endpoint "lb-02 Backup LB " "http://${LB02}/" || true

# 3. Test High Availability Virtual IP
echo -e "\n${YELLOW}[3/4] Checking Keepalived Virtual IP (VIP)...${NC}"
check_endpoint "Keepalived VIP  " "http://${VIP}/" || true

# 4. Test Round Robin Load Balancing via VIP
echo -e "\n${YELLOW}[4/4] Verifying Round Robin Alternation via VIP...${NC}"
echo "Sending 4 consecutive requests to http://${VIP}/ :"

SERVERS_SEEN=""
for i in {1..4}; do
    # Try reading from X-Server header first, fall back to grep in body
    SERVER_NAME=$(curl -sI --connect-timeout 2 "http://${VIP}/" | grep -i "^x-server:" | awk '{print $2}' | tr -d '\r' || true)
    
    if [ -z "$SERVER_NAME" ]; then
        SERVER_NAME=$(curl -s --connect-timeout 2 "http://${VIP}/" | grep -m 1 -ioE "web-01|web-02" || echo "Unknown")
    fi

    echo "  Request #${i} handled by -> ${SERVER_NAME}"
    SERVERS_SEEN="${SERVERS_SEEN} ${SERVER_NAME}"
    sleep 0.5
done

echo -e "\n${BLUE}==========================================================${NC}"
if echo "$SERVERS_SEEN" | grep -q "web-01" && echo "$SERVERS_SEEN" | grep -q "web-02"; then
    echo -e "${GREEN}✓ RESULT: Both backend nodes are actively receiving traffic!${NC}"
    echo -e "${GREEN}✓ High Availability & Round Robin are FUNCTIONAL.${NC}"
else
    echo -e "${YELLOW}! NOTICE: Only one server responded during the sample test.${NC}"
    echo -e "${YELLOW}! (Check if one backend is stopped or failover testing is active).${NC}"
fi
echo -e "${BLUE}==========================================================${NC}"