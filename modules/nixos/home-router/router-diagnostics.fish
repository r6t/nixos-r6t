#!/usr/bin/env fish
# Comprehensive router diagnostics script
# Covers: interfaces, routing, NAT, DNS, DHCP, CAKE QoS, services, connectivity

set -l WAN_IFACE "$argv[1]"
set -l LAN_IFACE "$argv[2]"
set -l LAN_ADDR "$argv[3]"

if test -z "$WAN_IFACE" -o -z "$LAN_IFACE" -o -z "$LAN_ADDR"
    echo "Usage: router-diagnostics.fish <wan_iface> <lan_iface> <lan_addr>"
    echo "Example: router-diagnostics.fish enp101s0 enp100s0 192.168.6.1/24"
    exit 1
end

set -l LAN_IP (string split "/" $LAN_ADDR)[1]
set -l IFB_IFACE "ifb4$WAN_IFACE"

set -l BOLD (tput bold 2>/dev/null; or echo "")
set -l NORMAL (tput sgr0 2>/dev/null; or echo "")
set -l GREEN (tput setaf 2 2>/dev/null; or echo "")
set -l YELLOW (tput setaf 3 2>/dev/null; or echo "")
set -l RED (tput setaf 1 2>/dev/null; or echo "")
set -l BLUE (tput setaf 4 2>/dev/null; or echo "")

set -l pass_count 0
set -l fail_count 0
set -l warn_count 0

function section
    echo
    echo "$BOLD$BLUE━━━ $argv[1] ━━━$NORMAL"
end

function pass
    set pass_count (math $pass_count + 1)
    echo "  $GREEN✓$NORMAL $argv[1]"
end

function fail
    set fail_count (math $fail_count + 1)
    echo "  $RED✗$NORMAL $argv[1]"
end

function warn
    set warn_count (math $warn_count + 1)
    echo "  $YELLOW⚠$NORMAL $argv[1]"
end

function detail
    echo "    $argv[1]"
end

# --- Header ---
echo "$BOLD══════════════════════════════════════════════════$NORMAL"
echo "$BOLD  Router Diagnostics — "(date +"%Y-%m-%d %H:%M:%S")"$NORMAL"
echo "$BOLD══════════════════════════════════════════════════$NORMAL"

# --- 1. Interface Status ---
section "Interfaces"

# WAN
if ip link show $WAN_IFACE &>/dev/null
    set -l wan_state (ip -br link show $WAN_IFACE | awk '{print $2}')
    set -l wan_ip (ip -4 -br addr show $WAN_IFACE | awk '{print $3}')
    if test "$wan_state" = UP
        if test -n "$wan_ip"
            pass "WAN ($WAN_IFACE): $wan_state — $wan_ip"
        else
            fail "WAN ($WAN_IFACE): UP but no IPv4 address (DHCP issue?)"
        end
    else
        fail "WAN ($WAN_IFACE): $wan_state"
    end
    ethtool $WAN_IFACE 2>/dev/null | grep -E "Speed:|Link detected:" | while read -l line
        detail (string trim $line)
    end
else
    fail "WAN interface $WAN_IFACE not found"
end

# LAN
if ip link show $LAN_IFACE &>/dev/null
    set -l lan_state (ip -br link show $LAN_IFACE | awk '{print $2}')
    set -l lan_ip_actual (ip -4 -br addr show $LAN_IFACE | awk '{print $3}')
    if test "$lan_state" = UP
        if echo "$lan_ip_actual" | grep -q "$LAN_IP"
            pass "LAN ($LAN_IFACE): $lan_state — $lan_ip_actual"
        else
            warn "LAN ($LAN_IFACE): UP but IP is $lan_ip_actual (expected $LAN_ADDR)"
        end
    else
        # ConfigureWithoutCarrier means this can be UP without link
        warn "LAN ($LAN_IFACE): $lan_state"
    end
else
    fail "LAN interface $LAN_IFACE not found"
