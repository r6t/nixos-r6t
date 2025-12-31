#!/usr/bin/env fish
# CAKE QoS Router Diagnostics Script
# Displays current CAKE statistics, interface stats, and network health

set -l BOLD (tput bold 2>/dev/null || echo "")
set -l NORMAL (tput sgr0 2>/dev/null || echo "")
set -l GREEN (tput setaf 2 2>/dev/null || echo "")
set -l YELLOW (tput setaf 3 2>/dev/null || echo "")
set -l RED (tput setaf 1 2>/dev/null || echo "")
set -l BLUE (tput setaf 4 2>/dev/null || echo "")

function section_header
    echo
    echo "$BOLD$BLUE━━━ $argv[1] ━━━$NORMAL"
    echo
end

function check_cake_active
    set -l iface $argv[1]
    if tc qdisc show dev $iface | grep -q "qdisc cake"
        return 0
    else
        return 1
    end
end

# Header
clear
echo "$BOLD╔═══════════════════════════════════════════════════════════╗$NORMAL"
echo "$BOLD║         CAKE QoS Router Diagnostics                      ║$NORMAL"
echo "$BOLD╚═══════════════════════════════════════════════════════════╝$NORMAL"

# WAN Interface Detection
section_header "WAN Interface Status"
set -l wan_interface enp101s0
echo "Interface: $wan_interface"
ip -br addr show $wan_interface 2>/dev/null || echo "${RED}Error: Interface not found$NORMAL"
ethtool $wan_interface 2>/dev/null | grep -E "Speed:|Duplex:|Link detected:" || echo "${YELLOW}No ethtool data available$NORMAL"

# CAKE Status - Egress (Upload)
section_header "CAKE Egress (Upload) Status"
if check_cake_active $wan_interface
    echo "${GREEN}✓ CAKE is ACTIVE on $wan_interface (egress/upload)$NORMAL"
    tc -s qdisc show dev $wan_interface
else
    echo "${RED}✗ CAKE is NOT active on $wan_interface$NORMAL"
    echo "Current qdisc:"
    tc qdisc show dev $wan_interface
end

# CAKE Status - Ingress (Download) via IFB
section_header "CAKE Ingress (Download) Status"
set -l ifb_interface "ifb4$wan_interface"
if ip link show $ifb_interface &>/dev/null
    if check_cake_active $ifb_interface
        echo "${GREEN}✓ CAKE is ACTIVE on $ifb_interface (ingress/download)$NORMAL"
        tc -s qdisc show dev $ifb_interface
    else
        echo "${RED}✗ IFB exists but CAKE is NOT active$NORMAL"
        tc qdisc show dev $ifb_interface
    end
else
    echo "${RED}✗ IFB interface $ifb_interface does not exist$NORMAL"
    echo "Ingress shaping is not configured"
end

# Network Performance Test
section_header "Network Latency Test"
echo "Testing latency to 1.1.1.1 (Cloudflare DNS)..."
ping -c 5 -i 0.2 1.1.1.1 2>&1 | tail -2

# Interface Statistics
section_header "WAN Interface Traffic Statistics"
ip -s link show $wan_interface 2>/dev/null | head -10

# System Load
section_header "System Load"
uptime

# Service Status
section_header "CAKE QoS Service Status"
systemctl status cake-qos-egress.service --no-pager -l | head -15
echo
systemctl status cake-qos-ingress.service --no-pager -l | head -15

# Tips
section_header "Quick Commands"
echo "  ${BOLD}Watch CAKE stats:$NORMAL       watch -n 1 'tc -s qdisc show dev $wan_interface'"
echo "  ${BOLD}Restart CAKE:$NORMAL           sudo systemctl restart cake-qos-egress cake-qos-ingress"
echo "  ${BOLD}Disable CAKE:$NORMAL           sudo systemctl stop cake-qos-egress cake-qos-ingress"
echo "  ${BOLD}Check bufferbloat:$NORMAL      Open https://www.waveform.com/tools/bufferbloat"
echo "  ${BOLD}Detailed stats:$NORMAL         tc -s -d qdisc show dev $wan_interface"
echo

echo "$BOLD════════════════════════════════════════════════════════════$NORMAL"
