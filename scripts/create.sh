#!/bin/bash
set -euo pipefail

NAMESPACE="vote"

if ! kubectl get secret pulse-secrets -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: 'pulse-secrets' is missing. Run setup.sh first."
  exit 1
fi

echo "Deploying via Helm..."
helm upgrade --install pulse ./sentinel -n "$NAMESPACE"

echo "Waiting for backend to be ready..."
if kubectl wait --for=condition=available --timeout=120s deployment/pulse-backend -n "$NAMESPACE"; then
  echo "Deployment successful!"
else
  echo "Error: Deployment failed or timed out."
  kubectl get pods -n "$NAMESPACE"
  exit 1
fi
