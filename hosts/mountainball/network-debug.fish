#!/usr/bin/env fish
# Network Hang Diagnostics Script
# Run this when you experience network freezes/hangs to capture diagnostic data

set -l BOLD (tput bold 2>/dev/null || echo "")
set -l NORMAL (tput sgr0 2>/dev/null || echo "")
set -l GREEN (tput setaf 2 2>/dev/null || echo "")
set -l YELLOW (tput setaf 3 2>/dev/null || echo "")
set -l RED (tput setaf 1 2>/dev/null || echo "")
set -l BLUE (tput setaf 4 2>/dev/null || echo "")

# Create timestamped log directory
set -l timestamp (date +%Y%m%d_%H%M%S)
set -l log_dir "/tmp/network-debug-$timestamp"
mkdir -p $log_dir

function section
    echo "$BOLD$BLUE━━━ $argv[1] ━━━$NORMAL"
end

function log_to_file
    set -l filename "$log_dir/$argv[1]"
    shift
    eval $argv > "$filename" 2>&1
    echo "${GREEN}✓${NORMAL} Captured: $filename"
end

clear
echo "$BOLD╔═══════════════════════════════════════════════════════════╗$NORMAL"
echo "$BOLD║         Network Hang Diagnostics                         ║$NORMAL"
echo "$BOLD║         Log Directory: $log_dir         ║$NORMAL"
echo "$BOLD╚═══════════════════════════════════════════════════════════╝$NORMAL"
echo

section "1. Timestamp & System State"
log_to_file "00-timestamp.txt" date
log_to_file "01-uptime.txt" uptime
log_to_file "02-load.txt" cat /proc/loadavg
echo

section "2. Network Connectivity Tests"
echo "Testing various endpoints..."
log_to_file "10-ping-gateway.txt" ping -c 5 -W 2 192.168.6.1
log_to_file "11-ping-cloudflare.txt" ping -c 5 -W 2 1.1.1.1
log_to_file "12-ping-google.txt" ping -c 5 -W 2 8.8.8.8
log_to_file "13-traceroute-cloudflare.txt" traceroute -m 10 -w 2 1.1.1.1
echo

section "3. DNS Resolution Tests"
echo "Testing DNS performance..."
log_to_file "20-dns-resolve-google.txt" time dig google.com
log_to_file "21-dns-resolve-cloudflare.txt" time dig cloudflare.com
log_to_file "22-dns-stats.txt" resolvectl statistics
log_to_file "23-dns-status.txt" resolvectl status
echo

section "4. Interface Statistics"
echo "Capturing interface state..."
log_to_file "30-ip-addr.txt" ip addr show
log_to_file "31-ip-route.txt" ip route show
log_to_file "32-ip-link-stats.txt" ip -s link show
log_to_file "33-ethtool-stats.txt" bash -c 'for iface in (ip -o link show | awk -F: \'{print $2}\' | tr -d \' \'); do echo "=== $iface ==="; ethtool -S $iface 2>&1; done'
echo

section "5. Connection State"
echo "Capturing connection table..."
log_to_file "40-ss-summary.txt" ss -s
log_to_file "41-ss-tcp.txt" ss -tpn
log_to_file "42-ss-udp.txt" ss -upn
log_to_file "43-netstat-stats.txt" netstat -s
echo

section "6. Network Queue State"
echo "Checking qdisc and traffic control..."
log_to_file "50-tc-qdisc.txt" tc qdisc show
log_to_file "51-tc-qdisc-stats.txt" tc -s qdisc show
echo

section "7. System Journal (Last 100 Network-Related Lines)"
echo "Extracting recent network errors..."
log_to_file "60-journal-network.txt" journalctl -n 100 --no-pager -p warning -u NetworkManager -u systemd-networkd -u systemd-resolved
log_to_file "61-journal-kernel-net.txt" journalctl -n 100 --no-pager -k | grep -iE 'network|link|ethernet|wifi'
echo

section "8. NetworkManager State"
if systemctl is-active --quiet NetworkManager
    log_to_file "70-nmcli-general.txt" nmcli general status
    log_to_file "71-nmcli-device.txt" nmcli device status
    log_to_file "72-nmcli-connection.txt" nmcli connection show
else
    echo "${YELLOW}NetworkManager not active${NORMAL}"
end
echo

section "9. Router Connectivity (if reachable)"
if ping -c 1 -W 1 192.168.6.1 &>/dev/null
    echo "Router is reachable, gathering remote stats..."
    log_to_file "80-router-cake-egress.txt" ssh 192.168.6.1 'tc -s qdisc show dev enp101s0'
    log_to_file "81-router-cake-ingress.txt" ssh 192.168.6.1 'tc -s qdisc show dev ifb4enp101s0 2>/dev/null || echo "IFB not found"'
    log_to_file "82-router-interface-stats.txt" ssh 192.168.6.1 'ip -s link show enp101s0'
    log_to_file "83-router-journal.txt" ssh 192.168.6.1 'journalctl -n 50 --no-pager -p warning'
else
    echo "${RED}✗ Router not reachable${NORMAL}"
    log_to_file "80-router-unreachable.txt" echo "Router 192.168.6.1 not reachable at this time"
end
echo

section "10. Memory & CPU State"
log_to_file "90-memory.txt" free -h
log_to_file "91-cpu-usage.txt" top -b -n 1 | head -20
echo

section "Summary"
echo
echo "Diagnostic data captured to: $BOLD$log_dir$NORMAL"
echo
echo "File summary:"
ls -lh $log_dir | tail -n +2
echo
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$NORMAL"
echo
echo "Quick analysis tips:"
echo "  ${BOLD}Check ping results:$NORMAL         grep 'rtt\|loss' $log_dir/1*ping*.txt"
echo "  ${BOLD}DNS resolution time:$NORMAL        grep 'Query time' $log_dir/2*dns*.txt"
echo "  ${BOLD}Interface errors:$NORMAL           grep -E 'error|drop' $log_dir/3*.txt"
echo "  ${BOLD}Recent kernel issues:$NORMAL       cat $log_dir/61-journal-kernel-net.txt"
echo "  ${BOLD}Connection state:$NORMAL           cat $log_dir/40-ss-summary.txt"
echo
echo "To save these logs permanently:"
echo "  ${YELLOW}cp -r $log_dir ~/network-hangs/${NORMAL}"
echo
