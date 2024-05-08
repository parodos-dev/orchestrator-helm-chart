#!/usr/bin/env bash

function captureWorkflowNamespace {
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
  WORKFLOW_NAMESPACE=$workflow_namespace
}

function captureK8sURL {
  url="$(oc whoami --show-server)"
  K8S_CLUSTER_URL=$url
}

function generateBackendSecret {
  BACKEND_SECRET=$(mktemp -u XXXXXXXXXXXXXXXXXXXXXXX)
}

function generateK8sToken {
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
  K8S_CLUSTER_TOKEN=$token
}

function captureGitToken {
   if [ -z "$GITHUB_TOKEN" ]; then
    read -s -p "Enter GitHub access token: " value
    echo ""
    GITHUB_TOKEN=$value
  else
    echo "GitHub access token already set."
  fi
}

function captureArgoCDNamespace {
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
  ARGOCD_NAMESPACE=$argocd_namespace
}

function captureArgoCDURL {
  argocd_instances=$(oc get argocd -n "$argocd_namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  if [ -z "$argocd_instances" ]; then
      echo "No ArgoCD instances found in namespace $argocd_namespace. Continuing without ArgoCD support"
  else
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
    ARGOCD_URL=https://$argocd_route
  fi

}

function captureArgoCDCreds {
  if [ -n "$selected_instance" ]; then
    admin_password=$(oc get secret -n $argocd_namespace ${selected_instance}-cluster -ojsonpath='{.data.admin\.password}' | base64 -d)
    ARGOCD_USERNAME=admin
    ARGOCD_PASSWORD=$admin_password
  fi
}

function checkPrerequisite {
  if ! command -v oc &> /dev/null; then
    echo "oc is required for this script to run. Exiting."
    exit 1
  fi
}

function createBackstageSecret {
  if [[ $(oc get secret backstage-backend-auth-secret -n rhdh-operator) ]]; then
    oc delete secret backstage-backend-auth-secret -n rhdh-operator
  fi
  declare -A secretKeys
  if [ -n "$K8S_CLUSTER_URL" ]; then
    secretKeys[K8S_CLUSTER_URL]=$K8S_CLUSTER_URL
  fi
  if [ -n "$K8S_CLUSTER_TOKEN" ]; then
    secretKeys[K8S_CLUSTER_TOKEN]=$K8S_CLUSTER_TOKEN
  fi
  if [ -n "$ARGOCD_USERNAME" ]; then
    secretKeys[ARGOCD_USERNAME]=$ARGOCD_USERNAME
  fi
  if [ -n "$ARGOCD_URL" ]; then
    secretKeys[ARGOCD_URL]=$ARGOCD_URL
  fi
  if [ -n "$ARGOCD_PASSWORD" ]; then
    secretKeys[ARGOCD_PASSWORD]=$ARGOCD_PASSWORD
  fi
  if [ -n "$GITHUB_TOKEN" ]; then
    secretKeys[GITHUB_TOKEN]=$GITHUB_TOKEN
  fi
  cmd="oc create secret generic backstage-backend-auth-secret -n rhdh-operator --from-literal=BACKEND_SECRET=$BACKEND_SECRET"
  for key in "${!secretKeys[@]}"; do
    cmd="${cmd} --from-literal=${key}=${secretKeys[$key]}"
  done
  eval $cmd
}

function labelNamespaces {
  for a in $(oc get namespace -l rhdh.redhat.com/workflow-namespace -oname); do
    oc label $a rhdh.redhat.com/workflow-namespace- ;
  done
  for a in $(oc get namespace -l rhdh.redhat.com/argocd-namespace -oname); do
    oc label $a rhdh.redhat.com/argocd-namespace- ;
  done
  if [ -n "$WORKFLOW_NAMESPACE" ]; then
    oc label namespace $WORKFLOW_NAMESPACE rhdh.redhat.com/workflow-namespace=
  fi
  if [[ -n "$ARGOCD_NAMESPACE" && -n "$ARGOCD_PASSWORD" && -n "$ARGOCD_URL" && -n "$ARGOCD_USERNAME" ]]; then
    oc label namespace $ARGOCD_NAMESPACE rhdh.redhat.com/argocd-namespace=
  fi
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

function main {

  # Check if using default values or not
  if [ "$use_default" == "true" ]; then
      echo "Using default values."
  else
      echo "Not using default values."
  fi

  checkPrerequisite
  generateBackendSecret
  captureWorkflowNamespace
  captureK8sURL
  generateK8sToken
  captureGitToken
  captureArgoCDNamespace
  captureArgoCDURL
  captureArgoCDCreds
  createBackstageSecret
  labelNamespaces
  echo "Setup completed successfully!"
}

main


