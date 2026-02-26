#!/usr/bin/env fish
# WAN connectivity watchdog
# Pings multiple targets; if ALL fail for N consecutive checks, bounces WAN DHCP
# Uses a state file to track consecutive failures across invocations

set -l WAN_IFACE "$argv[1]"
set -l FAIL_THRESHOLD "$argv[2]"
# Remaining args are ping targets
set -l TARGETS $argv[3..-1]

if test -z "$WAN_IFACE" -o -z "$FAIL_THRESHOLD" -o (count $TARGETS) -eq 0
    echo "Usage: wan-watchdog.fish <wan_iface> <fail_threshold> <target1> [target2] ..."
    exit 1
end

set -l STATE_FILE "/run/wan-watchdog/failures"

# Ensure state dir exists
mkdir -p /run/wan-watchdog

# Read current failure count
set -l failures 0
if test -f $STATE_FILE
    set failures (cat $STATE_FILE)
end

# Test connectivity — success if ANY target responds
set -l reachable false
for target in $TARGETS
    if ping -c 2 -W 3 -I $WAN_IFACE $target &>/dev/null
        set reachable true
        break
    end
end

if test "$reachable" = true
    # Reset counter on success
    if test $failures -gt 0
        echo "WAN reachable (was at $failures consecutive failures), resetting counter"
    end
    echo 0 >$STATE_FILE
    exit 0
end

# All targets unreachable
set failures (math $failures + 1)
echo $failures >$STATE_FILE
echo "WAN unreachable ($failures/$FAIL_THRESHOLD consecutive failures)"

if test $failures -ge $FAIL_THRESHOLD
    echo "Threshold reached — bouncing DHCP on $WAN_IFACE"
    networkctl renew $WAN_IFACE 2>&1
    # If renew doesn't help, reconfigure the interface
    if not ping -c 2 -W 5 $TARGETS[1] &>/dev/null
        echo "Renew insufficient — reconfiguring $WAN_IFACE"
        networkctl reconfigure $WAN_IFACE 2>&1
    end
    echo 0 >$STATE_FILE
end
