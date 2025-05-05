# 🔐 SSL Configuration Guide

This guide walks you through using the `SSL_Details.sh` script to configure SSL for your local or cloud-based deployment. The script supports both **ZeroSSL** and **Let's Encrypt** as certificate authorities and sets up the necessary configuration files.

---

## 📁 Script Location

Make sure you're running the script from your deployment setup. It should be located in a directory like this:

```bash
your-project/
├── scripts/
│   └── SSL_Details.sh
├── config.env
└── deployment/
```

---

## ✅ Prerequisites

- Bash shell (Linux/macOS)
- Valid email address
- (For ZeroSSL) EAB credentials (HMAC Key + Access Key ID)

---

## 🚀 Running the Script

To begin the SSL configuration process, run:

```bash
bash scripts/SSL_Details.sh
```

---

## 🖥️ Step 1: Choose Installation Type

You will be prompted to specify whether you are installing on a **local machine** or a **cloud instance**:

```
Are you installing on a local machine or a cloud instance? [local/cloud]:
```

- If `local`, no SSL will be configured, and the script exits.
- If `cloud`, you'll proceed with SSL provider selection.

---

## 🔐 Step 2: Choose SSL Provider

You'll be prompted to choose an SSL certificate provider:

```
Would you like to use ZeroSSL (requires API token) or Let's Encrypt?
[1] ZeroSSL
[2] Let's Encrypt
```

- Press `1` for **ZeroSSL** – you will need:
  - **EAB HMAC Key**
  - **Access Key ID**
- Press `2` or Enter to choose **Let's Encrypt**

---

## 📧 Step 3: Enter Email Address

You'll then be asked for your email address. This is required by certificate providers to register your account.

---

## 🛠️ What the Script Does

- Creates or updates a main config file: `config.env`
- Writes appropriate SSL settings (provider, email, tokens) to:
  - `deployment/kubeflow/.../cert-manager/overlay/[provider]/config.env`
  - `deployment/mlflow/base/config.env`
  - `deployment/kubeflow/.../pipeline/config.env`
  - `deployment/monitoring/grafana/config.env`
  - `deployment/monitoring/prometheus/config.env`
- Calls `Finding_Hostname.sh` to determine the hostname (must be present in the same directory)

---

## ⚠️ Errors and Troubleshooting

- If an invalid email is entered, the script will ask again.
- If `Finding_Hostname.sh` is not found, the script will display an error and exit.
- The script uses `set -e` for early failure handling—any failure halts execution.

---

## ✅ Example Output

```bash
Are you installing on a local machine or a cloud instance? [local/cloud]: cloud
Would you like to use ZeroSSL (requires API token) or Let's Encrypt?
[1] ZeroSSL
[2] Let's Encrypt
Enter your choice [1-2] (default is [2]): 1
Please enter your ZeroSSL EAB HMAC KEY: ****
Please enter your ZeroSSL Access Key ID: ****
Please enter your email address: your.email@example.com
Running hostname detection script...
SSL configuration completed successfully and saved to config files.
```

---

## 📎 Notes

- This script ensures all your components use consistent SSL settings.
- You can re-run the script anytime to change the provider or email.
