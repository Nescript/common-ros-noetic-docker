FROM osrf/ros:noetic-desktop-full

USER root

# 1. 设置环境变量，避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# ROS 环境配置环境变量
ENV ROBOT_TYPE=standard6 \
    ROS_IP=127.0.0.1 \
    ROS_MASTER_URI=http://localhost:11311 \
    QT_AUTO_SCREEN_SCALE_FACTOR=0 \
    QT_ENABLE_HIGHDPI_SCALING=1 \
    QT_SCALE_FACTOR=1

ARG HOST_HOME_DIR=/home/hyd
ENV HOST_HOME_DIR=${HOST_HOME_DIR}

# 2. 基础系统工具、PPA 及 LLVM 21 源配置
# 将 LLVM 源提到前面，减少 apt-get update 次数
RUN apt-get update && apt-get install -y \
    sudo software-properties-common wget gnupg curl build-essential git vim jq sshpass\
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/llvm.gpg] http://apt.llvm.org/focal/ llvm-toolchain-focal-21 main' > /etc/apt/sources.list.d/llvm.list \
    && add-apt-repository -y ppa:kisak/kisak-mesa \
    && apt-get update && apt-get dist-upgrade -y \
    && apt-get install -y clangd-21 clang-format llvm-21-dev \
    && ln -s /usr/bin/clangd-21 /usr/local/bin/clangd \
    && ln -sf /usr/lib/llvm-21/bin/llvm-config /usr/local/bin/llvm-config \
    && rm -rf /var/lib/apt/lists/*
    
# 3. 安装 ROS Noetic 常用包及开发依赖
RUN apt-get update && apt-get install -y \
        ros-noetic-rqt-* ros-noetic-rviz ros-noetic-rviz-plugin-tutorials \
        ros-noetic-rviz-visual-tools ros-noetic-plotjuggler ros-noetic-plotjuggler-ros \
        ros-noetic-robot-localization ros-noetic-navigation ros-noetic-slam-gmapping \
        ros-noetic-hector-mapping ros-noetic-moveit ros-noetic-gazebo-ros-pkgs \
        ros-noetic-ros-control ros-noetic-ros-controllers ros-noetic-joint-state-publisher \
        ros-noetic-xacro ros-noetic-urdf ros-noetic-geometry-msgs ros-noetic-sensor-msgs \
        ros-noetic-nav-msgs ros-noetic-tf2-ros ros-noetic-tf2-geometry-msgs \
        ros-noetic-message-filters ros-noetic-rosbridge-server ros-noetic-joy \
        ros-noetic-teleop-twist-keyboard ros-noetic-teleop-twist-joy \
        ros-noetic-imu-complementary-filter ros-noetic-imu-filter-madgwick \
        ros-noetic-actionlib ros-noetic-actionlib-msgs ros-noetic-serial \
        ros-noetic-rosmon ros-noetic-rosmon-core ros-noetic-rosmon-msgs \
        python3-pip python3-catkin-tools python3-rosdep python3-rosinstall \
        python3-rosinstall-generator python3-wstool cmake libserial-dev iproute2 \
        # 补充编译 Mesa 所需的底层库
        libssl-dev zlib1g-dev libncurses5-dev libffi-dev libxml2-dev bison flex \
        libelf-dev libunwind-dev libglvnd-dev x11proto-dev libx11-dev \
        libx11-xcb-dev libxcb1-dev libxcb-randr0-dev libxcb-dri2-0-dev libxcb-dri3-dev \
        libxcb-present-dev libxcb-sync-dev libxcb-shm0-dev libxcb-glx0-dev libxcb-xfixes0-dev \
        libxfixes-dev libxdamage-dev libxshmfence-dev libxxf86vm-dev libxrandr-dev \
    && rm -rf /var/lib/apt/lists/*

# 4. 初始化 rosdep
RUN rm -f /etc/ros/rosdep/sources.list.d/20-default.list \
    && rosdep init \
    && rosdep fix-permissions \
    && mkdir -p /tmp/rosdep \
    && chmod 755 /tmp/rosdep \
    && chown nobody:nogroup /tmp/rosdep \
    && bash -lc 'set -e; for i in 1 2 3 4 5; do sudo -u nobody env HOME=/tmp/rosdep rosdep update && exit 0; echo "rosdep update failed (attempt ${i}), retrying..."; sleep 5; done; exit 1'

# 5. 编译安装 Python 3.10 及现代构建工具 (Meson/Mako/Ninja)
# 注意：此时不修改 /usr/bin/python3 软链接
WORKDIR /opt/python_build
RUN wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz && \
    tar -xf Python-3.10.13.tgz && cd Python-3.10.13 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) install && \
    # 使用新安装的 python3.10 安装最新版构建工具，彻底解决 Ninja 版本过低问题
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 && \
    python3.10 -m pip install meson mako ninja docutils pyyaml && \
    cd / && rm -rf /opt/python_build

# 6. 升级驱动栈 (Wayland -> Libdrm -> Mesa)
# 采用“临时软链接”策略，在单条 RUN 内完成编译后立即还原
WORKDIR /opt/driver_stack
RUN ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    # --- Wayland ---
    git clone --depth 1 https://gitlab.freedesktop.org/wayland/wayland.git && \
    cd wayland && meson setup build -Dprefix=/usr -Ddocumentation=false && \
    ninja -C build install && cd .. && \
    git clone --depth 1 https://gitlab.freedesktop.org/wayland/wayland-protocols.git && \
    cd wayland-protocols && meson setup build -Dprefix=/usr && \
    ninja -C build install && cd .. && \
    # --- Libdrm (支持 RDNA 3.5) ---
    git clone --depth 1 https://gitlab.freedesktop.org/mesa/drm.git && \
    cd drm && meson setup build -Dprefix=/usr && \
    ninja -C build install && cd .. && \
    # --- Mesa 26.1-devel ---
    git clone --depth 1 https://gitlab.freedesktop.org/mesa/mesa.git && \
    cd mesa && \
    sed -i "s/need: '>= 3.10'/need: '>= 3.8'/g" meson.build && \
    meson setup build \
        -Dprefix=/usr \
        -Dlibdir=lib/x86_64-linux-gnu \
        -Dplatforms=x11,wayland \
        -Dgallium-drivers=radeonsi,softpipe,llvmpipe \
        -Dvulkan-drivers=[] \
        -Dbuildtype=release \
        -Dllvm=enabled \
        -Dshared-llvm=enabled && \
    ninja -C build install && \
    rm -f /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python3.8 /usr/bin/python3 && \
    cd / && rm -rf /opt/driver_stack

# 恢复python3.8环境的小补丁,以及git信任仓库
RUN rm -f /usr/bin/python && \
    rm /usr/bin/python3 && \
    rm /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.8 /usr/bin/python3 && \
    ln -s /usr/bin/python3 && \
    git config --global --add safe.directory '*'
# 7. 运行时配置
ENV XINIT_THREADS=1 \
    MESA_LOADER_DRIVER_OVERRIDE=radeonsi

RUN mkdir -p -m 0700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hostsq

RUN apt-get update && apt-get install bash-completion

# 8. 配置 Bash 交互环境
RUN cat <<EOF >> /root/.bashrc

# 颜色化 bash
export TERM=xterm-256color
alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias ll="ls -alF --color=auto"
alias pl="rosrun plotjuggler plotjuggler"
alias openbash="vim ~/.bashrc"
alias wired="sshpass -p dynamicx ssh dynamicx@192.168.100.2"
alias wireless="sshpass -p dynamicx ssh dynamicx@192.168.1.116"
alias hl='echo "Hello,world!"'
alias wired_rqt="export ROS_MASTER_URI=http://192.168.100.2 && rqt"
PS1='\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '
source /usr/share/bash-completion/bash_completion
# ROS 环境配置
source /opt/ros/noetic/setup.bash

#export ROS_MASTER_URI=http://192.168.100.2:11311/
#export ROS_IP=192.168.100.1
export ROS_IP=127.0.0.1
export ROS_MASTER_URI=http://127.0.0.1:11311/
echo ROS_IP=$ROS_IP
echo ROS_MASTER_URI=$ROS_MASTER_URI
export ROBOT_TYPE=series_legged2
export WORKSPACE=/home/nesc/catkin_ws
source $WORKSPACE/devel/setup.bash
echo "Workspace env: $WORKSPACE"
EOF

WORKDIR ${HOST_HOME_DIR}

LABEL org.opencontainers.image.source=https://github.com/HydrogenZp/common-ros-noetic-docker \
      org.opencontainers.image.description="ROS Noetic with Mesa 26.1 (AMD 880M/RDNA 3.5 support)" \
      org.opencontainers.image.licenses=MIT
