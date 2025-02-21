# Preliminary Description

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

If it shows `ImagePullErr`, check the image name and repository.

### Authenticate to Container Registry

If using a private container registry, authenticate:

```sh
docker login -u <username> -p <password> <registry-url>
```

For Kubernetes, create a secret for authentication:

```sh
kubectl create secret docker-registry my-registry-secret \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>
```

Attach the secret to your deployment:

```yaml
imagePullSecrets:
  - name: my-registry-secret
```

### Check Network Issues

Ensure your cluster has internet access to pull images:

```sh
kubectl get nodes -o wide
ping <registry-url>
```

### Manually Pull the Image

Try pulling the image manually on the node:

```sh
docker pull <image-name>
```

If successful, tag and push it to a working registry:

```sh
docker tag <image-name> my-registry/new-image-name
docker push my-registry/new-image-name
```

Update your Kubernetes deployment to use the new image.

## 5. Deploy and Test

Redeploy the application:

```sh
kubectl apply -f deployment.yaml
```

Check pod status:

```sh
kubectl get pods
kubectl logs <pod-name>
