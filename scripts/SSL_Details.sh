#!/bin/bash

# Exit on error, but handle the errors properly
set -o errexit
set -o pipefail

# Function for error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up the error trap
trap 'handle_error $? $LINENO' ERR

# Internal directory where to store platform settings
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PLATFORM_DIR="$SCRIPT_DIR/.platform"
mkdir -p "$PLATFORM_DIR"
PLATFORM_CONFIG="$PLATFORM_DIR/.config"

# Copy the config or exit if it fails
if ! cp "$SCRIPT_DIR/config.env" "$PLATFORM_CONFIG"; then
    echo "ERROR: Failed to copy config.env to $PLATFORM_CONFIG"
    exit 1
fi

# Source the config file
if ! source "$PLATFORM_CONFIG"; then
    echo "ERROR: Failed to source $PLATFORM_CONFIG"
    exit 1
fi

# Set default values
RUN_TESTS=false
LOG_LEVEL_TESTS="WARNING"

# Parse command line arguments
while true; do
    if [ "$1" = "--test" -o "$1" = "-t" ]; then
        RUN_TESTS=true
        shift 1
    elif [ "$1" = "--debug" -o "$1" = "-d" ]; then
        LOG_LEVEL_TESTS="INFO"
        shift 1
    else
        break
    fi
done

# Display configuration
echo "Cluster name set to: $CLUSTER_NAME"
echo "Host IP set to: $HOST_IP"
echo "Run tests after installation set to: $RUN_TESTS"

# Select deployment option
DEFAULT_DEPLOYMENT_OPTION="kubeflow-monitoring"
echo
echo "Please choose the deployment option:"
echo "[1] Kubeflow (all components)"
echo "[2] Kubeflow (without monitoring)"
echo "[3] Standalone KFP"
echo "[4] Standalone KFP (without monitoring)"
echo "[5] Standalone KFP and Kserve"
echo "[6] Standalone KFP and Kserve (without monitoring)"
read -p "Enter the number of your choice [1-6] (default is [1]): " choice
case "$choice" in
    1 ) DEPLOYMENT_OPTION="kubeflow-monitoring" ;;
    2 ) DEPLOYMENT_OPTION="kubeflow" ;;
    3 ) DEPLOYMENT_OPTION="standalone-kfp-monitoring" ;;
    4 ) DEPLOYMENT_OPTION="standalone-kfp" ;;
    5 ) DEPLOYMENT_OPTION="standalone-kfp-kserve-monitoring" ;;
    6 ) DEPLOYMENT_OPTION="standalone-kfp-kserve" ;;
    * ) DEPLOYMENT_OPTION="$DEFAULT_DEPLOYMENT_OPTION" ;;
esac

# Docker registry option
INSTALL_LOCAL_REGISTRY=true
echo
read -p "Install local Docker registry? (y/n) (default is [y]): " choice
case "$choice" in
    n|N ) INSTALL_LOCAL_REGISTRY=false ;;
    * ) INSTALL_LOCAL_REGISTRY=true ;;
esac

# Ray installation option
INSTALL_RAY=false
echo
read -p "Install Ray? (It requires ~4 additional CPUs) (y/n) (default is [n]): " choice
case "$choice" in
    y|Y ) INSTALL_RAY=true ;;
    * ) INSTALL_RAY=false ;;
esac

# Save selections to settings file
{
    echo -e "\nDEPLOYMENT_OPTION=$DEPLOYMENT_OPTION" >> "$PLATFORM_CONFIG"
    echo -e "\nINSTALL_LOCAL_REGISTRY=$INSTALL_LOCAL_REGISTRY" >> "$PLATFORM_CONFIG"
    echo -e "\nINSTALL_RAY=$INSTALL_RAY" >> "$PLATFORM_CONFIG"
} || {
    echo "ERROR: Failed to save settings to $PLATFORM_CONFIG"
    exit 1
}

# CHECK DISK SPACE
RECOMMENDED_DISK_SPACE_KUBEFLOW=26214400  # 25GB in KB
RECOMMENDED_DISK_SPACE_KUBEFLOW_GB=$(($RECOMMENDED_DISK_SPACE_KUBEFLOW / 1024 / 1024))
RECOMMENDED_DISK_SPACE_KFP=18874368  # 18GB in KB
RECOMMENDED_DISK_SPACE_KFP_GB=$(($RECOMMENDED_DISK_SPACE_KFP / 1024 / 1024))

