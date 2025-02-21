# Notice
you need to install wsl(for windows user only) before a user start creating a virtual machine.
how to setup wsl

# Setting Up Jupyter Notebook in WSL 2 Environment

This guide walks through the process of setting up a virtual environment for Jupyter Notebook in Windows Subsystem for Linux 2 (WSL 2).

## Prerequisites

- Windows 10 or 11 with WSL 2 installed
- Ubuntu or another Linux distribution running in WSL 2
- Basic familiarity with command line operations

## System Update and Package Installation

First, update your system's package list and install Python pip:

```bash
sudo apt update
sudo apt install python3-pip -y
```

## Creating and Setting Up the Virtual Environment

### 1. Clean Up Previous Installation (if any)

If you have a previous installation, remove it:

```bash
rm -rf ~/jupyter-env
```

Note: Be careful with the `rm -rf` command as it permanently deletes files and directories.

### 2. Create New Virtual Environment

Create a fresh Python virtual environment:

```bash
python3 -m venv ~/jupyter-env
```

### 3. Activate Virtual Environment

Activate the newly created environment:

```bash
source ~/jupyter-env/bin/activate
```

You should see `(jupyter-env)` appear at the beginning of your command prompt.

### 4. Update Pip and Install Jupyter

Update pip to the latest version and install Jupyter:

```bash
pip install --upgrade pip
pip install jupyter
```

## Starting Jupyter Notebook

Once installation is complete, start Jupyter Lab with:

```bash
jupyter-lab
```

This will launch Jupyter Lab in your default web browser. The server typically starts at `http://localhost:8888`.

## Tips and Troubleshooting

1. To deactivate the virtual environment when you're done:
   ```bash
   deactivate
   ```

2. If you need to install additional packages, make sure the virtual environment is activated first.

3. To check if you're in the virtual environment, look for `(jupyter-env)` in your command prompt.

4. If Jupyter Lab doesn't open automatically, copy the URL from the terminal and paste it into your browser.



## WSL 2 Specific Notes

- Jupyter will be accessible from Windows through your browser
- Files created in Jupyter can be accessed from Windows through the WSL file system
- The WSL environment can access your Windows files through `/mnt/c/`

Remember to keep your virtual environment activated while working with Jupyter. The environment needs to be reactivated each time you start a new terminal session.
