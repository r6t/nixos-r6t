# Gitea Git Operations

This repository is public on GitHub and is also mirrored into a private Gitea
instance for local source storage.

GitHub remains the main upstream for `nixos-r6t`. Gitea is a primary internal
code store, but normal catch-up pulls should continue to come from GitHub unless
that policy changes deliberately.

## Repository Model

- `origin` fetches from GitHub.
- `origin` pushes to both GitHub and Gitea with multiple push URLs.
- Each development clone must be configured independently.
- Development hosts are `goldenball`, `mountainball`, and `crown`.

This keeps normal commands simple:

```fish
git pull
git push
```

`git pull` fetches from GitHub. `git push` sends the same refs to GitHub and
Gitea.

## Initial Gitea Import

Use Gitea's migration/import flow to import the repository from GitHub first.
After import, verify Gitea has the same default branch and current refs before
adding it as a push target from any development clone.

Do not start by pushing an unrelated empty Gitea repository over the imported
one. Let the import establish the matching history, then use normal pushes.

## Remote Configuration

Run this once in each local clone, replacing the Gitea URL with the actual
repository SSH URL shown by Gitea:

```fish
git remote set-url origin git@github.com:r6t/nixos-r6t.git

git remote set-url --push origin git@github.com:r6t/nixos-r6t.git
git remote set-url --add --push origin ssh://git@gitea.example/r6t/nixos-r6t.git

git remote -v
```

Expected shape:

```text
origin  git@github.com:r6t/nixos-r6t.git (fetch)
origin  git@github.com:r6t/nixos-r6t.git (push)
origin  ssh://git@gitea.example/r6t/nixos-r6t.git (push)
```

Once `remote.origin.pushurl` exists, Git uses only the configured push URLs for
pushes. That is why both GitHub and Gitea must be listed as push URLs.

## Optional Gitea Remote

An extra read remote is optional. It is useful for inspecting Gitea directly,
but it is not required for normal work.

```fish
git remote add gitea ssh://git@gitea.example/r6t/nixos-r6t.git
```

Keep `origin` fetching from GitHub unless Gitea is intentionally promoted to the
canonical upstream for this repository.

## Daily Workflow

Use the same commands from `goldenball`, `mountainball`, and `crown`:

```fish
git pull
git push
```

Before switching hosts, push finished work so the other stores and machines can
catch up from GitHub.

Avoid making direct edits in the Gitea web UI unless there is a deliberate plan
to reconcile those commits back through GitHub. Direct Gitea-only commits can
make the two stores diverge.

## Tags

Normal branch pushes do not necessarily push every tag. When tags should exist
in both stores, push them explicitly:

```fish
git push --tags
```

## Failure Handling

Multi-URL pushes are not atomic. GitHub can accept a push while Gitea rejects it,
or the reverse can happen.

If one target fails:

1. Fix the failing target, network path, SSH key, or permissions.
2. Re-run `git push` from the same clone.
3. Verify both remotes show the expected branch tip.

Useful checks:

```fish
git remote -v
git ls-remote origin HEAD
git ls-remote ssh://git@gitea.example/r6t/nixos-r6t.git HEAD
```

## SSH Access

Each development host needs an SSH key that Gitea trusts for the Gitea user.
Add the public key from each host to the Gitea account under user settings.

Use one key per host when possible. Host-specific keys make it easy to revoke
access for a single machine without rotating keys everywhere.

Recommended key labels:

- `goldenball`
- `mountainball`
- `crown`

After adding keys, verify SSH access from each host:

```fish
ssh -T git@gitea.example
```

The exact success message depends on Gitea and the SSH server configuration, but
it should identify the authenticated Gitea user or otherwise confirm successful
authentication.
