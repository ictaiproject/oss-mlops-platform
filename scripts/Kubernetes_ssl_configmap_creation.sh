#!/bin/bash

set -e

# Define the config.env file path
ENV_FILE="../deployment/kubeflow/manifests/common/cert-manager/cert-manager/base/config.env"

# Check if the config.env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "🖥️ Installing on a local host. No SSL configuration is required."
  echo "Exiting script."
  exit 0
fi

# Load variables from config.env
echo "✅ config.env file found. Loading variables..."
export $(grep -v '^#' $ENV_FILE | xargs)

# Check required values
if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "❌ DOMAIN and EMAIL must be set in $ENV_FILE"
  exit 1
fi

# Create ConfigMap for DOMAIN and EMAIL
echo "✅ Creating ConfigMap 'cert-manager-config' in cert-manager namespace..."
kubectl create configmap cert-manager-config \
  --from-literal=domain="$DOMAIN" \
  --from-literal=email="$EMAIL" \
  -n cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Create Secret for ZeroSSL API token if available
if [[ -n "$ZEROSSL_API_TOKEN" ]]; then
  echo "✅ Creating Secret 'zerossl-api-secret' in cert-manager namespace..."
  kubectl create secret generic zerossl-api-secret \
    --from-literal=api-key="$ZEROSSL_API_TOKEN" \
    -n cert-manager --dry-run=client -o yaml | kubectl apply -f -
else
  echo "ℹ️ ZEROSSL_API_TOKEN is not set. Skipping Secret creation."
fi

echo "✅ SSL configuration completed successfully."

# Apply the selected configuration
if [ -z "$SSL_PROVIDER" ]; then
  echo "❌ SSL_PROVIDER is not set. Please set it to 'letsencrypt' or 'zerossl' in your config.env file."
  exit 1
fi

CA_DIR="./deployment/kubeflow/manifests/common/cert-manager/base/$SSL_PROVIDER"
echo "Applying certificate configuration from $CA_DIR..."
kubectl apply -k "$CA_DIR"

echo "✅ Certificate authority setup complete!"