#!/bin/bash
set -euo pipefail # Exit on error, undefined vars or pipe failures

NAMESPACE="vote"
FORCE_DELETE=false

# Check optional --force flag
if [[ "${1:-}" == "--force" ]] || [[ "${1:-}" == "-f" ]]; then
  FORCE_DELETE=true
fi

if kubectl get NAMESPACE "$NAMESPACE" >/dev/null 2>&1; then
  if [ "$FORCE_DELETE" = true ]; then
    echo "Force flag detected. Deleting existing namespace: $NAMESPACE"
    kubectl delete namespace "$NAMESPACE" --wait=true
    echo "namespace deleted. Recreating..."
    kubectl create namespace "$NAMESPACE"
  else
    echo "Namespace '$NAMESPACE' already exists. Skipping creation."
    echo "Run with --force to recreate it."
  fi
else
  echo "Creating namespace '$NAMESPACE'..."
  kubectl create namespace "$NAMESPACE"
fi
