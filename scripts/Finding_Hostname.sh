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

# Validate domain or fallback
if [ -z "$DOMAIN" ]; then
    echo "WARNING: No hostname found for IP. Using IP as domain."
    DOMAIN="$IP_ADDRESS"
fi


echo "Using domain: $DOMAIN"

ENV_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager/overlay/$SSL_PROVIDER/config.env"

MLFLOW_FILE="$SCRIPT_DIR/../deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/../deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/../deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/../deployment/monitoring/prometheus/config.env"

# Create the cert-manager config file
echo "Creating config.env file at $ENV_FILE..."
{
    echo "DOMAIN=$DOMAIN"
    
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
        echo "DOMAIN=$DOMAIN"
    } > "$FILE" || {
        echo "ERROR: Failed to write to $FILE"
        exit 1
    }
done


