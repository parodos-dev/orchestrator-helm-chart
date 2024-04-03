#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENVIRONMENT=staging
# File path to the YAML template relative to the script's directory
TEMPLATE_FILE="${SCRIPT_DIR}/../charts/orchestrator/templates/rhdh-operator.yaml"
VALUES_FILE="${SCRIPT_DIR}/../charts/orchestrator/values.yaml"

usage() {
  echo "Usage: $0 [-o Npm organization] [-r Npm registry]"
  echo "Options:"
  echo "  -o ORG: Specify the npm organization. Can be used for debugging personal npm accounts. (default: janus-idp for upstream, redhat for staging and production)"  
  echo "  -e Environment: Specify the npm registry environment. production for https://npm.registry.redhat.com, staging for https://npm.stage.registry.redhat.com, upstream for https://registry.npmjs.org/ (default: staging)"  
  echo "  -h: Display this help message"
  exit 1
}

while getopts ":o:e:h" opt; do
  case $opt in
    o)
      ORG="$OPTARG"
      ;;
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

case $ENVIRONMENT in
    "upstream")
        REGISTRY="https://registry.npmjs.org"
        ORG=${ORG-janus-idp}
        ;;
    "production")
        REGISTRY="https://npm.registry.redhat.com"
        ORG=redhat
        ;;
    "staging")
      REGISTRY="https://npm.stage.registry.redhat.com"
      ORG=redhat
      ;;
    *)
        echo "Invalid environment specified. Please specify 'staging', 'production' or 'upstream'."
        exit 1
        ;;
esac

PLUGINS=(
  "plugin-notifications"
  "plugin-notifications-backend-dynamic"
  "backstage-plugin-orchestrator"
  "backstage-plugin-orchestrator-backend-dynamic"
)

get_plugin_info() {
  PLUGIN_NAME=$1
  local result=$(curl -sf -q "${REGISTRY}/@$ORG/${PLUGIN_NAME}/" | \
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
  for PLUGIN_NAME in "${PLUGINS[@]}"; do    
    PLUGIN_VERSION=$(get_plugin_info "$PLUGIN_NAME" | cut -d '#' -f 1)    
    PLUGIN_INTEGRITY=$(get_plugin_info "$PLUGIN_NAME" | cut -d '#' -f 2)
    sed -i "s|@.*\\/${PLUGIN_NAME//\//\\/}@.*|@${ORG}/${PLUGIN_NAME}@${PLUGIN_VERSION}\"|g; /${PLUGIN_NAME//\//\\/}/{n;n;s|\(^\s*\)\(sha512\).*|\1${PLUGIN_INTEGRITY}|}" $TEMPLATE_FILE
  done
  sed -i "s|npmRegistry: .*|npmRegistry: ${REGISTRY}|" $VALUES_FILE
}

# Run function to replace plugin versions and integrity in the YAML template
update_plugins_in_yaml "$TEMPLATE_FILE"
