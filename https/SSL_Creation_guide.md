# SSL Creation Script Guide

This guide explains how to use the `SSL_Creation.sh` script to set up SSL for your Kubernetes cluster using cert-manager.

## Overview

The script performs the following:
- Validates and sources the configuration from `config.env`
- Installs or re-installs `cert-manager`
- Disables and re-enables cert-manager webhooks to ensure compatibility
- Applies the appropriate SSL configuration based on the `INSTALL_TYPE` (local or cloud)
- Supports both Let's Encrypt and ZeroSSL as providers

---

## 📁 Prerequisites

1. **Ensure `config.env` exists** at the root level of your project (`../config.env` relative to the script).
2. Kubernetes cluster is running and `kubectl` is configured.
3. Internet access to pull cert-manager manifests from GitHub.
4. You have run the `SSL_Details.sh` script first to generate the configuration.

---

## 🧾 Configuration File (`config.env`)

Required keys:
- `INSTALL_TYPE`: either `local` or `cloud`
- `SSL_PROVIDER`: `letsencrypt` or `zerossl` (only for cloud)
- `EMAIL`: contact email
- `ZEROSSL_EAB_HMAC_KEY` and `ZEROSSL_ACCESS_KEY_ID` (only for ZeroSSL)

---

## 🚀 Running the Script

Make the script executable and run it:

```bash
chmod +x SSL_Creation.sh
./SSL_Creation.sh
```

---

## 🔍 What the Script Does

### 1. **Environment Setup**
- Ensures `config.env` is present.
- Copies it to `.platform/.config` and sources it.

### 2. **cert-manager Cleanup**
- Deletes existing cert-manager resources.
- Waits to ensure they are removed.

### 3. **cert-manager Installation**
- Installs CRDs and base resources.
- Temporarily disables webhooks for smoother initial installation.

### 4. **SSL Configuration (Cloud Only)**
- Applies provider-specific overlay manifests (`overlay/letsencrypt` or `overlay/zerossl`).
- Uses a temp directory to apply `.yaml` files individually.
- Re-applies overlay after re-enabling webhooks.

### 5. **Secret Creation (ZeroSSL)**
- Creates a Kubernetes secret `zerossl-eab-secret` with the HMAC key.

---

## 📌 Output

At the end, you will see:
- ClusterIssuers and Certificates applied
- Any warnings about individual file application
- Final confirmation: `SSL creation completed successfully.`

---

## 🛠 Troubleshooting

- **Missing `config.env`**: Ensure you ran the setup script (`SSL_Details.sh`) before.
- **Overlay not found**: Confirm the directory exists under `cert-manager/overlay/{provider}`.
- **Webhook errors**: The script handles webhook issues by disabling/re-enabling them. Retry if needed.

---

## ✅ Notes

- This script is designed for **modular SSL setup** in a microservices-based Kubernetes deployment.
- It is part of a broader platform deployment pipeline and works best when run in sequence with the setup scripts.

