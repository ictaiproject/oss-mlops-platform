# 📌 MLOps Platform Setup Guide

## 🚀 1. Cloning the Repository

### 1.1 Clone the MLOps Repository
```sh

git clone https://github.com/Softala-MLOPS/oss-mlops-platform.git
cd oss-mlops-platform
```

---

## 🛠️ 2. Installing Required Tools

### 2.1 Install Docker
```sh
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
Verify installation:
```sh
docker --version
```

### 2.2 Install Kubernetes (kubectl)
```sh
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```
Verify installation:
```sh
kubectl version --client
```

### 2.3 Install Kind (Kubernetes in Docker)
```sh
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/
```
Verify installation:
```sh
kind version
```

---

## 🌍 3. Creating and Configuring Kubernetes Cluster

### 3.1 Create a Kubernetes Cluster with Kind
```sh
kind create cluster --name mlops-cluster
```
Verify cluster is running:
```sh
kubectl cluster-info
```

### 3.2 Check Kubernetes Nodes
```sh
kubectl get nodes
```

---

## 🚀 4. Deploying MLOps Services

### 4.1 Apply MLOps Deployment Files
```sh
kubectl apply -f mlflow-deployment.yaml
```

### 4.2 Check Running Pods
```sh
kubectl get pods -A
```

---

## 🔧 5. Troubleshooting Issues

### Issue: Kubernetes Deployment Not Found
```
Error from server (NotFound): deployments.apps "mlflow" not found
```
#### Solution:
```sh
kubectl get deployments -A
kubectl apply -f mlflow-deployment.yaml
```

### Issue: Pod Stuck in "CrashLoopBackOff"
```sh
kubectl describe pod <pod-name> -n mlflow
kubectl logs <pod-name> -n mlflow
```

### Issue: Kubernetes Cluster Not Found
```sh
kubectl config current-context
kubectl config use-context kind-mlops-cluster
```

### Issue: Pods Not Running
```sh
kubectl get pods -A
kubectl describe pod <pod-name>
```
#### Solution:
- Check if any pods are in `Pending` state.
- Verify logs for errors and missing dependencies.
- Restart failed pods:
```sh
kubectl delete pod <pod-name>
kubectl apply -f mlflow-deployment.yaml
```

---

## 🎯 Conclusion
- Ensure **Docker, Kubernetes, and Kind** are installed correctly.
- If any **pods are failing**, check logs and redeploy.
- **Keep repositories updated** and sync with upstream regularly.
- **Now, you should have a fully working MLOps deployment!** 🚀
