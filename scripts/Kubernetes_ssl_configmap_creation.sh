SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PLATFORM_DIR="$SCRIPT_DIR/.platform"
mkdir -p "$PLATFORM_DIR"
PLATFORM_CONFIG="$PLATFORM_DIR/.config"
cp "$SCRIPT_DIR/../config.env" "$PLATFORM_CONFIG"

# Source config to get INSTALL_TYPE and SSL_PROVIDER
source "$PLATFORM_CONFIG"

SETUP_DIR="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager"

kubectl apply -k "$SETUP_DIR/base"
if [ "$INSTALL_TYPE" = "cloud" ]; then
    kubectl apply -k "$SETUP_DIR/overlay/$SSL_PROVIDER"
    kubectl get certificaterequest --all-namespaces 
fi