# 📌 MLOps Platform Setup Guide

## 🚀 1. Cloning the Repository

### 1.1 Clone the MLOps Repository
```sh
# Replace <repo-url> with the actual repository link
git clone <repo-url>
cd oss-mlops-platform
```

---

## 2Install Docker
```sh
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
Verify installation:
```sh
docker --version
```




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
