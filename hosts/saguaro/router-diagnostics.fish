#!/usr/bin/env fish
# Router diagnostics for saguaro
# Run this on saguaro when routing is broken

echo "=== ROUTER DIAGNOSTICS ==="
echo ""

echo "1. Interface Status:"
ip addr show enp100s0
ip addr show enp101s0
echo ""

echo "2. Routing Table:"
ip route
echo ""

echo "3. NAT/nftables Status:"
sudo nft list ruleset
echo ""

echo "4. DNS Status:"
systemctl status dnsmasq --no-pager
systemctl status nextdns --no-pager
echo ""

echo "5. DHCP Status:"
networkctl status enp100s0 | grep -i dhcp
echo ""

echo "6. Test DNS from router:"
dig @127.0.0.1 google.com +short
echo ""

echo "7. Test internet from router:"
ping -c 3 8.8.8.8
echo ""

echo "8. IP forwarding enabled:"
cat /proc/sys/net/ipv4/ip_forward
echo ""

echo "=== END DIAGNOSTICS ==="
