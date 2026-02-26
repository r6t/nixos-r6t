#!/usr/bin/env fish
# Router health check — runs on a timer, logs structured results to journald
# Exit 0 = all checks pass, exit 1 = at least one critical failure

set -l WAN_IFACE "$argv[1]"
set -l LAN_IFACE "$argv[2]"
set -l LAN_ADDR "$argv[3]"

if test -z "$WAN_IFACE" -o -z "$LAN_IFACE" -o -z "$LAN_ADDR"
    echo "Usage: router-health-check.fish <wan_iface> <lan_iface> <lan_addr>"
    exit 1
end

set -l LAN_IP (string split "/" $LAN_ADDR)[1]
set -l IFB_IFACE "ifb4$WAN_IFACE"
set -l failures 0
set -l warnings 0

function check_critical
    set -l name $argv[1]
    set -l result $argv[2]
    if test "$result" = "0"
        echo "PASS: $name"
    else
        echo "FAIL: $name"
        set failures (math $failures + 1)
    end
end

function check_warn
    set -l name $argv[1]
    set -l result $argv[2]
    if test "$result" = "0"
        echo "PASS: $name"
    else
        echo "WARN: $name"
        set warnings (math $warnings + 1)
    end
end

# WAN interface has IP
ip -4 addr show $WAN_IFACE 2>/dev/null | grep -q "inet "
check_critical "wan_has_ip ($WAN_IFACE)" $status

# LAN interface has correct IP
ip -4 addr show $LAN_IFACE 2>/dev/null | grep -q "$LAN_IP"
check_critical "lan_has_ip ($LAN_IFACE=$LAN_IP)" $status

# IP forwarding
test (cat /proc/sys/net/ipv4/ip_forward) = "1"
check_critical "ipv4_forwarding" $status

# Default route via WAN
ip route show default 2>/dev/null | grep -q "$WAN_IFACE"
check_critical "default_route_via_wan" $status

# NAT masquerade loaded
nft list ruleset 2>/dev/null | grep -q "masquerade"
check_critical "nat_masquerade" $status

# Forward chain exists
nft list ruleset 2>/dev/null | grep -q "chain forward"
check_critical "forward_chain" $status

# dnsmasq running
systemctl is-active dnsmasq &>/dev/null
check_critical "dnsmasq_active" $status

# Local DNS resolution
dig +short +timeout=5 @127.0.0.1 nixos.org &>/dev/null
or dig +short +timeout=5 @127.0.0.1 nextdns.io &>/dev/null
check_critical "dns_local_resolution" $status

# LAN-facing DNS
dig +short +timeout=5 @$LAN_IP nixos.org &>/dev/null
or dig +short +timeout=5 @$LAN_IP nextdns.io &>/dev/null
check_critical "dns_lan_resolution" $status

# External ICMP
ping -c 2 -W 5 1.1.1.1 &>/dev/null
check_critical "external_icmp" $status

# External DNS (full path validation)
dig +short +timeout=5 cloudflare.com &>/dev/null
check_critical "external_dns_resolution" $status

# NextDNS
systemctl is-active nextdns &>/dev/null
check_warn "nextdns_active" $status

# CAKE egress
systemctl is-active cake-qos-egress &>/dev/null
check_warn "cake_egress_active" $status

# CAKE ingress
systemctl is-active cake-qos-ingress &>/dev/null
check_warn "cake_ingress_active" $status

# CAKE qdisc on WAN
tc qdisc show dev $WAN_IFACE 2>/dev/null | grep -q "cake"
check_warn "cake_qdisc_wan" $status

# CAKE qdisc on IFB
test -e /sys/class/net/$IFB_IFACE; and tc qdisc show dev $IFB_IFACE 2>/dev/null | grep -q "cake"
check_warn "cake_qdisc_ifb" $status

# Incus
systemctl is-active incus &>/dev/null
check_warn "incus_active" $status

# DHCP server
networkctl status $LAN_IFACE 2>/dev/null | grep -qi "DHCPServer"
check_warn "dhcp_server" $status

# Conntrack table usage
set -l ct_count (cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null)
set -l ct_max (cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null)
if test -n "$ct_count" -a -n "$ct_max"
    set -l ct_pct (math "round($ct_count * 100 / $ct_max)")
    echo "INFO: conntrack=$ct_count/$ct_max ($ct_pct%)"
    if test $ct_pct -ge 80
        check_warn "conntrack_usage ($ct_pct%)" 1
    end
end

# Summary
echo "SUMMARY: failures=$failures warnings=$warnings"

if test $failures -gt 0
    exit 1
end
