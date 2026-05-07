#!/usr/bin/env bash

# Docker Build Helper Script
# This script simplifies running builds using Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║    MTEA FSG - Infrastructure Automation Build Helper      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup       - Initial setup: build image and create config"
    echo "  build       - Run interactive build menu"
    echo "  validate    - Validate all Packer templates"
    echo "  shell       - Open a shell in the container"
    echo "  clean       - Remove Docker images and containers"
    echo "  rebuild     - Rebuild Docker image from scratch"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup      # First-time setup"
    echo "  $0 build      # Run a build"
    echo "  $0 validate   # Validate all templates"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
        echo "Please install Docker from: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed${NC}"
        echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
        exit 1
    fi
}

check_config() {
    if [ ! -d "$SCRIPT_DIR/config" ] || [ -z "$(ls -A "$SCRIPT_DIR/config" 2>/dev/null)" ]; then
        echo -e "${YELLOW}Warning: Config directory is missing or empty${NC}"
        echo "Creating config files..."
        bash "$SCRIPT_DIR/config.sh"
        echo -e "${GREEN}Config files created in ./config/${NC}"
        echo -e "${YELLOW}Please edit the config files with your Proxmox settings before running builds${NC}"
        return 1
    fi
    return 0
}

build_image() {
    echo -e "${BLUE}Building Docker image...${NC}"
    docker-compose build
    echo -e "${GREEN}Docker image built successfully${NC}"
}

setup() {
    print_header
    echo -e "${BLUE}Running initial setup...${NC}"
    echo ""

    # Build Docker image
    build_image
    echo ""

    # Create config
    if [ ! -d "$SCRIPT_DIR/config" ]; then
        echo -e "${BLUE}Creating configuration files...${NC}"
        bash "$SCRIPT_DIR/config.sh"
        echo -e "${GREEN}Configuration files created in ./config/${NC}"
    else
        echo -e "${YELLOW}Config directory already exists, skipping...${NC}"
    fi

    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit configuration files in ./config/ with your Proxmox settings"
    echo "  2. Run: $0 build"
    echo ""
}

run_build() {
    print_header
    check_config || {
        echo ""
        echo "Please configure your settings in ./config/ and try again"
        exit 1
    }

    echo -e "${BLUE}Starting interactive build...${NC}"
    docker-compose run --rm packer ./build.sh "$@"
}

run_validate() {
    print_header
    check_config || {
        echo ""
        echo "Please configure your settings in ./config/ and try again"
        exit 1
    }

    echo -e "${BLUE}Validating Packer templates...${NC}"
    docker-compose run --rm packer ./validate.sh "$@"
}

run_shell() {
    print_header
    echo -e "${BLUE}Opening shell in container...${NC}"
    docker-compose run --rm packer /bin/bash
}

clean() {
    print_header
    echo -e "${YELLOW}This will remove Docker images and containers${NC}"
    echo -e "${RED}Are you sure? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning up...${NC}"
        docker-compose down -v
        docker rmi mtea-fsg-automation:latest 2>/dev/null || true
        echo -e "${GREEN}Cleanup complete${NC}"
    else
        echo "Cancelled"
    fi
}

rebuild() {
    print_header
    echo -e "${BLUE}Rebuilding Docker image from scratch...${NC}"
    docker-compose build --no-cache
    echo -e "${GREEN}Rebuild complete${NC}"
}

# Main script
check_docker

case "${1:-}" in
    setup)
        setup
        ;;
    build)
        shift
        run_build "$@"
        ;;
    validate)
        shift
        run_validate "$@"
        ;;
    shell)
        run_shell
        ;;
    clean)
        clean
        ;;
    rebuild)
        rebuild
        ;;
    help|--help|-h)
        print_header
        print_usage
        ;;
    *)
        print_header
        echo -e "${RED}Error: Invalid option${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac
