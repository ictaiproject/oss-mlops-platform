#!/bin/bash

# Ask the user if they are installing on a local machine or a cloud instance
read -p "Are you installing on a local machine or a cloud instance? [local/cloud]: " INSTALL_TYPE

if [ "$INSTALL_TYPE" == "local" ]; then
    echo "You have chosen to install on a local machine. No SSL configuration is required."
    echo "Exiting SSL configuration script."
    exit 0
fi

# If the user chooses cloud, proceed with SSL configuration
echo "SSL Configuration:"
echo "Would you like to use ZeroSSL (requires API token) or Let's Encrypt?"
echo "[1] ZeroSSL"
echo "[2] Let's Encrypt"
read -p "Enter your choice [1-2] (default is [2]): " ssl_choice

case "$ssl_choice" in
    1 ) 
        SSL_PROVIDER="zerossl"
        read -p "Please enter your ZeroSSL API token: " ZEROSSL_API_TOKEN
        if [ -z "$ZEROSSL_API_TOKEN" ]; then
            echo "Error: ZeroSSL API token cannot be empty"
            exit 1
        fi

        read -p "Please enter your ZeroSSL Key ID: " ZEROSSL_KEY_ID
        if [ -z "$ZEROSSL_KEY_ID" ]; then
            echo "Error: ZeroSSL Key ID cannot be empty"
            exit 1
        fi
        ;;
    2 | "" )
        SSL_PROVIDER="letsencrypt"
        ;;
    * )
        echo "Invalid choice. Defaulting to Let's Encrypt."
        SSL_PROVIDER="letsencrypt"
        ;;
esac

# Get email and domain information
read -p "Please enter your email address: " USER_EMAIL
if [ -z "$USER_EMAIL" ]; then
    echo "Error: Email address cannot be empty"
    exit 1
fi

read -p "Please enter your domain name: " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Domain name cannot be empty"
    exit 1
fi

# Define the .env file path
ENV_FILE="../deployment/kubeflow/manifests/common/cert-manager/base/config.env"
MlFLOW_FILE="../deployment/mlflow/base/config.env"
KUBEFLOW_FILE="../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/kustomization.yaml"
GRAFANA_FILE="../deployment/monitoring/grafana/kustomization.yaml"
PROMETHEUS_FILE="../deployment/monitoring/prometheus/kustomization.yaml"
# Create the .env file and save SSL configurations


echo "Creating config.env file at $ENV_FILE..."
{
    echo "SSL_PROVIDER=$SSL_PROVIDER"
    echo "EMAIL=$USER_EMAIL"
    echo "DOMAIN=$DOMAIN_NAME"
    if [ "$SSL_PROVIDER" == "zerossl" ]; then
        echo "ZEROSSL_API_TOKEN=$ZEROSSL_API_TOKEN"
        echo "ZEROSSL_KEY_ID=$ZEROSSL_KEY_ID"
    fi
} > "$ENV_FILE"

# Define an array of target files
TARGET_FILES=("$MlFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

# Write the DOMAIN to each target file
for FILE in "${TARGET_FILES[@]}"; do
    echo "Writing DOMAIN to $FILE..."
    {
        echo "DOMAIN=$DOMAIN_NAME"
    } > "$FILE"
done



echo "SSL configuration completed successfully and saved to $ENV_FILE."