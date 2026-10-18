# OpenSSF Best Practices Badge Guide

This document guides the process of applying for and earning the [OpenSSF Best Practices Badge](https://www.bestpractices.dev/) for the Ghostwire project.

## What is the OpenSSF Best Practices Badge?

The OpenSSF (Open Source Security Foundation) Best Practices Badge demonstrates that an open source project follows security best practices. Projects earn the badge by completing a self-certification questionnaire covering:

- Basics: Project website, documentation, version control
- Change Control: Public version-controlled source repository
- Reporting: Bug reporting process, vulnerability disclosure
- Quality: Automated test suite, coding standards
- Security: Secure development practices, vulnerability response
- Analysis: Static/dynamic analysis tools

## How to Apply

### 1. Create an Account

Visit <https://www.bestpractices.dev/> and sign in with your GitHub account.

### 2. Add Your Project

1. Click "Add Project"
2. Enter repository URL: `https://github.com/drengskapur/ghostwire`
3. The system will auto-populate basic information from GitHub

### 3. Complete the Questionnaire

Answer questions across all categories. The badge requires:

- Passing level: 100% of required criteria (66+ questions)
- Silver level: Passing + additional criteria (optional)
- Gold level: Silver + highest-level criteria (optional)

### 4. Badge Display

The project already has an entry. Project id **11320**: <https://www.bestpractices.dev/projects/11320>. The badge on the README stays at the in-progress level until the form is saved at passing. Answers for every passing-level criterion are in [openssf-badge-answers.md](openssf-badge-answers.md).

---

## Ghostwire Readiness Checklist

### ✅ Already Implemented

#### Basics

- [x] Project website (README.md, GitHub Pages available)
- [x] Basic documentation for installation and usage
- [x] Open source license (Apache 2.0)
- [x] Version control (Git/GitHub)
- [x] Unique version numbering (SemVer)
- [x] Release notes (CHANGELOG.md)

#### Change Control

- [x] Public version-controlled source repository
- [x] Distributed version control (Git)
- [x] Version tags for releases

#### Reporting

- [x] Bug tracking (GitHub Issues)
- [x] Security vulnerability reporting process (SECURITY.md)
- [x] Security response timeline documented

#### Quality

- [x] Working build system (Helm chart)
- [x] Automated test suite (helm lint, template tests)
- [x] Continuous integration (GitHub Actions)
- [x] Coding standards documented (CONTRIBUTING.md)

#### Security

- [x] Security policy (SECURITY.md)
- [x] Secure development practices documented
- [x] No hardcoded credentials in public repos
- [x] TLS for data in transit (via ingress)
- [x] Input validation documented
- [x] Memory-safe language where applicable
- [x] Security tools enabled:
  - Static analysis (Trivy)
  - Secret scanning (TruffleHog, Gitleaks)
  - Dependency scanning (Dependabot, Renovate)

#### Analysis

- [x] Static code analysis (Trivy for IaC)
- [x] Dynamic analysis capability (deployment testing)
- [x] Automated security scanning in CI/CD
- [x] OpenSSF Scorecard enabled

#### Build & Release

- [x] Reproducible builds (Helm chart packaging)
- [x] Generated artifacts signed:
  - OCI charts signed with Cosign keyless signing
  - GitHub release archives signed with `cosign sign-blob` (`.tgz.sigstore.json`)
  - SLSA provenance from `slsa-framework/slsa-github-generator` attached as `ghostwire.intoto.jsonl`
- [x] Build provenance generated (`.github/workflows/release.yml`)
- [x] Build process documented
- [x] Artifact verification instructions (SECURITY.md)

### ⚠️ Single-Maintainer Limitations

#### Code Review (High Priority)

- Status: Infrastructure in place, but 0/10 score due to single maintainer
- Issue: Cannot approve own PRs; all recent commits show no external review
- Mitigation:
  - Branch protection requires reviews (ready for contributors)
  - Comprehensive automated testing compensates
  - Security scanning provides additional validation
  - See [Code Review Strategy](./code-review-strategy.md) for details
- Solution: Recruit co-maintainers from community
  - Post in GitHub Discussions calling for co-maintainers
  - Engage quality contributors
  - Highlight in README
- Timeline: Score will improve as review history accumulates

### 🔄 May Need Clarification/Enhancement

#### Documentation

- [ ] Contribution instructions - Documented in CONTRIBUTING.md ✅
  - May need: Examples of good first issues
- [ ] Code of Conduct - Need to verify existence
- [ ] Installation instructions - Documented in README.md and chart/README.md ✅
- [ ] Usage documentation - May need: More detailed examples

#### Testing

- [ ] Test coverage - Need to add coverage metrics
  - Current: Basic helm lint and template tests
  - Improvement: Add coverage reporting for template coverage
- [ ] Test invocation - Documented in Taskfile.yml ✅

#### Security

- [ ] Known vulnerabilities - Need to document how we track/fix them
  - Already using: Trivy, Dependabot, Renovate
  - May need: Public vulnerability database/CVE tracking
- [ ] Cryptography - Need to document:
  - Signal Desktop uses industry-standard E2E encryption
  - TLS termination at ingress layer
  - Key management for PVC encryption

#### Analysis

- [ ] Warning flags - Need to document:
  - Helm linting warnings handled
  - Template validation against Kubernetes schemas
- [ ] Static analysis enforcement - Currently enabled, may need policy documentation

#### Fuzzing

- [x] Fuzzing implemented
  - Go fuzz target `FuzzRender` in `fuzz/render_test.go` (runs `helm template` on the chart)
  - CI job `fuzz` on every pull request and push to `main`
  - ClusterFuzzLite build in `.clusterfuzzlite/`
  - Property-based script `scripts/helm-fuzz.sh` still runs from the same workflow
  - See [Fuzzing Strategy](./fuzzing-strategy.md)
- [ ] OSS-Fuzz project registration is not set up. ClusterFuzzLite builds the same target.

---

## Recommended Enhancements

### 1. Code of Conduct

`CODE_OF_CONDUCT.md` is already the Contributor Covenant. Link it from the form where a project site or contribution URL is requested.

### 2. Enhance Test Coverage Documentation

File: `docs/testing-strategy.md`

Document:

- Current test coverage metrics
- How to run tests locally
- CI/CD test gates
- Coverage requirements for PRs

### 3. Vulnerability Disclosure Timeline

File: `SECURITY.md` (enhancement)

Add section on:

- How quickly vulnerabilities are typically fixed (by severity)
- Process for coordinated disclosure
- CVE assignment process (if applicable)

### 4. Security Tooling Documentation

File: `docs/security-tooling.md`

Document:

- All security tools in use
- How they're configured
- How to interpret results
- False positive handling

### 5. Enhance Build Documentation

File: `docs/build-process.md`

Document:

- Complete build steps from source to release
- How to verify builds
- Artifact signing process
- Signature verification examples

---

## Application Process Timeline

1. Week 1: Complete questionnaire draft
2. Week 2: Address any gaps identified
3. Week 3: Review answers with team/maintainers
4. Week 4: Submit for badge approval

The badge is self-certified, so approval is automatic once all required criteria are met.

---

## Maintaining the Badge

After earning the badge:

1. Annual Renewal: Re-certify yearly (form saved, quick update)
2. Update on Changes: Update answers if practices change
3. Badge Display: Keep badge visible in README.md
4. Continuous Improvement: Work toward Silver/Gold levels

---

## Resources

- Badge Program: <https://www.bestpractices.dev/>
- Criteria: <https://www.bestpractices.dev/en/criteria>
- FAQ: <https://www.bestpractices.dev/en/faq>
- GitHub Integration: <https://github.com/apps/cii-best-practices-badge>

---

## Next Steps

1. Sign in to <https://www.bestpractices.dev/> with the GitHub account that owns project 11320
2. Enter the answers in [openssf-badge-answers.md](openssf-badge-answers.md)
3. Save the form at the passing level

Scorecard's CII-Best-Practices check stays at 2 until that form is saved as passing. Passing is recorded by the badge site as 5. This repository cannot submit the form.
