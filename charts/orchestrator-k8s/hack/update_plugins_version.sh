#!/bin/bash -x

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# File path to the YAML template relative to the script's directory
TEMPLATE_FILE="${SCRIPT_DIR}/../values.yaml"

# Define PLUGINS list
PLUGINS=(
  "@janus-idp/plugin-notifications"
  "@janus-idp/plugin-notifications-backend-dynamic"
  "@janus-idp/backstage-plugin-orchestrator"
  "@janus-idp/backstage-plugin-orchestrator-backend-dynamic"
)

# Function to fetch plugin information
get_plugin_info() {
  PLUGIN_NAME=$1
  curl -s -q "https://registry.npmjs.com/${PLUGIN_NAME}" | \
  jq -r '.versions | keys_unsorted[-1] as $latest_version |
  .[$latest_version] | "\(.version)#\(.dist.integrity)"'
}

# Function to update YAML file with plugin information
update_plugins_in_yaml() {
  for PLUGIN_NAME in "${PLUGINS[@]}"; do
    PLUGIN_VERSION=$(get_plugin_info "$PLUGIN_NAME" | cut -d '#' -f 1)
    PLUGIN_INTEGRITY=$(get_plugin_info "$PLUGIN_NAME" | cut -d '#' -f 2)
    # Update YAML file
    sed -i "s|${PLUGIN_NAME//\//\\/}@.*|${PLUGIN_NAME}@${PLUGIN_VERSION}\"|g; /${PLUGIN_NAME//\//\\/}/{n;n;s|\(^\s*\)\(sha512\).*|\1${PLUGIN_INTEGRITY}|}" "$1"
  done
}

# Run function to replace plugin versions and integrity in the YAML template
update_plugins_in_yaml "$TEMPLATE_FILE"
