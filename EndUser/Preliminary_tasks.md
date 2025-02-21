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

## 🛠️ 2. Troubleshooting ImagePullErr: Moving Code from Cpouta to GitHub to Local Machine

### 2.1 Create a New Branch on GitHub
Before pushing the code from **Cpouta**, create a new branch on GitHub:

```sh
git checkout -b new-branch
```

Push the branch to GitHub:

```sh
git push origin new-branch
```

### 2.2 Push Code from Cpouta to GitHub
Ensure your Git is configured correctly:

```sh
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Add and commit your changes:

```sh
git add .
git commit -m "Pushing code from Cpouta"
```

Push the changes:

```sh
git push origin new-branch
```

### 2.3 Pull the Branch to a Local Machine
On your local machine, clone the repository if you haven't already:

```sh
git clone https://github.com/your-username/repository.git
```

Navigate into the repository and switch to the new branch:

```sh
cd repository
git checkout new-branch
```

Pull the latest changes:

```sh
git pull origin new-branch
```

---

## 🔧 3. Troubleshooting `ImagePullErr`

### 3.1 Check the Image Name
Ensure the image name in the `Dockerfile` or Kubernetes deployment YAML is correct.

```sh
kubectl describe pod <pod-name>
```

### 3.2 Force Kubernetes to Use a Locally Available Image
If using local images, prevent Kubernetes from pulling remote images:

```sh
kubectl patch deployment mlflow -p '{"spec": {"template": {"spec": {"containers": [{"name": "mlflow", "imagePullPolicy": "IfNotPresent"}]}}}}'
```

### 3.3 Restart Kubelet
```sh
sudo systemctl restart kubelet
```

---

## 🌍 4. Installing and Running MLOps Platform on Cpouta

### 4.1 Connect to Cpouta Environment
```sh
ssh <username>@csc.fi
```

### 4.2 Clone the MLOps Repository on Cpouta
```sh
git clone <repo-url>
cd oss-mlops-platform
```

### 4.3 Install Dependencies
```sh
module load python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4.4 Set Up Kubernetes on Cpouta
1️⃣ **Start a Kubernetes Cluster:**
```sh
kubectl create cluster --name mlops-platform
```

2️⃣ **Verify Kubernetes Status:**
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

## ❌ 5. Troubleshooting Issues on Cpouta

### Issue: Kubernetes Deployment Not Found
```
Error from server (NotFound): deployments.apps "mlflow" not found
```

#### ✅ Solution:
- Check if the deployment exists:
  ```sh
  kubectl get deployments --all-namespaces
  ```
- If missing, redeploy it:
  ```sh
  kubectl apply -f mlflow-deployment.yaml
  ```

---

## 🎯 Conclusion
- If **local setup** fails, prefer **Cpouta deployment**.
- Keep **Docker images correctly referenced** in Kubernetes.
- Use **GitHub branches** to safely move code from Cpouta to local.
- **Regularly sync** with the upstream repository.

🚀 **Now, you should have a stable MLOps deployment on Cpouta!**