if [[ "$DEPLOYMENT_OPTION" == *"kfp"* ]]; then
    RECOMMENDED_DISK_SPACE=$RECOMMENDED_DISK_SPACE_KFP
    RECOMMENDED_DISK_SPACE_GB=$RECOMMENDED_DISK_SPACE_KFP_GB
else
    RECOMMENDED_DISK_SPACE=$RECOMMENDED_DISK_SPACE_KUBEFLOW
    RECOMMENDED_DISK_SPACE_GB=$RECOMMENDED_DISK_SPACE_KUBEFLOW_GB
fi

# Get available disk space
if ! DISK_SPACE=$(df -k . | awk -F ' ' '{print $4}' | sed -n '2 p'); then
    echo "ERROR: Failed to get disk space information"
    exit 1
fi

DISK_SPACE_GB=$(($DISK_SPACE / 1024 / 1024))

# Check if there's enough disk space
if [[ $DISK_SPACE -lt $RECOMMENDED_DISK_SPACE ]]; then
    echo "WARNING: Not enough disk space detected!"
    echo "The recommended is > ${RECOMMENDED_DISK_SPACE_GB} GB of disk space. You have ${DISK_SPACE_GB} GB."
    while true; do
        read -p "Do you want to continue with the installation? (y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            "" ) echo "Please enter a response.";;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# CHECK CPU COUNT
RECOMMENDED_CPUS_KUBEFLOW=12
RECOMMENDED_CPUS_KFP=8
EXTRA_RAY_CPUS=4

if [[ "$DEPLOYMENT_OPTION" == *"kfp"* ]]; then
    RECOMMENDED_CPUS=$RECOMMENDED_CPUS_KFP
else
    RECOMMENDED_CPUS=$RECOMMENDED_CPUS_KUBEFLOW
fi

if [ "$INSTALL_RAY" = true ]; then
    RECOMMENDED_CPUS=$(($RECOMMENDED_CPUS + $EXTRA_RAY_CPUS))
fi

# Detect the OS
OS=$(uname)

# Get CPU count based on OS
if [ "$OS" = "Darwin" ]; then
    # For macOS
    if ! CPU_COUNT=$(sysctl -n hw.ncpu); then
        echo "ERROR: Failed to get CPU count"
        exit 1
    fi
else
    # For Linux
    if ! CPU_COUNT=$(nproc); then
        echo "ERROR: Failed to get CPU count"
        exit 1
    fi
fi

# Check if there are enough CPUs
if [[ $CPU_COUNT -lt $RECOMMENDED_CPUS ]]; then
    echo "WARNING: Not enough CPU cores detected!"
    echo "The recommended is >= ${RECOMMENDED_CPUS} CPU cores for this deployment configuration. You have ${CPU_COUNT} cores."
    while true; do
        read -p "Do you want to continue with the installation? (y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            "" ) echo "Please enter a response.";;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# INSTALL TOOLS
echo "Installing required tools..."
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific tooling
    if ! bash "$SCRIPT_DIR/scripts/SSL_Details.sh"; then
        echo "ERROR: Failed to run SSL_Details.sh"
        exit 1
    fi
    
    if ! bash "$SCRIPT_DIR/scripts/install_tools_mac.sh"; then
        echo "ERROR: Failed to install required tools for macOS"
        exit 1
    fi
else
    # Linux specific tooling
    if ! /bin/bash "$SCRIPT_DIR/scripts/SSL_Details.sh"; then
        echo "ERROR: Failed to run SSL_Details.sh"
        exit 1
    fi
    
    if ! /bin/bash "$SCRIPT_DIR/scripts/install_tools.sh"; then
        echo "ERROR: Failed to install required tools"
        exit 1
    fi
fi

# Function for logging errors related to cluster creation
function fail {
    printf "ERROR: %s\n" "$1" >&2
    printf "If the error is caused because the cluster already exists, you can delete it with the following command:\n"
    printf "kind delete cluster --name %s\n" "$CLUSTER_NAME"
    exit "${2-1}"  # Return a code specified by $2, or 1 by default
}

# CREATE CLUSTER
echo "Checking for existing cluster..."
if ! kind get clusters &>/dev/null; then
    echo "ERROR: 'kind' command not found or failed. Make sure it's installed properly."
    exit 1
fi

# Check if the kind cluster already exists
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo
    echo "Kind cluster with name \"$CLUSTER_NAME\" already exists."
    echo "It can be deleted with the following command: kind delete cluster --name $CLUSTER_NAME"
    while true; do
        read -p "Do you want to continue the installation on the existing cluster? (y/n): " choice
        case "$choice" in
            y|Y ) echo "Using existing kind cluster..."; break;;
            n|N ) echo "Exiting setup..."; exit 0;;
            "" ) echo "Please enter a response.";;
            * ) echo "Invalid response. Please enter y or n.";;
        esac
    done
