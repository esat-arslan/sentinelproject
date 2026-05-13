#!/bin/bash
set -euo pipefail

NAMESPACE="vote"
FORCE_DELETE=false

if [[ "${1:-}" == "--force" ]] || [[ "${1:-}" == "-f" ]]; then
  FORCE_DELETE=true
fi

if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  if [ "$FORCE_DELETE" = true ]; then
    echo "Force flag detected. Deleting namespace: $NAMESPACE"
    kubectl delete namespace "$NAMESPACE" --wait=true
    kubectl create namespace "$NAMESPACE"
  else
    echo "Namespace '$NAMESPACE' already exists. Skipping."
  fi
else
  echo "Creating namespace '$NAMESPACE'..."
  kubectl create namespace "$NAMESPACE"
fi

if ! kubectl get secret pulse-secrets -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Creating secrets..."
  # Prompt for password if not provided in environment variable
  if [ -z "${DB_PASSWORD:-}" ]; then
    read -sp "Enter Database Password: " DB_PASSWORD
    echo
  fi
  kubectl create secret generic pulse-secrets \
    --from-literal=postgres-password="$DB_PASSWORD" \
    -n "$NAMESPACE"
fi
