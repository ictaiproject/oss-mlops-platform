#!/bin/bash

# --- Load environment variables from .env file ---
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# --- Validate Required Variables ---
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_EMAIL" ] || [ -z "$DOMAIN" ]; then
  echo "Error: One or more required environment variables are missing."
  exit 1
fi

# --- Save CA API Token to Kubernetes Secret ---
kubectl create secret generic ca-api-token-secret \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  -n "$SECRET_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "API Token for CA saved as Kubernetes Secret."

# --- Create ClusterIssuer for the CA ---
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: $CA_NAME
spec:
  acme:
    email: "$CLOUDFLARE_EMAIL"
    server: https://acme-v02.api.letsencrypt.org/directory  # Use ACME API URL of your CA
    privateKeySecretRef:
      name: $CA_NAME-account-key
    solvers:
    - dns01:
        cloudflare:
          email: "$CLOUDFLARE_EMAIL"
          apiTokenSecretRef:
            name: ca-api-token-secret
            key: api-token
EOF

echo "ClusterIssuer for $CA_NAME has been created."

# --- Create Certificate resource ---
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-cert-$DOMAIN
  namespace: $SECRET_NAMESPACE
spec:
  secretName: tls-secret-$DOMAIN
  issuerRef:
    name: $CA_NAME
    kind: ClusterIssuer
  commonName: $DOMAIN
  dnsNames:
  - $DOMAIN
EOF

echo "Certificate resource for $DOMAIN has been requested."

# --- Check the certificate status ---
echo "You can check the status with:"
echo "kubectl describe certificate tls-cert-$DOMAIN -n $SECRET_NAMESPACE"