else
    echo "Creating kind cluster..."
    if ! /bin/bash "$SCRIPT_DIR/scripts/create_cluster.sh"; then
        fail "Failed to create kind cluster" 2
    fi
fi

# Check cluster connectivity
echo "Checking cluster connectivity..."
if ! kubectl cluster-info --context kind-"$CLUSTER_NAME"; then
    echo "ERROR: Failed to connect to the cluster"
    exit 1
fi

# Handle SSL setup for cloud deployments
if [ "$INSTALL_TYPE" = "cloud" ]; then
    echo "Setting up SSL for cloud deployment..."
    if ! /bin/bash "$SCRIPT_DIR/scripts/SSL_Creation.sh"; then
        echo "ERROR: Failed to set up SSL certificates"
        exit 1
    fi
fi

# DEPLOY LOCAL DOCKER REGISTRY
if [ "$INSTALL_LOCAL_REGISTRY" = true ]; then
    echo "Setting up local Docker registry..."
    if ! /bin/bash "$SCRIPT_DIR/scripts/install_local_registry.sh"; then
        echo "ERROR: Failed to install local Docker registry"
        exit 1
    fi
fi

# DEPLOY STACK
echo "Setting kubectl context..."
if ! kubectl config use-context kind-"$CLUSTER_NAME"; then
    echo "ERROR: Failed to set kubectl context"
    exit 1
fi

# Build the kustomization and store the output in a temporary file
tmp_file=$(mktemp)
DEPLOYMENT_ROOT="$SCRIPT_DIR/deployment/envs/$DEPLOYMENT_OPTION"
echo "Deployment root set to: $DEPLOYMENT_ROOT"
echo
echo "Building manifests..."
if ! kustomize build "$DEPLOYMENT_ROOT" > "$tmp_file"; then
    echo "ERROR: Failed to build manifests"
    rm -f "$tmp_file"
    exit 1
fi
echo "Manifests built successfully."

# Apply the manifests with retries
echo "Applying resources..."
retry_count=0
max_retries=10
success=false

while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
    if kubectl apply -f "$tmp_file"; then
        echo "Resources successfully applied."
        success=true
    else
        retry_count=$((retry_count + 1))
        echo
        echo "Retry $retry_count of $max_retries to apply resources."
        echo "Be patient, this might take a while... (Errors are expected until all resources are available!)"
        echo
        echo "Help:"
        echo "  If the errors persist, please check the pods status with: kubectl get pods --all-namespaces"
        echo "  All pods should be either in Running state, or ContainerCreating if they are still starting up."
        echo "  Check specific pod errors with: kubectl describe pod -n [NAMESPACE] [POD_NAME]"
        echo "  For further help, see the Troubleshooting section in setup.md"
        echo

        if [ $retry_count -eq $max_retries ]; then
            echo "ERROR: Failed to apply resources after $max_retries attempts"
            rm -f "$tmp_file"
            exit 1
        fi

        sleep 10
    fi
done

# Clean up the temporary file
rm -f "$tmp_file"

# DEPLOY RAY
if [ "$INSTALL_RAY" = true ]; then
    echo "Installing Ray..."
    if ! /bin/bash "$SCRIPT_DIR/scripts/install_helm.sh"; then
        echo "ERROR: Failed to install Helm"
        exit 1
    fi
    
    if ! /bin/bash "$SCRIPT_DIR/scripts/install_ray.sh"; then
        echo "ERROR: Failed to install Ray"
        exit 1
    fi
fi

# Run tests if requested
if [ "$RUN_TESTS" = "true" ]; then
    echo "Running tests..."
    if ! /bin/bash "$SCRIPT_DIR/scripts/run_tests.sh"; then
        echo "WARNING: Some tests failed. Check the logs for details."
        # Don't exit here, as test failures shouldn't prevent the rest of the setup
    fi
fi

echo
echo "Setting up Kubernetes SSL configuration..."
if ! /bin/bash "$SCRIPT_DIR/scripts/Kubernetes_ssl_configmap_creation.sh"; then
    echo "ERROR: Failed to setup Kubernetes SSL configuration"
    exit 1
fi

echo
echo "Installation completed successfully!"
echo "You can now access your deployment at: https://$DOMAIN_NAME (if you configured SSL)"
