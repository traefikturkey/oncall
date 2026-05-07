#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Docker Build Helper Script for MTEA FSG Infrastructure Automation

.DESCRIPTION
    This script simplifies running builds using Docker on Windows/PowerShell

.PARAMETER Command
    The command to execute: setup, build, validate, shell, clean, rebuild, help

.EXAMPLE
    .\docker-build.ps1 setup
    .\docker-build.ps1 build
    .\docker-build.ps1 validate

.NOTES
    Requires Docker and Docker Compose to be installed
#>

param(
    [Parameter(Position=0)]
    [ValidateSet('setup', 'build', 'validate', 'shell', 'clean', 'rebuild', 'help', '')]
    [string]$Command = '',

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs = @()
)

# Script configuration
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Color functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Print-Header {
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════╗" -Color Cyan
    Write-ColorOutput "║    MTEA FSG - Infrastructure Automation Build Helper      ║" -Color Cyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════╝`n" -Color Cyan
}

function Print-Usage {
    Write-Host @"

Usage: .\docker-build.ps1 [COMMAND]

Commands:
  setup       - Initial setup: build image and create config
  build       - Run interactive build menu
  validate    - Validate all Packer templates
  shell       - Open a shell in the container
  clean       - Remove Docker images and containers
  rebuild     - Rebuild Docker image from scratch
  help        - Show this help message

Examples:
  .\docker-build.ps1 setup      # First-time setup
  .\docker-build.ps1 build      # Run a build
  .\docker-build.ps1 validate   # Validate all templates

"@
}

function Test-Docker {
    Write-ColorOutput "Checking Docker installation..." -Color Gray

    # Check Docker
    try {
        $null = Get-Command docker -ErrorAction Stop
    } catch {
        Write-ColorOutput "Error: Docker is not installed or not in PATH" -Color Red
        Write-ColorOutput "Please install Docker from: https://docs.docker.com/get-docker/" -Color Yellow
        exit 1
    }

    # Check Docker Compose
    $composeAvailable = $false
    try {
        $null = Get-Command docker-compose -ErrorAction Stop
        $composeAvailable = $true
    } catch {
        # Try docker compose (v2 syntax)
        try {
            docker compose version | Out-Null
            $composeAvailable = $true
        } catch {
            Write-ColorOutput "Error: Docker Compose is not installed" -Color Red
            Write-ColorOutput "Please install Docker Compose from: https://docs.docker.com/compose/install/" -Color Yellow
            exit 1
        }
    }

    Write-ColorOutput "✓ Docker and Docker Compose found`n" -Color Green
}

function Test-Config {
    $configPath = Join-Path $ScriptDir "config"

    if (-not (Test-Path $configPath) -or ((Get-ChildItem $configPath -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0)) {
        Write-ColorOutput "Warning: Config directory is missing or empty" -Color Yellow
        Write-ColorOutput "Creating config files..." -Color Gray

        $configScript = Join-Path $ScriptDir "config.sh"
        if (Test-Path $configScript) {
            & bash $configScript
            Write-ColorOutput "✓ Config files created in .\config\" -Color Green
            Write-ColorOutput "Please edit the config files with your Proxmox settings before running builds`n" -Color Yellow
        } else {
            Write-ColorOutput "Error: config.sh not found" -Color Red
            return $false
        }
        return $false
    }
    return $true
}

function Build-Image {
    Write-ColorOutput "Building Docker image..." -Color Cyan
    Push-Location $ScriptDir
    try {
        docker-compose build
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }
        Write-ColorOutput "✓ Docker image built successfully`n" -Color Green
    } finally {
        Pop-Location
    }
}

