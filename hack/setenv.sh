#!/bin/bash
function exportWorkflowNamespace {
  default="sonataflow-infra"
  if [ "$use_default" == true ]; then
    workflow_namespace="$default"
  else
    read -p "Enter workflow namespace (default: $default): " value
    if [ -z "$value" ]; then
        workflow_namespace="$default"
    else
        workflow_namespace="$value"
    fi
  fi
  echo "export WORKFLOW_NAMESPACE=$workflow_namespace" >> .env
}

function exportK8sURL {
  url="$(oc whoami --show-server)"
  echo "export K8S_CLUSTER_URL=$url" >> .env
}

function exportK8sToken {
  sa_namespace="orchestrator"
  sa_name="orchestrator"
  if [ "$use_default" == false ]; then
    read -p "Which namespace should be used or created to check the SA holding the persistent token? (default: $sa_namespace): "
    if [ -n "$sa_namespace" ]; then
      sa_namespace="$sa_namespace"
    fi

    read -p "What is the name of the SA? (default: $sa_name): " selected_name
    if [ -n "$selected_name" ]; then
      sa_name="$selected_name"
    fi
  fi
  if oc get namespace "$sa_namespace" &> /dev/null; then
    echo "Namespace '$sa_namespace' already exists."
  else
    echo "Namespace '$sa_namespace' does not exist. Creating..."
    oc create namespace "$sa_namespace"
  fi

  if oc get sa -n "$sa_namespace" $sa_name &> /dev/null; then
    echo "ServiceAccount '$sa_name' already exists in '$sa_namespace'."
  else
    echo "ServiceAccount '$sa_name' does not exist in '$sa_namespace'. Creating..."
    oc create sa "$sa_name" -n "$sa_namespace"
  fi

  oc adm policy add-cluster-role-to-user cluster-admin -z $sa_name -n $sa_namespace
  echo "Added cluster-admin role to '$sa_name' in '$sa_namespace'."
  token_secret=$(oc get secret -o name -n $sa_namespace | grep ${sa_name}-token)
  token=$(oc get -n $sa_namespace ${token_secret} -o jsonpath="{.data.token}" | sed 's/"//g' | base64 -d)
  echo "export K8S_CLUSTER_TOKEN=$token" >> .env
}

function exportGitToken {
   if [ -z "$GITHUB_TOKEN" ]; then
    read -s -p "Enter GitHub access token: " value
    echo ""
    echo "export GITHUB_TOKEN=$value" >> .env
  else
    echo "GitHub access token already set."
  fi
}

function exportArgoCDNamespace {
  default="orchestrator-gitops"
  if [ "$use_default" == true ]; then
    argocd_namespace="$default"
  else
    read -p "Enter ArgoCD installation namespace (default: $default): " value

    if [ -z "$value" ]; then
        argocd_namespace="$default"
    else
        argocd_namespace="$value"
    fi
  fi
  echo "export ARGOCD_NAMESPACE=$argocd_namespace" >> .env
}

function exportArgoCDURL {
  argocd_instances=$(oc get argocd -n "$argocd_namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  if [ -z "$argocd_instances" ]; then
      echo "No ArgoCD instances found in namespace $argocd_namespace."
      exit 1
  fi

  if [ "$use_default" == true ]; then
        selected_instance=$(echo "$argocd_instances" | awk 'NR==1')
        echo "Select an ArgoCD instance: $selected_instance"
  else
    echo "Select an ArgoCD instance:"
    select instance in $argocd_instances; do
        if [ -n "$instance" ]; then
            selected_instance="$instance"
            break
        else
            echo "Invalid selection. Please choose a valid option."
        fi
    done
  fi

  argocd_route=$(oc get route -n $argocd_namespace -l app.kubernetes.io/managed-by=$selected_instance -ojsonpath='{.items[0].status.ingress[0].host}')
  echo "Found Route at $argocd_route"
  echo "export ARGOCD_URL=https://$argocd_route" >> .env
  echo 
}

function exportArgoCDCreds {
  admin_password=$(oc get secret -n $argocd_namespace ${selected_instance}-cluster -ojsonpath='{.data.admin\.password}' | base64 -d)
  echo "export ARGOCD_USERNAME=admin" >> .env
  echo "export ARGOCD_PASSWORD=$admin_password" >> .env
}

function checkPrerequisite {
  if ! command -v oc &> /dev/null; then
    echo "oc is required for this script to run. Exiting."
    exit 1
  fi
}

function cleanUpEnvFile {
  echo "" > .env
}

# Function to display usage instructions
display_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help        Display usage instructions"
    echo "  --use-default     Specify to use all default values"
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_usage
            ;;
        --use-default)
            use_default=true
            ;;
        *)
            echo "Error: Invalid option $1"
            display_usage
            ;;
    esac
    shift
done


# Check if using default values or not
if [ "$use_default" == "true" ]; then
    echo "Using default values."
else
    echo "Not using default values."
fi

checkPrerequisite
cleanUpEnvFile
exportWorkflowNamespace
exportK8sURL
exportK8sToken
exportGitToken
exportArgoCDNamespace
exportArgoCDURL
exportArgoCDCreds
echo "Setup completed successfully! Please run 'source .env' to export the environment variables."


