# Preliminary Description
# Setting Up GitHub Organization and Repository Forking  

## 1. Creating a GitHub Organization  
We created a new GitHub organization named **`ictaigithub`** to manage our repositories collaboratively.  

## 2. Forking the Repository  
We forked the main branch of **`oss-mlops-platform`** into our newly created organization. This allows us to make changes independently while keeping the option to sync with the upstream repository.  

## 3. Managing Organization Members  
- Added all team members to the organization for collaboration.  
- Assigned **Jukka** as the **owner** of the organization to grant full administrative control.  

## 4. Next Steps  
- Set up repository access permissions to ensure smooth collaboration.  
- Define contribution workflows for the team.  
- Synchronize changes from the upstream repository when needed.  

## cPouta Installation

Initially, I attempted to install the GitHub project locally on my Windows 11 machine. To do this, I needed to have WSL (Windows Subsystem for Linux) installed. Additionally, Docker Desktop must be installed on the Windows machine. Next, I copied the GitHub organization project, MLOPSAI. Using WSL, I was able to clone the repository to the Linux subsystem folder on my Windows machine with the `git clone` command. After that, I executed the installation using the command `sudo ./Setup.sh`.

Unfortunately, during the installation on the Windows machine, I encountered an error message stating "Kind not found," which prevented a successful setup of the MLOPSAI project.

Additionally, I installed this system on the CSC computer named Pouta. The steps for this are as follows:

1. Create a CSC account.
2. Start the project on the Pouta machine.
3. Copy the `.pem` key to the Linux folder and generate an SSH key pair.
4. Establish an SSH connection to the Pouta machine.
5. Copy the GitHub project to the Linux environment on Pouta.
6. After that, execute the installation using the command `sudo ./setup.sh`.



# Troubleshooting ImagePullErr: Moving Code from Cpouta to GitHub to Local Machine

## 1. Create a New Branch on GitHub

Before pushing the code from **Cpouta**, create a new branch on GitHub:

```sh
git checkout -b new-branch
```

Push the branch to GitHub:

```sh
git push origin new-branch
```

## 2. Push Code from Cpouta to GitHub

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

## 3. Pull the Branch to a Local Machine

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

## 4. Troubleshooting `ImagePullErr`

### Check the Image Name

Ensure the image name in the `Dockerfile` or Kubernetes deployment YAML is correct.

```sh
kubectl describe pod <pod-name>
```


## 1️ Initial Attempt: Installing and Running MLOps Platform on macOS

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

1️ **Checked Pod Logs:**

```sh
kubectl describe pod <POD_NAME>
```

2️ **Ensured Image Existed in Kind Cluster:**

```sh
docker images | grep mlflow_v2
```

3️ **Forced Kubernetes to Use Local Image:**

```sh
kubectl patch deployment mlflow -p '{"spec": {"template": {"spec": {"containers": [{"name": "mlflow", "imagePullPolicy": "IfNotPresent"}]}}}}'
```

4️ **Restarted Kubelet:**

```sh
sudo systemctl restart kubelet
```

### **Final Decision:** Move Installation to CSC with Cpouta

Since local execution was unstable due to image pulling issues, **Cpouta was chosen as the new deployment environment.**

---

## 2️ Setting Up MLOps on CSC with Cpouta

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

1️ **Start a Kubernetes Cluster:**

```sh
kubectl create cluster --name mlops-platform
```

2️ **Verify Kubernetes Status:**

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

## 3️.Troubleshooting Issues on Cpouta

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




