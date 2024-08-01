#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# File path to the YAML template relative to the script's directory
TEMPLATE_FILE="${SCRIPT_DIR}/../values.yaml"

# Define PLUGINS list
PLUGINS=(
  # TODO notifications are not published upstream for now.
  #"@janus-idp/plugin-notifications"
  #"@janus-idp/plugin-notifications-backend-dynamic"
  "@janus-idp/backstage-plugin-orchestrator"
  "@janus-idp/backstage-plugin-orchestrator-backend-dynamic"
)


# Function to update YAML file with plugin information
update_plugins_in_yaml() {
  for PLUGIN_NAME in "${PLUGINS[@]}"; do
    out=$(curl -s -q "https://registry.npmjs.com/${PLUGIN_NAME}/latest" | jq '{id:._id, integrity: .dist.integrity}')
    package=$(echo "$out" | jq .id)
    integrity=$(echo "$out" | jq .integrity)
    yq -i ".backstage.global.dynamic.plugins[] |= select(.package == \"${PLUGIN_NAME}@*\") |= (.package = $package, .integrity = $integrity)"  "$TEMPLATE_FILE"
  done
}

# Run function to replace plugin versions and integrity in the YAML template
update_plugins_in_yaml "$TEMPLATE_FILE"

