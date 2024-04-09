#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

CHART_FILE="${SCRIPT_DIR}/../Chart.yaml" "${SCRIPT_DIR}/../../../hack/bump_chart_version.sh" "$@"

