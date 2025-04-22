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
#!/bin/bash

# filepath: /Users/ayushghimire/Documents/GitHub/oss-mlops-platform/scripts/delete_ssl_config_files.sh

# Define the paths of the files to delete
ENV_FILE="$SCRIPT_DIR/deployment/kubeflow/manifests/common/cert-manager/cert-manager/base/config.env"
MlFLOW_FILE="$SCRIPT_DIR/deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/deployment/monitoring/prometheus/config.env"

# Define an array of target files
TARGET_FILES=("$ENV_FILE" "$MlFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

# Delete each file
for FILE in "${TARGET_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "Deleting $FILE..."
        rm -f "$FILE" || {
            echo "Error: Failed to delete $FILE"
            exit 1
        }
    else
        echo "File $FILE does not exist. Skipping."
    fi
done

echo "All specified SSL configuration files have been deleted."

rm -rf "$PLATFORM_DIR"

echo "The platform has been successfully uninstalled."
exit 0
