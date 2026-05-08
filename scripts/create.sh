#!/bin/bash
set -euo pipefail

SECRET_NAME="pulse-secrets"
NAMESPACE="vote"
MANIFEST_DIR="$(dirname "$0")/../k8s"
# Check if needed secrets has been set
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: '$SECRET_NAME' secret is missing in '$NAMESPACE'"
  exit 1
fi

echo "Applying manifests from $MANIFEST_DIR..."
kubectl apply -f "$MANIFEST_DIR" -n "$NAMESPACE"

echo "Waiting for vote-deployment to be ready.."

if kubectl wait --for=condition=avaible --timeout=90s deployment/backend -n "$NAMESPACE"; then
  echo "All pods are running."
else
  echo "Error: deployment failed or timed out"
  kubectl get pods -n "$NAMESPACE"
  exit 1
fi
