# Common ROS Noetic Docker

基于 Docker 的 ROS Noetic 开发环境，预配置了常用工具与依赖。

## 项目简介

本项目提供一个容器化的 ROS Noetic 开发环境，预装了常用的 ROS 功能包、调试工具和开发 utilities。

> **其他语言**: [English](README.md)

> 默认使用 `.env` 中的 `HOST_HOME_DIR` 作为容器工作目录和主目录挂载路径，避免硬编码用户名。

## 主要特性

- **基础镜像**: OSRF ROS Noetic desktop full
- **开发工具**: catkin_tools, rosinstall, wstool, build-essential, cmake
- **调试工具**: rqt 套件、RViz、PlotJuggler
- **导航与 SLAM**: navigation 导航栈、gmapping、hector_mapping、robot_localization
- **运动规划**: MoveIt
- **仿真环境**: Gazebo、ros_control
- **通信工具**: rosbridge_server、tf2、actionlib
- **硬件接口**: serial、joy、teleop 系列包
- **数据处理**: sensor_msgs、geometry_msgs、nav_msgs、message_filters

## 快速开始

### 1. 配置环境变量

首次使用请先在项目根目录 `.env` 中设置您的宿主机用户目录：

```bash
HOST_HOME_DIR=/home/你的用户名
```

### 2. 选择并使用对应显卡配置

根据您的电脑硬件配置，选择运行对应的 Docker Compose 文件：

#### A. AMD 核显 (RDNA 3.5 架构及其他新款 AMD 显卡)
本项目会自动下载 Python 3.10 并基于 LLVM 21 源码编译 Mesa 26.1-devel，以完美支持新款 AMD 显卡（例如 Radeon 880M）。
* **构建**：
  ```bash
  docker compose -f docker-compose.amd.yml build
  ```
* **启动**：
  ```bash
  docker compose -f docker-compose.amd.yml up -d
  ```

#### B. Intel 核显 (Intel UHD, Iris Xe 等)
本项目会自动源码编译 Mesa 26.1-devel，并指定编译 Intel 的 `iris` 与 `crocus` 驱动，以兼容新款与旧款 Intel 核显。
* **构建**：
  ```bash
  docker compose -f docker-compose.intel.yml build
  ```
* **启动**：
  ```bash
  docker compose -f docker-compose.intel.yml up -d
  ```

#### C. NVIDIA 独显/卡
本项目**跳过了耗时的 Mesa 源码编译阶段**，通过 `nvidia-container-toolkit` 直接透传宿主机的 NVIDIA 显卡驱动，构建速度极快。
* **前提条件**：宿主机需要提前安装好 `nvidia-container-toolkit`。
* **构建**：
  ```bash
  docker compose -f docker-compose.nvidia.yml build
  ```
* **启动**：
  ```bash
  docker compose -f docker-compose.nvidia.yml up -d
  ```

### 3. 进入容器

```bash
docker exec -it ros1_noetic_dev bash
```

## 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ROS_IP` | `127.0.0.1` | ROS 网络接口地址 |
| `ROS_MASTER_URI` | `http://localhost:11311` | ROS 主节点 URI |
| `DISPLAY` | - | X11 显示，用于 GUI 应用 |
| `HOST_HOME_DIR` | `/home/hyd` | 宿主用户目录（同时用于构建参数、容器工作目录和卷映射） |

### 卷映射

- `/tmp/.X11-unix`: X11 套接字，支持图形界面应用
- `${HOST_HOME_DIR}:${HOST_HOME_DIR}`: 用户主目录映射
- `vscode-server-data:/root/.vscode-server`: 持久化 VS Code Server 二进制与远程用户数据
- `vscode-extensions:/root/.vscode/extensions`: 持久化附加扩展缓存

### Dev Container 二次连接加速建议（推荐）

1. 保持相同的 Compose 项目名（默认就是目录名），确保命名卷可复用。
2. 非必要不要执行 `down -v`，否则会清空缓存卷。
3. 需要重建镜像时，优先只重建镜像，不删除卷。

如果首次连接仍慢，通常是 VS Code Server 首次下载阶段受网络带宽影响。

## 可用工具

### ROS 调试工具
- `rqt-*` - 完整的 rqt 插件套件
- `rviz` - 3D 可视化工具
- `plotjuggler` - 时序数据可视化工具

### 导航与建图
- `robot_localization` - 多传感器状态估计
- `navigation` - 导航功能栈
- `slam_gmapping` - 栅格地图 SLAM
- `hector_mapping` - Hector SLAM 算法

### 机器人控制
- `moveit` - 运动规划框架
- `gazebo_ros_pkgs` - 机器人仿真环境
- `ros_control` - 机器人控制框架

## 依赖要求

- Docker
- Docker Compose
- X11 服务器（用于图形界面应用）

## 许可证

MIT License

## 致谢

- [OSRF](https://www.osrfoundation.org/) - ROS Noetic 基础镜像
- [ROS](https://www.ros.org/) - 机器人操作系统
