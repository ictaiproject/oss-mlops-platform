set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SETUP_DIR="$SCRIPT_DIR/../deployment/kubeflow/manifests/common/cert-manager/cert-manager"

# Create directory structure

mkdir -p "$SETUP_DIR/overlays/letsencrypt"
mkdir -p "$SETUP_DIR/overlays/zerossl"



kubectl apply -k "$SETUP_DIR/base"
kubectl apply -k "$SETUP_DIR/overlays/$SSL_PROVIDER"




