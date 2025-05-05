# Cloud Setup Guide for HTTPS Setup Script

This guide explains how to use the `setup.sh` script from the `https-setup-script` branch to configure the application on a cloud environment. It also clarifies why this branch is not suitable for local installations and provides guidance on choosing the appropriate Certificate Authority (CA).

## Overview

The `setup.sh` script is designed to configure the application with HTTPS support in a Kubernetes cluster. The `https-setup-script` branch is specifically tailored for **cloud deployments** and is not intended for local installations. For local setups, use the `main` branch instead.

When running the `setup.sh` script, it will prompt you to confirm whether you are deploying on a **cloud** or **local** environment. For cloud deployments, you must specify `cloud` as the environment, as this branch relies on Kustomization resources that require cloud-specific variables (e.g., `ssl_provider`). These variables are not needed for local setups.

## Cloud Deployment

### Prerequisites

- A Kubernetes cluster running in a cloud environment.
- Cert-Manager installed in the `cert-manager` namespace.
- Access to the `https-setup-script` branch of the repository.
- A valid email address and domain name for certificate issuance.
- The `setup.sh` script and associated Kustomization files (e.g., `kustomization.yaml`, `letsclusterissuer.yaml`, `letscertificate.yaml`).

### Setup Instructions

1. **Clone the Repository**:

   - Clone the repository and checkout the `https-setup-script` branch:

     ```bash
     git clone <repository-url>
     cd <repository-directory>
     git checkout https-setup-script
     ```

2. **Run the** `setup.sh` **Script**:

   - Execute the `setup.sh` script:

     ```bash
     ./setup.sh
     ```

   - The script will prompt you to specify whether you are running the application on a **local** or **cloud** environment.

3. **Select Cloud Environment**:

   - When prompted, enter `cloud` to indicate a cloud deployment. Do **not** enter `local`, as the `https-setup-script` branch is not designed for local installations.

     ```
     Are you running the app on local or cloud? (Enter 'cloud' for cloud deployment): cloud
     ```

   - Entering `local` will result in an error or unsupported behavior, as this branch requires cloud-specific configurations.

4. **Choose Certificate Authority**:

   - The script will prompt you to select a Certificate Authority (CA) for SSL certificate issuance. The options are:
     - **Let's Encrypt**
     - **ZeroSSL**

   - **Important**: Currently, the **ZeroSSL** option is **not working** due to an issue with the API secret configuration. Therefore, you must select **Let's Encrypt** as the CA.

     ```
     Choose SSL provider (letsencrypt/zerossl): letsencrypt
     ```

   - Let's Encrypt is fully functional and will issue certificates without issues.

5. **Provide Configuration Values**:

   - The script may prompt for additional configuration values, such as:
     - Email address for ACME registration.
     - Domain name for the certificate.
   - These values are typically stored in a `config.env` file, which is used by the Kustomization to generate a ConfigMap.

6. **Apply Kustomization**:

   - The script will apply the Kustomization resources (e.g., `letsclusterissuer.yaml`, `letscertificate.yaml`) to the Kubernetes cluster.
   - Ensure the `config.env` file contains the required variables:

     ```
     EMAIL=your@email.com
     DOMAIN=example.com
     ```

   - The Kustomization will use these values to configure the `ClusterIssuer` and `Certificate` resources.

7. **Verify Certificate Issuance**:

   - After the script completes, verify that the certificate has been issued:

     ```bash
     kubectl -n cert-manager describe certificate myapp-cert
     ```

   - Check the Cert-Manager logs for any errors:

     ```bash
     kubectl -n cert-manager logs -l app=cert-manager
     ```

## Local Installation

The `https-setup-script` branch is **not suitable** for local installations because it includes Kustomization resources that depend on cloud-specific variables (e.g., `ssl_provider`). These variables are unnecessary for local setups and may cause configuration errors.

If you want to install the application on a **local machine**, follow these steps:

1. **Switch to the Main Branch**:

   - Checkout the `main` branch:

     ```bash
     git checkout main
     ```

2. **Run the Local Setup**:

   - Use the setup instructions provided in the `main` branch, which are designed for local environments.
   - The `main` branch does not require cloud-specific configurations like `ssl_provider`.

3. **Follow Local Setup Instructions**:

   - Refer to the documentation in the `main` branch for local installation steps. These typically involve running the application without Kustomization or Cert-Manager dependencies.

## Why Choose Let's Encrypt?

- **ZeroSSL Issue**: The ZeroSSL configuration is currently broken due to an error in the API secret (related to the External Account Binding secret). This issue prevents ZeroSSL from issuing certificates.
- **Let's Encrypt Reliability**: Let's Encrypt is working correctly and is recommended for cloud deployments. It does not require External Account Binding credentials, making it simpler to configure.
- **Future Fixes**: If the ZeroSSL API secret issue is resolved, ZeroSSL may become a viable option again. Check the repository for updates or fixes.

## Troubleshooting

- **Certificate Not Issued**:
  - Verify the `ClusterIssuer` status: