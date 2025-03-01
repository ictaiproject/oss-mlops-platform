# 📌 MLOps Platform Setup and Deployment Guide

## 🚀 1. Setting Up GitHub Organization and Repository Forking

### 1.1 Creating a GitHub Organization
We created a new GitHub organization named **`ictaigithub`** to manage our repositories collaboratively.

### 1.2 Forking the Repository
We forked the main branch of **`oss-mlops-platform`** into our newly created organization. This allows us to make changes independently while keeping the option to sync with the upstream repository.

### 1.3 Managing Organization Members
- Added all team members to the organization for collaboration.
- Assigned **Jukka** as the **owner** of the organization to grant full administrative control.

### 1.4 Next Steps
- Set up repository access permissions to ensure smooth collaboration.
- Define contribution workflows for the team.
- Synchronize changes from the upstream repository when needed.

---



## 🌍 2. Installing and Running MLOps Platform on Cpouta

### 2.1 Connect to Cpouta Environment
```sh
ssh <username>@csc.fi
```

### 2.2 Clone the MLOps Repository on Cpouta
```sh
git clone <repo-url>
cd oss-mlops-platform
```

### 2.3 Install Dependencies
```sh
module load python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2.4 Set Up Kubernetes on Cpouta
1️ **Start a Kubernetes Cluster:**
```sh
kubectl create cluster --name mlops-platform
```

2️ **Verify Kubernetes Status:**
```sh
kubectl get nodes
```

### 4.5 Deploy MLflow on Cpouta
```sh
kubectl apply -f mlflow-deployment.yaml
```

### 4.6 Verify Deployment
```sh
kubectl get pods -n mlflow
kubectl get svc -n mlflow
```

---

## 5. Troubleshooting Issues on Cpouta

### Issue: Kubernetes Deployment Not Found
```
Error from server (NotFound): deployments.apps "mlflow" not found
```

#### Solution:
- Check if the deployment exists:
  ```sh
  kubectl get deployments --all-namespaces
  ```
- If missing, redeploy it:
  ```sh
  kubectl apply -f mlflow-deployment.yaml
  ```

---

## Conclusion
- If **local setup** fails, prefer **Cpouta deployment**.
- Keep **Docker images correctly referenced** in Kubernetes.
- Use **GitHub branches** to safely move code from Cpouta to local.
- **Regularly sync** with the upstream repository.

 **Now, you should have a stable MLOps deployment on Cpouta!**
