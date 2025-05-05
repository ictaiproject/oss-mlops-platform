# Using ZeroSSL and Let's Encrypt with Cert-Manager

This guide explains how to configure and use ZeroSSL and Let's Encrypt as Certificate Authorities (CAs) with Cert-Manager in a Kubernetes cluster, based on the provided Kustomization configuration. It includes prerequisites, setup steps, and details about the configuration.

## Overview

We are using **Cert-Manager** to automate the management and issuance of TLS certificates in a Kubernetes cluster. Two Certificate Authorities are configured:

1. **ZeroSSL**: A Certificate Authority that provides free SSL certificates via the ACME protocol, with support for External Account Binding (EAB) for authentication.
2. **Let's Encrypt**: A widely-used, free, and automated Certificate Authority that also uses the ACME protocol to issue SSL certificates.

Both CAs are integrated into the cluster via **ClusterIssuer** resources, and certificates are managed using **Certificate** resources. The configuration uses Kustomize to manage resources and inject environment-specific values (e.g., email, domain, and EAB keys) from a `config.env` file.

---

## ZeroSSL Configuration

### Purpose

ZeroSSL is used to issue SSL certificates for specific domains in the cluster. It requires an External Account Binding (EAB) for authentication, which is configured via a secret and a `keyID`.

### Prerequisites

To use ZeroSSL, you need:

- A ZeroSSL account.
- An **External Account Binding (EAB)** key pair, consisting of:
  - **EAB Key ID** (`ZEROSSL_ACCESS_KEY_ID`).
  - **EAB HMAC Key** (`ZEROSSL_EAB_HMAC_KEY`). These can be obtained from the ZeroSSL dashboard.
- A valid email address for ACME registration.
- A domain name for which the certificate will be issued.
- Cert-Manager installed in the Kubernetes cluster (in the `cert-manager` namespace).
- An ingress controller (e.g., NGINX) to handle HTTP-01 challenges.

### Configuration Details

The ZeroSSL configuration is defined in the following resources:

1. **ClusterIssuer (**`zerossl`**)**

   - Defined in `zerossl-clusterissuer.yaml`.
   - Uses the ZeroSSL ACME server: `https://acme.zerossl.com/v2/DV90`.
   - Configures an email address (replaced dynamically from `config.env`).
   - References a private key secret (`zerossl-prod`) for storing the ACME account key.
   - Configures EAB using:
     - `keyID`: Dynamically replaced from `ZEROSSL_ACCESS_KEY_ID` in `config.env`.
     - `keySecretRef`: References the `zerossl-eab-secret` secret, which contains the EAB HMAC key.
   - Uses the HTTP-01 solver with the NGINX ingress class to validate domain ownership.

2. **Certificate (**`myapp-cert`**)**

   - Defined in `zerossl-certificate.yaml`.
   - Requests a certificate for a domain specified in `spec.dnsNames.0`, dynamically replaced from `DOMAIN` in `config.env`.

3. **Secret (**`zerossl-eab-secret`**)**

   - Generated via `secretGenerator` in the Kustomization.
   - Contains the EAB HMAC key (`ZEROSSL_EAB_HMAC_KEY`) as a literal value under the key `secret`.

4. **ConfigMap (**`cert-manager-config`**)**

   - Generated from `config.env`.
   - Provides values for:
     - `EMAIL`: The email address for ACME registration.
     - `DOMAIN`: The domain for the certificate.
     - `ZEROSSL_ACCESS_KEY_ID`: The EAB Key ID for ZeroSSL.

5. **Kustomization**

   - Defined in `kustomization.yaml`.
   - Ties together the resources, secrets, and ConfigMap.
   - Uses `replacements` to inject values from the ConfigMap into the `ClusterIssuer` and `Certificate` resources.

### Setup Steps for ZeroSSL

1. **Obtain EAB Credentials**:

   - Log in to your ZeroSSL account.
   - Generate an EAB key pair in the ZeroSSL dashboard.
   - Note down the **EAB Key ID** and **EAB HMAC Key**.

2. **Prepare** `config.env`:

   - Create a `config.env` file with the following variables:

     ```
     EMAIL=your@email.com
     DOMAIN=example.com
     ZEROSSL_ACCESS_KEY_ID=your_eab_key_id
     ```

   - Ensure the file is in the same directory as your Kustomization files.

3. **Set Environment Variable for EAB HMAC Key**:

   - Set the `ZEROSSL_EAB_HMAC_KEY` environment variable in your shell or CI/CD pipeline:

     ```bash
     export ZEROSSL_EAB_HMAC_KEY=your_eab_hmac_key
     ```

   - This value is used by the `secretGenerator` to create the `zerossl-eab-secret`.

