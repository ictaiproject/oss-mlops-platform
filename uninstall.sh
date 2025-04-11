#!/bin/bash

set -eoa pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PLATFORM_DIR="$SCRIPT_DIR/.platform"
PLATFORM_CONFIG="$PLATFORM_DIR/.config"

# check if the platform directory exists
if [ -d "$PLATFORM_DIR" ]; then
    # source the configuration file
    source $PLATFORM_CONFIG
else
    echo "The platform directory not found: $PLATFORM_DIR"
    echo "Please run the setup.sh script first, or check the 'Manual deletion' section in the setup.md for manual deletion of the platform."
    exit 1
fi

# Delete the cluster
kind delete cluster --name $CLUSTER_NAME

if [ "$INSTALL_LOCAL_REGISTRY" = "true" ]; then
    # Delete the local Docker registry
    echo "Deleting the local Docker registry..."
    docker stop kind-registry
    docker rm kind-registry
    echo "Local Docker registry deleted."
fi

# Remove the .env file
ENV_FILE="/Users/ayushghimire/Documents/GitHub/oss-mlops-platform/deployment/kubeflow/manifests/common/cert-manager/cert-manager/base/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Deleting the .env file at $ENV_FILE..."
    rm -f "$ENV_FILE"
    echo ".env file deleted."
else
    echo "No .env file found at $ENV_FILE. Skipping."
fi

rm -rf "$PLATFORM_DIR"

echo "The platform has been successfully uninstalled."
exit 0