end

# IFB (CAKE ingress)
if ip link show $IFB_IFACE &>/dev/null
    set -l ifb_state (ip -br link show $IFB_IFACE | awk '{print $2}')
    if test "$ifb_state" = UP
        pass "IFB ($IFB_IFACE): $ifb_state"
    else
        warn "IFB ($IFB_IFACE): $ifb_state"
    end
else
    warn "IFB interface $IFB_IFACE not found (CAKE ingress not configured?)"
end

# --- 2. Routing ---
section "Routing"

# IP forwarding
set -l fwd (cat /proc/sys/net/ipv4/ip_forward)
if test "$fwd" = "1"
    pass "IPv4 forwarding enabled"
else
    fail "IPv4 forwarding DISABLED"
end

# Default route
set -l default_route (ip route show default 2>/dev/null)
if test -n "$default_route"
    if echo "$default_route" | grep -q "$WAN_IFACE"
        pass "Default route via $WAN_IFACE"
        detail "$default_route"
    else
        warn "Default route exists but not via $WAN_IFACE"
        detail "$default_route"
    end
else
    fail "No default route"
end

# --- 3. NAT / nftables ---
section "NAT / Firewall"

set -l nft_ruleset (sudo nft list ruleset 2>/dev/null)
if test -n "$nft_ruleset"
    # Check masquerade
    if echo "$nft_ruleset" | grep -q "masquerade"
        pass "NAT masquerade rule present"
    else
        fail "NAT masquerade rule MISSING"
    end

    # Check forward chain
    if echo "$nft_ruleset" | grep -q "chain forward"
        pass "Forward chain present"
        # Check LAN->WAN forwarding
        if echo "$nft_ruleset" | grep -q "$LAN_IFACE.*$WAN_IFACE.*accept"
            pass "LAN→WAN forwarding rule present"
        else
            warn "LAN→WAN forwarding rule not found (check nftables config)"
        end
    else
        fail "Forward chain MISSING"
    end

    # Check input chain policy
    if echo "$nft_ruleset" | grep -q "chain input.*policy drop"
        pass "Input chain policy: drop (good)"
    else
        warn "Input chain may not have drop policy"
    end
else
    fail "Cannot read nftables ruleset (need root?)"
end

# --- 4. DNS ---
section "DNS"

# dnsmasq service
if systemctl is-active dnsmasq &>/dev/null
    pass "dnsmasq service running"
else
    fail "dnsmasq service NOT running"
end

# nextdns service
if systemctl is-active nextdns &>/dev/null
    pass "nextdns service running"
else
    warn "nextdns service not running"
end

# Local DNS resolution
set -l dns_result (dig +short +timeout=5 @127.0.0.1 nixos.org 2>/dev/null)
if test -z "$dns_result"
    set dns_result (dig +short +timeout=5 @127.0.0.1 nextdns.io 2>/dev/null)
end
if test -n "$dns_result"
    pass "Local DNS resolution working ($dns_result)"
else
    fail "Local DNS resolution FAILED"
end

# LAN-facing DNS
set -l lan_dns_result (dig +short +timeout=5 @$LAN_IP nixos.org 2>/dev/null)
if test -z "$lan_dns_result"
    set lan_dns_result (dig +short +timeout=5 @$LAN_IP nextdns.io 2>/dev/null)
end
if test -n "$lan_dns_result"
    pass "LAN DNS resolution working ($LAN_IP → $lan_dns_result)"
else
    fail "LAN DNS resolution FAILED (clients can't resolve)"
end

# --- 5. DHCP ---
section "DHCP"

if networkctl status $LAN_IFACE 2>/dev/null | grep -qi "DHCPServer"
    pass "DHCP server active on $LAN_IFACE"
else
    warn "DHCP server status unclear on $LAN_IFACE"
end

# --- 6. CAKE QoS ---
section "CAKE QoS"

