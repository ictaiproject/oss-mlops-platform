# MLOps Setup & Troubleshooting Report

---

## 📌 Introduction

This document summarizes the **step-by-step setup process** and **troubleshooting solutions** encountered while configuring an **MLOps platform** on a MacBook and later moving the installation to **CSC with Cpouta** due to local image pull issues. The report covers **Kubernetes, MLflow, Jupyter Notebook, and GitHub**.

---

## 1️⃣ Initial Attempt: Installing and Running MLOps Platform on macOS

### **Step 1: Install Homebrew (Package Manager for macOS)**

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### **Step 2: Install Required Dependencies**

```sh
brew install git python3 kubectl kind docker
```

### **Step 3: Clone the MLOps Platform Repository**

```sh
git clone <repo-url>
cd oss-mlops-platform
```

### **Step 4: Install Python Virtual Environment and Required Packages**

```sh
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### **Step 5: Start Docker and Verify Installation**

- Ensure Docker is running.
- Check Docker version:
  ```sh
  docker --version
  ```

### **Step 6: Create a Kind Kubernetes Cluster**

```sh
kind create cluster --name mlops-platform
```

### **Step 7: Load the MLflow Docker Image into Kind**

```sh
kind load docker-image ghcr.io/oss-mlops-platform/mlflow_v2:0.0.1 --name mlops-platform
```

### **Step 8: Deploy MLflow on Kubernetes**

```sh
kubectl apply -f mlflow-deployment.yaml
```

### **Step 9: Verify Pods and Services**

```sh
kubectl get pods -n mlflow
kubectl get svc -n mlflow
```

### **Issue: ImagePullBackOff Error on Local Installation**

Despite successfully setting up the environment, the Kubernetes deployment encountered the **ImagePullBackOff** error, preventing MLflow from running locally.

#### **Troubleshooting Attempts:**

1️⃣ **Checked Pod Logs:**

```sh
kubectl describe pod <POD_NAME>
```

2️⃣ **Ensured Image Existed in Kind Cluster:**

```sh
docker images | grep mlflow_v2
```

3️⃣ **Forced Kubernetes to Use Local Image:**

```sh
kubectl patch deployment mlflow -p '{"spec": {"template": {"spec": {"containers": [{"name": "mlflow", "imagePullPolicy": "IfNotPresent"}]}}}}'
```

4️⃣ **Restarted Kubelet:**

```sh
sudo systemctl restart kubelet
```

### **Final Decision:** Move Installation to CSC with Cpouta

Since local execution was unstable due to image pulling issues, **Cpouta was chosen as the new deployment environment.**

---

## 2️⃣ Setting Up MLOps on CSC with Cpouta

### **Step 1: Connect to Cpouta Environment**

```sh
ssh <username>@csc.fi
```

### **Step 2: Clone the MLOps Repository on CSC**

```sh
git clone <repo-url>
cd oss-mlops-platform
```

### **Step 3: Install Dependencies**

```sh
module load python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### **Step 4: Set Up Kubernetes on Cpouta**

1️⃣ **Start a Kubernetes Cluster:**

```sh
kubectl create cluster --name mlops-platform
```

2️⃣ **Verify Kubernetes Status:**

```sh
kubectl get nodes
```

### **Step 5: Deploy MLflow on Cpouta**

```sh
kubectl apply -f mlflow-deployment.yaml
```

### **Step 6: Verify Deployment**

```sh
kubectl get pods -n mlflow
kubectl get svc -n mlflow
```

---

## 3️⃣ Troubleshooting Issues on Cpouta

### **Issue: Kubernetes Deployment Not Found**

```
Error from server (NotFound): deployments.apps "mlflow" not found
```

#### **Solution:**

- Check if the deployment exists:
  ```sh
  kubectl get deployments --all-namespaces
  ```
- If missing, redeploy it:
  ```sh
  kubectl apply -f mlflow-deployment.yaml
  ```

---

## 📌 Conclusion

### **Key Takeaways:**

- **Attempted local installation on macOS**, but faced `ImagePullBackOff` errors due to issues pulling images.
- **Migrated deployment to CSC with Cpouta**, where Kubernetes and MLflow were successfully installed.
- **Encountered and resolved issues** with deployment visibility.

🚀 **Final Status: MLOps is running successfully on Cpouta!** 🚀
