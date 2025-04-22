#!/bin/bash

# filepath: /Users/ayushghimire/Documents/GitHub/oss-mlops-platform/scripts/User_ssl_details.sh

# Determine the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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
        SSL_PROVIDER="lets-encrypt"
        ;;
    * )
        echo "Invalid choice. Defaulting to Let's Encrypt."
        SSL_PROVIDER="lets-encrypt"
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



# Create config.env file
cat > "$SCRIPT_DIR/../config.env" <<EOF
SSL_PROVIDER=$SSL_PROVIDER
EMAIL=$USER_EMAIL
DOMAIN=$DOMAIN_NAME
INSTALL_TYPE=$INSTALL_TYPE

EOF

# Create a general-purpose ConfigMap (no namespace specified)
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ssl-config
data:
  SSL_PROVIDER: "$SSL_PROVIDER"
  EMAIL: "$USER_EMAIL"
  DOMAIN: "$DOMAIN_NAME"
EOF

echo "General-purpose ConfigMap 'ssl-config' applied (default namespace)."


