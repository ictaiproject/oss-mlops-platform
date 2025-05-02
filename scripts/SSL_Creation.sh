#!/bin/bash

# Exit on error, but handle errors properly
set -o errexit
set -o pipefail

# Function for error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error in SSL_Creation.sh on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up the error trap
trap 'handle_error $? $LINENO' ERR

# Script location detection
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PLATFORM_DIR="$SCRIPT_DIR/../.platform"
PLATFORM_CONFIG="$PLATFORM_DIR/.config"

# First check if config.env exists
if [ ! -f "$SCRIPT_DIR/../config.env" ]; then
    echo "ERROR: config.env not found at $SCRIPT_DIR/../config.env"
    exit 1
fi

# Copy the config file
if ! cp "$SCRIPT_DIR/../config.env" "$PLATFORM_CONFIG"; then
    echo "ERROR: Failed to copy config.env to $PLATFORM_CONFIG"
    exit 1
fi

# Source the configuration
if ! source "$PLATFORM_CONFIG"; then
    echo "ERROR: Failed to source $PLATFORM_CONFIG"
    exit 1
fi

# Check if required variables are set
if [ -z "$INSTALL_TYPE" ]; then
    echo "ERROR: INSTALL_TYPE is not set in the configuration"
    exit 1
fi

if [ "$INSTALL_TYPE" = "cloud" ] && [ -z "$SSL_PROVIDER" ]; then
    echo "ERROR: SSL_PROVIDER is not set in the configuration"
    exit 1
fi

# Path to cert-manager setup directory
SETUP_DIR="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager"

# Check if directory exists
if [ ! -d "$SETUP_DIR" ]; then
    echo "ERROR: cert-manager directory not found at $SETUP_DIR"
    exit 1
fi 


# Clean up any existing cert-manager installation
echo "Cleaning up any existing cert-manager installation..."
kubectl delete -n cert-manager --all deployments,services,pods,secrets --ignore-not-found=true
kubectl delete namespace cert-manager --ignore-not-found=true
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true

echo "Waiting for cert-manager resources to be fully deleted..."
sleep 15

# Step 1: Install cert-manager with webhooks disabled
echo "Installing cert-manager with webhooks disabled..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml

# Apply base resources but temporarily disable the webhooks
echo "Applying cert-manager base resources..."
kubectl apply -k "$SETUP_DIR/base"

# Disable the webhooks immediately after installation
echo "Temporarily disabling webhook validations..."
kubectl delete -n cert-manager mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true
kubectl delete -n cert-manager validatingwebhookconfiguration cert-manager-webhook --ignore-not-found=true

echo "Waiting for cert-manager pods to be ready..."
kubectl -n cert-manager wait --for=condition=Available deployment/cert-manager-webhook --timeout=120s || {
    echo "WARNING: cert-manager webhook deployment not ready within timeout"
    kubectl get pods -n cert-manager
    echo "Continuing anyway..."
}
kubectl create secret generic zerossl-eab-secret \
    --namespace cert-manager \
    --from-literal=secret="YOUR_ZEROSSL_EAB_HMAC_KEY_HERE"


# Apply SSL provider configuration for cloud deployments
if [ "$INSTALL_TYPE" = "cloud" ]; then
    # Check if SSL_PROVIDER overlay exists
    if [ ! -d "$SETUP_DIR/overlay/$SSL_PROVIDER" ]; then
        echo "ERROR: SSL provider overlay directory not found at $SETUP_DIR/overlay/$SSL_PROVIDER"
        exit 1
    fi
    
    echo "Applying $SSL_PROVIDER SSL provider configuration..."
    
    # Extract and apply the ClusterIssuer and Certificate resources directly
    TEMP_DIR=$(mktemp -d)
    
    # Find all yaml files in the overlay directory
    find "$SETUP_DIR/overlay/$SSL_PROVIDER" -name "*.yaml" -type f | while read -r file; do
        # Skip kustomization files
        if [[ "$(basename "$file")" == "kustomization.yaml" ]]; then
            continue
        fi
        
        echo "Processing $file..."
        cp "$file" "$TEMP_DIR/$(basename "$file")"
        
        # Apply each file individually
        kubectl apply -f "$TEMP_DIR/$(basename "$file")" || {
            echo "WARNING: Failed to apply $(basename "$file"), will retry later..."
        }
    done
    
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    
    # Now re-enable the webhooks
    echo "Re-enabling cert-manager webhooks..."
    kubectl apply -k "$SETUP_DIR/base"
    
    echo "Waiting for webhooks to be ready..."
    sleep 30
    
    # Apply the overlay again with webhooks enabled
    echo "Applying $SSL_PROVIDER SSL provider configuration with webhooks enabled..."
    kubectl apply -k "$SETUP_DIR/overlay/$SSL_PROVIDER" || {
        echo "WARNING: Failed to apply $SSL_PROVIDER overlay with webhooks enabled"
        echo "Individual resources may still have been applied successfully"
    }
    
    echo "Checking certificate issuers status:"
    kubectl get clusterissuers --all-namespaces
    
    echo "Checking certificate status:"
    kubectl get certificates --all-namespaces
    
    echo "SSL provider configuration completed."
else
    echo "Local deployment detected. Skipping SSL provider configuration."
fi



echo "SSL creation completed successfully."
exit 0