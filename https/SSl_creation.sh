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


echo "ClusterIssuer for Cloudflare created."

# --- Step 3: Update Ingress Host to Domain Name ---
echo "Updating Ingress host to domain name: $CLOUDFLARE_DOMAIN"
kubectl patch ingress mlflow-ingress -n mlflow --type='json' -p="[
  {
    \"op\": \"replace\",
    \"path\": \"/spec/rules/0/host\",
    \"value\": \"$CLOUDFLARE_DOMAIN\"
  },
  {
    \"op\": \"replace\",
    \"path\": \"/spec/tls/0/hosts/0\",
    \"value\": \"$CLOUDFLARE_DOMAIN\"
  }
]"

echo "Ingress host updated to $CLOUDFLARE_DOMAIN."

# --- Step 4: Retrieve Ingress Controller IP ---
echo "Retrieving Ingress Controller IP..."
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$INGRESS_IP" ]; then
  echo "Error: Could not retrieve Ingress Controller IP. Ensure the ingress-nginx service is configured with a LoadBalancer."
  exit 1
fi

echo "Ingress Controller IP: $INGRESS_IP"

# --- Step 5: Output DNS Configuration ---
echo "Please configure your DNS settings as follows:"
echo "Domain: $CLOUDFLARE_DOMAIN"
echo "IP Address: $INGRESS_IP"