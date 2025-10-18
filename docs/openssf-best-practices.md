# OpenSSF Best Practices Badge Guide

This document guides the process of applying for and earning the [OpenSSF Best Practices Badge](https://www.bestpractices.dev/) for the Ghostwire project.

## What is the OpenSSF Best Practices Badge?

The OpenSSF (Open Source Security Foundation) Best Practices Badge demonstrates that an open source project follows security best practices. Projects earn the badge by completing a self-certification questionnaire covering:

- **Basics:** Project website, documentation, version control
- **Change Control:** Public version-controlled source repository
- **Reporting:** Bug reporting process, vulnerability disclosure
- **Quality:** Automated test suite, coding standards
- **Security:** Secure development practices, vulnerability response
- **Analysis:** Static/dynamic analysis tools

## How to Apply

### 1. Create an Account

Visit https://www.bestpractices.dev/ and sign in with your GitHub account.

### 2. Add Your Project

1. Click "Add Project"
2. Enter repository URL: `https://github.com/drengskapur/ghostwire`
3. The system will auto-populate basic information from GitHub

### 3. Complete the Questionnaire

Answer questions across all categories. The badge requires:
- **Passing level:** 100% of required criteria (66+ questions)
- **Silver level:** Passing + additional criteria (optional)
- **Gold level:** Silver + highest-level criteria (optional)

### 4. Badge Display

Once earned, add the badge to README.md:

```markdown
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/XXXX/badge)](https://www.bestpractices.dev/projects/XXXX)
```

Replace `XXXX` with your project ID from the badge URL.

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
  - OCI images signed with Cosign keyless signing
  - GitHub Releases signed with SLSA provenance attestations
- [x] Build provenance generated (SLSA attestations via actions/attest-build-provenance)
- [x] Build process documented
- [x] Artifact verification instructions (SECURITY.md)

### ⚠️ Single-Maintainer Limitations

#### Code Review (High Priority)
- **Status:** Infrastructure in place, but 0/10 score due to single maintainer
- **Issue:** Cannot approve own PRs; all recent commits show no external review
- **Mitigation:**
  - Branch protection requires reviews (ready for contributors)
  - Comprehensive automated testing compensates
  - Security scanning provides additional validation
  - See [Code Review Strategy](./code-review-strategy.md) for details
- **Solution:** Recruit co-maintainers from community
  - Post in GitHub Discussions calling for co-maintainers
  - Engage quality contributors
  - Highlight in README
- **Timeline:** Score will improve as review history accumulates

### 🔄 May Need Clarification/Enhancement

#### Documentation
- [ ] **Contribution instructions** - Documented in CONTRIBUTING.md ✅
  - May need: Examples of good first issues
- [ ] **Code of Conduct** - Need to verify existence
- [ ] **Installation instructions** - Documented in README.md and chart/README.md ✅
- [ ] **Usage documentation** - May need: More detailed examples

#### Testing
- [ ] **Test coverage** - Need to add coverage metrics
  - Current: Basic helm lint and template tests
  - Improvement: Add coverage reporting for template coverage
- [ ] **Test invocation** - Documented in Taskfile.yml ✅

#### Security
- [ ] **Known vulnerabilities** - Need to document how we track/fix them
  - Already using: Trivy, Dependabot, Renovate
  - May need: Public vulnerability database/CVE tracking
- [ ] **Cryptography** - Need to document:
  - Signal Desktop uses industry-standard E2E encryption
  - TLS termination at ingress layer
  - Key management for PVC encryption

#### Analysis
- [ ] **Warning flags** - Need to document:
  - Helm linting warnings handled
  - Template validation against Kubernetes schemas
- [ ] **Static analysis enforcement** - Currently enabled, may need policy documentation

#### Fuzzing
- [x] **Fuzzing implemented** - Property-based testing for Helm templates
  - Custom fuzzing script (`scripts/helm-fuzz.sh`)
  - Weekly automated fuzzing runs (`.github/workflows/fuzzing.yml`)
  - Generates random valid configurations and tests template rendering
  - See [Fuzzing Strategy](./fuzzing-strategy.md) for details
- [ ] **OSS-Fuzz integration** - Not applicable for Helm chart projects
  - OSS-Fuzz targets compiled runtime code (C, C++, Go, Rust)
  - Helm charts are declarative templates with no runtime execution
  - Property-based testing provides equivalent risk reduction

---

## Recommended Enhancements

### 1. Add Code of Conduct

**File:** `CODE_OF_CONDUCT.md`

Use the [Contributor Covenant](https://www.contributor-covenant.org/):

```bash
curl -o CODE_OF_CONDUCT.md https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md
```

### 2. Enhance Test Coverage Documentation

**File:** `docs/testing-strategy.md`

Document:
- Current test coverage metrics
- How to run tests locally
- CI/CD test gates
- Coverage requirements for PRs

### 3. Vulnerability Disclosure Timeline

**File:** `SECURITY.md` (enhancement)

Add section on:
- How quickly vulnerabilities are typically fixed (by severity)
- Process for coordinated disclosure
- CVE assignment process (if applicable)

### 4. Security Tooling Documentation

**File:** `docs/security-tooling.md`

Document:
- All security tools in use
- How they're configured
- How to interpret results
- False positive handling

### 5. Enhance Build Documentation

**File:** `docs/build-process.md`

Document:
- Complete build steps from source to release
- How to verify builds
- Artifact signing process
- Signature verification examples

---

## Application Process Timeline

1. **Week 1:** Complete questionnaire draft
2. **Week 2:** Address any gaps identified
3. **Week 3:** Review answers with team/maintainers
4. **Week 4:** Submit for badge approval

The badge is self-certified, so approval is automatic once all required criteria are met.

---

## Maintaining the Badge

After earning the badge:

1. **Annual Renewal:** Re-certify yearly (form saved, quick update)
2. **Update on Changes:** Update answers if practices change
3. **Badge Display:** Keep badge visible in README.md
4. **Continuous Improvement:** Work toward Silver/Gold levels

---

## Resources

- **Badge Program:** https://www.bestpractices.dev/
- **Criteria:** https://www.bestpractices.dev/en/criteria
- **FAQ:** https://www.bestpractices.dev/en/faq
- **GitHub Integration:** https://github.com/apps/cii-best-practices-badge

---

## Next Steps

1. Sign in to https://www.bestpractices.dev/ with GitHub account
2. Add the Ghostwire project
3. Start completing the questionnaire using this checklist
4. Flag any gaps that need to be addressed
5. Work through enhancements before submitting

The project is well-positioned to earn the passing badge - most criteria are already met through existing security practices and documentation.
