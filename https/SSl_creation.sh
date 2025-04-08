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
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: $CA_NAME
  namespace: cert-manager
spec:
  acme:
    email: "$CLOUDFLARE_EMAIL"
    server: https://acme-v02.api.letsencrypt.org/directory  # ACME API endpoint
    privateKeySecretRef:
      name: $CA_NAME-account-key
    solvers:
    - dns01:
        cloudflare:
          email: "$CLOUDFLARE_EMAIL"
          apiTokenSecretRef:
            name: cloudflare-api-secret
            key: api-token
EOF

echo "ClusterIssuer for Cloudflare has been created."

# --- Step 3: Create Certificate Resource ---
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-cert-$CLOUDFLARE_DOMAIN
  namespace: $SECRET_NAMESPACE
spec:
  secretName: myapp-cert
  issuerRef:
    name: $CA_NAME
    kind: ClusterIssuer
  commonName: $CLOUDFLARE_DOMAIN
  dnsNames:
  - $CLOUDFLARE_DOMAIN
EOF

echo "Certificate resource for $CLOUDFLARE_DOMAIN has been requested."

# --- Step 4: Check the certificate status ---
echo "You can check the status with:"
echo "kubectl describe certificate tls-cert-$CLOUDFLARE_DOMAIN -n $SECRET_NAMESPACE"
