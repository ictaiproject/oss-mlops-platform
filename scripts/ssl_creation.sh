#!/bin/bash

# Load environment variables from .env file
set -a
source .env
set +a

# --- Validate Required Variables ---
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_EMAIL" ] || [ -z "$CLOUDFLARE_DOMAIN" ] || [ -z "$SECRET_NAMESPACE" ]; then
  echo "Error: Missing required environment variables. Ensure the .env file is properly configured."
  exit 1
fi

# --- Step 1: Create the Secret for Cloudflare API ---
kubectl create secret generic cloudflare-api-secret \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  --from-literal=email="$CLOUDFLARE_EMAIL" \
  --from-literal=domain="$CLOUDFLARE_DOMAIN" \
  --from-literal=secret-namespace="$SECRET_NAMESPACE" \
  -n cert-manager --dry-run=client -o yaml | kubectl apply -f -

echo "Cloudflare API token and details saved to Kubernetes Secret."

# --- Step 2: Create ClusterIssuer for Cloudflare ---