4. **Apply the Kustomization**:

   - Run the following command to apply the ZeroSSL configuration:

     ```bash
     kubectl apply -k .
     ```

   - This creates the `ClusterIssuer`, `Certificate`, `ConfigMap`, and `Secret` resources in the `cert-manager` namespace.

5. **Verify Certificate Issuance**:

   - Check the status of the `Certificate` resource:

     ```bash
     kubectl -n cert-manager describe certificate myapp-cert
     ```

   - Ensure the certificate is issued and the corresponding secret is created.

---

## Let's Encrypt Configuration

### Purpose

Let's Encrypt is used as an alternative Certificate Authority to issue SSL certificates for domains in the cluster. It is simpler to configure than ZeroSSL as it does not require EAB credentials.

### Prerequisites

To use Let's Encrypt, you need:

- A valid email address for ACME registration.
- A domain name for which the certificate will be issued.
- Cert-Manager installed in the Kubernetes cluster (in the `cert-manager` namespace).
- An ingress controller (e.g., NGINX) to handle HTTP-01 challenges.

### Configuration Details

The Let's Encrypt configuration is defined in the following resources:

1. **ClusterIssuer (**`letsencrypt`**)**

   - Defined in `letsclusterissuer.yaml`.
   - Uses the Let's Encrypt ACME server (typically `https://acme-v02.api.letsencrypt.org/directory`).
   - Configures an email address (replaced dynamically from `config.env`).
   - References a private key secret for storing the ACME account key.
   - Uses the HTTP-01 solver with the NGINX ingress class to validate domain ownership.

2. **Certificate (**`myapp-cert`**)**

   - Defined in `letscertificate.yaml`.
   - Requests a certificate for a domain specified in `spec.dnsNames.0`, dynamically replaced from `DOMAIN` in `config.env`.

3. **ConfigMap (**`cert-manager-config`**)**

   - Generated from `config.env`.
   - Provides values for:
     - `EMAIL`: The email address for ACME registration.
     - `DOMAIN`: The domain for the certificate.

4. **Kustomization**

   - Defined in `kustomization.yaml`.
   - Ties together the resources and ConfigMap.
   - Uses `replacements` to inject values from the ConfigMap into the `ClusterIssuer` and `Certificate` resources.

### Setup Steps for Let's Encrypt

1. **Prepare** `config.env`:

   - Ensure the `config.env` file includes:

     ```
     EMAIL=your@email.com
     DOMAIN=example.com
     ```

   - This file is shared with the ZeroSSL configuration.

2. **Apply the Kustomization**:

   - Run the following command to apply the Let's Encrypt configuration:

     ```bash
     kubectl apply -k .
     ```

   - This creates the `ClusterIssuer`, `Certificate`, and `ConfigMap` resources in the `cert-manager` namespace.

3. **Verify Certificate Issuance**:

   - Check the status of the `Certificate` resource:

     ```bash
     kubectl -n cert-manager describe certificate myapp-cert
     ```

   - Ensure the certificate is issued and the corresponding secret is created.

---

## Common Notes

- **Namespace**: Both configurations deploy resources in the `cert-manager` namespace.
- **ConfigMap Sharing**: The `cert-manager-config` ConfigMap is shared between ZeroSSL and Let's Encrypt configurations, providing `EMAIL` and `DOMAIN` values.
- **HTTP-01 Solver**: Both CAs use the HTTP-01 challenge with the NGINX ingress controller to verify domain ownership. Ensure the ingress controller is properly configured.
- **Certificate Management**: Cert-Manager automatically renews certificates before they expire, provided the `ClusterIssuer` and `Certificate` resources are correctly configured.
- **Troubleshooting**:
  - Check Cert-Manager logs for errors: `kubectl -n cert-manager logs -l app=cert-manager`.
  - Verify the `ClusterIssuer` status: `kubectl -n cert-manager describe clusterissuer zerossl` or `kubectl -n cert-manager describe clusterissuer letsencrypt`.
  - Ensure the domain's DNS records point to the correct ingress controller.

## When to Use ZeroSSL vs. Let's Encrypt

- **ZeroSSL**:
  - Use when you need certificates from a CA other than Let's Encrypt (e.g., for compliance or diversity).
  - Requires EAB credentials, which adds setup complexity.
  - Suitable for production environments with specific CA requirements.
- **Let's Encrypt**:
  - Use for simplicity and widespread acceptance.
  - No EAB credentials required, making setup easier.
  - Ideal for development, testing, or production environments where Let's Encrypt is sufficient.

## Security Considerations

- Store `config.env` and `ZEROSSL_EAB_HMAC_KEY` securely (e.g., in a secret management system).
- Restrict access to the `cert-manager` namespace.
- Regularly update Cert-Manager to the latest version to address security vulnerabilities.

By following this guide, you can successfully configure ZeroSSL and Let's Encrypt with Cert-Manager to issue and manage SSL certificates in your Kubernetes cluster.