# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the MTEA FSG Infrastructure Automation project.

## Workflows

### 1. Build and Publish Docker Image (`docker-build.yml`)

**Triggers:**
- Push to `main` or `develop` branches (when Dockerfile or docker-compose.yml changes)
- Pull requests to `main`
- Manual trigger via workflow_dispatch

**What it does:**
- Builds the Docker image using buildx for multi-platform support
- Pushes to GitHub Container Registry (ghcr.io)
- Creates multiple tags:
  - `latest` - Latest main branch build
  - `main-<sha>` - Specific commit on main
  - `develop-<sha>` - Specific commit on develop
  - Branch name tags for tracking
- Generates build attestations for supply chain security
- Uses GitHub Actions cache to speed up builds

**Image Location:**
```
ghcr.io/eagletg-development/dev-packer:latest
ghcr.io/eagletg-development/dev-packer:main-1a2b3c4
```

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

### 3. Cleanup Old Container Images (`cleanup-old-images.yml`)

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

## Permissions Required

The workflows need these GitHub permissions:
- `contents: read` - Read repository contents
- `packages: write` - Push to container registry
- `attestations: write` - Generate build attestations
- `id-token: write` - OIDC token for attestations

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

- Images are signed with build attestations
- Supply chain provenance tracked
- Images scanned for vulnerabilities (add Trivy scan if needed)
- Only MTEA FSG team members can push images

## Future Enhancements

Potential additions:
- [ ] Security scanning with Trivy
- [ ] Multi-architecture builds (arm64)
- [ ] Release tagging workflow
- [ ] Integration tests in CI
- [ ] Slack/Teams notifications
- [ ] Automatic changelog generation

---

**Questions or Issues?**
Contact MTEA FSG Infrastructure team or open an issue in the repository.
