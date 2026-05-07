# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the MTEA FSG Infrastructure Automation project.

## Workflows

### 1. Build and Publish Docker Image (`docker-build.yml`)

**Security:** Includes Trivy vulnerability scanning on every build

**Triggers:**
- Push to `main` or `develop` branches (when Dockerfile or docker-compose.yml changes)
- Pull requests to `main`
- Manual trigger via workflow_dispatch

**What it does:**
- Builds the Docker image using buildx for multi-platform support
- Pushes to GitHub Container Registry (ghcr.io)
- **Scans image with Trivy** for vulnerabilities (CRITICAL, HIGH, MEDIUM)
- Uploads scan results to GitHub Security tab
- Uploads detailed scan reports as artifacts
- Creates multiple tags:
  - `latest` - Latest main branch build
  - `main-<sha>` - Specific commit on main
  - `develop-<sha>` - Specific commit on develop
  - Branch name tags for tracking
- Uses GitHub Actions cache to speed up builds

**Image Location:**
```
ghcr.io/eagletg-development/dev-packer:latest
ghcr.io/eagletg-development/dev-packer:main-1a2b3c4
```

> **Note:** All image names are lowercase as required by GitHub Container Registry.

**Usage:**
```bash
# Pull latest
docker pull ghcr.io/eagletg-development/dev-packer:latest

# Pull specific version
docker pull ghcr.io/eagletg-development/dev-packer:main-1a2b3c4

# Run
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/config:/workspace/config" \
  ghcr.io/eagletg-development/dev-packer:latest
```

### 2. Validate Packer Templates (`validate-templates.yml`)

**Triggers:**
- Push to `main` or `develop` (when .pkr.hcl files change)
- Pull requests to `main` (when .pkr.hcl files change)
- Manual trigger via workflow_dispatch

**What it does:**
- Builds Docker image for testing
- Generates configuration templates
- Validates all Packer templates for syntax errors
- Uploads validation results as artifacts
- Runs on every PR to catch issues early

**Validation Process:**
1. Build Docker image
2. Create config directory structure
3. Run `./validate.sh` inside container
4. Upload any error logs

**Viewing Results:**
- Check the "Actions" tab in GitHub
- Download validation artifacts if there are errors

### 3. Security Scan with Trivy (`security-scan.yml`)

> ⚠️ **Note for Private Repositories:** The Security tab integration requires GitHub Advanced Security (GHAS), which is a paid feature. However, scan results are still available in:
> - **Workflow Summary** - Vulnerability counts displayed on workflow run page
> - **Workflow Logs** - Full table output in the Actions logs
> - **Artifacts** - Downloadable JSON/SARIF reports for every scan

**Triggers:**
- Scheduled: Daily at 6am UTC
- Push to `main` (when Dockerfile changes)
- Manual trigger via workflow_dispatch

**What it does:**
- **Container Image Scan:**
  - Pulls latest image from ghcr.io
  - Scans for vulnerabilities (ALL severity levels)
  - Scans for secrets and misconfigurations
  - Checks both OS and library vulnerabilities
  - Reports critical and high severity counts
  
- **Filesystem Scan:**
  - Scans repository files
  - Detects hardcoded secrets
  - Checks for configuration issues
  - Validates infrastructure-as-code files

- **Security Integration:**
  - Uploads results to GitHub Security tab
  - Creates SARIF reports for code scanning
  - Stores detailed JSON reports as artifacts
  - Warns if critical vulnerabilities found

**Viewing Results:**
1. **Security Tab**: Navigate to repository → Security → Code scanning alerts
2. **Actions Tab**: View scan summaries in workflow logs
3. **Artifacts**: Download detailed JSON/SARIF reports

**Severity Levels:**
- 🔴 **CRITICAL** - Immediate action required
- 🟠 **HIGH** - Important to fix soon
- 🟡 **MEDIUM** - Should be reviewed
- 🔵 **LOW** - Nice to fix (filesystem scan only)

### 4. Cleanup Old Container Images (`cleanup-old-images.yml`)

**Triggers:**
- Scheduled: Every Sunday at 2am UTC
- Manual trigger via workflow_dispatch

