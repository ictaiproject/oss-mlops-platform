#!/bin/bash

# Function to check and install required tools
ensure_tool_installed() {
    local tool="$1"
    if ! command -v "$tool" &> /dev/null; then
        echo "$tool is not installed. Installing..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update
            sudo apt-get install -y "$tool"
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y "$tool"
        else
            echo "ERROR: Unsupported package manager. Please install $tool manually."
            exit 1
        fi
    else
        echo "$tool is already installed."
    fi
}

# Define script directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")

# Make sure necessary tools are installed
ensure_tool_installed curl
ensure_tool_installed dig

# Automatically detect public IP address
echo "Detecting public IP address..."
IP_ADDRESS=$(curl -s ifconfig.me)

if [ -z "$IP_ADDRESS" ]; then
    echo "ERROR: Failed to retrieve public IP address."
    exit 1
fi
echo "Detected IP address: $IP_ADDRESS"

# Do a reverse DNS lookup
echo "Looking up hostname from IP address..."
DOMAIN=$(dig +short -x "$IP_ADDRESS")

# Remove any trailing dot
DOMAIN=${DOMAIN%.}

# Get SSL_PROVIDER from config.env if it exists
CONFIG_ENV="$SCRIPT_DIR/../config.env"
if [ -f "$CONFIG_ENV" ]; then
    source "$CONFIG_ENV"
    echo "SSL_PROVIDER=$SSL_PROVIDER"
fi

# Validate domain or fallback
if [ -z "$DOMAIN" ]; then
    echo "WARNING: No hostname found for IP. Using IP as domain."
    DOMAIN="$IP_ADDRESS"
fi

echo "Using domain: $DOMAIN"

# Define target files
ENV_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/overlay/$SSL_PROVIDER/config.env"
MLFLOW_FILE="$SCRIPT_DIR/../deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/../deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/../deployment/monitoring/prometheus/config.env"

TARGET_FILES=("$ENV_FILE" "$MLFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

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

# Update domain in all target files
for FILE in "${TARGET_FILES[@]}"; do
    update_config_var "$FILE" "DOMAIN" "$DOMAIN"
done