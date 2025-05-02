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

# Determine the directory of the script - handle both Linux and macOS
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")

# Function to validate email addresses
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format"
        return 1
    fi
    return 0
}

# Function to add or update a variable in config file
update_config_var() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file")"
    
    # Create the file if it doesn't exist
    if [ ! -f "$file" ]; then
        echo "${key}=${value}" > "$file"
        echo "Created $file with $key=$value."
        return
    fi
    
    # Check if the key already exists in the file
    if grep -q "^${key}=" "$file"; then
        # Update existing key - use temp file for compatibility with BSD and GNU sed
        local tmpfile=$(mktemp)
        grep -v "^${key}=" "$file" > "$tmpfile"
        echo "${key}=${value}" >> "$tmpfile"
        mv "$tmpfile" "$file"
        echo "Updated $key in $file."
    else
        # Add a blank line if file is not empty and doesn't end with one
        if [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ]; then
            echo "" >> "$file"
        fi
        # Append the new key-value pair
        echo "${key}=${value}" >> "$file"
        echo "Appended $key to $file."
    fi
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

# Define the config.env file path
CONFIG_ENV="$SCRIPT_DIR/../config.env"

# Exit early if local installation
if [ "$INSTALL_TYPE" = "local" ]; then
    echo "You have chosen to install on a local machine. No SSL configuration is required."
    
    # Update the configuration file
    update_config_var "$CONFIG_ENV" "INSTALL_TYPE" "local"
    
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
            read -p "Please enter your ZeroSSL EAB HMAC KEY: " ZEROSSL_EAB_HMAC_KEY
            if [ -n "$ZEROSSL_EAB_HMAC_KEY" ]; then
                break
            else
                echo "ERROR: ZeroSSL API token cannot be empty"
            fi
        done

        # Get ZeroSSL Key ID with validation
        while true; do
            read -p "Please enter your ZeroSSL Access Key ID: " ZEROSSL_ACCESS_KEY_ID
            if [ -n "$ZEROSSL_ACCESS_KEY_ID" ]; then
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
    read -p "Please enter your email address: " EMAIL
    if [ -n "$EMAIL" ]; then
        if validate_email "$EMAIL"; then
            break
        fi
    else
        echo "ERROR: Email address cannot be empty"
    fi
done

# Update the main config.env file
update_config_var "$CONFIG_ENV" "INSTALL_TYPE" "$INSTALL_TYPE"
update_config_var "$CONFIG_ENV" "SSL_PROVIDER" "$SSL_PROVIDER"
update_config_var "$CONFIG_ENV" "EMAIL" "$EMAIL"

# If using ZeroSSL, add the API token and key ID
if [ "$SSL_PROVIDER" = "zerossl" ]; then
    update_config_var "$CONFIG_ENV" "ZEROSSL_EAB_HMAC_KEY" "$ZEROSSL_EAB_HMAC_KEY"
    update_config_var "$CONFIG_ENV" "ZEROSSL_ACCESS_KEY_ID" "$ZEROSSL_ACCESS_KEY_ID"
    kubectl create secret generic zerossl-eab-secret \
    --namespace cert-manager \
    --from-literal=secret="YOUR_ZEROSSL_EAB_HMAC_KEY_HERE"
fi

# Define the config file paths

ENV_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/overlay/$SSL_PROVIDER/config.env"
MLFLOW_FILE="$SCRIPT_DIR/../deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/../deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/../deployment/monitoring/prometheus/config.env"

# Create/update the cert-manager config file
update_config_var "$ENV_FILE" "SSL_PROVIDER" "$SSL_PROVIDER"
update_config_var "$ENV_FILE" "EMAIL" "$EMAIL"
if [ "$SSL_PROVIDER" = "zerossl" ]; then
    update_config_var "$ENV_FILE" "ZEROSSL_EAB_HMAC_KEY" "$ZEROSSL_EAB_HMAC_KEY"
    update_config_var "$ENV_FILE" "ZEROSSL_ACCESS_KEY_ID" "$ZEROSSL_ACCESS_KEY_ID"
fi

# Define an array of target files
TARGET_FILES=("$MLFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

# Write the SSL_PROVIDER and EMAIL to each target file
for FILE in "${TARGET_FILES[@]}"; do
    update_config_var "$FILE" "SSL_PROVIDER" "$SSL_PROVIDER"
    update_config_var "$FILE" "EMAIL" "$EMAIL"
done

# For cloud installations, run the hostname finding script
if [ -f "$SCRIPT_DIR/Finding_Hostname.sh" ]; then
    echo "Running hostname detection script..."
    chmod +x "$SCRIPT_DIR/Finding_Hostname.sh"
    /bin/bash "$SCRIPT_DIR/Finding_Hostname.sh"
else
    echo "ERROR: Finding_Hostname.sh script not found"
    exit 1
fi

echo "SSL configuration completed successfully and saved to config files."
exit 0