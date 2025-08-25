# Deep Learning Container Management Scripts
[简体中文](README_zh-CN.md)

This project provides a set of scripts for building and managing Docker containers tailored for deep learning development on servers. It simplifies the process of creating reproducible environments with specific CUDA versions, managing ports, and handling storage.

## ✨ Core Features

- **Custom Docker Image Build**: Build a custom deep learning environment with Miniconda, JupyterLab, and essential development tools pre-installed.
- **Dynamic CUDA Version Support**: Create containers with different CUDA versions (e.g., 12.4, 12.1, 11.8) using a single script.
- **Automated Port Management**: Automatically assigns and manages SSH and service ports for each container, preventing conflicts.
- **Firewall Integration**: Automatically configures firewall rules (using `firewall-cmd`) for container ports.
- **Simplified Container Lifecycle Management**: Easy-to-use scripts to create, delete, and manage containers.
- **Persistent Storage**: Automatically creates and mounts workspace directories for persistent data.
- **Robust JupyterLab Management**: Includes a script inside the container to safely start, stop, and check the status of the JupyterLab service.

##  Prerequisites

Before you begin, ensure you have the following installed on your host machine:
- **Docker Engine**: [Installation Guide](https://docs.docker.com/engine/install/)
- **NVIDIA GPU Drivers**: The appropriate drivers for your GPU.
- **NVIDIA Container Toolkit**: [Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- **firewalld**: The scripts use `firewall-cmd` to manage firewall rules.

## 📂 Directory Structure

```
.
├── build/
│   ├── Dockerfile           # Dockerfile to build the base deep learning image.
│   ├── init_container.sh    # Entrypoint script for the container (starts SSH).
│   └── lab.sh               # Script to manage JupyterLab inside the container.
├── run_container.sh         # Script to create and run a new container.
├── del_container.sh         # Script to delete a container and clean up resources.
└── README.md                # This documentation file.
```

## 🚀 Getting Started

### 1. Build the Docker Image

The provided `Dockerfile` is designed to build a complete deep learning environment. You should build and tag the images that your `run_container.sh` script will use.

For example, to build an image for CUDA 12.4.1:

```bash
# Navigate to the project root directory
cd /path/to/deep-container

# Build and tag the image
# The Dockerfile uses 'nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04' as its base
cd build
docker buildx build -t cuda:12.4.1-cudnn-miniconda-ubuntu22.04 .
```

*Note: The `run_container.sh` script expects specific image tags (e.g., `cuda:12.4.1-cudnn-miniconda-ubuntu22.04`, `cuda:11.8.0-cudnn-miniconda-ubuntu22.04`, etc.). You need to build these images yourself or pull them from a registry if they already exist.*

### 2. Create a New Container

The `run_container.sh` script simplifies the creation of new containers.

**Usage:**
```bash
bash run_container.sh <name> [cuda_version]
```

- `<name>`: A unique name for your container. The final container will be named `deep-<name>`.
- `[cuda_version]`: (Optional) The desired CUDA version. Defaults to `12.4`. Supported versions are `12.4`, `12.1`, `12.0`, `11.8`, `11.7`.

**Examples:**

```bash
# Create a container named 'my-project' with the default CUDA version (12.4)
bash run_container.sh my-project

# Create a container named 'legacy-project' with CUDA 11.8
bash run_container.sh legacy-project 11.8
```

The script will:
1.  Assign a unique SSH port (starting from 23).
2.  Create persistent workspace directories at `/data/<name>` and `/data/share/<name>`.
3.  Select the appropriate Docker image based on the CUDA version.
4.  Start the container `deep-<name>`.
5.  Open the necessary firewall ports for SSH, JupyterLab, and TensorBoard.

### 3. Delete a Container

The `del_container.sh` script is used to remove a container and optionally clean up associated resources.

**Usage:**
```bash
bash del_container.sh <name> [--port] [--file] [--all]
```
- `<name>`: The name of the container to delete.
- `--port`: Removes the port mapping from `containers.txt` and closes the associated firewall ports.
- `--file`: Deletes the container's workspace directories (`/data/<name>` and `/data/share/<name>`).
- `--all`: Performs all cleanup actions (`--port` and `--file`).

**Examples:**

```bash
# Only delete the Docker container 'deep-my-project'
bash del_container.sh my-project

# Delete the container and also close firewall ports
bash del_container.sh my-project --port

# Delete the container and all its files
bash del_container.sh my-project --file

# Delete the container and all associated resources
bash del_container.sh my-project --all
```

## 🖥️ Inside the Container

### Connecting to the Container

Once a container is running, you can connect to it via SSH. The script will output the assigned SSH port.

```bash
ssh root@<server_ip> -p <assigned_ssh_port>
```
The default password is `123456`. It is strongly recommended to change it after the first login.

### Managing JupyterLab

A script is provided at `/root/lab.sh` inside the container to manage the JupyterLab service.

**Usage:**
```bash
# Start the JupyterLab service
bash /root/lab.sh start

# Stop the JupyterLab service
bash /root/lab.sh stop

# Check the running status of JupyterLab
bash /root/lab.sh status
```
- The JupyterLab port is automatically calculated as `<ssh_port> + 8000`.
- The service runs in the background, and logs are stored in `/var/log/jupyter.log`.
