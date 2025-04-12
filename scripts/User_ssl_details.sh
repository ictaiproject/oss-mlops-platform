#!/bin/bash

# Ask the user for domain name
read -p "Please enter your domain name: " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Domain name cannot be empty"
    exit 1
fi

# Validate USER_EMAIL
if [ -z "$USER_EMAIL" ]; then
    echo "Error: Email address cannot be empty"
    exit 1
fi

# Validate SSL_PROVIDER
if [ -z "$SSL_PROVIDER" ]; then
    echo "Error: SSL_PROVIDER is not set. Please choose 'letsencrypt' or 'zerossl'."
    exit 1
fi

# Define the config.env file paths
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ENV_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/base/config.env"
MLFLOW_ENV_FILE="$SCRIPT_DIR/../deployment/mlflow/config.env"

# Create the config.env file and save SSL configurations in both locations
echo "Creating config.env file at $ENV_FILE and $MLFLOW_ENV_FILE..."
{
    echo "SSL_PROVIDER=$SSL_PROVIDER"
    echo "EMAIL=$USER_EMAIL"
    echo "DOMAIN=$DOMAIN_NAME"
    if [ "$SSL_PROVIDER" == "zerossl" ]; then
        echo "ZEROSSL_API_TOKEN=$ZEROSSL_API_TOKEN"
        echo "ZEROSSL_KEY_ID=$ZEROSSL_KEY_ID"
    fi
} > "$ENV_FILE"

# Save the same content to the mlflow location
{
    echo "DOMAIN=$DOMAIN_NAME"
} > "$MLFLOW_ENV_FILE"

echo "SSL configuration completed successfully and saved to:"
echo "  - $ENV_FILE"
echo "  - $MLFLOW_ENV_FILE"