#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Launch Packer container with proper Windows networking configuration
.DESCRIPTION
    This script handles the quirks of running Packer in Docker Desktop on Windows:
    - Verifies GitHub authentication
    - Detects the correct host IP for Proxmox connectivity
    - Configures HTTP bind address for Packer
    - Launches container with appropriate port mappings
.PARAMETER Shell
    Launch interactive shell (default)
.PARAMETER Build
    Launch build.sh directly
.PARAMETER Validate
    Launch validate.sh directly
.EXAMPLE
    .\docker-run.ps1
    .\docker-run.ps1 -Build
    .\docker-run.ps1 -Build -PackerDebug
    .\docker-run.ps1 -Validate
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Shell,

    [Parameter()]
    [switch]$Build,

    [Parameter()]
    [switch]$Validate,

    [Parameter()]
    [switch]$PackerDebug
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Banner
Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  MTEA FSG - Docker Container Launcher (Windows)" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check GitHub CLI authentication
Write-Host "[1/5] Checking GitHub CLI authentication..." -ForegroundColor Yellow

try {
    $ghStatus = gh auth status 2>&1 | Out-String

    if ($ghStatus -match "Logged in to github.com") {
        Write-Host "  ✓ GitHub CLI authenticated" -ForegroundColor Green

        # Check for read:packages scope
        if ($ghStatus -match "read:packages" -or $ghStatus -match "repo") {
            Write-Host "  ✓ Required scopes present" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Warning: Missing 'read:packages' scope" -ForegroundColor Yellow
            Write-Host "  Run: gh auth refresh -s read:packages" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ Not logged in to GitHub" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please authenticate with GitHub CLI first:" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Cyan
        Write-Host "  gh auth refresh -s read:packages" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "  ✗ GitHub CLI not found or not working" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install GitHub CLI:" -ForegroundColor Yellow
    Write-Host "  winget install --id GitHub.cli" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Step 2: Detect Windows IP for Proxmox connectivity
Write-Host "[2/5] Detecting Windows host IP for Proxmox connectivity..." -ForegroundColor Yellow

$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "127.*" -and
        $_.IPAddress -notlike "169.254.*" -and
        $_.IPAddress -notlike "192.168.65.*" -and  # Docker Desktop internal
        $_.PrefixOrigin -ne "WellKnown"
    } |
    Select-Object IPAddress, InterfaceAlias, PrefixLength

if ($ipAddresses.Count -eq 0) {
    Write-Host "  ✗ No suitable network interface found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure you have a network connection to Proxmox" -ForegroundColor Yellow
    exit 1
} elseif ($ipAddresses.Count -eq 1) {
    $selectedIP = $ipAddresses[0].IPAddress
    $selectedInterface = $ipAddresses[0].InterfaceAlias
    Write-Host "  ✓ Detected IP: $selectedIP ($selectedInterface)" -ForegroundColor Green
} else {
    Write-Host "  Multiple network interfaces detected:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $ipAddresses.Count; $i++) {
        $ip = $ipAddresses[$i]
        Write-Host "    [$($i+1)] $($ip.IPAddress) - $($ip.InterfaceAlias)" -ForegroundColor White
    }
    Write-Host ""

    $selection = Read-Host "  Select interface number [1-$($ipAddresses.Count)]"
    $index = [int]$selection - 1

    if ($index -lt 0 -or $index -ge $ipAddresses.Count) {
        Write-Host "  ✗ Invalid selection" -ForegroundColor Red
        exit 1
    }

    $selectedIP = $ipAddresses[$index].IPAddress
    $selectedInterface = $ipAddresses[$index].InterfaceAlias
    Write-Host "  ✓ Using: $selectedIP ($selectedInterface)" -ForegroundColor Green
}

Write-Host ""

# Step 3: Check Docker
Write-Host "[3/5] Checking Docker..." -ForegroundColor Yellow

try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker is running (v$dockerVersion)" -ForegroundColor Green
    } else {
        throw "Docker not running"
    }
} catch {
    Write-Host "  ✗ Docker is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 4: Pull/check image
Write-Host "[4/5] Checking Docker image..." -ForegroundColor Yellow

$imageName = "ghcr.io/eagletg-development/dev-packer:latest"

$imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^$([regex]::Escape($imageName))$" -Quiet

if (-not $imageExists) {
    Write-Host "  Image not found locally. Pulling from GitHub Container Registry..." -ForegroundColor Yellow

    # Login to ghcr.io
    try {
        $ghToken = gh auth token
        $ghToken | docker login ghcr.io -u $env:USERNAME --password-stdin 2>&1 | Out-Null
    } catch {
        Write-Host "  ⚠ Could not login to ghcr.io automatically" -ForegroundColor Yellow
    }

    docker pull $imageName

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ Failed to pull image" -ForegroundColor Red
        Write-Host ""
        Write-Host "Try manually:" -ForegroundColor Yellow
        Write-Host "  gh auth token | docker login ghcr.io -u YOUR_USERNAME --password-stdin" -ForegroundColor Cyan
        Write-Host "  docker pull $imageName" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "  ✓ Image ready: $imageName" -ForegroundColor Green
Write-Host ""

# Step 5: Launch container
Write-Host "[5/5] Launching container..." -ForegroundColor Yellow

$httpPorts = "8000-8099"
$packerHttpAddr = "${selectedIP}:8000"

Write-Host "  HTTP Bind Address: $packerHttpAddr" -ForegroundColor Cyan
Write-Host "  Port Mapping: $httpPorts -> $httpPorts" -ForegroundColor Cyan
Write-Host ""

# Determine command to run
$containerCommand = "/bin/bash"
if ($Build) {
    $containerCommand = "./build.sh"
    Write-Host "  Mode: Build" -ForegroundColor Cyan
} elseif ($Validate) {
    $containerCommand = "./validate.sh"
    Write-Host "  Mode: Validate" -ForegroundColor Cyan
} else {
    Write-Host "  Mode: Interactive Shell" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Build docker run command
$dockerArgs = @(
    "run"
    "-it"
    "--rm"
    "-p", "${httpPorts}:${httpPorts}"
    "-e", "PACKER_HTTP_ADDR=$packerHttpAddr"
    "-v", "${PWD}:/workspace"
    "-v", "${PWD}/config:/workspace/config"
    "-v", "${PWD}/manifests:/workspace/manifests"
)

# Add Packer debug logging if requested
if ($PackerDebug) {
    $dockerArgs += "-e"
    $dockerArgs += "PACKER_LOG=1"
    $dockerArgs += "-e"
    $dockerArgs += "PACKER_LOG_PATH=/workspace/packer-debug.log"
    Write-Host "  Debug Logging: ENABLED (packer-debug.log)" -ForegroundColor Cyan
} else {
    Write-Host "  Debug Logging: DISABLED (use -PackerDebug to enable)" -ForegroundColor Gray
}

$dockerArgs += $imageName

if ($containerCommand -ne "/bin/bash") {
    $dockerArgs += $containerCommand
}

# Execute
& docker $dockerArgs
