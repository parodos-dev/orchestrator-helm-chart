#!/bin/bash

usage() {
  echo "Usage: $0 [-e environment]"
  echo "Options:"
  echo "  -e environment: Specify the npm registry environment."
  echo "                 Accepted values are:"
  echo "                 - production - for https://npm.registry.redhat.com"
  echo "                 - staging - for https://npm.stage.registry.redhat.com"
  echo "                 - upstream - for https://registry.npmjs.org/"
  echo "  -h: Display this help message"
  exit 1
}

# Check if -e option is provided
if [[ $# -eq 0 ]]; then
  usage
fi

# Extract environment value
while getopts ":e:h" opt; do
  case $opt in
    e)
      ENVIRONMENT="$OPTARG"
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEMPLATE_FILE="${TEMPLATE_FILE:-${SCRIPT_DIR}/../charts/orchestrator/templates/rhdh-operator.yaml}"

case $ENVIRONMENT in
    "upstream")
      REGISTRY="https://registry.npmjs.org"
      SCOPE="janus-idp"
      VALUES_FILE="${SCRIPT_DIR}/../charts/orchestrator/values.yaml"
      ;;
    "production")
      REGISTRY="https://npm.registry.redhat.com"
      SCOPE="redhat"
      VALUES_FILE="${SCRIPT_DIR}/../charts/orchestrator/values-plugins-stable.yaml"
      ;;
    "staging")
      REGISTRY="https://npm.stage.registry.redhat.com"
      SCOPE="redhat"
      VALUES_FILE="${SCRIPT_DIR}/../charts/orchestrator/values-plugins-stable.yaml"
      ;;
    *)
      echo "Invalid environment specified. Please specify 'staging', 'production' or 'upstream'."
      exit 1
      ;;
esac

# Maps plugins elements from values yaml to their name
declare -A PLUGINS
PLUGINS["notifications"]="plugin-notifications"
PLUGINS["notifications_backend"]="plugin-notifications-backend-dynamic"
PLUGINS["orchestrator"]="backstage-plugin-orchestrator"
PLUGINS["orchestrator_backend"]="backstage-plugin-orchestrator-backend-dynamic"

get_plugin_info() {
  PLUGIN_NAME=$1
  local result=$(curl -sf -q "${REGISTRY}/@${SCOPE}/${PLUGIN_NAME}/" | \
    jq -r '.versions | keys_unsorted[-1] as $latest_version |
    .[$latest_version] | "\(.version)#\(.dist.integrity)"')
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo "$result"
  else
    echo "Failed to fetch plugin information for $PLUGIN_NAME from registry $REGISTRY" >&2
    exit 1
  fi
}

# Function to update YAML file with plugin information
update_plugins_in_yaml() {
  for PLUGIN_KEY in "${!PLUGINS[@]}"; do
    PLUGIN_NAME=${PLUGINS[$PLUGIN_KEY]}
    PLUGIN_INFO=$(get_plugin_info "$PLUGIN_NAME")
    PLUGIN_VERSION=$(echo $PLUGIN_INFO | cut -d '#' -f 1)
    PLUGIN_INTEGRITY=$(echo $PLUGIN_INFO | cut -d '#' -f 2)
    sed -i "/^  $PLUGIN_KEY:/!b;n;c\    package: \"$PLUGIN_NAME@$PLUGIN_VERSION\"" "$VALUES_FILE"
    sed -i "/^  $PLUGIN_KEY:/!b;n;n;c\    integrity: $PLUGIN_INTEGRITY" "$VALUES_FILE"
  done

  if [ "$ENVIRONMENT" != "upstream" ]; then
    sed -i "s|npmRegistry: .*|npmRegistry: ${REGISTRY}|" $VALUES_FILE
  fi
}

# Run function to replace plugin versions and integrity in the YAML template
update_plugins_in_yaml "$TEMPLATE_FILE"