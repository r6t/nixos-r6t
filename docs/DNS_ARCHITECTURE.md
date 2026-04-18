# DNS Architecture

This document describes the segmented DNS resolution patterns used across this flake to balance privacy, performance, and internal connectivity.

## Overview

The fleet follows a "local-first" resolution strategy. Every host and container runs a local DNS service to manage custom overrides and split-DNS routing.

## Patterns by Role

### 1. Physical Workstations (mountainball)

- **Primary Resolver**: Tailscale (`100.100.100.100`).
- **Secondary**: Systemd-resolved (fallback).
- **Behavior**: Direct, low-latency resolution of MagicDNS names and internet queries via Tailscale's optimized path to NextDNS.

### 2. The Router (saguaro)

- **Resolver**: `dnsmasq` -> `NextDNS-CLI` (port 5353).
- **Security**: Completely Tailscale-unaware for reliability.
- **Monitoring**: Uses a private `/etc/hosts` override for `loki.r6t.io` -> `192.168.6.10` for bootstrap log shipping. This override is NOT served to other LAN clients.

### 3. Tailscale App Containers (spire)

- **Imports**: `lib/base.nix`, `tailscale` module. (Does NOT import `mullvad-dns.nix`).
- **Path**: `App` -> `dnsmasq` -> `Tailscale` (`100.100.100.100`).
- **Benefits**: Fastest possible internal/external resolution. Short-names (`ssh crown`) work out-of-the-box via automatic `cloudforest-darter.ts.net` search domain injection.

### 4. Tailscale Exit Nodes (mv-\*)

- **Imports**: `lib/base.nix`, `lib/mullvad-dns.nix`, `tailscale` module.
- **Split-DNS Behavior**:
  - `*.ts.net` -> `100.100.100.100` (Tailscale neighbors)
  - `*` (everything else) -> `127.0.0.1#5353` (Mullvad DNS)
- **Benefits**: Preserves regional routing for client traffic while maintaining visibility of Tailscale neighbors.

### 5. "Dumb" LAN Containers (immich, miniflux)

- **Imports**: `lib/base.nix`, `lib/mullvad-dns.nix`.
- **Path**: `App` -> `dnsmasq` -> `Stubby` -> `Mullvad`.
- **Overrides**: Resolves `*.r6t.io` to `192.168.6.10` via the LAN short-circuit to reach PocketID and monitoring.

## Key Logic

- **Search Domains**: Managed centrally in `modules/nixos/tailscale/default.nix`. Containers with Tailscale enabled automatically receive `networking.search = [ "cloudforest-darter.ts.net" ];`.
- **DNS Isolation**: Containers set `resolv.conf` to `127.0.0.1` and use `--accept-dns=false` for Tailscale to prevent upstream settings from poisoning the `dnsmasq` pattern.
