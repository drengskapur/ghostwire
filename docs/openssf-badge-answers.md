# OpenSSF Best Practices badge answers

Project id: **11320**

Form: <https://www.bestpractices.dev/en/projects/11320>

Badge level on that page is still **in progress**. Scorecard's CII-Best-Practices check stays at 2 until this form is saved at passing. Passing is what moves that check to 5. This file is the fill-in sheet for the passing level only. It does not claim silver or gold.

URLs below are the evidence to paste into the form. A criterion marked Met is true from the repository as of the change that added this sheet, except where the note says the release URL exists only after `v1.3.3` is published. Fill the form after that release. `v1.3.2` has a Cosign bundle and no `ghostwire.intoto.jsonl`, because that release was published before provenance was attached and is immutable.

The form's old `release_notes` answer is Unmet, with the justification "No release notes file found". That is stale. [CHANGELOG.md](https://github.com/drengskapur/ghostwire/blob/main/CHANGELOG.md) is the release-notes file. Change that answer to Met.

## Passing MUST

### description_good — Met

The README states what the project is: a Helm chart that runs Signal Desktop in Kubernetes with browser access.

<https://github.com/drengskapur/ghostwire#what-this-does>

### interact — Met

Bug reports and questions have a public place to land.

<https://github.com/drengskapur/ghostwire/issues>

<https://github.com/drengskapur/ghostwire/discussions>

### contribution — Met

URL (required): <https://github.com/drengskapur/ghostwire/blob/main/CONTRIBUTING.md>

### floss_license — Met

Apache License 2.0.

<https://github.com/drengskapur/ghostwire/blob/main/LICENSE>

### license_location — Met

URL (required): <https://github.com/drengskapur/ghostwire/blob/main/LICENSE>

The README links the same file: <https://github.com/drengskapur/ghostwire#license>

### documentation_basics — Met

Install, configuration, and operations docs are in the README and the docs tree.

<https://github.com/drengskapur/ghostwire#quick-start>

<https://github.com/drengskapur/ghostwire/blob/main/chart/README.md>

### documentation_interface — Met

The external interface is the Helm values. They are documented in the chart README, `chart/values.yaml`, and `chart/values.schema.json`.

<https://github.com/drengskapur/ghostwire/blob/main/chart/README.md>

### sites_https — Met

The repository, release downloads, and the chart registry all use HTTPS: `https://github.com/drengskapur/ghostwire`, GitHub release assets, and `https://ghcr.io`.

### discussion — Met

<https://github.com/drengskapur/ghostwire/discussions>

<https://github.com/drengskapur/ghostwire/issues>

### maintained — Met

The repository is public and receives commits. The default branch shows recent dependency and chart updates.

<https://github.com/drengskapur/ghostwire/commits/main>

### repo_public — Met

<https://github.com/drengskapur/ghostwire>

### repo_track — Met

Changes are made in Git, with pull requests and commit history on that repository.

### repo_interim — Met

Interim commits between tags are in the same public history. Tags such as `v1.3.1` point at commits on that history.

### version_unique — Met

