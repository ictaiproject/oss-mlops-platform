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



Initial Attempt: Installing and Running MLOps Platform on macOSStep 1: Install Homebrew (Package Manager for macOS)/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"Step 2: Install Required Dependenciesbrew install git python3 kubectl kind dockerStep 3: Clone the MLOps Platform Repositorygit clone <repo-url>
cd oss-mlops-platformStep 4: Install Python Virtual Environment and Required Packagespython3 -m venv venv
source venv/bin/activate
pip install -r requirements.txtStep 5: Start Docker and Verify InstallationEnsure Docker is running.
Check Docker version:
docker --versionStep 6: Create a Kind Kubernetes Clusterkind create cluster --name mlops-platformStep 7: Load the MLflow Docker Image into Kindkind load docker-image ghcr.io/oss-mlops-platform/mlflow_v2:0.0.1 --name mlops-platformStep 8: Deploy MLflow on Kuberneteskubectl apply -f mlflow-deployment.yamlStep 9: Verify Pods and Serviceskubectl get pods -n mlflow
kubectl get svc -n mlflowIssue: ImagePullBackOff Error on Local InstallationDespite successfully setting up the environment, the Kubernetes deployment encountered the ImagePullBackOff error, preventing MLflow from running locally.
Troubleshooting Attempts:1\ufe0f\u20e3 Checked Pod Logs:
kubectl describe pod <POD_NAME>2\ufe0f\u20e3 Ensured Image Existed in Kind Cluster:
docker images | grep mlflow_v23\ufe0f\u20e3 Forced Kubernetes to Use Local Image:
kubectl patch deployment mlflow -p '{"spec": {"template": {"spec": {"containers": [{"name": "mlflow", "imagePullPolicy": "IfNotPresent"}]}}}}'4\ufe0f\u20e3 Restarted Kubelet:
sudo systemctl restart kubeletFinal Decision: Move Installation to CSC with CpoutaSince local execution was unstable due to image pulling issues, Cpouta was chosen as the new deployment environment.
2\ufe0f\u20e3 Setting Up MLOps on CSC with CpoutaStep 1: Connect to Cpouta Environmentssh <username>@csc.fiStep 2: Clone the MLOps Repository on CSCgit clone <repo-url>
cd oss-mlops-platformStep 3: Install Dependenciesmodule load python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txtStep 4: Set Up Kubernetes on Cpouta1\ufe0f\u20e3 Start a Kubernetes Cluster:
kubectl create cluster --name mlops-platform2\ufe0f\u20e3 Verify Kubernetes Status:
kubectl get nodesStep 5: Deploy MLflow on Cpoutakubectl apply -f mlflow-deployment.yamlStep 6: Verify Deploymentkubectl get pods -n mlflow
kubectl get svc -n mlflow3\ufe0f\u20e3 Troubleshooting Issues on CpoutaIssue: Kubernetes Deployment Not FoundError from server (NotFound): deployments.apps "mlflow" not foundSolution:Check if the deployment exists:
kubectl get deployments --all-namespacesIf missing, redeploy it:
kubectl apply -f mlflow-deployment.yaml


