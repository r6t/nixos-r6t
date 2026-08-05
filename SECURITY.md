# Security Policy

This repository is a public NixOS flake for personal infrastructure. Treat all
committed content as public, reusable reference material.

## Reporting Security Issues

Report security issues privately. Do not open a public issue with exploit steps,
active secrets, private infrastructure details, or proof-of-compromise data.

Use GitHub private vulnerability reporting if it is enabled for this repository.
If it is not enabled, contact the repository owner through a private channel
already known to you and include only the minimum detail needed to establish
impact.

Useful reports include:

- Affected file paths and line numbers.
- The exposed asset, privilege, or trust boundary.
- Whether the issue is exploitable from the public internet, LAN, tailnet, local
  account, container, or build environment.
- A minimal reproduction or reasoning path.
- Suggested mitigations, if known.

## Public Repository Threat Model

The following are not automatically security issues in this repository:

- Public hostnames, domains, local IP addresses, and local mount paths.
- Public SSH keys and GitHub public key URLs.
- Placeholder secrets in examples.
- References to secret file paths under `/run/secrets`, SOPS-managed locations,
  or host-local encrypted storage.
- Hardware UUIDs, PCI paths, and similar inventory data, unless they create a
  concrete exploit path.

The following are security-sensitive and should not be committed unless they are
intentional, reviewed, and documented:

- Plaintext secrets, private keys, auth tokens, API keys, cookies, session files,
  recovery codes, or seed phrases.
- Password hashes for remotely reachable services.
- Reusable enrollment keys or bootstrap tokens, especially if a compromised
  machine could use them to join a private network.
- Public reverse-proxy routes to services without authentication, authorization,
  rate limits, or a clear public-use threat model.
- Writable host mounts into containers that expose broad source trees, media
  libraries, backups, or application configuration.
- Mutable container images or external artifacts used in privileged or public
  services without a pinning and update strategy.

## Configuration Review Checklist

Before merging infrastructure changes, review these trust boundaries:

- Secrets are stored outside git, encrypted, or referenced by path only.
- Public routes require application auth, route-level auth, mTLS, IP allowlists,
  tailnet-only access, or an explicit decision that anonymous access is safe.
- Monitoring, metrics, logs, admin UIs, model APIs, file converters, and proxy-like
  tools are not exposed anonymously by accident.
- Firewalls allow the minimum required ports per interface. Avoid broad trusted
  interfaces unless the upstream ACL boundary is intentionally relied upon.
- Containers bind host proxy devices to `127.0.0.1` when only the host reverse
  proxy needs access.
- Container mounts are read-only unless write access is required. Writable mounts
  are scoped to the smallest practical host path.
- Container nesting, GPU passthrough, host networking, Docker-in-LXC, and other
  isolation relaxations are enabled only for workloads that need them.
- Tailscale and other enrollment keys are short-lived, tagged, least-privilege,
  mounted read-only, and rotated after suspected exposure.
- NFS, SMB, SSH, Incus, and admin APIs are restricted to specific clients or
  management networks where possible.
- Logs are written with restrictive permissions and rotated safely because logs
  can contain tokens, URLs, headers, and personal data.
- External images, package sources, and plugins are pinned or otherwise reviewed
  before deployment.

## Incident Response

If a secret or credential may have been committed or exposed:

- Revoke or rotate it first. Removing it from git is not sufficient.
- Audit live systems for use of the old credential.
- Replace shared credentials with per-service or per-host credentials where
  possible.
- Review logs for unauthorized use during the exposure window.
- Document the root cause and the prevention added afterward.

If a public service may have been unintentionally exposed:

- Remove the public route or restrict access first.
- Check service logs, reverse-proxy logs, and application state for abuse.
- Rotate credentials that may have appeared in logs or application data.
- Add a regression check or checklist item so the exposure pattern is not
  repeated.

## Maintenance Expectations

Security review is part of normal infrastructure maintenance. Periodically audit
public routes, tailnet ACL assumptions, container mounts, service authentication,
and secret references. Prefer small, explicit configuration over broad reusable
defaults when crossing trust boundaries.