**What it does:**
- Keeps the 10 most recent container versions
- Deletes old untagged versions
- Helps maintain clean container registry
- Prevents storage bloat

**Configuration:**
- `min-versions-to-keep: 10` - Adjust to keep more/fewer versions
- `delete-only-untagged-versions: true` - Only removes untagged images

## Using Pre-Built Images

### Quick Start

Instead of building locally, use pre-built images:

**Linux/macOS/WSL:**
```bash
# Create config
./config.sh

# Use pre-built image
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/config:/workspace/config" \
  -v "$(pwd)/manifests:/workspace/manifests" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  ghcr.io/eagletg-development/dev-packer:latest \
  ./build.sh
```

**Windows PowerShell:**
```powershell
# Create config
.\config.sh

# Use pre-built image
docker run -it --rm --network host `
  -v "${PWD}:/workspace" `
  -v "${PWD}/config:/workspace/config" `
  -v "${PWD}/manifests:/workspace/manifests" `
  -v "${HOME}/.ssh:/root/.ssh:ro" `
  ghcr.io/eagletg-development/dev-packer:latest `
  ./build.sh
```

### Using with Docker Compose

Edit `docker-compose.yml` to use pre-built image:

```yaml
services:
  packer:
    # Comment out build section
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    
    # Use pre-built image instead
    image: ghcr.io/eagletg-development/dev-packer:latest
    container_name: mtea-fsg-packer
    # ... rest of config
```

Then run:
```bash
docker-compose run --rm packer ./build.sh
```

## Image Tags Explained

| Tag Pattern | Description | Example |
|-------------|-------------|---------|
| `latest` | Most recent main branch build | `latest` |
| `main-<sha>` | Specific commit on main | `main-a1b2c3d` |
| `develop-<sha>` | Specific commit on develop | `develop-x9y8z7w` |
| `<branch>` | Latest from a specific branch | `main`, `develop` |

## GitHub Advanced Security (GHAS) - Optional

### What Works Without GHAS (Current Setup)

✅ **Full Trivy scanning** - All vulnerabilities detected  
✅ **Workflow summaries** - Vulnerability counts on every run  
✅ **Detailed reports** - JSON/SARIF artifacts downloadable  
✅ **Table output** - Full CVE details in logs  
✅ **Secret detection** - Filesystem scans work  
✅ **Daily scans** - Scheduled monitoring active  

### What Requires GHAS (Private Repos Only)

❌ **Security Tab Integration** - Centralized alert dashboard  
❌ **Persistent Alerts** - Alerts that stay until fixed  
❌ **Trend Graphs** - Historical vulnerability tracking  
❌ **Email Notifications** - Automatic alert emails  
❌ **PR Annotations** - Security comments on pull requests  

### Enabling GHAS Features

**Option 1: Make Repository Public**
- Free code scanning for public repositories
- All Security tab features enabled
- Navigate to: Settings → General → Danger Zone → Change visibility

**Option 2: Purchase GitHub Advanced Security**
- Contact GitHub Sales for organization plan
- Enables GHAS for private repositories
- Includes Dependabot, Secret scanning, Code scanning

**Option 3: Keep Current Setup (Recommended)**
- You're already getting full vulnerability scanning
- View results in Workflow Summary and Artifacts
- Works perfectly for team visibility
- No additional cost

## Permissions Required

The workflows need these GitHub permissions:
- `contents: read` - Read repository contents
- `packages: write` - Push to container registry
- `packages: read` - Pull images for scanning
- `security-events: write` - Upload security scan results (attempts, but gracefully fails without GHAS)

These are automatically granted in GitHub Actions.

## Manual Workflow Triggers

You can manually trigger workflows:

1. Go to **Actions** tab in GitHub
2. Select the workflow (e.g., "Build and Publish Docker Image")
3. Click **Run workflow** button
4. Select branch and click **Run workflow**

Useful for:
- Testing workflow changes
- Rebuilding images on demand
- Forcing a cleanup of old images

## Troubleshooting

### Build Failures

**Problem:** Docker build fails in Actions

**Check:**
1. Review workflow logs in Actions tab
2. Ensure Dockerfile is valid
3. Test build locally: `docker build -t test .`
4. Check for dependency issues

### Validation Failures

**Problem:** Template validation fails

