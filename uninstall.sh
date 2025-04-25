#!/bin/bash

# Exit on error, but handle errors properly
set -o errexit
set -o pipefail

# Function for error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error in uninstall.sh on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up the error trap
trap 'handle_error $? $LINENO' ERR

# Determine the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PLATFORM_DIR="$SCRIPT_DIR/.platform"
PLATFORM_CONFIG="$PLATFORM_DIR/.config"

echo "Starting uninstallation process..."

# Check if the platform directory exists
if [ -d "$PLATFORM_DIR" ]; then
    # Check if the configuration file exists
    if [ -f "$PLATFORM_CONFIG" ]; then
        echo "Loading platform configuration..."
        source "$PLATFORM_CONFIG"
    else
        echo "WARNING: Platform configuration file not found: $PLATFORM_CONFIG"
        echo "Will attempt to continue uninstallation with default values."
        # Set default values
        CLUSTER_NAME="ml-platform"
        INSTALL_LOCAL_REGISTRY="false"
    fi
else
    echo "WARNING: Platform directory not found: $PLATFORM_DIR"
    echo "Will attempt to continue uninstallation with default values."
    # Set default values
    CLUSTER_NAME="ml-platform"
    INSTALL_LOCAL_REGISTRY="false"
    
    # Ask for confirmation
    read -p "No platform installation detected. Continue with default uninstallation? (y/n): " confirm
    if [[ "$confirm" != [Yy]* ]]; then
        echo "Uninstallation canceled."
        exit 0
    fi
fi

# Function to safely delete a cluster
safely_delete_cluster() {
    local cluster_name=$1
    
    # Check if kind is installed
    if ! command -v kind &> /dev/null; then
        echo "WARNING: 'kind' command not found. Skipping cluster deletion."
        return 1
    fi
    
    # Check if cluster exists
    if kind get clusters | grep -q "^$cluster_name$"; then
        echo "Deleting kind cluster: $cluster_name"
        if ! kind delete cluster --name "$cluster_name"; then
            echo "WARNING: Failed to delete cluster $cluster_name"
            return 1
        fi
        echo "Cluster $cluster_name deleted successfully."
    else
        echo "Cluster $cluster_name not found. Skipping deletion."
    fi
    
    return 0
}

# Function to safely delete Docker registry
safely_delete_registry() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "WARNING: 'docker' command not found. Skipping registry deletion."
        return 1
    fi
    
    # Check if registry container exists
    if docker ps -a | grep -q "kind-registry"; then
        echo "Deleting the local Docker registry..."
        
        # Stop the registry if it's running
        if docker ps | grep -q "kind-registry"; then
            if ! docker stop kind-registry; then
                echo "WARNING: Failed to stop kind-registry container"
            fi
        fi
        
        # Remove the registry container
        if ! docker rm kind-registry; then
            echo "WARNING: Failed to remove kind-registry container"
            return 1
        fi
        
        echo "Local Docker registry deleted."
    else
        echo "Docker registry container not found. Skipping deletion."
    fi
    
    return 0
}

# Function to safely delete files
safely_delete_files() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo "Deleting $file..."
            if ! rm -f "$file"; then
                echo "WARNING: Failed to delete $file"
            fi
        else
            echo "File $file does not exist. Skipping."
        fi
    done
}

# Delete the cluster
if ! safely_delete_cluster "$CLUSTER_NAME"; then
    echo "WARNING: There were issues deleting the cluster. Continuing with uninstallation."
fi

# Delete the local Docker registry if it was installed
if [ "$INSTALL_LOCAL_REGISTRY" = "true" ]; then
    if ! safely_delete_registry; then
        echo "WARNING: There were issues deleting the Docker registry. Continuing with uninstallation."
    fi
fi

# Define config files to delete
ENV_FILE="$SCRIPT_DIR/deployment/kubeflow/manifests/common/cert-manager/cert-manager/overlay/$SSL_PROVIDER/config.env"
MLFLOW_FILE="$SCRIPT_DIR/deployment/mlflow/base/config.env"
KUBEFLOW_FILE="$SCRIPT_DIR/deployment/kubeflow/manifests/apps/pipeline/upstream/base/pipeline/config.env"
GRAFANA_FILE="$SCRIPT_DIR/deployment/monitoring/grafana/config.env"
PROMETHEUS_FILE="$SCRIPT_DIR/deployment/monitoring/prometheus/config.env"

# Define an array of target files
TARGET_FILES=("$ENV_FILE" "$MLFLOW_FILE" "$KUBEFLOW_FILE" "$GRAFANA_FILE" "$PROMETHEUS_FILE")

# Delete configuration files
echo "Cleaning up configuration files..."
safely_delete_files "${TARGET_FILES[@]}"

# Clean up platform directory
if [ -d "$PLATFORM_DIR" ]; then
    echo "Removing platform directory..."
    if ! rm -rf "$PLATFORM_DIR"; then
        echo "WARNING: Failed to remove $PLATFORM_DIR"
    fi
fi

# Clean up any lingering docker images (optional)
if command -v docker &> /dev/null; then
    echo "Checking for lingering Docker resources..."
    
    # List containers that might be related to the platform
    CONTAINERS=$(docker ps -a --filter "name=k8s_" --format "{{.ID}}")
    if [ -n "$CONTAINERS" ]; then
        echo "Found lingering containers. Would you like to remove them? (y/n): "
        read -r remove_containers
        if [[ "$remove_containers" =~ ^[Yy] ]]; then
            echo "Removing lingering containers..."
            docker rm -f $CONTAINERS || echo "WARNING: Failed to remove some containers"
        fi
    fi
    
    # Check for dangling images
    DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
    if [ -n "$DANGLING_IMAGES" ]; then
        echo "Found dangling Docker images. Would you like to remove them? (y/n): "
        read -r remove_images
        if [[ "$remove_images" =~ ^[Yy] ]]; then
            echo "Removing dangling images..."
            docker rmi $DANGLING_IMAGES || echo "WARNING: Failed to remove some images"
        fi
    fi
fi

echo "The platform has been successfully uninstalled."
echo "If you want to reinstall, run ./setup.sh"
exit 0