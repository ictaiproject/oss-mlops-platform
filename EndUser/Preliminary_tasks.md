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
