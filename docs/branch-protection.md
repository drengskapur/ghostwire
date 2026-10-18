# Branch protection

The default branch is protected by the repository ruleset in [branch-protection-ruleset.json](branch-protection-ruleset.json). Apply that file with the call at the bottom of this page. The ruleset is the setting that Scorecard reads.

## What the ruleset requires

- Name `main-protection`, enforcement `active`, target the default branch.
- Block deletion and non-fast-forward pushes.
- Require a linear history. Squash and rebase are the allowed merge methods. Merge commits stay disabled in `.github/settings.yml`.
- Require signed commits. History on `main` is already signed (GitHub web-flow commits carry a signature). The rule does not rewrite history.
- Require a pull request with **1** approving review.
- Dismiss stale reviews on each push, require approval of the latest push, and require review threads to be resolved.
- Require a code-owner review. `.github/CODEOWNERS` lists `@drengskapur` and `@davidagustin` on the same line, so either one can approve. A review from David satisfies both the one required approval and the code-owner rule.
- Require the status checks below, and require the branch to be up to date (`strict_required_status_checks_policy`):
  - `Lint and Test`
  - `YAML Lint`
  - `ShellCheck Analysis`
  - `CodeQL Analyze (actions)`
  - `Scorecard analysis`
  - `Trivy Repository Scan`
  - `TruffleHog Secret Scan`
  - `Security Scan Summary`
  - `fuzz`

`Build and Test` is not required. That job is conditional, and two workflows publish a check with the same name.

## One review, and an admin bypass

The pull-request rule sets `required_approving_review_count` to 1. A second person with write access can approve, and that approval is enough.

Repository administrators bypass the ruleset (`actor_id` 5, `actor_type` `RepositoryRole`, `bypass_mode` `always`). The owner can merge when the second reviewer is away. An admin bypass is not an approving review. Do not create reviews to satisfy the check.

Scorecard's Branch-Protection tiers stop at 8 with this shape:

| Tier | Score | This ruleset |
| --- | --- | --- |
| Force-push and deletion blocked | 3 | Yes |
| At least one review, pull requests, up-to-date branch, last-push approval | 6 | Yes |
| At least one required status check | 8 | Yes |
| Two reviews and code owners | 9 | Code-owner review is on. The required approving review count stays 1, so this tier is not met. |
| Dismiss-stale plus no admin bypass | 10 | No. The admin bypass is what keeps the owner from being locked out. |

## Second reviewer

GitHub user `davidagustin` is the intended second reviewer and needs write (push) access. An attempt to send that invite returned HTTP 403, `Resource not accessible by integration`. This token cannot manage collaborators. Do not look for another API to send the invite. The owner sends it:

```bash
gh api --method PUT repos/drengskapur/ghostwire/collaborators/davidagustin -f permission=push
```

Code-Review stays 0, and Contributors stays 3, until that person actually reviews work that lands on `main`.

## Apply the ruleset

Apply it after the current pull request is merged. Applying it first would demand an approval this pull request does not have.

```bash
gh api --method POST repos/drengskapur/ghostwire/rulesets \
  --input docs/branch-protection-ruleset.json
```

A 403 on that call means the token is not an admin. The JSON file is the whole request body. Do not drop the review rule or the admin bypass to make the call succeed.
