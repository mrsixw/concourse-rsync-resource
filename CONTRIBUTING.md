# Contributing to concourse-rsync-resource

## Branching

Create a branch from `master` with the issue number and a short description:

```text
issue-29_fix-shellcheck-warnings
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature (triggers minor version bump)
- `fix:` — bug fix (triggers patch version bump)
- `docs:` — documentation only
- `refactor:` — code change that neither fixes a bug nor adds a feature
- `test:` — adding or updating tests
- `chore:` — maintenance tasks
- `ci:` — CI/CD changes

Keep the summary short and imperative (e.g., `fix: quote ssh-agent subshell`).

For breaking changes, add `BREAKING CHANGE:` in the commit footer or `!` after the type (e.g., `feat!: remove disable_version_path support`). This triggers a major version bump.

## Pull Requests

- Include the issue number in the PR title (e.g., `#29: Fix shellcheck warnings in assets/`).
- Ensure CI is green before requesting review.
- Keep PRs focused — one issue per PR where possible.