**Check:**
1. Download validation artifacts from Actions
2. Review error messages
3. Test locally: `./validate.sh`
4. Fix .pkr.hcl syntax errors

### Image Pull Failures

**Problem:** Can't pull image from ghcr.io

**Solutions:**

1. **Authenticate with GitHub:**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Make package public:**
   - Go to package settings in GitHub
   - Change visibility to public

3. **Use Personal Access Token:**
   - Create PAT with `read:packages` scope
   - Login: `echo $PAT | docker login ghcr.io -u USERNAME --password-stdin`

### Cache Issues

**Problem:** Builds are slow even with cache

**Solution:**
- Cache is stored in GitHub Actions cache
- First build after cache clear will be slow
- Subsequent builds use cached layers
- Force rebuild: Delete workflow cache in Settings → Actions → Caches

## Best Practices

1. **Pin Image Versions in Production**
   ```yaml
   # Don't use in production
   image: ghcr.io/eagletg-development/dev-packer:latest
   
   # Use specific commit SHA
   image: ghcr.io/eagletg-development/dev-packer:main-a1b2c3d
   ```

2. **Test Before Merge**
   - Validation workflow runs on PRs
   - Review validation results before merging

3. **Regular Cleanup**
   - Scheduled cleanup runs weekly
   - Manually trigger if needed

4. **Monitor Image Sizes**
   - Check container registry for size
   - Optimize Dockerfile if images grow large

## Security

- ✅ **Trivy Vulnerability Scanning** - Automatic on every build and daily
- ✅ **Images built from trusted source** - GitHub Actions only
- ✅ **Access control** - Only authenticated team members can push
- ✅ **Audit logs** - Build logs available in Actions tab
- ✅ **Security alerts** - Integrated with GitHub Security tab
- ✅ **Secret detection** - Scans for hardcoded credentials
- ✅ **Configuration checks** - Validates Dockerfile and IaC files
- 📋 **Consider:** Enable Dependabot for Dockerfile dependency updates

**Security Dashboard:**
- Navigate to repository → **Security** tab
- View **Code scanning alerts** for Trivy findings
- Check **Dependabot alerts** (if enabled)
- Review **Secret scanning** alerts (if enabled)

## Trivy Scanning Details

### What Trivy Scans For

**Container Images:**
- OS package vulnerabilities (Ubuntu packages)
- Application library vulnerabilities (Python, etc.)
- Known CVEs with severity ratings
- Exploitability information

**Filesystem:**
- Hardcoded secrets (passwords, API keys, tokens)
- Configuration issues in Dockerfile
- Misconfigurations in IaC files
- Security best practice violations

### Understanding Scan Results

**In GitHub Security Tab:**
1. Go to **Security** → **Code scanning**
2. Filter by tool: "Trivy"
3. Click on any alert to see:
   - CVE identifier and description
   - Severity level
   - Affected package and version
   - Fixed version (if available)
   - Links to vulnerability databases

**In Workflow Logs:**
- View summary table of findings
- See vulnerability counts by severity
- Get warnings for critical issues

**In Artifacts:**
- Download full JSON report for detailed analysis
- SARIF format compatible with security tools
- Historical tracking across builds

### Handling Vulnerabilities

**Critical/High Severity:**
1. Review the CVE details
2. Update affected packages in Dockerfile
3. Rebuild image
4. Verify fix in next scan

**False Positives:**
- Can't update package: Document in security policy
- Already mitigated: Add comment in Dockerfile
- Not applicable: Dismiss alert in GitHub UI

**Regular Maintenance:**
- Monitor daily scan results
- Update base image regularly
- Keep application dependencies current
- Review and fix findings promptly

## Future Enhancements

Potential additions:
- [x] ~~Security scanning with Trivy~~ ✅ **Implemented**
- [ ] Multi-architecture builds (arm64)
- [ ] Release tagging workflow
- [ ] Integration tests in CI
- [ ] Slack/Teams notifications for critical vulnerabilities
- [ ] Automatic changelog generation
- [ ] SBOM (Software Bill of Materials) generation
- [ ] Container signing with Cosign

---

**Questions or Issues?**
Contact MTEA FSG Infrastructure team or open an issue in the repository.