# Egress
if systemctl is-active cake-qos-egress &>/dev/null
    if tc qdisc show dev $WAN_IFACE 2>/dev/null | grep -q "cake"
        set -l bw (tc qdisc show dev $WAN_IFACE 2>/dev/null | grep -o 'bandwidth [^ ]*' | awk '{print $2}')
        pass "CAKE egress active on $WAN_IFACE ($bw)"
    else
        warn "cake-qos-egress service running but no CAKE qdisc on $WAN_IFACE"
    end
else
    warn "cake-qos-egress service not running"
end

# Ingress
if systemctl is-active cake-qos-ingress &>/dev/null
    if test -e /sys/class/net/$IFB_IFACE; and tc qdisc show dev $IFB_IFACE 2>/dev/null | grep -q "cake"
        set -l bw (tc qdisc show dev $IFB_IFACE 2>/dev/null | grep -o 'bandwidth [^ ]*' | awk '{print $2}')
        pass "CAKE ingress active on $IFB_IFACE ($bw)"
    else
        warn "cake-qos-ingress service running but no CAKE qdisc on $IFB_IFACE"
    end
else
    warn "cake-qos-ingress service not running"
end

# CAKE stats summary
if tc -s qdisc show dev $WAN_IFACE 2>/dev/null | grep -q "cake"
    section "CAKE Egress Stats"
    tc -s qdisc show dev $WAN_IFACE 2>/dev/null | head -20
end
if test -e /sys/class/net/$IFB_IFACE; and tc -s qdisc show dev $IFB_IFACE 2>/dev/null | grep -q "cake"
    section "CAKE Ingress Stats"
    tc -s qdisc show dev $IFB_IFACE 2>/dev/null | head -20
end

# --- 7. Connectivity ---
section "Connectivity"

# ICMP to external
if ping -c 3 -W 3 1.1.1.1 &>/dev/null
    set -l latency (ping -c 3 -W 3 1.1.1.1 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    pass "External ICMP (1.1.1.1): avg ${latency}ms"
else
    fail "External ICMP to 1.1.1.1 FAILED"
end

# DNS-based external check
set -l ext_dns (dig +short +timeout=5 cloudflare.com 2>/dev/null)
if test -n "$ext_dns"
    pass "External DNS resolution (cloudflare.com → $ext_dns)"
else
    fail "External DNS resolution FAILED"
end

# --- 8. Key Services ---
section "Services"

for svc in dnsmasq nextdns systemd-networkd incus cake-qos-egress cake-qos-ingress
    set -l state (systemctl is-active $svc 2>/dev/null)
    switch $state
        case active
            pass "$svc: active"
        case inactive
            warn "$svc: inactive"
        case failed
            fail "$svc: FAILED"
        case '*'
            warn "$svc: $state"
    end
end

# --- 9. System ---
section "System"
detail "Uptime: "(uptime -p)
detail "Load: "(cat /proc/loadavg | awk '{print $1, $2, $3}')
detail "Memory: "(free -h | awk '/Mem:/{print $3 "/" $2 " used"}')
detail "Journal disk: "(journalctl --disk-usage 2>/dev/null | awk '{print $NF}')

set -l ct_count (cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null)
set -l ct_max (cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null)
if test -n "$ct_count" -a -n "$ct_max"
    set -l ct_pct (math "round($ct_count * 100 / $ct_max)")
    detail "Conntrack: $ct_count / $ct_max ($ct_pct%)"
    if test $ct_pct -ge 80
        warn "Conntrack table above 80% ($ct_pct%)"
    end
end

# --- Summary ---
echo
echo "$BOLD══════════════════════════════════════════════════$NORMAL"
echo "  $GREEN✓ $pass_count passed$NORMAL  $RED✗ $fail_count failed$NORMAL  $YELLOW⚠ $warn_count warnings$NORMAL"
echo "$BOLD══════════════════════════════════════════════════$NORMAL"

if test $fail_count -gt 0
    exit 1
end
