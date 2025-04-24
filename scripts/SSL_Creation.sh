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
mkdir -p "$PLATFORM_DIR"
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

echo "Applying cert-manager base resources..."
if ! kubectl apply -k "$SETUP_DIR/base"; then
    echo "ERROR: Failed to apply cert-manager base resources"
    exit 1
fi

# Apply SSL provider configuration for cloud deployments
if [ "$INSTALL_TYPE" = "cloud" ]; then
    # Check if SSL_PROVIDER overlay exists
    if [ ! -d "$SETUP_DIR/overlay/$SSL_PROVIDER" ]; then
        echo "ERROR: SSL provider overlay directory not found at $SETUP_DIR/overlay/$SSL_PROVIDER"
        exit 1
    fi

    echo "Applying $SSL_PROVIDER SSL provider configuration..."
    if ! kubectl apply -k "$SETUP_DIR/overlay/$SSL_PROVIDER"; then
        echo "ERROR: Failed to apply $SSL_PROVIDER SSL provider configuration"
        exit 1
    fi
    
    echo "Checking certificate request status..."
    if ! kubectl get certificaterequest --all-namespaces; then
        echo "ERROR: Failed to get certificate requests"
        exit 1
    fi
    
    echo "Waiting for cert-manager pods to be ready..."
    if ! kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=180s; then
        echo "WARNING: Not all cert-manager pods are ready yet. This might be normal during initial deployment."
        # Don't exit here, as this might be normal during initial deployment
    fi
    
    echo "SSL provider configuration applied successfully."
else
    echo "Local deployment detected. Skipping SSL provider configuration."
fi

echo "SSL creation completed successfully."
exit 0