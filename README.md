# Common ROS Noetic Docker

A Docker-based development environment for ROS Noetic with pre-configured tools and dependencies.

## Overview

This project provides a containerized ROS Noetic development environment with commonly used packages, debugging tools, and development utilities pre-installed.

> **Other Languages**: [简体中文](README_zh.md)

> By default, this project uses `HOST_HOME_DIR` from `.env` for both container working directory and home volume mapping, so usernames are not hardcoded.

## Features

- **Base Image**: OSRF ROS Noetic desktop full
- **Development Tools**: catkin_tools, rosinstall, wstool, build-essential, cmake
- **Debugging Tools**: rqt suite, RViz, PlotJuggler
- **Navigation & SLAM**: navigation stack, gmapping, hector_mapping, robot_localization
- **Motion Planning**: MoveIt
- **Simulation**: Gazebo, ros_control
- **Communication**: rosbridge_server, tf2, actionlib
- **Hardware Interface**: serial, joy, teleop packages
- **Data Processing**: sensor_msgs, geometry_msgs, nav_msgs, message_filters

## Quick Start

### 1. Configure Environment Variables

Before first use, set your host user directory path in the `.env` file at the project root:

```bash
HOST_HOME_DIR=/home/your-username
```

### 2. Choose and Run the Configuration Matching Your GPU

Select the Docker Compose file that matches your hardware configuration:

#### A. AMD Integrated GPU (RDNA 3.5 architecture & newer AMD cards)
Compiles Python 3.10 and Mesa 26.1-devel from source based on LLVM 21 to fully support new AMD integrated GPUs (such as Radeon 880M).
* **Build**:
  ```bash
  docker compose -f docker-compose.amd.yml build
  ```
* **Start**:
  ```bash
  docker compose -f docker-compose.amd.yml up -d
  ```

#### B. Intel Integrated GPU (Intel UHD, Iris Xe, etc.)
Compiles Mesa 26.1-devel from source targeting Intel's `iris` and `crocus` drivers to support both new and old Intel graphics cards.
* **Build**:
  ```bash
  docker compose -f docker-compose.intel.yml build
  ```
* **Start**:
  ```bash
  docker compose -f docker-compose.intel.yml up -d
  ```

#### C. NVIDIA Discrete GPU
**Skips the time-consuming Mesa compilation phase**, leveraging the host's NVIDIA drivers via the `nvidia-container-toolkit` for high performance and fast build speeds.
* **Prerequisites**: Ensure the host has `nvidia-container-toolkit` installed.
* **Build**:
  ```bash
  docker compose -f docker-compose.nvidia.yml build
  ```
* **Start**:
  ```bash
  docker compose -f docker-compose.nvidia.yml up -d
  ```

### 3. Access the Container

For AMD and NVIDIA configurations:
```bash
docker exec -it ros1_noetic_dev bash
```

For Intel configuration:
```bash
docker exec -it ros1_noetic_intel_dev bash
```

*(Note: The SSH server inside the Intel container is configured on port `2223` instead of `2222` to avoid host network conflicts when running containers concurrently.)*

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ROS_IP` | `127.0.0.1` | ROS network interface |
| `ROS_MASTER_URI` | `http://localhost:11311` | ROS master URI |
| `DISPLAY` | - | X11 display for GUI applications |
| `HOST_HOME_DIR` | `/home/hyd` | Host user directory (used for build arg, container workdir, and volume mapping) |

### Volumes

- `/tmp/.X11-unix`: X11 socket for GUI support
- `${HOST_HOME_DIR}:${HOST_HOME_DIR}`: User home directory mapping
- `vscode-server-data:/root/.vscode-server`: persist VS Code Server binaries and remote user data
- `vscode-extensions:/root/.vscode/extensions`: persist additional extension cache

### Faster Dev Container Reopen (recommended)

1. Keep using the same Docker Compose project name (default is folder name), so named volumes are reused.
2. Avoid `down -v` unless you intentionally want to clear caches.
3. If you need to rebuild image, prefer rebuild without deleting volumes.

If startup is still slow on first run, it's usually network-bound while downloading VS Code Server.

## Available Tools

### ROS Debugging
- `rqt-*` - Complete rqt plugin suite
- `rviz` - 3D visualization
- `plotjuggler` - Time series data visualization

### Navigation & Mapping
- `robot_localization` - Multi-sensor state estimation
- `navigation` - Navigation stack
- `slam_gmapping` - Grid-based SLAM
- `hector_mapping` - Hector SLAM

### Robot Control
- `moveit` - Motion planning framework
- `gazebo_ros_pkgs` - Robot simulation
- `ros_control` - Robot control framework

## Dependencies

- Docker
- Docker Compose
- X11 server (for GUI applications)

## License

MIT License

## Acknowledgments

- [OSRF](https://www.osrfoundation.org/) - ROS Noetic base image
- [ROS](https://www.ros.org/) - Robot Operating System
