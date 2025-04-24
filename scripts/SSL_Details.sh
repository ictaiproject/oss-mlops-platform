#!/bin/bash

# Exit on error, but handle errors properly
set -o errexit
set -o pipefail

# Function for error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error in SSL_Details.sh on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up the error trap
trap 'handle_error $? $LINENO' ERR

# Determine the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Function to validate email addresses
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format"
        return 1
    fi
    return 0
}

# Function to validate domain names
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        echo "ERROR: Invalid domain name format"
        return 1
    fi
    return 0
}

# Ask user for installation type
while true; do
    read -p "Are you installing on a local machine or a cloud instance? [local/cloud]: " INSTALL_TYPE
    INSTALL_TYPE=$(echo "$INSTALL_TYPE" | tr '[:upper:]' '[:lower:]')
    
    if [ "$INSTALL_TYPE" = "local" ] || [ "$INSTALL_TYPE" = "cloud" ]; then
        break
    else
        echo "ERROR: Please enter either 'local' or 'cloud'"
    fi
done

# Exit early if local installation
if [ "$INSTALL_TYPE" = "local" ]; then
    echo "You have chosen to install on a local machine. No SSL configuration is required."
    
    # Still need to create a minimal config
    CONFIG_ENV="$SCRIPT_DIR/../config.env"
    
    # Create or append to the config file
    if [ -f "$CONFIG_ENV" ]; then
        # Add a blank line if the file is not empty and doesn't already end with one
        if [ -s "$CONFIG_ENV" ] && [ -n "$(tail -c1 "$CONFIG_ENV")" ]; then
            echo "" >> "$CONFIG_ENV"
        fi
    else
        # Create the file if it doesn't exist
        touch "$CONFIG_ENV"
    fi
    
    # Add the installation type to config
    echo "INSTALL_TYPE=local" >> "$CONFIG_ENV"
    
    echo "Local configuration saved to $CONFIG_ENV"
    echo "Exiting SSL configuration script."
    exit 0
fi

# For cloud installations, continue with SSL configuration
echo "SSL Configuration:"
echo "Would you like to use ZeroSSL (requires API token) or Let's Encrypt?"
echo "[1] ZeroSSL"
echo "[2] Let's Encrypt"
read -p "Enter your choice [1-2] (default is [2]): " ssl_choice

case "$ssl_choice" in
    1 ) 
        SSL_PROVIDER="zerossl"
        
        # Get ZeroSSL API token with validation
        while true; do
            read -p "Please enter your ZeroSSL API token: " ZEROSSL_API_TOKEN
            if [ -n "$ZEROSSL_API_TOKEN" ]; then
                break
            else
                echo "ERROR: ZeroSSL API token cannot be empty"
            fi
        done

        # Get ZeroSSL Key ID with validation
        while true; do
            read -p "Please enter your ZeroSSL Key ID: " ZEROSSL_KEY_ID
            if [ -n "$ZEROSSL_KEY_ID" ]; then
                break
            else
                echo "ERROR: ZeroSSL Key ID cannot be empty"
            fi
        done
        ;;
    2 | "" )
        SSL_PROVIDER="letsencrypt"
        ;;
    * )
        echo "Invalid choice. Defaulting to Let's Encrypt."
        SSL_PROVIDER="letsencrypt"
        ;;
esac

# Get email with validation
while true; do
    read -p "Please enter your email address: " USER_EMAIL
    if [ -n "$USER_EMAIL" ]; then
        if validate_email "$USER_EMAIL"; then
            break
        fi
    else
        echo "ERROR: Email address cannot be empty"
    fi
done

# Get domain with validation
while true; do
    read -p "Please enter your domain name: " DOMAIN_NAME
    if [ -n "$DOMAIN_NAME" ]; then
        if validate_domain "$DOMAIN_NAME"; then
            break
        fi
    else
        echo "ERROR: Domain name cannot be empty"
    fi
done

# Define the config.env file path
CONFIG_ENV="$SCRIPT_DIR/../config.env"

# Create or append to the config file
if [ -f "$CONFIG_ENV" ]; then
    # Add a blank line if the file is not empty and doesn't already end with one
    if [ -s "$CONFIG_ENV" ] && [ -n "$(tail -c1 "$CONFIG_ENV")" ]; then
        echo "" >> "$CONFIG_ENV"
    fi
else
    # Create the file if it doesn't exist
    touch "$CONFIG_ENV"
fi

# Function to add or update a variable in config.env
set_config_var() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    # Remove any existing definition
    if grep -q "^${key}=" "$file"; then
        # Use a temporary file to avoid issues with in-place editing
        local tmpfile=$(mktemp)
        grep -v "^${key}=" "$file" > "$tmpfile"
        mv "$tmpfile" "$file"
    fi
    
    # Add the new definition
    echo "${key}=${value}" >> "$file"
}

# Set the configuration variables
set_config_var "INSTALL_TYPE" "$INSTALL_TYPE" "$CONFIG_ENV"
set_config_var "SSL_PROVIDER" "$SSL_PROVIDER" "$CONFIG_ENV"
set_config_var "EMAIL" "$USER_EMAIL" "$CONFIG_ENV"
set_config_var "DOMAIN" "$DOMAIN_NAME" "$CONFIG_ENV"

# If using ZeroSSL, add the API token and key ID
if [ "$SSL_PROVIDER" = "zerossl" ]; then
    set_config_var "ZEROSSL_API_TOKEN" "$ZEROSSL_API_TOKEN" "$CONFIG_ENV"
    set_config_var "ZEROSSL_KEY_ID" "$ZEROSSL_KEY_ID" "$CONFIG_ENV"
fi

# Create directory paths if they don't exist
mkdir -p "$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/base"
mkdir -p "$SCRIPT_DIR/../deployment/mlflow/base"
mkdir -p "$SCRIPT_DIR/../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline"
mkdir -p "$SCRIPT_DIR/../deployment/monitoring/grafana"
mkdir -p "$SCRIPT_DIR/../deployment/monitoring/prometheus"

# Define the config file paths
ENV_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/base/config.env"
MLFLOW_FILE="$SCRIPT_DIR/../deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/../deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/../deployment/monitoring/prometheus/config.env"

# Create the cert-manager config file
echo "Creating config.env file at $ENV_FILE..."
{
    echo "SSL_PROVIDER=$SSL_PROVIDER"
    echo "EMAIL=$USER_EMAIL"
    echo "DOMAIN=$DOMAIN_NAME"
    if [ "$SSL_PROVIDER" = "zerossl" ]; then
        echo "ZEROSSL_API_TOKEN=$ZEROSSL_API_TOKEN"
        echo "ZEROSSL_KEY_ID=$ZEROSSL_KEY_ID"
    fi
} > "$ENV_FILE" || {
    echo "ERROR: Failed to write to $ENV_FILE"
    exit 1
}

# Define an array of target files
TARGET_FILES=("$MLFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

# Write the DOMAIN to each target file
for FILE in "${TARGET_FILES[@]}"; do
    echo "Writing DOMAIN to $FILE..."
    {
        echo "DOMAIN=$DOMAIN_NAME"
    } > "$FILE" || {
        echo "ERROR: Failed to write to $FILE"
        exit 1
    }
done

echo "SSL configuration completed successfully and saved to config files."
exit 0