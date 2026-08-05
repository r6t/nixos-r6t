# Pinchflat LXC Migration

Pinchflat now runs as a NixOS Incus LXC on `crown`.

- Image: `containers/pinchflat.nix`
- Profile: `hosts/crown/incus-instances/pinchflat.yaml`
- Address: `192.168.6.107/24`
- Gateway: `192.168.6.5` (`mv-vancouver`)
- Web UI: `https://pinchflat.r6t.io`
- State: `/mnt/crownstore/app-storage/pinchflat` -> `/var/lib/pinchflat`
- YouTube media: `/mnt/thunderbay/8TB-D/storage/plex/youtube` -> same absolute path in the LXC
- Runtime identity files: `/mnt/crownstore/config/pinchflat/identity` -> `/run/pinchflat-identity` read-only

`/run/pinchflat-identity/cookies.txt` may hold a Netscape-format YouTube cookie file. It is linked to Pinchflat's `/var/lib/pinchflat/extras/cookies.txt` at service start if readable. `base-config.txt` in the same identity directory may hold sensitive `yt-dlp` base options such as extractor args or visitor-data values; do not put PO tokens or account credentials in Git.

Caddy serves `pinchflat.r6t.io` through crown, but the Incus proxy only listens on crown loopback and the route returns `403` for non-tailnet source addresses. It is intended for tailnet access only through crown.

The LXC does not join the tailnet and does not run SSH. Shell access is through Incus from `crown`, for example `incus exec pinchflat -- fish`.

## Prepare Crown Paths

Run on `crown` before launching the LXC:

```fish
sudo install -d -o 1000 -g 100 -m 0750 /mnt/crownstore/app-storage/pinchflat
sudo install -d -o 1000 -g 100 -m 0750 /mnt/crownstore/config/pinchflat/identity
sudo install -o 1000 -g 100 -m 0400 /dev/null /mnt/crownstore/config/pinchflat/identity/cookies.txt
```

Only create `base-config.txt` if you need mutable global `yt-dlp` options:

```fish
sudo install -o 1000 -g 100 -m 0400 /dev/null /mnt/crownstore/config/pinchflat/identity/base-config.txt
```

## Migrate State

Application data is the Pinchflat state directory, including `db`, `metadata`, `extras`, `logs`, and `tmp`. It belongs on persistent crownstore storage at `/mnt/crownstore/app-storage/pinchflat`.

Run on `mountainball`:

```fish
systemctl is-active pinchflat.service
sudo systemctl stop pinchflat.service
sudo tar --xattrs --acls -C /var/lib/pinchflat -cpf - . | ssh crown 'sudo tar --xattrs --acls --numeric-owner -C /mnt/crownstore/app-storage/pinchflat -xpf -'
ssh crown 'sudo chown -R 1000:100 /mnt/crownstore/app-storage/pinchflat; sudo chmod 0750 /mnt/crownstore/app-storage/pinchflat'
```

The new flake config removes Pinchflat from future `mountainball` generations, but that does not stop a manually started service in the current generation. Always stop the currently running unit before copying SQLite state.

The current Pinchflat media path on `mountainball` is the crown NFS export for `/mnt/thunderbay/8TB-D/storage/plex/youtube`. The LXC mounts that same crown path at the same absolute path, so media normally does not need copying. If `findmnt /mnt/thunderbay/8TB-D/storage/plex/youtube` does not show the crown NFS mount on `mountainball`, copy media manually before launching the LXC.

If the migrated state already has a non-empty `extras/cookies.txt` or `extras/yt-dlp-configs/base-config.txt`, the service pre-start hook leaves it in place instead of replacing it with the read-only identity mount. Move those files into `/mnt/crownstore/config/pinchflat/identity/` manually if you want the external identity path to own them.

## Launch

Git-backed flake commands ignore untracked files. Stage or commit the new Pinchflat container/profile/runbook files before running the flake-based image commands below.

Run on `crown` from the repo root:

```fish
sudo nixos-rebuild switch --flake .#crown
python3 containers/build.py pinchflat
python3 containers/relaunch.py pinchflat
```

Run on `mountainball` when ready to remove the local unit from the active host config:

```fish
sudo nixos-rebuild switch --flake .#mountainball
```

## Cookie Refresh

No proxy or SSH path is configured through the Pinchflat app LXC. Refresh cookies from a dedicated browser profile on `mountainball`, export a Netscape-format cookie file, and install it on `crown` without printing the contents.

If cookie refresh must use the exact `mv-vancouver` egress later, design that explicitly at the crown or exit-node layer. Do not add SSH, Tailscale, or proxy daemons to this app LXC for that purpose.

Install the refreshed cookie file on `crown`:

```fish
scp cookies.txt crown:/tmp/pinchflat-youtube-cookies.txt
ssh crown 'sudo install -o 1000 -g 100 -m 0400 /tmp/pinchflat-youtube-cookies.txt /mnt/crownstore/config/pinchflat/identity/cookies.txt; rm /tmp/pinchflat-youtube-cookies.txt'
```

If `cookies.txt` existed before `pinchflat.service` started, replacing it does not require a restart because Pinchflat reads the same symlink path. If the file did not exist when the service started, restart once:

```fish
incus exec pinchflat -- systemctl restart pinchflat.service
```

## Validate

Service and mounts:

```fish
incus exec pinchflat -- systemctl status pinchflat.service --no-pager
incus exec pinchflat -- findmnt /var/lib/pinchflat /mnt/thunderbay/8TB-D/storage/plex/youtube /run/pinchflat-identity
incus exec pinchflat -- stat -c '%U:%G %a %n' /var/lib/pinchflat /mnt/thunderbay/8TB-D/storage/plex/youtube /run/pinchflat-identity
```

Egress and gateway:

```fish
incus exec pinchflat -- ip route get 1.1.1.1
incus exec pinchflat -- curl -fsS4 https://am.i.mullvad.net/json
incus exec mv-vancouver -- curl -fsS4 https://am.i.mullvad.net/json
```

IPv6 check if a br1 IPv6 route is later configured:

```fish
incus exec pinchflat -- curl -fsS6 --max-time 10 https://am.i.mullvad.net/json
```

Kill-switch test, during a maintenance window because this affects other containers using `mv-vancouver`:

```fish
incus exec mv-vancouver -- systemctl stop wg-quick-wg0.service
incus exec pinchflat -- curl -fsS4 --max-time 10 https://am.i.mullvad.net/ip
incus exec mv-vancouver -- systemctl start wg-quick-wg0.service
```

The curl command should fail while `wg0` is down.

UI access from a tailnet client:

```fish
curl -I https://pinchflat.r6t.io
```

Direct LAN access to the container port should fail:

```fish
curl -I --max-time 5 http://192.168.6.107:8945
```

Cookie visibility without printing contents:

```fish
incus exec pinchflat -- sh -lc 'test -r /run/pinchflat-identity/cookies.txt && stat -c "%U:%G %a %s %n" /run/pinchflat-identity/cookies.txt /var/lib/pinchflat/extras/cookies.txt'
```

Harmless metadata test:

```fish
incus exec pinchflat -- sudo -u r6t yt-dlp --skip-download --print title 'https://www.youtube.com/watch?v=BaW_jenozKc'
```

## Rollback

Do not delete the old mountainball state. If the LXC fails before rebuilding mountainball, stop the LXC and restart the old unit:

```fish
incus stop pinchflat
sudo systemctl start pinchflat.service
```

If mountainball has already been rebuilt without the service, roll back or re-apply the previous host configuration before starting the old unit.
