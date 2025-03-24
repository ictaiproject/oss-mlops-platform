# Managing Certificates and Ingress for MLflow in Kubernetes
This guide explains how to apply, verify, troubleshoot, and delete certificates and Ingress resources in a Kubernetes cluster.

## 1.1 Apply the Required Resources
These commands apply the necessary Kubernetes resources to set up HTTPS for MLflow using cert-manager and an nginx ingress controller.

### Commands:
```bash
kubectl apply -f clusterIssuer.yaml
kubectl apply -f mlflow-certificate.yaml
kubectl apply -f mlflow-ingress.yaml
```
### What These Commands Do:
* `clusterIssuer.yaml` – Creates a ClusterIssuer, which is responsible for issuing TLS certificates using a self-signed CA or Let's Encrypt.
* `mlflow-certificate.yaml` – Requests a TLS certificate for the MLflow domain (e.g., mlflow.local).
* `mlflow-ingress.yaml` – Configures the Ingress to route traffic to MLflow and use the TLS certificate.

## 1.2 Verify Certificate and Certificate Requests
After applying the resources, verify if the certificates are correctly issued.

### Commands:
```bash
kubectl get certificate -n mlflow
kubectl get certificaterequest -n mlflow
kubectl get orders -n mlflow
```
### What These Commands Do:
* `get certificate` – Lists all TLS certificates in the mlflow namespace.
* `get certificaterequest` – Displays the current status of certificate requests.
* `get orders` – Shows certificate signing requests handled by cert-manager.

## 1.3 Troubleshoot and Inspect Certificates
If there are issues with the certificate, check detailed information.

### Commands:
```bash
kubectl describe certificate mlflow-cert -n mlflow
kubectl describe certificaterequest -n mlflow
kubectl describe order -n mlflow
kubectl delete secret mlflow-tls -n mlflow
```
### What These Commands Do:
* `describe certificate mlflow-cert` – Provides details about the mlflow-cert, including its status and conditions.
* `describe certificaterequest` – Shows why a certificate request might be failing.
* `describe order` – Provides information about how the certificate is being issued.
* `delete secret mlflow-tls` – Removes the TLS secret, forcing a re-issuance of the certificate.

## 1.4 Delete Certificate and Ingress Resources
If a certificate is not working correctly, you might need to delete and reapply it.

### Commands:
```bash
kubectl delete clusterIssuer self-signature-issuer -n mlflow
kubectl delete certificate mlflow-cert -n mlflow
kubectl delete ingress mlflow-ingress -n mlflow
```
### What These Commands Do:
* `delete clusterIssuer` – Removes the ClusterIssuer.
* `delete certificate` – Deletes the MLflow certificate, allowing for regeneration.
* `delete ingress` – Deletes the Ingress resource.

## 1.5 Debugging the Nginx Ingress
To check if the Nginx Ingress Controller is working properly:

### Commands:
```bash
kubectl get ingress -n mlflow
kubectl describe ingress mlflow-ingress -n mlflow
kubectl logs -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
kubectl exec -it <nginx-ingress-pod> -n ingress-nginx -- cat /etc/nginx/nginx.conf
```
### What These Commands Do:
* `get ingress` – Lists the Ingress resources.
* `describe ingress` – Shows detailed information about how traffic is being routed.
* `logs -l app.kubernetes.io/name=ingress-nginx` – Fetches logs from the Nginx Ingress Controller.
* `exec -it <nginx-ingress-pod> -- cat /etc/nginx/nginx.conf` – Allows you to inspect the nginx.conf file inside the pod.

## 1.6 Testing HTTPS Connectivity
After everything is applied, test if MLflow is reachable over HTTPS.

### Commands:
```bash
curl -v https://mlflow.local
kubectl port-forward service/mlflow 5000:5000 -n mlflow
kubectl get services -n mlflow
```
### What These Commands Do:
* `curl -v https://mlflow.local` – Checks if HTTPS is working.
* `port-forward service/mlflow 5000:5000` – Temporarily exposes MLflow on localhost:5000 for testing.
* `get services` – Ensures the mlflow service is running.

--------------------