Chart releases use a unique `vMAJOR.MINOR.PATCH` tag. `chart/Chart.yaml` carries the chart version (the release workflow writes the tag's version at package time).

<https://github.com/drengskapur/ghostwire/releases>

### release_notes — Met

URL (required): <https://github.com/drengskapur/ghostwire/blob/main/CHANGELOG.md>

GitHub Releases are the generated notes for each tag: <https://github.com/drengskapur/ghostwire/releases>

### release_notes_vulns — Met

Release notes name each vulnerability fixed in that release. The release workflow copies the changelog's security entries into the GitHub release notes. Those entries name PYSEC-2026-3864 / CVE-2026-73295 (mkdocs-material, pinned to 9.7.7) and PYSEC-2026-215 / CVE-2026-45409 (idna, pinned to 3.20).

<https://github.com/drengskapur/ghostwire/blob/main/CHANGELOG.md>

After the tag exists, also cite <https://github.com/drengskapur/ghostwire/releases/tag/v1.3.3>.

### report_process — Met

URL (required): <https://github.com/drengskapur/ghostwire/issues>

### report_responses — Met

The issue tracker is the response channel. Recent issues are dependency updates that were merged. There is no open human bug report left unanswered as of 2026-10-18. Confirm that again on the day you save the form.

<https://github.com/drengskapur/ghostwire/issues>

### report_archive — Met

URL (required): <https://github.com/drengskapur/ghostwire/issues?q=is%3Aissue>

### vulnerability_report_process — Met

URL (required): <https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

### vulnerability_report_private — Met

URL (required): <https://github.com/drengskapur/ghostwire/security/advisories>

`SECURITY.md` also lists <security@drengskapur.com> for reports that should not be public issues.

### vulnerability_report_response — N/A

No vulnerability report has been received in the window this criterion measures. The response times, if a report arrives, are in `SECURITY.md`: initial response within 48 hours, a critical fix or mitigation within 48 hours of confirmation, and other public vulnerabilities within 60 days.

### build — Met

The chart is packaged with `helm package`. The release workflow does that and publishes the `.tgz`.

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/release.yml>

### test — Met

CI runs `helm lint`, `helm template`, and `helm unittest --strict` (job `Lint and Test`), and the chart-rendering fuzz target (job `fuzz`).

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/helm-release.yml>

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/fuzzing.yml>

<https://github.com/drengskapur/ghostwire/tree/main/chart/tests>

### test_policy — Met

New functionality and bug fixes include tests. Documentation-only changes do not. CI fails the pull request when `Lint and Test` or `fuzz` fails.

<https://github.com/drengskapur/ghostwire/blob/main/CONTRIBUTING.md#test-policy>

<https://github.com/drengskapur/ghostwire/blob/main/docs/development/testing.md>

### tests_are_added — Met

Chart tests live in `chart/tests/`. The values-rendering fuzz target lives in `fuzz/render_test.go`. The test policy above is what requires the next change to add its own test.

<https://github.com/drengskapur/ghostwire/tree/main/chart/tests>

<https://github.com/drengskapur/ghostwire/blob/main/fuzz/render_test.go>

### warnings — N/A

This repository does not compile a language that has compiler warning flags. The chart is YAML templates. Shell scripts are checked with ShellCheck, which is recorded under `static_analysis`.

### warnings_fixed — N/A

Follows from `warnings`. There is no compiler warning set to keep clean.

### know_secure_design — Met

Self-certification for the maintainer, with the practices written down: least-privilege workflow tokens, pinned build dependencies, private vulnerability reports, and defaults called out when they are unsafe (the VNC password).

<https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

<https://github.com/drengskapur/ghostwire/blob/main/docs/architecture/security.md>

### know_common_errors — Met

Self-certification for the maintainer. The security docs cover injection into rendered values, leaked credentials, unsigned or unverified artifacts, and dependency vulnerabilities. CI runs CodeQL, ShellCheck, Trivy, TruffleHog, and OSV-style dependency review.

<https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

### crypto_published — N/A

The chart does not implement a cryptographic algorithm. Signal's protocol is upstream of this repository, and TLS is terminated by the cluster ingress.

### crypto_floss — N/A

Same reason. No cryptographic implementation is shipped by this chart.

### crypto_keylength — N/A

The chart does not select key lengths.

### crypto_working — N/A

The chart does not implement cryptography, so it has no home-grown algorithm to justify.

### crypto_password_storage — N/A

The chart does not operate a password database. Operators can set `auth.password`, and the chart passes that string to the upstream image as `VNC_PW`. It is deployment configuration, not an account store implemented here. The default is a public placeholder and `SECURITY.md` says to change it before any exposed deployment.

<https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

### crypto_random — N/A

The chart does not generate keys or nonces.

### delivery_mitm — Met

Source, issues, and release assets are served over HTTPS on github.com. Chart packages are pushed to `oci://ghcr.io/drengskapur/charts`.

### delivery_unsigned — Met

Releases intended for use are signed with Sigstore keyless signing (`cosign sign-blob`). There is no long-lived private key stored in the repository or on the release host. Verification steps are in `SECURITY.md`. SLSA provenance is attached as `ghostwire.intoto.jsonl`.

<https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/release.yml>

Cite the assets on `v1.3.3` once that release exists: the `.tgz`, the `.tgz.sigstore.json` bundle, and `ghostwire.intoto.jsonl`. `v1.3.2` has the `.tgz` and the `.tgz.sigstore.json` bundle only.

### vulnerabilities_fixed_60_days — Met

PYSEC-2026-3864 (CVE-2026-73295) in mkdocs-material was public on 2026-09-10. The documentation requirements pin `mkdocs-material==9.7.7`, the fixed release, inside 60 days. The same file pins `idna==3.20`, so PYSEC-2026-215 (CVE-2026-45409) is not an open finding. The changelog names both identifiers.

<https://osv.dev/vulnerability/PYSEC-2026-3864>

<https://github.com/drengskapur/ghostwire/blob/main/docs/requirements.txt>

<https://github.com/drengskapur/ghostwire/blob/main/CHANGELOG.md>

### no_leaked_credentials — Met

TruffleHog runs on every pull request and push. Workflow tokens are scoped per job. The VNC password in `chart/values.yaml` is a documented public default, not a leaked credential.

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/security-scan.yml>

### static_analysis — Met

Justification (required): at least one static-analysis tool runs on the project. ShellCheck scans `scripts/`. yamllint scans the workflows. CodeQL analyzes GitHub Actions. Trivy scans the repository. `helm lint` runs on the chart. These run in CI before merge.

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/codeql.yml>

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/security-scan.yml>

### static_analysis_fixed — Met

The CI jobs above fail the pull request on ShellCheck warnings, yamllint errors, and the Trivy and CodeQL results those workflows report. A change that adds a finding does not merge while the job is red.

### dynamic_analysis_fixed — Met

The dynamic checks in use are the Go fuzz target and `scripts/helm-fuzz.sh`. A renderer panic or an invalid rendered manifest fails `FuzzRender`. The chart passes that target. Findings from these runs are fixed rather than ignored.

<https://github.com/drengskapur/ghostwire/blob/main/fuzz/render_test.go>

## Passing SHOULD

### contribution_requirements — Met

URL (required): <https://github.com/drengskapur/ghostwire/blob/main/CONTRIBUTING.md>

The test policy, commit style, and pull-request process are in that file.

### english — Met

Documentation, issues, and the chart templates' user-facing text are in English.

### report_tracker — Met

GitHub Issues tracks open and closed reports.

<https://github.com/drengskapur/ghostwire/issues>

### enhancement_responses — Met

Enhancement requests use the same issue tracker and GitHub Discussions. The maintainer should confirm, on the day the form is saved, that open enhancement requests have had a response.

<https://github.com/drengskapur/ghostwire/discussions>

### build_floss_tools — Met

The chart is built with Helm, which is FLOSS.

<https://github.com/helm/helm>

### test_invocation — Met

```bash
helm lint chart/
helm template test chart/ > /dev/null
helm unittest chart/ --strict
go test -C fuzz -fuzz=FuzzRender -fuzztime=30s
```

<https://github.com/drengskapur/ghostwire/blob/main/CONTRIBUTING.md#test-policy>

### crypto_call — N/A

The chart does not call a cryptographic primitive of its own. See `crypto_published`.

### crypto_weaknesses — N/A

No cryptographic implementation in this repository to audit for known weaknesses.

### crypto_pfs — N/A

The chart does not perform key agreement.

### vulnerabilities_critical_fixed — Met

`SECURITY.md` commits to a fix or mitigation of a critical vulnerability within 48 hours of a confirmed report. No known critical vulnerability in this repository is currently unfixed. The mkdocs-material issue above is high (DOM XSS in an optional documentation feature), and it is pinned to the fixed release.

<https://github.com/drengskapur/ghostwire/blob/main/SECURITY.md>

## Passing SUGGESTED

### floss_license_osi — Met

Apache-2.0 is an OSI-approved license.

<https://opensource.org/license/apache-2-0>

### repo_distributed — Met

Git is a distributed version-control system. Clones carry the full history.

### version_semver — Met

Tags and chart versions are `MAJOR.MINOR.PATCH`.

<https://github.com/drengskapur/ghostwire/releases>

### version_tags — Met

Releases are git tags (`v1.3.2` for the Cosign signature, and `v1.3.3` for the signature plus SLSA provenance).

### build_common_tools — Met

Helm is the usual tool for packaging a Kubernetes chart.

### test_most — Met

Helm unittests cover the chart templates. `FuzzRender` feeds values overlays through `helm template`. This is not a line-coverage percentage. It is the test set CI requires for the chart's behavior.

<https://github.com/drengskapur/ghostwire/tree/main/chart/tests>

### test_continuous_integration — Met

GitHub Actions runs the test jobs on every pull request to `main`.

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/helm-release.yml>

### tests_documented_added — Met

The requirement to add tests is written in `CONTRIBUTING.md` and `docs/development/testing.md`, linked from the test-policy criterion above.

### warnings_strict — N/A

Follows from `warnings`. ShellCheck in `.github/workflows/fuzzing.yml` is configured at style severity; that is static analysis, not a compiler `-Werror` flag.

### static_analysis_common_vulnerabilities — Met

CodeQL and Trivy look for common vulnerability patterns. Dependency review blocks high-severity dependency findings on pull requests.

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/codeql.yml>

<https://github.com/drengskapur/ghostwire/blob/main/.github/workflows/security-scan.yml>

### static_analysis_often — Met

Those jobs run on pull requests and on pushes to `main`, not only before a release.

### dynamic_analysis — Met

`FuzzRender` runs for 30 seconds in the `fuzz` job on every pull request and push to `main`. ClusterFuzzLite can build the same target from `.clusterfuzzlite/`. `scripts/helm-fuzz.sh` runs random valid values through the renderer.

<https://github.com/drengskapur/ghostwire/blob/main/docs/fuzzing-strategy.md>

<https://github.com/drengskapur/ghostwire/blob/main/.clusterfuzzlite/Dockerfile>

### dynamic_analysis_unsafe — N/A

This repository does not ship memory-unsafe code. The fuzzer is Go and executes the Helm binary, which is not built from this repository.

### dynamic_analysis_enable_assertions — Met

`FuzzRender` fails the test when the renderer panics or the rendered documents are not valid YAML. Helm unittests fail the job when an assertion does not hold. Both run in CI with those checks enabled.

## What this sheet does not claim

- Silver or gold criteria, including `achieve_passing` and `achieve_silver`.
- A Code-Review score above 0. That check counts real approvals from a second reviewer. None are invented here.
- That the badge site has already accepted these answers. Saving the form is an owner action.
