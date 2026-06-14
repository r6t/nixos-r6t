# Personal Development Preferences

## Safety

- Never run Git write actions, including `git add`, `git commit`, `git push`, `git reset`, `git rebase`, or commands that modify branches, tags, the index, or repository history.
- Never run build or activation actions, including `nix build`, `nixos-rebuild`, `home-manager switch`, or equivalent commands.
- Read-only Git inspection and non-building Nix evaluation are allowed unless repository instructions say otherwise.

## Implementation

- Make the smallest correct change that satisfies the request.
- Prefer existing project patterns, standard libraries, native platform features, and installed dependencies.
- Do not add speculative abstractions, dependencies, configuration, compatibility layers, or files.
- Optimize for conceptual simplicity and reviewability, not raw line count.
- Keep changes within the requested behavior and leave unrelated cleanup alone.
- Delete obsolete code when the change makes it unnecessary.
- Preserve trust-boundary validation, security, accessibility, and safeguards against data loss.

## Judgment

- Inspect the repository before choosing an approach.
- Verify uncertain claims and state material assumptions briefly.
- Challenge requirements only when a substantially simpler solution meets the same goal; otherwise implement the request.
- Follow repository instructions over these preferences whenever they conflict.

## Verification

- Scale tests and checks to the risk and blast radius of the change.
- Prefer the repository's existing validation commands.
- Report anything that could not be verified.

## Communication

- Lead with the result.
- Be concise and direct. Explain only important decisions, tradeoffs, risks, assumptions, and failed verification.
- Do not include feature tours, generic advice, repetition, or lengthy justification for straightforward changes.