User prompt 2 of 2 - 3/19/2025, 11:26:20 PM:
convert this to markdown file

Llama 3.3 70B:
Here is the Markdown file:
```markdown
# Managing Certificates and Ingress for MLflow in Kubernetes
This guide explains how to apply, verify, troubleshoot, and delete certificates and Ingress resources in a Kubernetes cluster.

## 1.1 Apply the Required Resources
These commands apply the necessary Kubernetes resources to set up HTTPS for MLflow using cert-manager and an nginx ingress controller.

### Commands:
```bash
kubectl apply -f clusterIssuer.yaml
kubectl apply -f mlflow-certificate.yaml
kubectl apply -f mlflow-ingress.yaml
```
### What These Commands Do:
* `clusterIssuer.yaml` – Creates a ClusterIssuer, which is responsible for issuing TLS certificates using a self-signed CA or Let's Encrypt.
* `mlflow-certificate.yaml` – Requests a TLS certificate for the MLflow domain (e.g., mlflow.local).
* `mlflow-ingress.yaml` – Configures the Ingress to route traffic to MLflow and use the TLS certificate.

## 1.2 Verify Certificate and Certificate Requests
After applying the resources, verify if the certificates are correctly issued.

### Commands:
```bash
kubectl get certificate -n mlflow
kubectl get certificaterequest -n mlflow
kubectl get orders -n mlflow
```
### What These Commands Do:
* `get certificate` – Lists all TLS certificates in the mlflow namespace.
* `get certificaterequest` – Displays the current status of certificate requests.
* `get orders` – Shows certificate signing requests handled by cert-manager.

## 1.3 Troubleshoot and Inspect Certificates
If there are issues with the certificate, check detailed information.

### Commands:
```bash
kubectl describe certificate mlflow-cert -n mlflow
kubectl describe certificaterequest -n mlflow
kubectl describe order -n mlflow
kubectl delete secret mlflow-tls -n mlflow
```
### What These Commands Do:
* `describe certificate mlflow-cert` – Provides details about the mlflow-cert, including its status and conditions.
* `describe certificaterequest` – Shows why a certificate request might be failing.
* `describe order` – Provides information about how the certificate is being issued.
* `delete secret mlflow-tls` – Removes the TLS secret, forcing a re-issuance of the certificate.

## 1.4 Delete Certificate and Ingress Resources
If a certificate is not working correctly, you might need to delete and reapply it.

### Commands:
```bash
kubectl delete clusterIssuer self-signature-issuer -n mlflow
kubectl delete certificate mlflow-cert -n mlflow
kubectl delete ingress mlflow-ingress -n mlflow
```
### What These Commands Do:
* `delete clusterIssuer` – Removes the ClusterIssuer.
* `delete certificate` – Deletes the MLflow certificate, allowing for regeneration.
* `delete ingress` – Deletes the Ingress resource.

## 1.5 Debugging the Nginx Ingress
To check if the Nginx Ingress Controller is working properly:

### Commands:
```bash
kubectl get ingress -n mlflow
kubectl describe ingress mlflow-ingress -n mlflow
kubectl logs -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
kubectl exec -it <nginx-ingress-pod> -n ingress-nginx -- cat /etc/nginx/nginx.conf
```
### What These Commands Do:
* `get ingress` – Lists the Ingress resources.
* `describe ingress` – Shows detailed information about how traffic is being routed.
* `logs -l app.kubernetes.io/name=ingress-nginx` – Fetches logs from the Nginx Ingress Controller.
* `exec -it <nginx-ingress-pod> -- cat /etc/nginx/nginx.conf` – Allows you to inspect the nginx.conf file inside the pod.

## 1.6 Testing HTTPS Connectivity
After everything is applied, test if MLflow is reachable over HTTPS.

### Commands:
```bash
curl -v https://mlflow.local
kubectl port-forward service/mlflow 5000:5000 -n mlflow
kubectl get services -n mlflow
```
### What These Commands Do:
* `curl -v https://mlflow.local` – Checks if HTTPS is working.
* `port-forward service/mlflow 5000:5000` – Temporarily exposes MLflow on localhost:5000 for testing.
* `get services` – Ensures the mlflow service is running.
