#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# File path to the YAML template relative to the script's directory
CHART_FILE="${CHART_FILE:-${SCRIPT_DIR}/../charts/orchestrator/Chart.yaml}"

# Function to bump the version
bump_version() {
    local line_name="$1"
    local increment_type="$2"
    local version_line=$(grep "^${line_name}" "${CHART_FILE}")
    local current_version=$(echo "${version_line}" | awk '{print $2}')
    local major=$(echo "${current_version}" | cut -d '.' -f1)
    local minor=$(echo "${current_version}" | cut -d '.' -f2)
    local patch=$(echo "${current_version}" | cut -d '.' -f3)
    
    case "${increment_type}" in
        minor)
            ((minor++))
            patch=0  # Reset patch version to 0 after bumping minor version
            ;;
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            echo "Invalid increment type"
            exit 1
            ;;
    esac

    new_version="${major}.${minor}.${patch}"
    sed -i "s/^${line_name} .*/${line_name} ${new_version}/" "${CHART_FILE}"
}

# Display usage
usage() {
    echo "Usage: $0 <flag>"
    echo "Flags:"
    echo "  --bump-minor-version       : Bump minor version and set patch to 0"
    echo "  --bump-major-version       : Bump major version"
    echo "  --bump-patch-version       : Bump patch version"
    echo "  --bump-minor-app-version   : Bump minor app version and set patch to 0"
    echo "  --bump-major-app-version   : Bump major app version"
    echo "  --bump-patch-app-version   : Bump patch app version"
}

# Check if exactly one argument is provided
if [ $# -ne 1 ]; then
    echo "Error: Incorrect number of arguments"
    usage
    exit 1
fi

# Parse flag
case "$1" in
    --bump-minor-version)
        bump_version "version:" "minor"
        ;;
    --bump-major-version)
        bump_version "version:" "major"
        ;;
    --bump-patch-version)
        bump_version "version:" "patch"
        ;;
    --bump-minor-app-version)
        bump_version "appVersion:" "minor"
        ;;
    --bump-major-app-version)
        bump_version "appVersion:" "major"
        ;;
    --bump-patch-app-version)
        bump_version "appVersion:" "patch"
        ;;
    *)
        echo "Error: Invalid flag: $1"
        usage
        exit 1
        ;;
esac
