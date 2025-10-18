# Code Review Strategy

## Current Status

Ghostwire is currently maintained by a single maintainer. While the project has implemented all the infrastructure for code review, the OpenSSF Scorecard Code-Review check reflects the challenge of single-maintainer projects.

## Infrastructure in Place

✅ **Branch Protection Enabled**
- Requires 1 approving review before merge
- Requires passing status checks
- Dismisses stale reviews on new commits
- Prevents direct pushes to main

✅ **PR Workflow Required**
- All changes must go through pull requests
- Automated testing runs on every PR
- Security scanning validates changes
- Clear contribution guidelines (CONTRIBUTING.md)

✅ **Review Process Documented**
- PR template guides contributors
- Required checks clearly defined
- Merge requirements transparent

## Single-Maintainer Limitation

**Current Configuration:**
- `enforce_admins: false` - Allows repository admins to bypass review requirements
- This is necessary for single-maintainer projects where self-review is not possible

**Impact on Scorecard:**
- Code-Review score: 0/10
- Reason: All recent commits were admin-merged without external review
- This is expected for projects with one active maintainer

## How Code Review Works

### When External Contributors Submit PRs:

1. Contributor forks the repository
2. Contributor submits PR from their fork
3. Automated tests run (CI/CD)
4. **Maintainer reviews and approves**
5. PR is merged

✅ This counts as code review for Scorecard

### When Maintainer Makes Changes:

1. Maintainer creates feature branch
2. Maintainer opens PR
3. Automated tests run (CI/CD)
4. **No external reviewer available**
5. Maintainer merges using admin override

❌ This does not count as code review for Scorecard

## Improving Code Review Score

### Short-term Strategies:

1. **Recruit Co-Maintainers**
   - Invite trusted contributors from other organizations
   - Establish review partnerships with peer projects
   - Engage with users who submit quality issues/PRs

2. **Community Engagement**
   - Highlight opportunities to contribute
   - Lower barrier to entry for new contributors
   - Recognize and reward quality contributions

3. **Transparent Process**
   - Continue following PR workflow even without reviews
   - Document all changes thoroughly
   - Maintain high-quality commit messages

### Long-term Goal:

**Target: Multi-Maintainer Model**
- Minimum 2-3 active maintainers
- From different organizations (improves Contributors score too)
- Regular review rotation

## Why This Matters

### Security Benefits of Code Review:

1. **Catches Bugs Early**: Second pair of eyes spots issues
2. **Prevents Vulnerabilities**: Reviewers may catch security flaws
3. **Deters Malicious Code**: Review makes injection attacks harder
4. **Improves Code Quality**: Feedback leads to better solutions
5. **Knowledge Sharing**: Multiple people understand the codebase

### Current Mitigations:

Even without human code review, the project uses multiple layers of defense:

- ✅ **Automated Testing**: Catches functional regressions
- ✅ **Static Analysis**: Detects code quality issues (ShellCheck)
- ✅ **Security Scanning**: Finds vulnerabilities (Trivy, TruffleHog)
- ✅ **Dependency Scanning**: Monitors third-party code (Renovate, Dependabot)
- ✅ **Signed Commits**: Verifies author identity
- ✅ **Pinned Dependencies**: Prevents supply chain attacks
- ✅ **SBOM Generation**: Tracks component inventory

## Accepting the Limitation

For projects that cannot realistically require code review for all changes:

### Document the Trade-off:
- Single maintainer cannot self-review
- `enforce_admins: false` is necessary for project maintenance
- Infrastructure is ready for reviews when contributors arrive

### Focus on Other Controls:
- Comprehensive automated testing
- Multiple security scanning tools
- Transparent development process
- Quick response to security reports

### Track Progress:
- Monitor contributor growth
- Celebrate first reviewed PR
- Track review coverage over time

## When Score Will Improve

The Code-Review score will naturally improve when:

1. **External contributors submit PRs** that are reviewed and merged
2. **Co-maintainers join** who can review each other's work
3. **Review history accumulates** over the last ~30 commits

Scorecard evaluates the most recent ~30 commits, so the score will reflect the project's evolution toward multi-maintainer collaboration.

## Call for Co-Maintainers

If you're interested in becoming a co-maintainer of Ghostwire:

1. Submit quality PRs demonstrating expertise
2. Engage constructively with issues and discussions
3. Show commitment to the project's goals and users
4. Understand Kubernetes, Helm, and security best practices

Contact the project maintainer at: https://github.com/drengskapur/ghostwire/discussions

---

**Bottom Line:** The infrastructure for code review is complete. The missing piece is additional maintainers. This is a community-building challenge, not a technical one.
