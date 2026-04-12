# Static DHCP reservations for saguaro's home-router module.
# This file is gitignored — MAC addresses are not committed to the public repo.
# Format: list of { MACAddress = "xx:xx:xx:xx:xx:xx"; Address = "192.168.6.x"; }
[
  { MACAddress = "f4:92:bf:8e:43:35"; Address = "192.168.6.8"; } # UniFi Alien WAP
  { MACAddress = "00:d0:2d:be:9f:4c"; Address = "192.168.6.9"; } # Honeywell thermostat
  { MACAddress = "c0:f5:35:c6:5f:d5"; Address = "192.168.6.90"; } # WiiM Amp
]