function Invoke-Setup {
    Print-Header
    Write-ColorOutput "Running initial setup...`n" -Color Cyan

    # Build Docker image
    Build-Image

    # Create config
    $configPath = Join-Path $ScriptDir "config"
    if (-not (Test-Path $configPath)) {
        Write-ColorOutput "Creating configuration files..." -Color Cyan
        $configScript = Join-Path $ScriptDir "config.sh"
        if (Test-Path $configScript) {
            & bash $configScript
            Write-ColorOutput "✓ Configuration files created in .\config\`n" -Color Green
        }
    } else {
        Write-ColorOutput "Config directory already exists, skipping...`n" -Color Yellow
    }

    Write-ColorOutput "✓ Setup complete!`n" -Color Green
    Write-ColorOutput "Next steps:" -Color Yellow
    Write-Host "  1. Edit configuration files in .\config\ with your Proxmox settings"
    Write-Host "  2. Run: .\docker-build.ps1 build`n"
}

function Invoke-Build {
    Print-Header

    if (-not (Test-Config)) {
        Write-Host "`nPlease configure your settings in .\config\ and try again"
        exit 1
    }

    Write-ColorOutput "Starting interactive build...`n" -Color Cyan
    Push-Location $ScriptDir
    try {
        if ($AdditionalArgs.Count -gt 0) {
            docker-compose run --rm packer ./build.sh $AdditionalArgs
        } else {
            docker-compose run --rm packer ./build.sh
        }
    } finally {
        Pop-Location
    }
}

function Invoke-Validate {
    Print-Header

    if (-not (Test-Config)) {
        Write-Host "`nPlease configure your settings in .\config\ and try again"
        exit 1
    }

    Write-ColorOutput "Validating Packer templates...`n" -Color Cyan
    Push-Location $ScriptDir
    try {
        if ($AdditionalArgs.Count -gt 0) {
            docker-compose run --rm packer ./validate.sh $AdditionalArgs
        } else {
            docker-compose run --rm packer ./validate.sh
        }
    } finally {
        Pop-Location
    }
}

function Invoke-Shell {
    Print-Header
    Write-ColorOutput "Opening shell in container...`n" -Color Cyan
    Push-Location $ScriptDir
    try {
        docker-compose run --rm packer /bin/bash
    } finally {
        Pop-Location
    }
}

function Invoke-Clean {
    Print-Header
    Write-ColorOutput "This will remove Docker images and containers" -Color Yellow
    $response = Read-Host "Are you sure? (y/n)"

    if ($response -match '^[Yy]$') {
        Write-ColorOutput "Cleaning up..." -Color Cyan
        Push-Location $ScriptDir
        try {
            docker-compose down -v
            docker rmi mtea-fsg-automation:latest 2>$null
            Write-ColorOutput "✓ Cleanup complete`n" -Color Green
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Cancelled"
    }
}

function Invoke-Rebuild {
    Print-Header
    Write-ColorOutput "Rebuilding Docker image from scratch...`n" -Color Cyan
    Push-Location $ScriptDir
    try {
        docker-compose build --no-cache
        if ($LASTEXITCODE -ne 0) {
            throw "Docker rebuild failed"
        }
        Write-ColorOutput "✓ Rebuild complete`n" -Color Green
    } finally {
        Pop-Location
    }
}

# Main script execution
try {
    Test-Docker

    switch ($Command.ToLower()) {
        'setup' {
            Invoke-Setup
        }
        'build' {
            Invoke-Build
        }
        'validate' {
            Invoke-Validate
        }
        'shell' {
            Invoke-Shell
        }
        'clean' {
            Invoke-Clean
        }
        'rebuild' {
            Invoke-Rebuild
        }
        'help' {
            Print-Header
            Print-Usage
        }
        '' {
            Print-Header
            Write-ColorOutput "Error: No command specified`n" -Color Red
            Print-Usage
            exit 1
        }
        default {
            Print-Header
            Write-ColorOutput "Error: Invalid command '$Command'`n" -Color Red
            Print-Usage
            exit 1
        }
    }
} catch {
    Write-ColorOutput "`nError: $($_.Exception.Message)" -Color Red
    exit 1
}
