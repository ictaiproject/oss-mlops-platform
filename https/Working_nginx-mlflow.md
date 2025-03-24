# How HTTPS Gets the Certificate Using ClusterIssuer and Nginx Ingress

This guide explains how cert-manager, ClusterIssuer, Nginx Ingress, and MLflow Ingress work together to issue and use a TLS certificate.

## Step 1: Certificate Issuance
* The ClusterIssuer (from `clusterIssuer.yaml`) generates or requests certificates.
* Cert-manager requests a certificate from the ClusterIssuer when `mlflow-certificate.yaml` is applied.
* The certificate is stored in a Kubernetes Secret named `mlflow-tls`.

### Key Resource: mlflow-certificate.yaml
```yml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mlflow-cert
  namespace: mlflow
spec:
  secretName: mlflow-tls
  issuerRef:
    name: self-signature-issuer
    kind: ClusterIssuer
  dnsNames:
    - mlflow.local
```

## Step 2: Nginx Ingress Uses the Certificate
* The `mlflow-ingress.yaml` file tells the Ingress controller (Nginx) to use TLS termination.
* Nginx uses the `mlflow-tls` secret as the source of the SSL certificate.

### Key Resource: mlflow-ingress.yaml
```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mlflow-ingress
  namespace: mlflow
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - mlflow.local
      secretName: mlflow-tls
```

## Step 3: Traffic Flow Through Nginx
1. A user requests `https://mlflow.local`.
2. Nginx checks the TLS certificate in the `mlflow-tls` secret.
3. If the certificate is valid, the HTTPS handshake is completed.
4. Nginx forwards the request to the MLflow service.

## Verification
* Check if the certificate is issued: `kubectl get certificate -n mlflow`
* Check if the secret is created: `kubectl get secret mlflow-tls -n mlflow`
* Check the Ingress configuration: `kubectl describe ingress mlflow-ingress -n mlflow`
* Test HTTPS with Curl: `curl -v https://mlflow.local`

## Recap
| Component | Role |
| --- | --- |
| ClusterIssuer | Issues certificates via cert-manager |
| Cert-Manager | Requests, manages, and renews certificates |
| Kubernetes Secret (mlflow-tls) | Stores the issued certificate and private key |
| Nginx Ingress Controller | Acts as a reverse proxy, handling HTTPS and forwarding requests |
| MLflow Ingress (mlflow-ingress.yaml) | Tells Nginx how to route requests to the MLflow service |
| MLflow Service (mlflow.yaml) | Exposes the MLflow server inside Kubernetes |
